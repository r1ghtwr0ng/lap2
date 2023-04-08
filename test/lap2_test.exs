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

  # Test process starting and killing procs
  test "start" do
    addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
    config = make_config(addr, 10000)
    case LAP2.start(config) do
      {:ok, pid} ->
        assert Process.alive?(pid)
        assert Process.alive?(:global.whereis_name({:global, config.router.name}))
        # TODO uncomment once TCP Server is implemented
        #assert Process.alive?(:global.whereis_name({:global, config.tcp_server.name}))
        assert Process.alive?(:global.whereis_name({:global, config.udp_server.name}))
        assert Process.alive?(:global.whereis_name({:global, config.data_processor.name}))
        assert :ok == LAP2.kill(config.main_supervisor.name)
      {:error, reason} -> IO.puts("[!] Unable to start daemon: #{reason}")
    end
  end

  # Bootstrap the process
  test "bootstrap" do
    # Generate LAP2 addresses
    addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
    bstrp_addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
    bstrp_ip = "127.0.0.1"
    bstrp_port = 10001
    port = 10000

    main_config = make_config(addr, port)
    bstrp_config = make_config(bstrp_addr, bstrp_port)

    case LAP2.start(main_config) do
      {:ok, _} ->
        case LAP2.start(bstrp_config) do
          {:ok, _} ->
            assert :ok == Router.update_config(main_config.router, main_config.router.name)
            assert :ok == Router.append_dht(bstrp_addr, {bstrp_ip, bstrp_port}, main_config.router.name)
            data = "Hello World"
            # TODO more complex data exchange
            clove_seq = LAP2.Utils.CloveHelper.gen_seq_num()
            assert :ok == Router.route_outbound_discovery({bstrp_ip, bstrp_port}, clove_seq, data, main_config.router.name)
            assert :ok == LAP2.kill(main_config.main_supervisor.name)
            assert :ok == LAP2.kill(bstrp_config.main_supervisor.name)
          {:error, reason} ->
            IO.puts("[!] Unable to start bootstrap proc daemon: #{reason}")
            assert :ok == LAP2.kill(main_config.main_supervisor.name)
        end
      {:error, reason} -> IO.puts("[!] Unable to start daemon: #{reason}")
    end
  end
  # ---- Private functions ----
  # Play russian roulette with the child tasks
  defp terminate_random_child(supervisor, children) do
    # Pick a child at random
    child = :global.whereis_name(Enum.random(children))
    # :brutal_kill the child
    Task.Supervisor.terminate_child(supervisor, child)
  end
end
