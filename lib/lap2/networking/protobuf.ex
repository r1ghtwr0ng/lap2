defmodule LAP2.Networking.ProtoBuf do
  use Protox,
  files: ["./specs/message.proto"],
  path: ["./specs"]

  @doc """
  Serialise a map via ProtoBuff before sending it
  """
  @spec serialise(map, atom) :: {:ok, iodata} | {:error, any}
  def serialise(clove, clove_type \\ :regular_proxy_clove) do
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
  # TODO add hop count, proxy_seq
  # Build clove object
  @spec build(map, atom) :: map
  defp build(clove, clove_type) do
    header = build_header(clove_type, clove.headers)
    case clove_type do
      :proxy_discovery ->
        %Clove{checksum: clove.checksum, headers: %{proxy_discovery_header: header}, data: clove.data}
      :proxy_response ->
        %Clove{checksum: clove.checksum, headers: %{proxy_response_header: header}, data: clove.data}
      :regular_proxy_clove ->
        %Clove{checksum: clove.checksum, headers: %{regular_proxy_header: header}, data: clove.data}
    end
  end

  # Build header struct
  @spec build_header(atom, map) :: map
  def build_header(:proxy_discovery, %{clove_seq: clove_seq, drop_probab: drop_probab}) do
    int_clove_seq = :binary.decode_unsigned(clove_seq)
    %ProxyDiscoveryHeader{clove_seq: int_clove_seq, drop_probab: drop_probab}
  end
  def build_header(:proxy_response, %{proxy_seq: proxy_seq, clove_seq: clove_seq, hop_count: hop_count}) do
    int_clove_seq = :binary.decode_unsigned(clove_seq)
    int_proxy_seq = :binary.decode_unsigned(proxy_seq)
    %ProxyResponseHeader{proxy_seq: int_proxy_seq, clove_seq: int_clove_seq, hop_count: hop_count}
  end
  def build_header(:regular_proxy_clove, %{proxy_seq: proxy_seq}) do
    int_proxy_seq = :binary.decode_unsigned(proxy_seq)
    %RegularProxyHeader{proxy_seq: int_proxy_seq}
  end
end
