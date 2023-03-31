defmodule LAP2.Utils.PacketHelper do
  @moduledoc """
  Helper functions for generating packet information, checksums, splitting and reconstructing packets, padding, etc.
  """
  require CRC
  alias LAP2.Networking.Router

  # ---- Checksum functions ----
  def verify_checksum(%{checksum: chksum, seq_num: seq_num, drop_probab: drop_probab, data: data}) do
    # Verify the checksum
    chksum == CRC.crc_32(seq_num <> drop_probab <> data)
  end

  def set_checksum(%{seq_num: seq_num, drop_probab: drop_probab, data: data} = pkt) do
    # Compute and prepend checksum to packet
    Map.put(pkt, :checksum, CRC.crc_32(seq_num <> drop_probab <> data))
  end

  @spec set_headers(binary, map) :: map()
  def set_headers(data, headers) do
    # Set the headers for the packet
    Map.put(headers, :data, data)
  end

  # ---- Packet handling functions ----
  @doc """
  Send out the deserialised packet for routing.
  """
  def handle_deserialised_pkt(source, pkt) do
    # Verify packet validity
    cond do
      verify_packet(pkt) ->
        IO.puts("[+] Valid packet") # DEBUG
        Task.async(fn -> Router.route_inbound(source, pkt); end)
        :ok

      true ->
        IO.puts("Invalid packet") # DEBUG
        :err
    end
  end

  @doc """
  Verify the packet's validity.
  """
  def verify_packet(pkt) do
    # Verify the checksum
    # TODO verify the data length
    verify_checksum(pkt) && verify_headers(pkt)
  end

  @doc """
  Verify the packet's headers.
  """
  def verify_headers(%{drop_probab: drop_probab}) do
    drop_probab > 0.0 && drop_probab <= 1.0
  end
  def verify_headers(_), do: true

  # ---- Header field generation functions ----
  def gen_seq_num(len), do: :crypto.strong_rand_bytes(len)
  def gen_drop_probab(min, max), do: :rand.uniform() * (max - min) + min
end
