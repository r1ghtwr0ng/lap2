defmodule LAP2.Networking.LAP2SocketTest do
  use ExUnit.Case, async: true

  alias LAP2.Networking.LAP2Socket

  setup do
    LAP2.start()
    udp_name = :udp_server
    router_name = :router
    # Start your UDP server, router or any other necessary processes here
    {:ok, udp_name: udp_name, router_name: router_name}
  end

  describe "parse_dgram/3" do
    test "Successfully parse and processes a received datagram", context do
      # Prepare a test clove and datagram
      dgram = <<42, 2, 8, 1, 8, 145, 216, 228, 143, 5, 18, 9, 84, 101, 115, 116, 32, 100, 97, 116, 97>>
      source = {"127.0.0.1", 8080}

      # Call the parse_dgram function
      result = LAP2Socket.parse_dgram(source, dgram, context.router_name)

      # Verify that the parse_dgram function succeeded
      assert result == :ok
    end

    test "Handle an error when deserialising a datagram", context do
      # Prepare an invalid datagram
      dgram = "invalid_datagram"
      source = {"127.0.0.1", 8080}

      # Call the parse_dgram function
      result = LAP2Socket.parse_dgram(source, dgram, context.router_name)

      # Verify that the parse_dgram function returned an error
      assert result == :err
    end
  end

  describe "send_clove/5" do
    test "successfully sends a clove to a destination", context do
      # Prepare the necessary data and destination
      data = "Test data"
      headers = %{proxy_seq: 1}
      dest = {"127.0.0.1", 8081}

      # Call the send_clove function
      result = LAP2Socket.send_clove(dest, data, headers, context.udp_name, :regular_proxy)

      # Verify that the send_clove function succeeded
      assert result == :ok
    end
  end
end
