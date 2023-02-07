defmodule LAP2.Networking.UdpServerTest do
    use ExUnit.Case
    doctest Networking.UdpServer

    # TODO fix test and add new tests
    test "test" do
        config = %{
            udp_port: 1234,
            queue_interval: 100,
            max_queue_size: 100
        }
        assert Networking.UdpServer.start_link(config) == {:ok, _}
    end
end