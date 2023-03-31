defmodule LAP2.Networking.Router do
  @moduledoc """
  Stores routing information, updates DHT and stores information for resolving addresses.
  The actual functions for resolving the addresses, extracting keys, etc. is located in LAP2.Networking.Resolver
  This module also stores connection information (anonymous paths and corresponidng crypto keys)
  TODO have a look at a secure way of storing the keys
  """
  use GenServer
  require Logger
  alias LAP2.Networking.Routing.{Remote, Local, State}

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
  def handle_info({:route_inbound, source, clove}, state) do
    state
    |> State.clean_state()
    |> State.get_route(source, clove)
    |> case do
      # Proxy discovery
      {:random_walk, dest} -> Remote.route_proxy_discovery(state, source, dest, clove)
      # Proxy request
      :proxy_request-> Local.handle_proxy_request(state, source, clove)
      # Route discovery response to data processor
      :recv_discovery -> Local.receive_discovery_response(state, source, clove)
      # Route discovery response
      {:discovery_response, ^source} -> Remote.route_discovery_response(state, source, clove)
      # Relay clove to local
      {:relay, dest} when is_pid(dest) -> Local.relay_clove(state, dest, clove)
      # Relay clove to remote
      {:relay, dest} when is_tuple(dest) -> Remote.relay_clove(state, dest, clove)
      # Drop clove
      _ -> IO.puts("[+] Dropping clove")
        {:noreply, state}
    end
  end

  def handle_info({:route_outbound, dest, proxy_seq, data}, state) do
    Remote.route_outbound(dest, proxy_seq, data)
    {:noreply, state}
  end

  def handle_info({:proxy_discovery, dest, data}, state) do
    Remote.route_outbound_discovery(dest, data)
    {:noreply, state}
  end

  # Accept a request to become a proxy.
  def handle_info({:accept_proxy, proxy_seq, node_1, node_2}, state) do
    new_state = State.add_relay(state, proxy_seq, node_1, node_2, :proxy)
    {:noreply, new_state}
  end

  # Remove outdated entries from state (clove_cache, relay_routes) based on timestamps.
  # Routing table is updated by DHT, which is a seperate mechanism.
  def handle_info({:clean_state}, state) do
    {:noreply, State.clean_state(state)}
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
  @spec terminate(any, map) :: :ok
  def terminate(reason, %{udp_sock: nil}) do
    Logger.error("UDP socket terminated unexpectedly. Reason: #{inspect reason}")
  end
  def terminate(reason, %{udp_sock: udp_sock}) do
    :gen_udp.close(udp_sock)
    Logger.info("Router terminated. Reason: #{inspect reason}")
  end

  # ---- Public functions ----
  def route_inbound(source, clove) do
    GenServer.cast({:global, :router}, {:route_inbound, source, clove})
  end

  def route_outbound(dest, proxy_seq, data) do
    # TODO route outgoing clove via existing connection chain (not known by router)
    # TODO essentially just send the clove via the nodes in the chain (known by the router by conn_chain identifiers)
    IO.puts("[+] Routing outbound clove")
    GenServer.cast({:global, :router}, {:route_outbound, dest, proxy_seq, data})
  end

  def accept_proxy(proxy_seq, node_1, node_2) do
    GenServer.cast({:global, :router}, {:accept_proxy, proxy_seq, node_1, node_2})
  end

  def clean_state() do
    GenServer.cast({:global, :router}, {:clean_state})
  end
end
