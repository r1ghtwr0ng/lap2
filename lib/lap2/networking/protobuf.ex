defmodule LAP2.Networking.ProtoBuf do
  use Protox,
    files: ["./specs/structs.proto"],
    path: ["./specs"]

  @doc """
  Serialise a map via ProtoBuff before sending it
  """
  @spec serialise(Clove.t() | Share.t() | Request.t() | EncryptedRequest.t()) ::
          {:ok, any} | {:error, any}
  def serialise(struct), do: Protox.encode(struct)

  @doc """
  Deserialised received data
  """
  @spec deserialise(binary, Clove | Share | Request | EncryptedRequest) ::
          {:error, any} | {:ok, struct}
  def deserialise(data, struct_type \\ Clove) do
    Protox.decode(data, struct_type)
  end
end
