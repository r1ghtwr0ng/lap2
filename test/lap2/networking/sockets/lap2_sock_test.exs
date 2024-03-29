defmodule LAP2.Networking.Sockets.Lap2SocketTest do
  use ExUnit.Case, async: true

  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Networking.Sockets.Lap2Socket

  setup do
    LAP2.start()
    udp_name = :udp_server
    router_name = :router
    {:ok, udp_name: udp_name, router_name: router_name}
  end

  describe "parse_dgram/3" do
    test "Successfully parse and processes a received datagram", context do
      dgram =
        <<42, 2, 8, 1, 8, 145, 216, 228, 143, 5, 18, 9, 84, 101, 115, 116, 32, 100, 97, 116, 97>>

      source = {"127.0.0.1", 8080}

      assert Lap2Socket.parse_dgram(source, dgram, context.router_name) == :ok
    end

    test "Handle an error when deserialising a datagram", context do
      dgram = "invalid_datagram"
      source = {"127.0.0.1", 8080}

      assert Lap2Socket.parse_dgram(source, dgram, context.router_name) == :error
    end
  end

  describe "send_clove/5" do
    test "successfully sends a clove to a destination", context do
      data = "Test data"
      headers = %{proxy_seq: 1}
      dest = {"127.0.0.1", 8081}
      clove = CloveHelper.create_clove(data, headers, :regular_proxy)

      assert Lap2Socket.send_clove(dest, clove, context.udp_name) == :ok
    end
  end
end
