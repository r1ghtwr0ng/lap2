defmodule LAP2.Networking.ProtoBufTest do
  alias LAP2.Networking.ProtoBuf
  alias LAP2.Utils.CloveHelper

  use ExUnit.Case
  doctest LAP2.Networking.ProtoBuf

  describe "serialise/2" do
    test "Test proxy discovery serialisation" do
      data = "TEST_DATA"
      # Packet serialisation
      hdr = %{clove_seq: 1, drop_probab: 0.7}
      # Create the clove
      clove = CloveHelper.set_headers(data, hdr)
      # Expected serial outputs
      serial = [[[[], "\x1A", ["\a", "\b\x01\x15333?"]], "\b", ["\xC7", ["\xD0", ["\xA7", ["\xEC", "\x02"]]]]],
      "\x12", ["\t", "TEST_DATA"]]
      # Serialise the cloves
      assert {:ok, serial} == ProtoBuf.serialise(clove, :proxy_discovery)
    end

    test "Test proxy response serialisation" do
      data = "TEST_DATA"
      # Packet serialisation
      hdr = %{clove_seq: 2, hop_count: 0, proxy_seq: 4}
      # Create the clove
      clove = CloveHelper.set_headers(data, hdr)
      # Expected serial outputs
      serial = [[[[], "\"", [<<4>>, <<8, 4, 16, 2>>]], "\b", [<<199>>, [<<208>>, [<<167>>, [<<236>>, <<2>>]]]]],
      <<18>>, ["\t", "TEST_DATA"]]
      # Serialise the cloves
      assert {:ok, serial} == ProtoBuf.serialise(clove, :proxy_response)
    end

    test "Test regular proxy serialisation" do
      data = "TEST_DATA"
      # Packet serialisation
      hdr = %{proxy_seq: 3}
      # Create the clove
      clove = CloveHelper.set_headers(data, hdr)
      # Expected serial outputs
      serial = [[[[], "*", [<<2>>, <<8, 3>>]], "\b", [<<199>>, [<<208>>, [<<167>>, [<<236>>, <<2>>]]]]],
      <<18>>, ["\t", "TEST_DATA"]]
      # Serialise the cloves
      assert {:ok, serial} == ProtoBuf.serialise(clove, :regular_proxy)
    end
  end

  describe "deserialise/1" do
    test "Test proxy discovery deserialisation" do
      # Serial data
      serial = <<26, 5, 21, 51, 51, 51, 63, 18, 9, 84, 69, 83, 84, 95, 68, 65, 84, 65>>
      # Expected deserial outputs
      clove = %Clove{data: "TEST_DATA", headers: {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: 0, drop_probab: 0.699999988079071}}, checksum: 0}
      # Deserialise the cloves
      assert {:ok, clove} == ProtoBuf.deserialise(serial, Clove)
    end

    test "Test proxy response deserialisation" do
      # Serial data
      serial = <<34, 4, 8, 4, 16, 2, 18, 9, 84, 69, 83, 84, 95, 68, 65, 84, 65>>
      # Expected deserial outputs
      clove = %Clove{data: "TEST_DATA", headers: {:proxy_response, %ProxyResponseHeader{proxy_seq: 4, clove_seq: 2, hop_count: 0, __uf__: []}}, checksum: 0}
      # Deserialise the cloves
      assert {:ok, clove} == ProtoBuf.deserialise(serial, Clove)
    end

    test "Test regular proxy deserialisation" do
      # Serial data
      serial = <<42, 2, 8, 3, 18, 9, 84, 69, 83, 84, 95, 68, 65, 84, 65>>
      # Expected deserial outputs
      clove = %Clove{data: "TEST_DATA", headers: {:regular_proxy, %RegularProxyHeader{proxy_seq: 3}}, checksum: 0}
      # Deserialise the cloves
      assert {:ok, clove} == ProtoBuf.deserialise(serial, Clove)
    end
  end
end
