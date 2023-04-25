defmodule LAP2.Networking.ProtoBuf do
  @moduledoc """
  ProtoBuf serialisation and deserialisation.
  """

  use Protox,
    files: ["./specs/clove_struct.proto", "./specs/share_struct.proto", "./specs/request_struct.proto"],
    path: ["./specs"]

  @doc """
  Serialise a map via ProtoBuff before sending it
  """
  @spec serialise(Clove.t() | Share.t() | Request.t() | EncryptedRequest.t()) ::
          {:ok, binary} | {:error, any}
  def serialise(struct) do
    case Protox.encode(struct) do
      {:ok, data} -> {:ok, IO.iodata_to_binary(data)}
      err -> err
    end
  end

  @doc """
  Deserialised received data
  """
  @spec deserialise(binary, Clove | Share | Request | EncryptedRequest) ::
          {:error, any} | {:ok, struct}
  def deserialise(data, struct_type \\ Clove) do
    Protox.decode(data, struct_type)
  end
end
