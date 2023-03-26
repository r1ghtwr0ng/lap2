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
    GenServer.start_link(__MODULE__, config, name: {:global, :udp_server})
  end

  @doc """
  Initialise the router.
  """
  def init(config) do
    # Initialise router state
    IO.puts("Starting router")
    state = %{
      clove_cache: %{},
      local_cloves: %{},
      anonymous_paths: %{},
      relay_routes: %{},
      routing_table: %{config.lap2_addr => {:local, self()}},
      config: %{
        lap2_addr: config.lap2_addr,
        clove_cache_size: config.clove_cache_size,
        clove_cache_ttl: config.clove_cache_ttl,
        relay_routes_size: config.relay_routes_size,
        relay_routes_ttl: config.relay_routes_ttl,
        data_processor: config.data_processor
      }
    }
    # TODO fix config to load from file
    {:ok, state}
  end

  # Handle received cloves
  def handle_info({:route_inbound, source, %{seq: seq_num, data: data, checksum: checksum} = clove}, state) do
    # TODO route packet ------------------- <<<<<<<<<<<<<<<<<<<<<<<<DO THIS NEXT>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    state = state
    |> RoutingHelper.clean_clove_cache()
    |> RoutingHelper.clean_relay_routes()
    case RoutingHelper.get_route(state, source, clove) do
      :local_exists ->
        IO.puts("[+] Sending clove to data processor (existing)")
        new_state = RoutingHelper.add_local_clove(state, seq_num, checksum)
        RoutingHelper.deliver_data([data], seq_num, state.config.data_processor)
        {:noreply, new_state}

      :local_new ->
        IO.puts("[+] Sending clove to data processor (new)")
        %{data: prev_data} = Map.get(state.local_cloves, seq_num)
        RoutingHelper.deliver_data([prev_data, data], seq_num, state.config.data_processor)
        new_state = state
        |> RoutingHelper.migrate_clove(seq_num)
        |> RoutingHelper.add_local_clove(seq_num, checksum)
        {:noreply, new_state}

      {:remote, dest} ->
        IO.puts("[+] Routing clove to #{inspect dest}") # Debug
        new_state = state
        |> RoutingHelper.cache_clove(clove)
        |> RoutingHelper.add_route(source, dest)
        # Send data off to destination
        Task.async(fn -> LAP2Socket.send_packet(dest, data); end)
        {:noreply, new_state}

      :drop ->
        IO.puts("[+] Discarding clove #{seq_num}")
        {:noreply, state}
    end
  end

  def handle_info({:route_outound, anonymous_path, packet}, state) do
    # TODO route packet ------------------- <<<<<<<<<<<<<<<<<<<<<<<<DO THIS NEXT>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    IO.puts("[+] Routing outbound packet")
    {:noreply, state}
  end

  # Remove outdated entries from state (clove_cache, relay_routes) based on timestamps.
  # Routing table is updated by DHT, which is a seperate mechanism.
  def handle_info({:clean_state}, state) do
    state = state
    |> RoutingHelper.clean_clove_cache()
    |> RoutingHelper.clean_relay_routes()
    {:noreply, state}
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
    GenServer.call({:global, :udp_server}, {:route_packet, source, clove})
  end

  def route_outbound(conn_chain, clove_list) do
    # TODO route outgoing packet via existing connection chain (not known by router)
    # TODO essentially just send the packet via the nodes in the chain (known by the router by conn_chain identifiers)
    IO.puts("[+] Routing outbound packet")
  end
end
