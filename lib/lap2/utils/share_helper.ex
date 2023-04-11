defmodule LAP2.Utils.ShareHelper do
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
  @spec deserialise(binary) :: {:ok, map} | {:error, any}
  def deserialise(dgram) do
    # Deserialise the share
    case ProtoBuf.deserialise(dgram, Share) do
      {:ok, share} -> {:ok, share}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Serialise a share.
  """
  @spec serialise(Share) :: {:ok, binary} | {:error, any}
  def serialise(share) do
    # Serialise the share
    case ProtoBuf.serialise(share) do
      {:ok, dgram} -> {:ok, IO.iodata_to_binary(dgram)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Reconstruct the data from the shares
  """
  @spec reconstruct(list(Share)) :: {:ok, binary} | {:error, any}
  def reconstruct(shares) do
    cond do
      valid_shares?(shares) -> {:ok, SecureIDA.reconstruct(shares)}
      true -> {:error, "Invalid shares"}
    end
  end

  @doc """
  Verify the share's validity.
  """
  @spec verify_share(Share) :: boolean
  def verify_share(%Share{total_shares: n, share_threshold: m, share_idx: idx, key_share: %KeyShare{}}) do
    m <= n && idx <= n
  end
  def verify_share(_), do: false

  # Verify that all the shares are valid
  @spec valid_shares?(list(Share)) :: boolean
  defp valid_shares?(shares) do
    threshold = Enum.at(shares, 0).share_threshold
    total_shares = Enum.at(shares, 0).total_shares
    Enum.all?(shares, fn share ->
      verify_share(share) && share.threshold == threshold && share.total_shares == total_shares; end)
  end
end
