defmodule LAP2.Main.ShareHandler do
  @moduledoc """
  Handle managing, sending and receiving data from the network.
  """
  use GenServer
  require Logger
  alias LAP2.Utils.ShareHelper
  alias LAP2.Main.Helpers.ProcessorState

  @doc """
  Start the Router process.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, config.name})
  end

  @doc """
  Initialise the data handler GenServer.
  """
  @spec init(map) :: {:ok, map}
  def init(config) do
    # Ensure that the ETS gets cleaned up on exit
    Process.flag(:trap_exit, true)
    # Initialise data handler state
    IO.puts("[i] Share Handler: Starting GenServer")
    state = %{
      ets: :ets.new(:clove_ets, [:set, :private]),
      share_info: %{},
      config: config
    }
    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_cast({:deliver, binary, map}, map) :: {:noreply, map}
  def handle_cast({:deliver, data, aux_data}, state) do
    # TODO send data for parsing
    share = ShareHelper.deserialise(data)
    case ProcessorState.route_share(state, share) do
      :reassemble ->
        {:noreply, state}
      :cache ->
        {:noreply, state}
      :drop -> {:noreply, state}
    end
  end

  # Cleanup the ETS table on exit
  @spec terminate(any, map) :: :ok
  def terminate(_reason, state) do
    :ets.delete(state.ets)
    :ok
  end

  # ---- Public Functions ----
  @doc """
  Receive data from the network.
  """
  @spec deliver(binary, map, atom) :: :ok
  def deliver(data, aux_data, name) do
    GenServer.cast({:global, name}, {:deliver, data, aux_data})
  end

  # ---- Private Functions ----
  @spec add_or_update(map, non_neg_integer, non_neg_integer, non_neg_integer) :: map
  defp add_or_update(state, msg_sequence, share_id, threshold) when is_map_key(state.share_info, msg_sequence) do
    current_entry = Map.get(state.share_info, msg_sequence)
    new_entry = %{current_entry |
      share_ids: [share_id | current_entry.share_ids],
      timestamp: :os.system_time(:millisecond)
    }
    new_share_info = Map.put(state.share_info, msg_sequence, new_entry)
    %{state | share_info: new_share_info}
  end
  defp add_or_update(state, msg_sequence, share_id, threshold) do
    new_entry = %{
      threshold: threshold,
      share_ids: [share_id],
      timestamp: :os.system_time(:millisecond)
    }
    new_share_info = Map.put(state.sharet_info, msg_sequence, new_entry)
    %{state | share_info: new_share_info}
  end

  # Add a share and auxiliary information to the ETS table
  @spec add_share_to_ets(reference, Share, map) :: :ok | :error
  defp add_share_to_ets(ets, share, aux_data) do
    # Check if share.message_id is in ets
    new_struct = case :ets.lookup(ets, share.message_id) do
      [] -> %{
          shares: [share],
          aux_data: [aux_data]
        }
      [{_key, ets_struct}] -> %{
          shares: [share | ets_struct.shares],
          aux_data: [aux_data | ets_struct.aux_data]
        }
    end
    if :ets.insert(ets, {share.message_id, new_struct}), do: :ok, else: :error
  end

  defp get_share_from_ets(ets, message_id) do
    case :ets.lookup(ets, message_id) do
      [] -> {:error, :not_found}
      [{_key, ets_struct}] -> {:ok, ets_struct}
    end
  end

  @spec delete_share_from_ets(reference, non_neg_integer) :: :ok
  defp delete_share_from_ets(ets, message_id), do: :ets.delete(ets, message_id)
end
