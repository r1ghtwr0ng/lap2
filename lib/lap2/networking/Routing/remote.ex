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
  @spec route_discovery_response(map, {binary, integer}, map) :: {:noreply, map}
  def route_discovery_response(state, source, %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops, data: data}) do
    dest = state.clove_cache[cseq].prv_hop
    IO.puts("[+] Relaying discovery response to #{inspect dest}")
    headers = %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops + 1}
    new_state = state
    |> State.add_relay(pseq, source, dest, :relay)
    |> State.evict_clove(cseq)
    route_clove(dest, [data], headers)
    {:noreply, new_state}
  end

  @doc """
  Relay a proxy request along its path.
  """
  @spec relay_clove(map, {binary, integer}, map) :: {:noreply, map}
  def relay_clove(state, dest, %{proxy_seq: pseq, data: data}) do
    IO.puts("[+] Relaying clove to #{inspect dest}") # Debug
    route_clove(dest, [data], %{proxy_seq: pseq})
    {:noreply, state}
  end

  @doc """
  Route a proxy discovery clove to a random neighbour.
  """
  @spec route_proxy_discovery(map, {binary, integer}, binary, map) :: {:noreply, map}
  def route_proxy_discovery(state, source, neighbor_addr, %{clove_seq: clove_seq, drop_probab: drop_prob, data: data} = clove) do
    dest = state.routing_table[neighbor_addr]
    IO.puts("[+] Relaying via random walk to #{inspect dest}")
    new_state = state
    |> State.cache_clove(source, dest, clove)
    |> State.remove_neighbor(neighbor_addr)
    route_clove(dest, [data], %{clove_seq: clove_seq, drop_probab: drop_prob})
    {:noreply, new_state}
  end

  # ---- Public outbound routing functions ----
  @spec route_outbound_discovery({binary, integer}, binary) :: :ok
  def route_outbound_discovery(dest, data) do
    IO.puts("[+] Routing outbound clove")
    clove_seq = CloveHelper.gen_seq_num()
    drop_probab = CloveHelper.gen_drop_probab(0.7, 1.0)
    headers = %{clove_seq: clove_seq, drop_probab: drop_probab}
    route_clove(dest, [data], headers)
  end

  @spec route_outbound({binary, integer}, binary, binary) :: :ok
  def route_outbound(dest, proxy_seq, data) do
    IO.puts("[+] Routing outbound clove")
    headers = %{proxy_seq: proxy_seq}
    route_clove(dest, [data], headers)
  end

  # ---- Private functions ----
  # MAJOR TODO: Update timestamps whenever accessed to prevent deletion
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove({binary, integer}, list, map) :: :ok
  defp route_clove( _receiver, [], _headers), do: :ok
  defp route_clove(dest, [data | tail], headers) do
    IO.puts("[+] Delivering to remote")
    LAP2Socket.send_clove(dest, data, headers)
    route_clove(dest, tail, headers)
  end
end
