defmodule LAP2.Networking.Routing.Remote do
  @moduledoc """
  Module for routing cloves to remote destinations.
  """
  require Logger
  alias LAP2.Utils.CloveHelper
  alias LAP2.Networking.LAP2Socket
  alias LAP2.Networking.Routing.State

  # ---- Public inbound routing functions ----
  @doc """
  Route a discovery response along its path.
  """
  @spec relay_discovery_response(map, {String.t, integer}, map) :: {:noreply, map}
  def relay_discovery_response(state, source, %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops, data: data}) do
    dest = state.clove_cache[cseq].prv_hop
    IO.puts("[+] Remote: Relaying discovery response to #{inspect dest}")
    headers = %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops + 1}
    new_state = state
    |> State.add_relay(pseq, source, dest, :relay)
    |> State.evict_clove(cseq)
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, [data], headers, udp_name, :proxy_response)
    {:noreply, new_state}
  end

  @doc """
  Relay a proxy discovery clove to a random neighbour.
  """
  @spec relay_proxy_discovery(map, {String.t, integer}, binary, map) :: {:noreply, map}
  def relay_proxy_discovery(state, source, neighbor_addr, %{clove_seq: clove_seq, drop_probab: drop_prob, data: data} = clove) do
    dest = state.routing_table[neighbor_addr]
    IO.puts("[+] Remote: Relaying via random walk to #{inspect dest}")
    new_state = State.cache_clove(state, source, dest, clove)
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, [data], %{clove_seq: clove_seq, drop_probab: drop_prob}, udp_name, :proxy_discovery)
    {:noreply, new_state}
  end

  @doc """
  Relay a proxy request along its path.
  """
  @spec relay_clove(map, {String.t, integer}, map) :: {:noreply, map}
  def relay_clove(state, dest, %{proxy_seq: pseq, data: data}) do
    IO.puts("[+] Remote: Relaying clove to #{inspect dest}") # Debug
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, [data], %{proxy_seq: pseq}, udp_name, :regular_proxy)
    {:noreply, state}
  end

  # ---- Public outbound routing functions ----
  @doc """
  Route a clove to a remote destination.
  """
  @spec route_outbound_discovery(map, {String.t, integer}, integer, binary) :: {:noreply, map}
  def route_outbound_discovery(state, dest, clove_seq, data) do
    IO.puts("[+] Remote: Routing outbound discovery")
    drop_probab = CloveHelper.gen_drop_probab(0.7, 1.0)
    headers = %{clove_seq: clove_seq, drop_probab: drop_probab}
    new_state = State.add_own_clove(state, clove_seq)
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, [data], headers, udp_name, :proxy_discovery)
    {:noreply, new_state}
  end

  @doc """
  Route a clove to a remote destination.
  """
  @spec route_outbound_proxy(map, {String.t, integer}, integer, binary) :: {:noreply, map}
  def route_outbound_proxy(state, dest, proxy_seq, data) do
    IO.puts("[+] Remote: Routing outbound clove")
    headers = %{proxy_seq: proxy_seq}
    udp_name = state.config.registry_table.udp_server
    route_clove(dest, [data], headers, udp_name, :regular_proxy)
    {:noreply, state}
  end

  # ---- Private functions ----
  # MAJOR TODO: Update timestamps whenever accessed to prevent deletion
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove({String.t, integer}, list, map, atom, atom) :: :ok
  defp route_clove( _receiver, [], _headers), do: :ok
  defp route_clove(dest, [data | tail], headers, udp_name, clove_type) do
    IO.puts("[+] Remote: Delivering to remote")
    Task.async(fn -> LAP2Socket.send_clove(dest, data, headers, udp_name, clove_type); end)
    route_clove(dest, tail, headers)
  end
end
