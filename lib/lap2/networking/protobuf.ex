defmodule LAP2.Networking.ProtoBuf do
  use Protox,
  files: ["./specs/message.proto"],
  path: ["./specs"]

  @doc """
  Serialise a map via ProtoBuff before sending it
  """
  def serialise(pkt) do
    pkt
    |> build()
    |> Protox.encode()
  end

  @spec deserialise(binary, atom) :: {:error, any} | {:ok, struct}
  @doc """
  Deserialised received data
  """
  def deserialise(data, spec \\ Packet) do
    Protox.decode(data, spec)
  end

  # Build packet object
  # TODO add hop count
  defp build(%{checksum: chksum, seq_num: seq_num, drop_probab: drop_probab, data: data}) do
    %Packet{checksum: chksum, seq_num: seq_num, drop_probab: drop_probab, data: data}
  end
end
