defmodule LAP2.Networking.UdpServerTest do
  use ExUnit.Case, async: true
  alias LAP2.Networking.UdpServer

  setup do
    config = %{
      name: {:global, :test_udp_server},
      udp_port: 0, # Let the OS assign the port
      registry_table: %{task_supervisor: {:global, :test_task_supervisor}}
    }
    opts = [strategy: :one_for_one, name: {:global, :test_supervisor}]
    children = [
      {Task.Supervisor, [name: {:global, :test_task_supervisor}, max_children: 2]},
      {LAP2.Networking.UdpServer, config}
    ]
    Supervisor.start_link(children, opts)

    # Get the actual port number assigned by the OS
    {:ok, udp_sock} = :gen_udp.open(0)
    {:ok, udp_port} = :inet.port(udp_sock)
    :gen_udp.close(udp_sock)
    {:ok, %{test_udp_server: {:global, :test_udp_server}, udp_port: udp_port}}
  end

  describe "send_dgram/3" do
    test "Test sending datagrams via UDP socket", context do
      dgram = 'Hello, UDP!'
      dest = {"127.0.0.1", context.udp_port}

      # Start a UDP server to receive the datagram
      {:ok, recv_socket} = :gen_udp.open(context.udp_port, [active: false])
      :ok = UdpServer.send_dgram(context.test_udp_server, dgram, dest)

      {:ok, {_src_ip, _src_port, received_dgram}} = :gen_udp.recv(recv_socket, 0)
      assert received_dgram == dgram
      :gen_udp.close(recv_socket)
    end
  end
end
