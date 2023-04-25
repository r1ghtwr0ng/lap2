defmodule LAP2Test do
  use ExUnit.Case
  doctest LAP2

  require Logger
  alias LAP2.Networking.Router
  alias LAP2.Utils.ProtoBuf.CloveHelper

  # Configs
  defp make_config(addr, udp_port) do
    %{
      main_supervisor: %{name: String.to_atom("lap2_daemon_#{addr}")},
      task_supervisor: %{max_children: 10, name: String.to_atom("lap2_superv_#{addr}")},
      proxy_manager: %{
        name: String.to_atom("proxy_manager_#{addr}"),
        registry_table: %{
          proxy_manager: String.to_atom("proxy_manager_#{addr}"),
          share_handler: String.to_atom("share_handler_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}"),
          crypto_manager: String.to_atom("crypto_manager_#{addr}")
        },
        max_hops: 10,
        min_hops: 1,
        proxy_limit: 20,
        proxy_ttl: 60000
      },
      crypto_manager: %{name: String.to_atom("crypto_manager_#{addr}"),
        identity: "IDENT_#{addr}",
        registry_table: %{
          proxy_manager: String.to_atom("proxy_manager_#{addr}"),
          share_handler: String.to_atom("share_handler_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}"),
          crypto_manager: String.to_atom("crypto_manager_#{addr}")
        }},
      router: %{
        clove_cache_size: 1000,
        clove_cache_ttl: 30000,
        lap2_addr: "LAP2_ADDR_#{addr}",
        name: String.to_atom("router_#{addr}"),
        proxy_limit: 20,
        proxy_policy: true,
        registry_table: %{
          proxy_manager: String.to_atom("proxy_manager_#{addr}"),
          share_handler: String.to_atom("share_handler_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}"),
          crypto_manager: String.to_atom("crypto_manager_#{addr}")
        },
        relay_table_size: 5000,
        relay_table_ttl: 1_800_000
      },
      tcp_server: %{
        max_queue_size: 1000,
        name: :tcp_server,
        queue_interval: 100,
        registry_table: %{
          proxy_manager: String.to_atom("proxy_manager_#{addr}"),
          share_handler: String.to_atom("share_handler_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}"),
          crypto_manager: String.to_atom("crypto_manager_#{addr}")
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
          proxy_manager: String.to_atom("proxy_manager_#{addr}"),
          share_handler: String.to_atom("share_handler_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}"),
          crypto_manager: String.to_atom("crypto_manager_#{addr}")
        },
        req_timeout: 50000,
        udp_port: udp_port
      },
      share_handler: %{
        name: String.to_atom("share_handler_#{addr}"),
        registry_table: %{
          proxy_manager: String.to_atom("proxy_manager_#{addr}"),
          share_handler: String.to_atom("share_handler_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}"),
          crypto_manager: String.to_atom("crypto_manager_#{addr}")
        },
        share_ttl: 60000
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
          # assert Process.alive?(GenServer.whereis({:global, config.tcp_server.name}))
          assert Process.alive?(GenServer.whereis({:global, :udp_server}))
          assert Process.alive?(GenServer.whereis({:global, :share_handler}))
          assert :ok == Supervisor.stop(pid)

        {:error, reason} ->
          Logger.error("[!] Unable to start daemon: #{reason}")
      end
    end
  end

  describe "start/1" do
    test "Test starting from custom config map" do
      addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
      config = make_config(addr, 0)

      case LAP2.start(config) do
        {:ok, pid} ->
          assert Process.alive?(pid)
          assert Process.alive?(GenServer.whereis({:global, config.router.name}))
          # TODO uncomment once TCP Server is implemented
          # assert Process.alive?(GenServer.whereis({:global, config.tcp_server.name}))
          assert Process.alive?(GenServer.whereis({:global, config.udp_server.name}))
          assert Process.alive?(GenServer.whereis({:global, config.share_handler.name}))
          assert :ok == Supervisor.stop(pid)

        {:error, reason} ->
          Logger.error("[!] Unable to start daemon: #{reason}")
      end
    end
  end

  describe "bootstrap" do
    test "Test bootstrapping the program with neighbor network addresses" do
      # Generate LAP2 addresses
      addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
      bstrp_addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
      bstrp_ip = "127.0.0.1"
      bstrp_port = 0
      port = 0

      main_config = make_config(addr, port)
      bstrp_config = make_config(bstrp_addr, bstrp_port)

      case LAP2.start(main_config) do
        {:ok, main_pid} ->
          case LAP2.start(bstrp_config) do
            {:ok, bstrp_pid} ->
              assert :ok == Router.update_config(main_config.router, main_config.router.name)

              assert :ok ==
                       Router.append_dht(
                         bstrp_addr,
                         {bstrp_ip, bstrp_port},
                         main_config.router.name
                       )
              # Create the clove
              data = "Hello World"
              hdr = %{clove_seq: LAP2.Utils.ProtoBuf.CloveHelper.gen_seq_num(), drop_probab: 0.7}
              clove = CloveHelper.create_clove(data, hdr, :proxy_discovery)

              assert :ok ==
                       Router.route_outbound_discovery(
                         {bstrp_ip, bstrp_port},
                         clove,
                         main_config.router.name
                       )

              assert :ok == Supervisor.stop(main_pid)
              assert :ok == Supervisor.stop(bstrp_pid)

            {:error, reason} ->
              Logger.error("[!] Unable to start bootstrap proc daemon: #{reason}")
              assert :ok == Supervisor.stop(main_pid)
          end

        {:error, reason} ->
          Logger.error("[!] Unable to start daemon: #{reason}")
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
          # Wait for the process to restart
          :timer.sleep(50)
          assert Process.alive?(GenServer.whereis({:global, :router}))
          # Test UDP server restart
          assert Process.exit(GenServer.whereis({:global, :udp_server}), :brutal_kill)
          :timer.sleep(50)
          assert Process.alive?(GenServer.whereis({:global, :udp_server}))
          # Test Share Handler restart
          assert Process.exit(GenServer.whereis({:global, :share_handler}), :brutal_kill)
          :timer.sleep(50)
          assert Process.alive?(GenServer.whereis({:global, :share_handler}))
          # TODO Test TCP server restart
          # assert Process.exit(GenServer.whereis({:global, :tcp_server}), :brutal_kill)
          # :timer.sleep(100) # Wait for the process to restart
          # assert Process.alive?(GenServer.whereis({:global, :tcp_server}))
          assert :ok == Supervisor.stop(pid)

        {:error, reason} ->
          Logger.error("[!] Unable to start daemon: #{reason}")
      end
    end
  end
end
