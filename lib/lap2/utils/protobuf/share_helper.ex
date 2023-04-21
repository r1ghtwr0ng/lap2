defmodule LAP2.Utils.ProtoBuf.ShareHelper do
  @moduledoc """
  Helper functions for processing IDA Shares.
  Verifies integrity, serves as interface for serialising/deserialising with ProtoBuf.
  """

  alias LAP2.Networking.ProtoBuf
  alias LAP2.Crypto.InformationDispersal.SecureIDA

  # ---- ProtoBuf wrappers ----
  @doc """
  Deserialise a share.
  """
  @spec deserialise(binary) :: {:ok, Share.t()} | {:error, any}
  def deserialise(dgram) do
    # Deserialise the share
    case ProtoBuf.deserialise(dgram, Share) do
      {:ok, share} -> {:ok, share}
      err -> err
    end
  end

  @doc """
  Serialise a share.
  """
  @spec serialise(Share.t()) :: {:ok, binary} | {:error, any}
  def serialise(share) do
    # Serialise the share
    case ProtoBuf.serialise(share) do
      {:ok, dgram} -> {:ok, IO.iodata_to_binary(dgram)}
      err -> err
    end
  end

  # ---- Share processing ----
  @doc """
  Reconstruct the data from the shares
  """
  @spec reconstruct(list(Share.t())) :: {:ok, binary} | {:error, any}
  def reconstruct(shares) do
    cond do
      valid_shares?(shares) -> SecureIDA.reconstruct(shares)
      true -> {:error, "Invalid shares"}
    end
  end

  @doc """
  Verify the share's validity.
  """
  @spec verify_share(Share.t()) :: boolean
  def verify_share(%Share{
        total_shares: n,
        share_threshold: m,
        share_idx: idx,
        key_share: %KeyShare{}
      }) do
    m <= n && idx <= n
  end

  def verify_share(_), do: false

  # Verify that all the shares are valid
  @spec valid_shares?(list(Share.t())) :: boolean
  defp valid_shares?(shares) do
    threshold = Enum.at(shares, 0).share_threshold
    total_shares = Enum.at(shares, 0).total_shares

    Enum.all?(shares, fn share ->
      verify_share(share) && share.threshold == threshold && share.total_shares == total_shares
    end)
  end

  @doc """
  Format the aux data into a map.
  """
  @spec format_aux_data(list(map)) :: {:ok, map} | {:error, :bad_aux_data}
  def format_aux_data([aux_data | rest]), do: format_aux_data(rest, aux_data)
  def format_aux_data(_), do: {:error, :bad_aux_data}

  @spec format_aux_data(list(map), map) :: {:ok, map} | {:error, atom}
  defp format_aux_data([], acc), do: {:ok, acc}
  defp format_aux_data([aux_data | rest], acc) do
    case merge_aux_data(aux_data, acc) do
      {:ok, acc} -> format_aux_data(rest, acc)
      err -> err
    end
  end

  # Merge the aux data into a map.
  @spec merge_aux_data(map, map) :: {:ok, map} | {:error, atom}
  defp merge_aux_data(aux_data, acc)
       when is_map_key(aux_data, :relay) and is_map_key(aux_data, :hop_count) do
    case Map.delete(Map.delete(aux_data, :relay), :hop_count) ===
           Map.delete(Map.delete(acc, :relay), :hop_count) do
      true -> {:ok, Map.merge(acc, aux_data, fn _k, v1, v2 -> [v1 | v2] end)}
      false -> {:error, :invalid_aux_data}
    end
  end

  defp merge_aux_data(aux_data, acc) when is_map_key(aux_data, :relay) do
    case Map.delete(aux_data, :relay) === Map.delete(acc, :relay) do
      true ->
        {:ok,
         Map.merge(acc, aux_data, fn
           :relay, v1, v2 -> List.flatten([v1, v2])
            _k, v1, _v2 -> v1
         end)}

      _ -> {:error, :invalid_aux_data}
    end
  end

  defp merge_aux_data(aux_data, acc) do
    case aux_data === acc do
      true -> {:ok, acc}
      false -> {:error, :invalid_aux_data}
    end
  end
end
