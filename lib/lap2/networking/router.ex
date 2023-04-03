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
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, config.name})
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
      random_neighbors: [],
      own_cloves: [],
      drop_rules: %{clove_seq: [], ip_addr: [], proxy_seq: []},
      relay_table: %{},
      routing_table: %{},
      config: %{
        lap2_addr: nil,
        data_processor: nil,
        clove_cache_size: config.clove_cache_size,
        clove_cache_ttl: config.clove_cache_ttl,
        relay_routes_size: config.relay_routes_size,
        relay_routes_ttl: config.relay_routes_ttl,
        proxy_policy: config.proxy_policy,
        proxy_limit: config.proxy_limit,
      }
    }
    # TODO fix config to load from file
    {:ok, state}
  end

  # TODO append data_processor, lap2_addr to the config
  # Handle received cloves
  @spec handle_info({atom, {binary, integer}, map}, map) :: {:noreply, map}
  def handle_cast({:route_inbound, source, clove}, state) do
    state
    |> State.clean_state()
    |> State.get_route(source, clove)
    |> case do
      # Proxy discovery
      {:random_walk, rand_neighbor} -> Remote.route_proxy_discovery(state, source, rand_neighbor, clove)
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

  def handle_cast({:route_outbound, dest, proxy_seq, data}, state) do
    Remote.route_outbound(dest, proxy_seq, data)
    {:noreply, state}
  end

  def handle_cast({:proxy_discovery, dest, data}, state) do
    Remote.route_outbound_discovery(dest, data)
    {:noreply, state}
  end

  # Accept a request to become a proxy.
  def handle_cast({:accept_proxy, proxy_seq, node_1, node_2}, state) do
    new_state = State.add_relay(state, proxy_seq, node_1, node_2, :proxy)
    {:noreply, new_state}
  end

  # Remove outdated entries from state (clove_cache, relay_routes) based on timestamps.
  # Routing table is updated by DHT, which is a seperate mechanism.
  def handle_cast({:clean_state}, state) do
    {:noreply, State.clean_state(state)}
  end

  # Update the router's configuration.
  def handle_cast({:update_config, config}, state), do: {:noreply, Map.put(state, :config, config)}

  # Update the router's routing table.
  def handle_cast({:append_dht, lap2_addr, dest}, state) do
    new_router = Map.put(state.routing_table, lap2_addr, dest)
    new_state = state
    |> Map.put(:routing_table, new_router)
    |> Map.put(:random_neighbors, [lap2_addr | state.random_neighbors])
    {:noreply, new_state}
  end

  def handle_cast({:debug}, state) do
    IO.inspect(state)
    {:noreply, state}
  end

  @doc """
  Terminate the UDP server.
  """
  @spec terminate(any, map) :: :ok
  def terminate(reason, _) do
    Logger.error("Router terminated. Reason: #{inspect reason}")
  end

  # ---- Public functions ----
  @doc """
  Route an inbound clove to the appropriate destination.
  """
  @spec route_inbound({binary, integer}, map, atom) :: :ok
  def route_inbound(source, clove, name \\ :router) do
    GenServer.cast({:global, name}, {:route_inbound, source, clove})
  end

  @doc """
  Route data to the appropriate destination.
  """
  @spec route_outbound({binary, integer}, binary, binary, atom) :: :ok
  def route_outbound(dest, proxy_seq, data, name \\ :router) do
    IO.puts("[+] Routing outbound clove")
    GenServer.cast({:global, name}, {:route_outbound, dest, proxy_seq, data})
  end

  @doc """
  Accept and reply to a proxy request, update state accordingly.
  """
  @spec accept_proxy(binary, {binary, integer}, {binary, integer}, atom) :: :ok
  def accept_proxy(proxy_seq, node_1, node_2, name \\ :router) do
    GenServer.cast({:global, name}, {:accept_proxy, proxy_seq, node_1, node_2})
  end

  @doc """
  Update the DHT with a new entry in the state
  """
  @spec append_dht(binary, {binary, integer}, atom) :: :ok
  def append_dht(lap2_addr, dest, name \\ :router) do
    GenServer.cast({:global, name}, {:append_dht, lap2_addr, dest})
  end

  @doc """
  Update the configuration in the state
  """
  @spec update_config(map, atom) :: :ok
  def update_config(config, name \\ :router) do
    GenServer.cast({:global, name}, {:update_config, config})
  end

  @doc """
  Delete outdated entries from state.
  """
  @spec clean_state(atom) :: :ok
  def clean_state(name \\ :router) do
    GenServer.cast({:global, name}, {:clean_state})
  end

  @doc """
  Inspect the router state.
  """
  @spec debug(atom) :: :ok
  def debug(name \\ :router) do
    GenServer.cast({:global, name}, {:debug})
  end
end
