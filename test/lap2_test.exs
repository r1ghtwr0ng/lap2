defmodule LAP2Test do
  use ExUnit.Case
  doctest LAP2
# Get user input
  def prompt() do
    IO.puts("[=] Bootstrap the following information:")
    port = IO.gets("[<] Port: ") |> String.trim |> String.to_integer
    bstrp_port = IO.gets("[<] Bootstrap port: ") |> String.trim |> String.to_integer
    bstrp_ip = IO.gets("[<] Bootstrap IP address: ") |> String.trim
    bstrp_addr = IO.gets("[<] Bootstrap LAP2 address: ") |> String.trim
    {port, bstrp_port, bstrp_ip, bstrp_addr}
  end

  alias LAP2.Networking.Router
  alias LAP2.Utils.CloveHelper
  alias LAP2.Networking.ProtoBuf

  {port, addr, bstrp_port, bstrp_ip, bstrp_addr} = Test.prompts()

  # Configs
  defp make_config(addr) do
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
        name: String.to_atom("data_processor_#{addr}")
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
    config = make_config(addr)
    IO.puts("[=] Testing LAP2.start")
    case LAP2.start(config) do
      {:ok, pid} ->
        assert Process.alive?(pid)
        assert Process.alive?(:global.whereis_name({:global, config.task_supervisor.name}))
        assert Process.alive?(:global.whereis_name({:global, config.router.name}))
        assert Process.alive?(:global.whereis_name({:global, config.tcp_server.name}))
        assert Process.alive?(:global.whereis_name({:global, config.udp_server.name}))
        assert Process.alive?(:global.whereis_name({:global, config.data_processor.name}))
        #IO.puts("[+] Stopping daemon")
        IO.puts("[=] Testing child termination")
        assert :ok == LAP2.terminaste_child(config.main_supervisor.name, :global.whereis_name({:global, config.task_supervisor.name}))
        assert :ok == LAP2.terminaste_child(config.main_supervisor.name, :global.whereis_name({:global, config.router.name}))
        assert :ok == LAP2.terminaste_child(config.main_supervisor.name, :global.whereis_name({:global, config.tcp_server.name}))
        assert :ok == LAP2.terminaste_child(config.main_supervisor.name, :global.whereis_name({:global, config.udp_server.name}))
        assert :ok == LAP2.terminaste_child(config.main_supervisor.name, :global.whereis_name({:global, config.data_processor.name}))
        assert :ok == LAP2.kill(config.main_supervisor.name)
      {:error, reason} -> IO.puts("[!] Unable to start daemon: #{reason}")
  end

  # Bootstrap the process
  test "bootstrap" do
    addr = :crypto.strong_rand_bytes(16) |> Base.encode16()
    config = make_config(addr)
    IO.puts("[=] Testing LAP2.bootsrap")
    case LAP2.start(config) do
      {:ok, pid} ->
        assert :ok == Router.update_config(config.router, config.router.name)
        assert :ok == Router.append_dht(bstrp_addr, {bstrp_ip, bstrp_port}, config.router.name)
        IO.puts("[=] Sending data")
        data = "Hello World"
        clove_seq = LAP2.Utils.CloveHelper.gen_seq_num()
        assert :ok == Router.route_outbound_discovery({bstrp_ip, bstrp_port}, clove_seq, data, config.router.name)
        assert :ok == LAP2.kill(config.main_supervisor.name)
      {:error, reason} -> IO.puts("[!] Unable to start daemon: #{reason}")
    end

    #IO.puts("[+] Stopping daemon")
    LAP2.kill(config.main_supervisor.name)
  end
  # ---- Private functions ----
  # Play russian roulette with the child tasks
  defp terminate_random_child(supervisor, children) do
    # Pick a child at random
    supervisor = Enum.random(supervisor_list)
    # :brutal_kill the child
    Task.Supervisor.terminate_child(supervisor, :random)
  end



IO.puts("[+] Building cloves")
data = Enum.map(headers, fn {req_type, hdr} -> {req_type, hdr, IO.gets("[+] Data: ")}; end)


end
