defmodule LAP2.Networking.Routing.Remote do
  @moduledoc """
  Helper functions for routing packets.
  """
  require Logger
  alias LAP2.Utils.PacketHelper
  alias LAP2.Networking.LAP2Socket
  alias LAP2.Networking.Routing.State

  # ---- Public inbound routing functions ----
  def route_discovery_response(state, source, %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops, data: data}) do
    dest = state.clove_cache[cseq].prv_hop
    IO.puts("[+] Relaying discovery response to #{inspect dest}")
    headers = %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops + 1}
    route_clove(dest, [data], headers)
    new_state = state
    |> State.add_relay(pseq, source, dest, :relay)
    |> State.evict_clove(cseq)
    {:noreply, new_state}
  end

  def relay_clove(state, dest, %{proxy_seq: pseq, data: data}) do
    IO.puts("[+] Relaying clove to #{inspect dest}") # Debug
    route_clove(dest, [data], %{proxy_seq: pseq})
    {:noreply, state}
  end

  def route_proxy_discovery(state, source, dest, %{clove_seq: clove_seq, drop_probab: drop_prob, data: data} = clove) do
    IO.puts("[+] Relaying via random walk to #{inspect dest}")
    new_state = State.cache_clove(state, source, dest, clove)
    route_clove(dest, [data], %{clove_seq: clove_seq, drop_probab: drop_prob})
    {:noreply, new_state}
  end

  # ---- Public outbound routing functions ----
  @spec route_outbound_discovery({binary, integer}, binary) :: :ok
  def route_outbound_discovery(dest, data) do
    IO.puts("[+] Routing outbound packet")
    clove_seq = PacketHelper.gen_seq_num(4)
    drop_probab = PacketHelper.gen_drop_probab(0.7, 1.0)
    headers = %{clove_seq: clove_seq, drop_probab: drop_probab}
    route_clove(dest, [data], headers)
  end

  @spec route_outbound({binary, integer}, binary, binary) :: :ok
  def route_outbound(dest, proxy_seq, data) do
    IO.puts("[+] Routing outbound packet")
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
    LAP2Socket.send_packet(dest, data, headers)
    route_clove(dest, tail, headers)
  end
end
