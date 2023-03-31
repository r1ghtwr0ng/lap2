defmodule LAP2.Networking.ProtoBuf do
  use Protox,
  files: ["./specs/message.proto"],
  path: ["./specs"]

  @doc """
  Serialise a map via ProtoBuff before sending it
  """
  @spec serialise(map) :: {:ok, iodata} | {:error, any}
  def serialise(clove) do
    clove
    |> build()
    |> Protox.encode()
  end

  @doc """
  Deserialised received data
  """
  @spec deserialise(binary, atom) :: {:error, any} | {:ok, struct}
  def deserialise(data, spec \\ Clove) do
    Protox.decode(data, spec)
  end

  # Build clove object
  # TODO add hop count, proxy_seq
  # Build clove object
  @spec build(map) :: map
  defp build(%{checksum: chksum, header: header, data: data}) do
    %Clove{checksum: chksum, header: build_header(header), data: data}
  end

  # Build header struct
  @spec build_header({atom, map}) :: map
  defp build_header({:proxy_discovery, %{clove_seq: clove_seq, drop_probab: drop_probab}}) do
    %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: drop_probab}
  end
  defp build_header({:proxy_response, %{proxy_seq: proxy_seq, clove_seq: clove_seq, hop_count: hop_count}}) do
    %ProxyResponseHeader{proxy_seq: proxy_seq, clove_seq: clove_seq, hop_count: hop_count}
  end
  defp build_header({:regular_proxy_clove, %{proxy_seq: proxy_seq}}) do
    %RegularProxyHeader{proxy_seq: proxy_seq}
  end
end
