defmodule LAP2Test do
  use ExUnit.Case
  doctest LAP2

  alias LAP2.Networking.Router

  # Configs
  defp make_config(addr, port) do
    %{main_supervisor: %{name: String.to_atom("lap2_daemon_#{addr}")},
      task_supervisor: %{max_children: 10, name: String.to_atom("lap2_superv_#{addr}")},
      router: %{
        clove_cache_size: 1000,
        clove_cache_ttl: 30000,
        lap2_addr: "LAP2_ADDR_#{addr}",
        name: String.to_atom("router_#{addr}"),
        proxy_limit: 20,
        proxy_policy: true,
        registry_table: %{
          data_processor: String.to_atom("data_processor_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}")
        },
        relay_routes_size: 5000,
        relay_routes_ttl: 1800000
      },
      tcp_server: %{
        max_queue_size: 1000,
        name: :tcp_server,
        queue_interval: 100,
        registry_table: %{
          data_processor: String.to_atom("data_processor_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}")
        },
        req_timeout: 50000,
        tcp_port: 3001
      },
      udp_server: %{
        max_dgram_handlers: 10,
        max_queue_size: 1000,
        name: String.to_atom("udp_server_#{addr}"),
        queue_interval: 100,
        registry_table: %{
          data_processor: String.to_atom("data_processor_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}")
        },
        req_timeout: 50000,
        udp_port: port
      },
      data_processor: %{
        name: String.to_atom("data_processor_#{addr}"),
        registry_table: %{
          data_processor: String.to_atom("data_processor_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}")
        }
      }
    }
  end

  describe "start/0" do
    test "Test starting from config file" do
      case LAP2.start() do
        {:ok, pid} ->
          assert Process.alive?(pid)
          assert Process.alive?(GenServer.whereis({:global, :router}))
          # TODO uncomment once TCP Server is implemented
          #assert Process.alive?(GenServer.whereis({:global, config.tcp_server.name}))
          assert Process.alive?(GenServer.whereis({:global, :udp_server}))
          assert Process.alive?(GenServer.whereis({:global, :data_processor}))
          assert :ok == Supervisor.stop(pid)
        {:error, reason} -> IO.puts("[!] Unable to start daemon: #{reason}")
      end
    end
  end

  describe "start/1" do
    test "Test starting from custom config map" do
      addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
      config = make_config(addr, 44987)
      case LAP2.start(config) do
        {:ok, pid} ->
          assert Process.alive?(pid)
          assert Process.alive?(GenServer.whereis({:global, config.router.name}))
          # TODO uncomment once TCP Server is implemented
          #assert Process.alive?(GenServer.whereis({:global, config.tcp_server.name}))
          assert Process.alive?(GenServer.whereis({:global, config.udp_server.name}))
          assert Process.alive?(GenServer.whereis({:global, config.data_processor.name}))
          assert :ok == Supervisor.stop(pid)
        {:error, reason} -> IO.puts("[!] Unable to start daemon: #{reason}")
      end
    end
  end

  describe "bootstrap" do
    test "Test bootstrapping the program with neighbor network addresses" do
      # Generate LAP2 addresses
      addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
      bstrp_addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
      bstrp_ip = "127.0.0.1"
      bstrp_port = 44988
      port = 44987

      main_config = make_config(addr, port)
      bstrp_config = make_config(bstrp_addr, bstrp_port)

      case LAP2.start(main_config) do
        {:ok, main_pid} ->
          case LAP2.start(bstrp_config) do
            {:ok, bstrp_pid} ->
              assert :ok == Router.update_config(main_config.router, main_config.router.name)
              assert :ok == Router.append_dht(bstrp_addr, {bstrp_ip, bstrp_port}, main_config.router.name)
              data = "Hello World"
              # TODO more complex data exchange
              clove_seq = LAP2.Utils.CloveHelper.gen_seq_num()
              assert :ok == Router.route_outbound_discovery({bstrp_ip, bstrp_port}, clove_seq, data, main_config.router.name)
              assert :ok == Supervisor.stop(main_pid)
              assert :ok == Supervisor.stop(bstrp_pid)
            {:error, reason} ->
              IO.puts("[!] Unable to start bootstrap proc daemon: #{reason}")
              assert :ok == Supervisor.stop(main_pid)
          end
        {:error, reason} -> IO.puts("[!] Unable to start daemon: #{reason}")
      end
    end
  end

  describe "server restart" do
    test "Test if killed processes are auto-restarted by the Supervisor" do
      case LAP2.start() do
        {:ok, pid} ->
          assert Process.alive?(pid)
          # Test Router restart
          assert Process.exit(GenServer.whereis({:global, :router}), :brutal_kill)
          :timer.sleep(50) # Wait for the process to restart
          assert Process.alive?(GenServer.whereis({:global, :router}))
          # Test UDP server restart
          assert Process.exit(GenServer.whereis({:global, :udp_server}), :brutal_kill)
          :timer.sleep(50)
          assert Process.alive?(GenServer.whereis({:global, :udp_server}))
          # Test Data Processor restart
          assert Process.exit(GenServer.whereis({:global, :data_processor}), :brutal_kill)
          :timer.sleep(50)
          assert Process.alive?(GenServer.whereis({:global, :data_processor}))
          # TODO Test TCP server restart
          #assert Process.exit(GenServer.whereis({:global, :tcp_server}), :brutal_kill)
          #:timer.sleep(100) # Wait for the process to restart
          #assert Process.alive?(GenServer.whereis({:global, :tcp_server}))
          assert :ok == Supervisor.stop(pid)
        {:error, reason} -> IO.puts("[!] Unable to start daemon: #{reason}")
      end
    end
  end
end
