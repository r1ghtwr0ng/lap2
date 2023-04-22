defmodule LAP2.Networking.Routing.Remote do
  @moduledoc """
  Module for routing cloves to remote destinations.
  """
  require Logger
  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Networking.Sockets.Lap2Socket
  alias LAP2.Networking.Routing.State

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
    dest = state.routing_table[neighbor_addr]
    IO.puts("[+] Remote: Relaying via random walk to #{inspect(dest)}")
    new_state = State.cache_clove(state, source, dest, clove)
    udp_name = state.config.registry_table.udp_server

    route_clove(dest, clove, udp_name)
    new_state
  end

  @doc """
  Route a discovery response along its path.
  """
  @spec relay_discovery_response(map, {String.t(), integer}, map) :: map
  def relay_discovery_response(state, source, %Clove{headers:
      {:proxy_response, %ProxyResponseHeader{clove_seq: cseq, proxy_seq: pseq, hop_count: hops}}} = clove) do
    dest = state.clove_cache[cseq].prv_hop
    IO.puts("[+] Remote: Relaying discovery response to #{inspect(dest)}")
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
    IO.puts("[+] Remote: Relaying clove to #{inspect(dest)}")
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
    IO.puts("[+] Remote: Routing outbound discovery")
    # Set random drop probability
    {hdr_type, hdr} = clove.headers
    new_header = {hdr_type, Map.put(hdr, :drop_probab, CloveHelper.gen_drop_probab(0.7, 1.0))}
    clove = Map.put(clove, :headers, new_header)
    # Route clove
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, clove, udp_name)
    # Add clove to own clove cache
    State.add_own_clove(state, clove.clove_seq)
  end

  @doc """
  Route a clove to a remote destination.
  """
  @spec route_outbound(map, {String.t(), integer}, Clove.t()) :: map
  def route_outbound(state, dest, clove) do
    IO.puts("[+] Remote: Routing outbound clove")
    # Route clove
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, clove, udp_name)
    # Add clove to own clove cache
    State.add_own_clove(state, clove.clove_seq)
  end

  # ---- Private functions ----
  # MAJOR TODO: Update timestamps whenever accessed to prevent deletion
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove({String.t(), non_neg_integer}, Clove.t(), atom) :: :ok
  defp route_clove(dest, clove, udp_name) do
    IO.puts("[+] Remote: Delivering to remote")
    Task.async(fn -> Lap2Socket.send_clove(dest, clove, udp_name) end)
    :ok
  end
end
