defmodule LAP2.Utils.ProtoBuf.CloveHelper do
  @moduledoc """
  Helper functions for generating clove information, checksums, splitting and reconstructing cloves, padding, etc.
  Handles serialising and deserialising cloves (simplifies serial data types).
  """
  require CRC
  alias LAP2.Networking.Router
  alias LAP2.Networking.ProtoBuf

  # ---- ProtoBuf wrappers ----
  @doc """
  Deserialise a clove.
  """
  @spec deserialise(binary) :: {:ok, map} | {:error, any}
  def deserialise(dgram) do
    # Deserialise the clove
    case ProtoBuf.deserialise(dgram, Clove) do
      {:ok, clove} -> {:ok, clove}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Serialise a clove.
  """
  @spec serialise(Clove) :: {:ok, binary} | {:error, any}
  def serialise(clove) do
    # Serialise the clove
    case ProtoBuf.serialise(clove) do
      {:ok, dgram} -> {:ok, IO.iodata_to_binary(dgram)}
      {:error, reason} -> {:error, reason}
    end
  end

  # ---- Checksum functions ----
  @doc """
  Verify the checksum of the clove.
  """
  @spec verify_checksum(map) :: boolean
  def verify_checksum(%{checksum: chksum, data: data}) do
    # Verify the checksum
    chksum == CRC.crc_32(data)
  end

  @doc """
  Build the clove from the headers and data.
  """
  @spec create_clove(binary, map, atom) :: map()
  def create_clove(data, headers, clove_type) do
    # Set the headers for the clove
    clove_map = %{data: data, headers: headers, checksum: CRC.crc_32(data)}
    build_clove(clove_map, clove_type)
  end

  # ---- Clove handling functions ----
  @doc """
  Send out the deserialised clove for routing.
  """
  @spec handle_deserialised_clove({binary, non_neg_integer}, map, atom) :: :ok | :err
  def handle_deserialised_clove(source, clove, router_name) do
    # Verify clove validity
    cond do
      verify_clove(clove) ->
        # DEBUG
        IO.puts("[+] CloveHelper: Valid clove")
        Task.async(fn -> Router.route_inbound(source, clove, router_name) end)
        :ok

      true ->
        # DEBUG
        IO.puts("[-] CloveHelper: Invalid clove")
        :err
    end
  end

  @doc """
  Verify the clove's validity.
  """
  @spec verify_clove(map) :: boolean
  def verify_clove(clove) do
    # Verify the checksum and header format
    verify_checksum(clove) && verify_headers(clove.headers)
  end

  @doc """
  Verify the clove's headers.
  """
  @spec verify_headers(map) :: boolean
  def verify_headers(
        {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: _, drop_probab: drop_probab}}
      ),
      do: drop_probab > 0.0 && drop_probab <= 1.0

  def verify_headers(
        {:proxy_response, %ProxyResponseHeader{clove_seq: _, proxy_seq: _, hop_count: _}}
      ),
      do: true

  def verify_headers({:regular_proxy, %RegularProxyHeader{proxy_seq: _}}), do: true
  def verify_headers(_), do: false

  # ---- Header field generation functions ----
  @spec gen_seq_num() :: integer
  def gen_seq_num(), do: :crypto.strong_rand_bytes(8) |> :binary.decode_unsigned()
  @spec gen_drop_probab(float, float) :: float
  def gen_drop_probab(min, max), do: :rand.uniform() * (max - min) + min

  # ---- Private Functions ----
  # Build Clove struct
  @spec build_clove(map, atom) :: map
  defp build_clove(clove, clove_type) do
    %Clove{
      checksum: clove.checksum,
      headers: build_header(clove_type, clove.headers),
      data: clove.data
    }
  end

  # Build Header struct
  @spec build_header(atom, map) :: map
  defp build_header(:proxy_discovery, %{clove_seq: clove_seq, drop_probab: drop_probab}) do
    {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: drop_probab}}
  end

  defp build_header(:proxy_response, %{
         proxy_seq: proxy_seq,
         clove_seq: clove_seq,
         hop_count: hop_count
       }) do
    {:proxy_response,
     %ProxyResponseHeader{proxy_seq: proxy_seq, clove_seq: clove_seq, hop_count: hop_count}}
  end

  defp build_header(:regular_proxy, %{proxy_seq: proxy_seq}) do
    {:regular_proxy, %RegularProxyHeader{proxy_seq: proxy_seq}}
  end
end
