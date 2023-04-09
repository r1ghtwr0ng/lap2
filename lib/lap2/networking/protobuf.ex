defmodule LAP2.Networking.ProtoBuf do
  use Protox,
  files: ["./specs/structs.proto"],
  path: ["./specs"]

  @doc """
  Serialise a map via ProtoBuff before sending it
  """
  @spec serialise(map, atom) :: {:ok, iodata} | {:error, any}
  def serialise(clove, clove_type \\ :regular_proxy) do
    clove
    |> build(clove_type)
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
  # Build clove object
  @spec build(map, atom) :: map
  defp build(clove, clove_type) do
    header = build_header(clove_type, clove.headers)
    case clove_type do
      :proxy_discovery ->
        %Clove{checksum: clove.checksum, headers: {clove_type, header}, data: clove.data}
      :proxy_response ->
        %Clove{checksum: clove.checksum, headers: {clove_type, header}, data: clove.data}
      :regular_proxy ->
        %Clove{checksum: clove.checksum, headers: {clove_type, header}, data: clove.data}
    end
  end

  # Build header struct
  @spec build_header(atom, map) :: map
  def build_header(:proxy_discovery, %{clove_seq: clove_seq, drop_probab: drop_probab}) do
    %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: drop_probab}
  end
  def build_header(:proxy_response, %{proxy_seq: proxy_seq, clove_seq: clove_seq, hop_count: hop_count}) do
    %ProxyResponseHeader{proxy_seq: proxy_seq, clove_seq: clove_seq, hop_count: hop_count}
  end
  def build_header(:regular_proxy, %{proxy_seq: proxy_seq}) do
    %RegularProxyHeader{proxy_seq: proxy_seq}
  end
end
