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
  def init(%{lap2_addr: lap2_addr} = config) do
    # Initialise router state
    IO.puts("Starting router")
    state = %{
      clove_cache: %{},
      lap2_addr: lap2_addr,
      relay_routes: %{},
      routing_table: %{lap2_addr => {:local, self()}},
      config: %{
        clove_cache_size: 100,
        clove_cache_ttl: 100000,
        relay_routes_size: 100,
        relay_routes_ttl: 100000,
      }
    }
    # TODO fix config to load from file
    {:ok, state}
  end

  # Handle received UDP packets
  def handle_info({:route_packet, %{seq: seq_num, headers: headers, data: data} = packet}, state) do
    # TODO route packet -------------------------------------------------<<<<<<<<<<<<<<<<<<DO THIS NEXT>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    state = state
    |> RoutingHelper.clean_clove_cache()
    |> RoutingHelper.clean_relay_routes()
    case RoutingHelper.get_route(packet, state) do
      {:local, pid} ->
        # TODO local proc routing
        IO.puts("[+] Sending packet to #{pid}")
        {:noreply, RoutingHelper.cache_clove(state, packet)}
      {:remote, dest, opts} ->
        IO.puts("[+] Routing packet to #{dest}") # Debug
        LAP2Socket.send_packet(dest, opts, data)

      {:drop, _} -> IO.puts("[+] Discarding packet")
    end
  end

  # TODO append route to state
  def handle_info({:add_route, route}, state), do: {:noreply, RoutingHelper.add_route(state, route)}

  def handle_info({:del_route, route}, state) do
    # TODO
    IO.puts("[+] Updating routing state")
  end

  # Remove outdated entries from state (clove_cache, relay_routes) based on timestamps.
  # Routing table is updated by DHT, which is a seperate mechanism.
  def handle_info({:clean_state}, state) do
    # TODO
    IO.puts("[+] Updating routing state")
  end

  # Lookup routing information from state.
  # Lookup is performed both in the routing table and the relay routes.
  def handle_info({:lookup, dest}, state) do
    # TODO
    IO.puts("[+] DHT lookup for #{inspect dest}")
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
  def route_packet(%{headers: headers, data: data} = packet) do
    GenServer.call({:global, :udp_server}, {:route_packet, packet})
  end
end
