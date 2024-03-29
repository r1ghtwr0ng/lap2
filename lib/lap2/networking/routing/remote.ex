defmodule LAP2.Networking.Routing.Remote do
  @moduledoc """
  Module for routing cloves to remote destinations.
  """
  require Logger
  alias LAP2.Utils.Generator
  alias LAP2.Networking.Resolver
  alias LAP2.Networking.Sockets.Lap2Socket
  alias LAP2.Networking.Helpers.State

  # ---- Public inbound routing functions ----
  @doc """
  Relay a proxy discovery clove to a random neighbour.
  """
  @spec relay_proxy_discovery(map, {String.t(), integer}, binary, map) :: map
  def relay_proxy_discovery(
        state,
        source,
        neighbor_addr,
        %Clove{headers: {:proxy_discovery, _}} = clove
      ) do
    # Resolve network address to IP address
    case Resolver.resolve_addr(neighbor_addr, state.routing_table) do
      {:ok, dest} ->
        #Logger.info("[+] Remote (#{state.config.lap2_addr}): Relaying via random walk to #{inspect(dest)}")
        udp_name = state.config.registry_table.udp_server

        route_clove(dest, clove, udp_name)
        State.cache_clove(state, source, dest, clove)

      _ ->
        Logger.error("[-] Remote (#{state.config.lap2_addr}): Unable to resolve address: #{neighbor_addr}")
        state
    end
  end

  @doc """
  Route a discovery response along its path.
  """
  @spec relay_discovery_response(map, {String.t(), non_neg_integer}, {String.t(), non_neg_integer}, map) :: map
  def relay_discovery_response(state, source, dest, %Clove{headers:
      {:proxy_response, %ProxyResponseHeader{clove_seq: cseq, proxy_seq: pseq, hop_count: hops}}} = clove) do
    #Logger.info("[+] Remote (#{state.config.lap2_addr}): Relaying discovery response to #{inspect(dest)}")
    {hdr_type, hdr} = clove.headers
    new_header = {hdr_type, Map.put(hdr, :hop_count, hops + 1)}
    clove = Map.put(clove, :headers, new_header)

    # Route the clove
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, clove, udp_name)

    # Update the relay state
    state
    |> State.add_relay(pseq, source, dest)
    |> State.evict_clove(cseq)
  end

  @doc """
  Relay a proxy request along its path.
  """
  @spec relay_clove(map, {String.t(), integer}, map) :: map
  def relay_clove(state, dest, %Clove{headers: {:regular_proxy, %RegularProxyHeader{proxy_seq: pseq}}} = clove) do
    # Debug
    #Logger.info("[+] Remote (#{state.config.lap2_addr}): Relaying clove to #{inspect(dest)}")
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, clove, udp_name)
    State.update_relay_timestamp(state, pseq)
  end

  # ---- Public outbound routing functions ----
  @doc """
  Route a clove to a remote destination.
  """
  @spec route_outbound_discovery(map, {String.t(), integer}, Clove.t()) :: map
  def route_outbound_discovery(state, dest, clove) do
    # Set random drop probability
    {hdr_type, hdr} = clove.headers
    new_header = {hdr_type, Map.put(hdr, :drop_probab, Generator.generate_float(0.8, 1.0))}
    clove = Map.put(clove, :headers, new_header)
    # Route clove
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, clove, udp_name)
    # Add clove to own clove cache
    State.add_own_clove(state, hdr.clove_seq)
  end

  @doc """
  Route a clove to a remote destination.
  """
  @spec route_outbound(map, {String.t(), integer}, Clove.t()) :: :ok
  def route_outbound(state, dest, clove) do
    # Route clove
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, clove, udp_name)
    :ok
  end

  # ---- Private functions ----
  # MAJOR TODO: Update timestamps whenever accessed to prevent deletion
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove({String.t(), non_neg_integer}, Clove.t(), atom) :: :ok
  defp route_clove(dest, clove, udp_name) do
    #Logger.info("[+] (#{udp_name}) Sending clove: #{inspect clove} to #{inspect(dest)}")
    Task.async(fn -> Lap2Socket.send_clove(dest, clove, udp_name) end)
    :ok
  end
end
