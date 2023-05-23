# Setup aliases
require Logger

alias LAP2.Main.Master
alias LAP2.Main.ProxyManager
alias LAP2.Main.ConnectionSupervisor
alias LAP2.Networking.Router
alias LAP2.Networking.Helpers.OutboundPipelines
alias LAP2.Crypto.InformationDispersal.RabinIDA
alias LAP2.Crypto.InformationDispersal.SecureIDA
alias LAP2.Crypto.KeyExchange.C_RSDAKE
alias LAP2.Crypto.Constructions.CryptoNifs
alias LAP2.Crypto.Constructions.ClaimableRS
alias LAP2.Services.FileIO
alias LAP2.Utils.Generator

defmodule NetUtils do
  @spec make_registry_table(String.t) :: map
  def make_registry_table(addr) do
    %{
      conn_supervisor: String.to_atom("conn_supervisor_#{addr}"),
      master: String.to_atom("master_#{addr}"),
      proxy_manager: String.to_atom("proxy_manager_#{addr}"),
      share_handler: String.to_atom("share_handler_#{addr}"),
      router: String.to_atom("router_#{addr}"),
      main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
      task_supervisor: String.to_atom("lap2_superv_#{addr}"),
      tcp_server: String.to_atom("tcp_server_#{addr}"),
      udp_server: String.to_atom("udp_server_#{addr}"),
      crypto_manager: String.to_atom("crypto_manager_#{addr}")
    }
  end

  @spec make_config(String.t, non_neg_integer, non_neg_integer) :: map
  def make_config(addr, udp_port, tcp_port) do
    registry_table = make_registry_table(addr)
    %{
      main_supervisor: %{name: String.to_atom("lap2_daemon_#{addr}")},
      task_supervisor: %{max_children: 10, name: String.to_atom("lap2_superv_#{addr}")},
      conn_supervisor: %{
        name: String.to_atom("conn_supervisor_#{addr}"),
        registry_table: registry_table,
        max_service_providers: 10
      },
      master: %{
        name: String.to_atom("master_#{addr}"),
        registry_table: registry_table
      },
      proxy_manager: %{
        name: String.to_atom("proxy_manager_#{addr}"),
        registry_table: registry_table,
        clove_casts: 32,
        max_hops: 20,
        min_hops: 5,
        proxy_limit: 40,
        proxy_ttl: 60000
      },
      crypto_manager: %{name: String.to_atom("crypto_manager_#{addr}"),
        identity: "IDENT_#{addr}",
        registry_table: registry_table},
      router: %{
        clove_cache_size: 1000,
        clove_cache_ttl: 30000,
        lap2_addr: addr,
        name: String.to_atom("router_#{addr}"),
        proxy_limit: 20,
        proxy_policy: true,
        registry_table: registry_table,
        relay_table_size: 5000,
        relay_table_ttl: 1_800_000
      },
      tcp_server: %{
        max_queue_size: 1000,
        name: String.to_atom("tcp_server_#{addr}"),
        queue_interval: 100,
        registry_table: registry_table,
        req_timeout: 50000,
        tcp_port: tcp_port
      },
      udp_server: %{
        max_dgram_handlers: 10,
        max_queue_size: 1000,
        name: String.to_atom("udp_server_#{addr}"),
        queue_interval: 100,
        registry_table: registry_table,
        req_timeout: 50000,
        udp_port: udp_port
      },
      share_handler: %{
        name: String.to_atom("share_handler_#{addr}"),
        registry_table: registry_table,
        share_ttl: 60000
      }
    }
  end

  # Start a node
  @spec start_node(map) :: :ok | :error
  def start_node(cfg) do
    case LAP2.start(cfg) do
      {:ok, pid} ->
        registry = %{
          genservers: cfg.master.registry_table,
          ip_addr: {"127.0.0.1", cfg.tcp_server.tcp_port},
          pid: pid
        }
        :ets.insert(:network_registry, {cfg.router.lap2_addr, registry})
        :ok

      {:error, reason} ->
        Logger.error("Failed to start node: #{inspect(reason)}")
        :error
    end
  end

  # Start a network of nodes, return a list of their network addresses
  @spec start_network(non_neg_integer, non_neg_integer) :: list(String.t())
  def start_network(nodes, starting_port) do
    # Create the network registry ETS if it doesn't exist
    case :ets.whereis(:network_registry) do
      :undefined -> :ets.new(:network_registry, [:named_table, :set, :public])
      _ -> :ok
    end
    Enum.map(0..nodes-1, fn i ->
      lap2_addr = Generator.generate_hex(8)
      udp_port = starting_port + i
      tcp_port = udp_port
      cfg = make_config(lap2_addr, udp_port, tcp_port)
      case start_node(cfg) do
        :ok -> lap2_addr
        :error -> nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
  end

  # Wrapper for retry_anon_proxy/2
  @spec find_anon_proxy(String.t()) :: :ok | :error
  def find_anon_proxy(lap2_addr), do: retry_anon_proxy(lap2_addr, 0)

  # Register a service provider with an introduction point from the proxy pool
  @spec find_intro_point(String.t(), list(String.t())) :: :ok | :error
  def find_intro_point(lap2_addr, service_ids) do
    case :ets.lookup(:network_registry, lap2_addr) do
      [{_, %{genservers: %{master: master}}}] ->
        Master.setup_introduction_point(service_ids, master)

      _ -> :error
    end
  end

  # Seed a single (random) network node's DHT table
  @spec seed_node() :: {:ok, {String.t(), non_neg_integer}} | {:error, :no_nodes}
  def seed_node() do
    # Define a lambda to run on the network map
    seed_lambda = fn network_map ->
      {seed_addr, seed_ip} = Enum.random(network_map)
      [{_, %{genservers: %{router: router}}}] = :ets.lookup(:network_registry, seed_addr)
      add_dht(network_map, router)
      {:ok, seed_ip}
    end
    # Run the lambda on the network map
    map_network(seed_lambda)
  end

  # Seed all of the nodes in the network
  @spec seed_network() :: :ok | :error
  def seed_network() do
    # Define a lambda to run on the network map
    seed_all = fn network_map ->
      Enum.each(network_map, fn {addr, _} ->
        [{_, %{genservers: %{router: router}}}] = :ets.lookup(:network_registry, addr)
        add_dht(network_map, router)
      end)
      :ok
    end
    # Run the lambda on the network map
    map_network(seed_all)
  end

  # Make a node request DHT updates from an (already seeded) single node
  @spec bootstrap_single(String.t(), {String.t(), non_neg_integer}) :: :ok | :error
  def bootstrap_single(lap2_addr, seed_ip) do
    case :ets.lookup(:network_registry, lap2_addr) do
      [{_, %{ip_addr: ^seed_ip}}] -> :ok # Don't bootstrap from self
      [{_, %{genservers: %{master: master}}}] ->
        Master.bootstrap_dht(seed_ip, master)

      [] ->
        Logger.error("Node not found: #{lap2_addr}")
        :error
    end
  end

  # Bootstrap all nodes in the network, without seeding
  @spec bootstrap_network() :: :ok | :error
  def bootstrap_network() do
    # Define a lambda to run on the network map
    bootstrap_lambda = fn network_map ->
      case seed_node() do
        {:ok, seed_ip} ->
          Logger.info("Seeded DHT with #{inspect seed_ip}")
          Enum.each(network_map, fn
            {_, ^seed_ip} -> :ok # Don't bootstrap from self
            {lap2_addr, _} ->
              bootstrap_single(lap2_addr, seed_ip)
              :timer.sleep(25) # Allow the network requests to propagate
          end)

        {:error, :no_nodes} ->
          Logger.error("No nodes found to seed DHT")
          :error
      end
    end
    # Run the lambda on the network map
    map_network(bootstrap_lambda)
  end

  # Stop a single nodes in the network
  @spec stop_node(String.t()) :: :ok | :error
  def stop_node(lap2_addr) do
    case :ets.lookup(:network_registry, lap2_addr) do
      [{_, %{pid: pid}}] ->
        # Kill the process supervisor and remove the node from the registry
        Logger.info("Stopping node: #{lap2_addr}")
        :ets.delete(:network_registry, lap2_addr)
        LAP2.kill(pid)

      [] ->
        Logger.error("Node not found: #{lap2_addr}")
        :error
    end
  end

  # Stop all nodes in the network
  @spec stop_network() :: :ok | :error
  def stop_network() do
    # Define a lambda to run on the network map
    stop_lambda = fn network_map ->
      Enum.each(network_map, fn {lap2_addr, _} ->
        stop_node(lap2_addr)
      end)
      :ok
    end
    # Run the lambda on the network map
    map_network(stop_lambda)
    # Delete the network registry ETS
    :ets.delete(:network_registry)
  end

  # Inspect DHT entries for a specific node
  @spec inspect_dht(String.t()) :: :ok | :error
  def inspect_dht(lap2_addr) do
    case :ets.lookup(:network_registry, lap2_addr) do
      [{_, %{genservers: %{router: router}}}] ->
        Router.debug(router).routing_table

      [] ->
        Logger.error("Node not found: #{lap2_addr}")
        :error
    end
  end

  # List all introduction points
  @spec list_introduction_points() :: map
  def list_introduction_points() do
    :ets.tab2list(:network_registry)
    |> Enum.reduce(%{}, fn
      {addr, %{genservers: %{conn_supervisor: cs}}}, acc ->
        case ConnectionSupervisor.debug(cs).service_providers do
          serv_ids when map_size(serv_ids) == 0 -> acc
          serv_ids -> Map.put(acc, addr, serv_ids)
        end
    end)
  end

  # Get the introduction point addresses for a specific service
  @spec get_introduction_points(String.t()) :: list(String.t())
  def get_introduction_points(service) do
    list_introduction_points()
    |> Enum.reduce([], fn {node, services}, acc ->
      cond do
        is_map_key(services, service) ->
          [node | acc]
        true ->
          acc
      end
    end)
  end

  # Run a FileIO service
  @spec run_fileio(String.t()) :: {:ok, String.t()} | :error
  def run_fileio(lap2_addr) do
    case :ets.lookup(:network_registry, lap2_addr) do
      [{_, %{genservers: %{master: master}}}] ->
        FileIO.run_service(master)

      [] ->
        Logger.error("Node not found: #{lap2_addr}")
        :error
    end
  end

  # Attempt to establish an anonymous proxy in the network
  @spec retry_anon_proxy(String.t(), non_neg_integer) :: :ok | :error
  defp retry_anon_proxy(_, 5), do: Logger.error("Unable to find proxy after 5 attempts"); :error
  defp retry_anon_proxy(lap2_addr, iter) do
    case :ets.lookup(:network_registry, lap2_addr) do
      [{_, registry}] ->
        proxies = map_size(get_proxy_pool(registry.genservers.proxy_manager))
        Master.discover_proxy(registry.genservers.master)
        :timer.sleep(500)
        cond do
          map_size(get_proxy_pool(registry.genservers.proxy_manager)) > proxies ->
            :ok
          true ->
            Logger.warn("Failed to find anonymous proxy, retrying (attempt: #{iter + 1})")
            retry_anon_proxy(lap2_addr, iter + 1)
        end

      [] ->
        Logger.error("Failed to find anonymous proxy: network address not found")
        :error
    end
  end

  # Get the proxy pool for a node
  @spec get_proxy_pool(atom) :: map
  defp get_proxy_pool(proxy_mgr) do
    Map.get(ProxyManager.debug(proxy_mgr), :proxy_pool)
  end

  # Get all LAP2 => IP address mappings in the network
  @spec get_network_map() :: map
  defp get_network_map() do
    :ets.tab2list(:network_registry)
    |> Enum.reduce(%{}, fn {lap2_addr, registry}, acc ->
      ip_addr = Map.get(registry, :ip_addr)
      Map.put(acc, lap2_addr, ip_addr)
    end)
  end

  # Perform a function over all network nodes
  @spec map_network(term) :: {:ok, any} | {:error, :no_nodes}
  defp map_network(lambda) do
    case get_network_map() do
      [] ->
        Logger.error("No nodes in network")
        {:error, :no_nodes}

      network_map -> lambda.(network_map)
    end
  end

  # Add entries to a node's DHT table
  @spec add_dht(map, atom) :: :ok
  defp add_dht(network_map, router) do
    Enum.each(network_map, fn {addr, ip} ->
      Router.append_dht(addr, ip, router)
    end)
  end
end

defmodule CryptoUtils do
  @spec gen_ring(non_neg_integer,charlist, non_neg_integer) :: list(charlist) | :error
  def gen_ring(ring_idx, pk, ring_size) when ring_idx < ring_size and ring_size > 1 do
    Enum.map(1..ring_size-1, fn _ ->
      {_, other_key} = ClaimableRS.rs_gen()
      other_key
    end)
    |> List.insert_at(ring_idx, pk)
  end
  def gen_ring(_, _, _) do
    Logger.error("Invalid ring index or ring size")
    :error
  end

  @spec list_to_hex(list) :: String.t()
  def list_to_hex(list) do
    list
    |> :binary.list_to_bin()
    |> Base.encode16()
  end

  @spec hex_to_list(String.t()) :: list
  def hex_to_list(hex) do
    Base.decode16!(hex)
    |> :binary.bin_to_list()
  end

  @spec list_to_b64(list) :: String.t()
  def list_to_b64(list) do
    list
    |> :binary.list_to_bin()
    |> Base.encode64()
  end

  @spec b64_to_list(String.t()) :: list
  def b64_to_list(hex) do
    Base.decode64!(hex)
    |> :binary.bin_to_list()
  end
end

defmodule TestUtils do
  # Benchmark function execution time
  @spec benchmark(term) :: float
  def benchmark(function) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end
