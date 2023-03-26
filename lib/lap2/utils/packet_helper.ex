defmodule LAP2.Utils.PacketHelper do
  @moduledoc """
  Helper functions for generating packet information, checksums, splitting and reconstructing packets, padding, etc.
  """
  require CRC

  # ---- Generator functions ----
  def gen_seq_num() do
    :crypto.strong_rand_bytes(4)
  end

  def generate_drop_probab() do
    # TODO implement
    1.0
  end

  # ---- Checksum functions ----
  def verify_checksum(%{checksum: chksum, seq_num: seq_num, drop_probab: drop_probab, data: data}) do
    # Verify the checksum
    chksum == CRC.crc_32(seq_num <> drop_probab <> data)
  end

  def set_checksum(%{seq_num: seq_num, drop_probab: drop_probab, data: data} = pkt) do
    # Compute and prepend checksum to packet
    Map.put(pkt, :checksum, CRC.crc_32(seq_num <> drop_probab <> data))
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
        Task.async(fn -> Router.route_packet(source, pkt); end)
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
    verify_checksum(pkt) && verify_headers(pkt)
  end

  @doc """
  Verify the packet's headers.
  """
  def verify_headers(%{seq_num: seq_num, drop_probab: drop_probab, data: data}) do
    # TODO check sequence number range
    # TODO check drop probability range
    # TODO check data length (must be padded to fixed size)
    true
  end

  @doc """
  Set the packet's headers.
  """
  def set_headers(pkt) do
    # Set sequence number
    seq_num = PacketHelper.generate_seq_num()
    # Set drop probability
    drop_probab = PacketHelper.generate_drop_probab()
    # TODO seq_num should be the same for all cloves of a single packet, fix it later
    %{seq_num: seq_num, drop_probab: drop_probab, data: pkt}
  end
end
