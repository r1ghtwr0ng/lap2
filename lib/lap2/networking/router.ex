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
    IO.puts("[i] Router: Starting router")

    state = %{
      clove_cache: %{},
      random_neighbors: [],
      own_cloves: [],
      drop_rules: %{clove_seq: [], ip_addr: [], proxy_seq: []},
      relay_table: %{},
      routing_table: %{},
      config: %{
        lap2_addr: config.lap2_addr,
        registry_table: config.registry_table,
        clove_cache_size: config.clove_cache_size,
        clove_cache_ttl: config.clove_cache_ttl,
        relay_table_size: config.relay_table_size,
        relay_table_ttl: config.relay_table_ttl,
        proxy_policy: config.proxy_policy,
        proxy_limit: config.proxy_limit
      }

      # TODO replace with config: config, this is just for debugging
    }

    {:ok, state}
  end

  # TODO append lap2_addr to the config
  # Handle received cloves
  @spec handle_cast({:route_inbound, {String.t(), non_neg_integer}, Clove}, map) ::
          {:noreply, map}
  def handle_cast({:route_inbound, source, clove}, state) do
    state
    |> State.clean_state()
    |> State.get_route(source, clove)
    |> case do
      # Proxy discovery
      {:random_walk, nil} ->
        IO.puts("No random neighbor found")
        {:noreply, state}

      {:random_walk, rand_neighbor} ->
        Remote.relay_proxy_discovery(state, source, rand_neighbor, clove)

      # Proxy request
      :proxy_request ->
        Local.handle_proxy_request(state, source, clove)

      # Route discovery response to share handler
      :recv_discovery ->
        Local.receive_discovery_response(state, source, clove)

      # Route discovery response
      {:discovery_response, ^source} ->
        Remote.relay_discovery_response(state, source, clove)

      # Relay clove to local
      {:relay, :share_handler} ->
        Local.relay_clove(state, clove)

      # Relay clove to remote
      {:relay, dest} when is_tuple(dest) ->
        Remote.relay_clove(state, dest, clove)

      # Drop clove
      _ ->
        IO.puts("[+] Router: Dropping clove")
        {:noreply, state}
    end
  end

  # Route outbound proxy cloves
  @spec handle_cast({:regular_proxy, {String.t(), non_neg_integer}, non_neg_integer, binary}, map) ::
          {:noreply, map}
  def handle_cast({:regular_proxy, dest, proxy_seq, data}, state) do
    Remote.route_outbound_proxy(state, dest, proxy_seq, data)
  end

  # Route outbound proxy discovery cloves
  @spec handle_cast(
          {:proxy_discovery, {String.t(), non_neg_integer}, non_neg_integer, binary},
          map
        ) :: {:noreply, map}
  def handle_cast({:proxy_discovery, dest, clove_seq, data}, state) do
    IO.puts("[+] Router GenServer: In proxy discovery handle cast")
    Remote.route_outbound_discovery(state, dest, clove_seq, data)
  end

  # Accept a request to become a proxy.
  @spec handle_cast(
          {:accept_proxy, non_neg_integer, {String.t(), non_neg_integer},
           {String.t(), non_neg_integer}},
          map
        ) :: {:noreply, map}
  def handle_cast({:accept_proxy, proxy_seq, node_1, node_2}, state) do
    new_state = State.add_relay(state, proxy_seq, node_1, node_2, :proxy)
    {:noreply, new_state}
  end

  # Remove outdated entries from state (clove_cache, relay_table) based on timestamps.
  # Routing table is updated by DHT, which is a seperate mechanism.
  @spec handle_cast({:clean_state}, map) :: {:noreply, map}
  def handle_cast({:clean_state}, state) do
    {:noreply, State.clean_state(state)}
  end

  # Update the router's configuration.
  @spec handle_cast({:update_config, map}, map) :: {:noreply, map}
  def handle_cast({:update_config, config}, state),
    do: {:noreply, Map.put(state, :config, config)}

  # Update the router's routing table.
  @spec handle_cast({:append_dht, String.t(), {String.t(), non_neg_integer}}, map) ::
          {:noreply, map}
  def handle_cast({:append_dht, lap2_addr, dest}, state) do
    new_router = Map.put(state.routing_table, lap2_addr, dest)

    new_state =
      state
      |> Map.put(:routing_table, new_router)
      |> Map.put(:random_neighbors, [lap2_addr | state.random_neighbors])

    {:noreply, new_state}
  end

  @spec handle_call({:debug}, pid, map) :: {:noreply, map}
  def handle_call({:debug}, _from, state) do
    {:reply, state, state}
  end

  @spec handle_info(any, map) :: {:noreply, map}
  def handle_info(_unexpected_msg, state) do
    # Handle unexpected messages
    # Logger.debug("Received unexpected message: #{inspect(unexpected_msg)}")
    {:noreply, state}
  end

  @doc """
  Terminate the UDP server.
  """
  @spec terminate(any, map) :: :ok
  def terminate(reason, _) do
    Logger.error("Router terminated. Reason: #{inspect(reason)}")
  end

  # ---- Public functions ----
  @doc """
  Route an inbound clove to the appropriate destination.
  """
  @spec route_inbound({String.t(), non_neg_integer}, Clove, atom) :: :ok
  def route_inbound(source, clove, name \\ :router) do
    GenServer.cast({:global, name}, {:route_inbound, source, clove})
  end

  @doc """
  Route data to the appropriate destination.
  """
  @spec route_outbound_proxy({String.t(), non_neg_integer}, non_neg_integer, binary, map) :: :ok
  def route_outbound_proxy(dest, proxy_seq, data, name) do
    IO.puts("[+] Router: Routing outbound clove")
    GenServer.cast({:global, name}, {:regular_proxy, dest, proxy_seq, data})
  end

  @spec route_outbound_discovery({String.t(), non_neg_integer}, non_neg_integer, binary, atom) ::
          :ok
  def route_outbound_discovery(dest, clove_seq, data, name) do
    IO.puts("[+] Router: Routing outbound discovery")
    GenServer.cast({:global, name}, {:proxy_discovery, dest, clove_seq, data})
  end

  @doc """
  Accept and reply to a proxy request, update state accordingly.
  """
  @spec accept_proxy(integer, {String.t(), non_neg_integer}, {String.t(), non_neg_integer}, atom) ::
          :ok
  def accept_proxy(proxy_seq, node_1, node_2, name \\ :router) do
    GenServer.cast({:global, name}, {:accept_proxy, proxy_seq, node_1, node_2})
  end

  @doc """
  Update the DHT with a new entry in the state
  """
  @spec append_dht(binary, {String.t(), non_neg_integer}, atom) :: :ok
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
    GenServer.call({:global, name}, {:debug})
  end
end
