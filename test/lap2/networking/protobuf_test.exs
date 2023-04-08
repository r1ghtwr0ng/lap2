defmodule LAP2.Networking.ProtoBufTest do
  alias LAP2.Networking.ProtoBuf
  alias LAP2.Utils.CloveHelper

  use ExUnit.Case
  doctest LAP2.Networking.ProtoBuf

  test "serialise" do
    data = "TEST_DATA"

    # Packet serialisation
    hdr_1 = %{clove_seq: 1, drop_probab: 0.7}
    hdr_2 = %{clove_seq: 2, hop_count: 0, proxy_seq: 4}
    hdr_3 = %{proxy_seq: 3}
    # Create the cloves
    clove_1 = CloveHelper.set_headers(data, hdr_1)
    clove_2 = CloveHelper.set_headers(data, hdr_2)
    clove_3 = CloveHelper.set_headers(data, hdr_3)
    # Expected serial outputs
    serial_1 = [
      [[[], "\x1A", ["\a", "\b\x01\x15333?"]], "\b", ["\xC7", ["\xD0", ["\xA7", ["\xEC", "\x02"]]]]],
      "\x12", ["\t", "TEST_DATA"]]
    serial_2 = [[[[], "\"", [<<4>>, <<8, 4, 16, 2>>]], "\b", [<<199>>, [<<208>>, [<<167>>, [<<236>>, <<2>>]]]]],
      <<18>>, ["\t", "TEST_DATA"]]
    serial_3 = [[[[], "*", [<<2>>, <<8, 3>>]], "\b", [<<199>>, [<<208>>, [<<167>>, [<<236>>, <<2>>]]]]],
      <<18>>, ["\t", "TEST_DATA"]]
    # Serialise the cloves
    IO.puts("[+] Testing ProtoBuf.serialise")
    assert {:ok, serial_1} == ProtoBuf.serialise(clove_1, :proxy_discovery)
    assert {:ok, serial_2} == ProtoBuf.serialise(clove_2, :proxy_response)
    assert {:ok, serial_3} == ProtoBuf.serialise(clove_3, :regular_proxy)
    # Test invalid clove
    #assert {:error, _} == ProtoBuf.serialise(%{}, :proxy_discovery)
    #assert {:errir, _} == ProtoBuf.serialise(%{}, :invalid_type)
  end

  test "deserialise" do
    # Packet serialisation
    serial_1 = ""
    serial_2 = ""
    serial_3 = ""
    # Expected deserial outputs
    clove_1 = %Clove{data: "TEST_DATA", headers: %{clove_seq: 0, drop_probab: 0.7}, checksum: 0}
    clove_2 = %Clove{data: "TEST_DATA", headers: %{clove_seq: 0, drop_probab: 0.7}, checksum: 0}
    clove_3 = %Clove{data: "TEST_DATA", headers: %{clove_seq: 0, drop_probab: 0.7}, checksum: 0}
    # Deserialise the cloves
    #assert clove_1 == ProtoBuf.deserialise(serial_1, :proxy_discovery)
    #assert clove_2 == ProtoBuf.deserialise(serial_2, :proxy_response)
    #assert clove_3 == ProtoBuf.deserialise(serial_3, :regular_proxy)
  end
end
