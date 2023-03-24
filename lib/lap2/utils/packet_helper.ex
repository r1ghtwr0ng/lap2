defmodule LAP2.Utils.RoutingHelper do
  @moduledoc """
  Helper functions for generating packet information, checksums, splitting and reconstructing packets, padding, etc.
  """
  require CRC

  # ---- Generator functions ----
  def gen_seq_num() do
    :crypto.strong_rand_bytes(4)
  end

  def generate_drop_probab() do
    :crypto.hash(:sha256, data)
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
end
