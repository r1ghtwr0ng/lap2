defmodule LAP2.Networking.Router do
  @moduledoc """
  Stores routing information, updates DHT and stores information for resolving addresses.
  The actual functions for resolving the addresses, extracting keys, etc. is located in LAP2.Networking.Resolver
  This module also stores connection information (anonymous paths and corresponidng crypto keys)
  TODO have a look at a secure way of storing the keys
  """
  use GenServer
  require Logger
  alias LAP2.Networking.LAP2Socket
  alias LAP2.Utils.RoutingHelper

  @doc """
  Start the Router process.
  """
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, :router})
  end

  @doc """
  Initialise the router.
  """
  @spec init(map) :: {:ok, map}
  def init(config) do
    # Initialise router state
    IO.puts("Starting router")
    state = %{
      clove_cache: %{},
      anon_pool: %{},
      own_cloves: [],
      drop_rules: %{clove_seq: [], ip_addr: [], proxy_seq: []},
      relay_table: %{},
      routing_table: %{config.lap2_addr => {:local, self()}},
      config: %{
        lap2_addr: config.lap2_addr,
        clove_cache_size: config.clove_cache_size,
        clove_cache_ttl: config.clove_cache_ttl,
        relay_routes_size: config.relay_routes_size,
        relay_routes_ttl: config.relay_routes_ttl,
        data_processor: config.data_processor,
        proxy_policy: config.proxy_policy,
        proxy_limit: config.proxy_limit,
      }
    }
    # TODO fix config to load from file
    {:ok, state}
  end

  # Handle received cloves
  @spec handle_info({atom, {binary, integer}, map}, map) :: {:noreply, map}
  def handle_info({:route_inbound, source, %{data: data} = clove}, state) do
    state
    |> RoutingHelper.clean_state()
    |> RoutingHelper.get_route(source, clove)
    |> case do
      # Proxy discovery
      {:random_walk, dest} ->
        IO.puts("[+] Relaying via random walk to #{inspect dest}")
        new_state = RoutingHelper.cache_clove(state, source, dest, clove)
        RoutingHelper.route_clove({:remote, dest}, [data], %{clove_seq: clove.clove_seq, drop_probab: clove.drop_probab})
        {:noreply, new_state}

      # Proxy request
      {:proxy_request, proxy_seq} ->
        IO.puts("[+] Relaying via proxy request to #{inspect proxy_seq}")
        prev_hop = state.clove_cache[clove.clove_seq].prv_hop
        dest = {:local, state.config.data_processor}
        RoutingHelper.route_clove(dest, [data], %{clove_seq: clove.clove_seq, proxy_seq: proxy_seq, hop_count: clove.hop_count, relays: [source, prev_hop]})
        new_state = state
        |> RoutingHelper.evict_clove(clove.clove_seq)
        |> RoutingHelper.ban_clove(clove.clove_seq)
        {:noreply, new_state}

      # Route discovery response to data processor
      :discovery_recv ->
        IO.puts("[+] Relaying discovery response to data processor")
        dest = {:local, state.config.data_processor}
        RoutingHelper.route_clove(dest, [data], %{clove_seq: clove.clove_seq, proxy_seq: clove.proxy_seq, hop_count: clove.hop_count, relays: [source]})
        {:noreply, state}

      # Route discovery response
      {:discovery_response, ^source} ->
        dest = clove.clove_cache[clove.clove_seq].prv_hop
        IO.puts("[+] Relaying discovery response to #{inspect dest}")
        RoutingHelper.route_clove({:remote, dest}, [data], %{clove_seq: clove.clove_seq, proxy_seq: clove.proxy_seq, hop_count: clove.hop_count})
        new_state = state
        |> RoutingHelper.add_relay(clove.proxy_seq, source, dest)
        |> RoutingHelper.evict_clove(clove.clove_seq)
        {:noreply, new_state}

      # Relay clove to local data processor
      {:relay, dest} when is_pid(dest) ->
        IO.puts("[+] Relaying clove to #{inspect dest}") # Debug
        RoutingHelper.route_clove({:local, dest}, [data], %{proxy_seq: clove.proxy_seq})
        {:noreply, state}

      # Relay clove to remote
      {:relay, dest} when is_tuple(dest) ->
        IO.puts("[+] Relaying clove to #{inspect dest}") # Debug
        RoutingHelper.route_clove({:remote, dest}, [data], %{proxy_seq: clove.proxy_seq})
        {:noreply, state}

      # Drop clove
      _ ->
        IO.puts("[+] Dropping clove")
        {:noreply, state}
    end
  end

  def handle_info({:route_outbound, anonymous_path, data}, state) do
    # TODO route packet ------------------- <<<<<<<<<<<<<<<<<<<<<<<<DO THIS NEXT>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    IO.puts("[+] Routing outbound packet")
    # Return, data_processor will reconstruct packet and decide if node can be a proxy.
    # If yes, in another handle_info, do
    # Save: proxy_seq => %{source_1 => data_processor, source_2 => data_processor, timestamp: t} -> relay_table
    # Save: proxy_seq => [source_1, source_2] -> anon_pool
    # Relay: for route in anon_pool[proxy_seq]: send(route, {checksum, clove_seq, proxy_seq, hop_count, data})
    {:noreply, state}
  end

  def handle_info({:establish_proxy, anonymous_path, packet}, state) do
    # TODO route packet ------------------- <<<<<<<<<<<<<<<<<<<<<<<<DO THIS NEXT>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    IO.puts("[+] Routing outbound packet")
    # Return, data_processor will reconstruct packet and decide if node can be a proxy.
    # If yes, in another handle_info, do
    # Save: proxy_seq => %{source_1 => data_processor, source_2 => data_processor, timestamp: t} -> relay_table
    # Save: proxy_seq => [source_1, source_2] -> anon_pool
    # Relay: for route in anon_pool[proxy_seq]: send(route, {checksum, clove_seq, proxy_seq, hop_count, data})
    {:noreply, state}
  end

  # Accept a request to become a proxy.
  def handle_info({:accept_proxy, proxy_seq, node_1, node_2}, state) do
    new_state = RoutingHelper.add_relay(state, proxy_seq, node_1, node_2, :proxy)
    {:noreply, new_state}
  end

  # Remove outdated entries from state (clove_cache, relay_routes) based on timestamps.
  # Routing table is updated by DHT, which is a seperate mechanism.
  def handle_info({:clean_state}, state) do
    {:noreply, RoutingHelper.clean_state(state)}
  end

  # Lookup routing information from state.
  # Lookup is performed both in the routing table and the relay routes.
  def handle_info({:lookup, dest}, state) do
    # TODO
    IO.puts("[+] DHT lookup for #{inspect dest}")
    {:noreply, state}
  end

  @doc """
  Terminate the UDP server.
  """
  def terminate(reason, %{udp_sock: nil}) do
    Logger.error("UDP socket terminated unexpectedly. Reason: #{inspect(reason)}")
  end

  def terminate(reason, %{udp_sock: udp_sock}) do
    :gen_udp.close(udp_sock)
    Logger.info("Router terminated. Reason: #{inspect(reason)}")
  end

  # ---- Public functions ----
  def route_inbound(source, clove) do
    GenServer.call({:global, :router}, {:route_packet, source, clove})
  end

  def route_outbound(conn_chain, clove_list) do
    # TODO route outgoing packet via existing connection chain (not known by router)
    # TODO essentially just send the packet via the nodes in the chain (known by the router by conn_chain identifiers)
    GenServer.call({:global, :router}, {:route_outbound, conn_chain, clove_list})
    IO.puts("[+] Routing outbound packet")
  end

  def accept_proxy(proxy_seq, node_1, node_2) do
    GenServer.call({:global, :router}, {:accept_proxy, proxy_seq, node_1, node_2})
  end

  def clean_state() do
    GenServer.call({:global, :router}, {:clean_state})
  end
end
