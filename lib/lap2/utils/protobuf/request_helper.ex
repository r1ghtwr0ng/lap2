defmodule LAP2.Utils.ProtoBuf.RequestHelper do
  @moduledoc """
  Helper functions for processing LAP2 requests.
  Verifies integrity, serves as interface for serialising/deserialising with ProtoBuf.
  """

  alias LAP2.Networking.ProtoBuf

  # ---- ProtoBuf wrappers ----
  @doc """
  Deserialise a request struct.
  """
  @spec deserialise(binary) :: {:ok, map} | {:error, any}
  def deserialise(data) do
    # Deserialise the request
    case ProtoBuf.deserialise(data, Request) do
      {:ok, request} -> {:ok, request}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Serialise a request struct.
  """
  @spec serialise(Request) :: {:ok, binary} | {:error, any}
  def serialise(request) do
    # Serialise the request
    case ProtoBuf.serialise(request) do
      {:ok, data} -> {:ok, IO.iodata_to_binary(data)}
      {:error, reason} -> {:error, reason}
    end
  end
end
