defmodule LAP2.Utils.ShareHelper do
  @moduledoc """
  Helper functions for processing IDA Shares.
  Verifies integrity, serves as interface for serialising/deserialising with ProtoBuf.
  """
  alias LAP2.Networking.ProtoBuf

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
end
