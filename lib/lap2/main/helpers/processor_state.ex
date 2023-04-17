defmodule LAP2.Main.Helpers.ProcessorState do
  @moduledoc """
  Helper functions for processing the share handler state.
  """

  alias LAP2.Utils.ProtoBuf.ShareHelper
  alias LAP2.Utils.EtsHelper

  @doc """
  Route a share to the appropriate processing stage.
  """
  @spec route_share(map, Share.t()) :: :drop | :cache | :reassemble
  def route_share(state, share) do
    cond do
      ShareHelper.verify_share(share) ->
        handle_valid_share(state, share)

      true ->
        :drop
    end
  end

  # ---- State Management ----
  @doc """
  Cache a share in the share_info map.
  """
  @spec cache_share(map, map) :: map
  def cache_share(state, %Share{message_id: msg_id, share_idx: share_idx})
      when is_map_key(state.share_info, msg_id) do
    current_entry = Map.get(state.share_info, msg_id)

    new_entry = %{
      current_entry
      | share_idxs: [share_idx | current_entry.share_idxs],
        timestamp: :os.system_time(:millisecond)
    }

    new_share_info = Map.put(state.share_info, msg_id, new_entry)
    %{state | share_info: new_share_info}
  end

  def cache_share(state, %Share{
        message_id: msg_id,
        share_idx: share_idx,
        share_threshold: threshold
      }) do
    new_entry = %{
      threshold: threshold,
      share_idxs: [share_idx],
      timestamp: :os.system_time(:millisecond)
    }

    new_share_info = Map.put(state.sharet_info, msg_id, new_entry)
    %{state | share_info: new_share_info}
  end

  @doc """
  Delete a share from the share_info map.
  """
  @spec delete_from_cache(map, non_neg_integer) :: map
  def delete_from_cache(state, msg_id) do
    new_share_info = Map.delete(state.share_info, msg_id)
    %{state | share_info: new_share_info}
  end

  @doc """
  Add a message id to the drop list.
  """
  @spec add_to_drop_list(map, non_neg_integer) :: map
  def add_to_drop_list(state, msg_id) do
    %{state | drop_list: [msg_id | state.drop_list]}
  end

  # ---- ETS Functions ----
  @doc """
  Add a share and auxiliary information to the ETS table
  """
  @spec add_share_to_ets(:ets.tid(), Share, map) :: :ok
  def add_share_to_ets(ets, share, aux_data) do
    # Check if share.message_id is in ets
    new_struct =
      case EtsHelper.get_value(ets, share.message_id) do
        {:error, :not_found} ->
          %{
            shares: [share],
            aux_data: [aux_data]
          }

        {:ok, struct} ->
          %{
            shares: [share | struct.shares],
            aux_data: [aux_data | struct.aux_data]
          }
      end

    EtsHelper.insert_value(ets, share.message_id, new_struct)
    :ok
  end

  # ---- Private Functions ----
  # Handle valid share routing
  @spec handle_valid_share(map, Share) :: :drop | :reassemble | :cache
  defp handle_valid_share(state, share) when is_map_key(state.share_info, share.message_id) do
    share_cache = state.share_info[share.message_id]

    cond do
      share.share_idx in share_cache.share_idxs -> :drop
      true -> check_share_count(share_cache)
    end
  end

  defp handle_valid_share(_, _), do: :cache

  # Check the share count to determine if we should reassemble or cache
  @spec check_share_count(map) :: :reassemble | :cache
  defp check_share_count(share_cache) do
    cond do
      length(share_cache.share_idxs) >= share_cache.threshold - 1 -> :reassemble
      true -> :cache
    end
  end
end
