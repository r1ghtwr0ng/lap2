defmodule LAP2.Networking.Routing.Local do
  @moduledoc """
  Helper functions for routing packets.
  """
  require Logger
  alias LAP2.Utils.PacketHelper
  alias LAP2.Networking.Routing.State

  # ---- Public functions ----
  def relay_clove(state, dest, %{proxy_seq: pseq, data: data}) do
    IO.puts("[+] Relaying clove to #{inspect dest}") # Debug
    route_clove(dest, [data], %{proxy_seq: pseq}, :clove_recv)
    {:noreply, state}
  end

  def receive_discovery_response(state, source, %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops, data: data}) do
    IO.puts("[+] Relaying discovery response to data processor")
    dest = state.config.data_processor
    headers = %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops, relays: [source]}
    route_clove(dest, [data], headers, :discovery_response)
    {:noreply, state}
  end

  def handle_proxy_request(state, source, %{clove_seq: cseq, hop_count: hops, data: data} = clove) do
    IO.puts("[+] Relaying via proxy request from #{inspect source}")
    prev_hop = state.clove_cache[cseq].prv_hop
    proxy_seq = PacketHelper.gen_seq_num(8)
    headers = %{clove_seq: cseq, proxy_seq: proxy_seq, hop_count: hops, relays: [source, prev_hop]}
    dest = state.config.data_processor
    route_clove(dest, [data], headers, :proxy_request)
    {:noreply, state}
    new_state = state
    |> State.evict_clove(clove.clove_seq)
    |> State.ban_clove(clove.clove_seq)
    {:noreply, new_state}
  end

  # ---- Private functions ----
  # MAJOR TODO: Update timestamps whenever accessed to prevent deletion
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove(pid, list, map, atom) :: :ok
  def route_clove(_receiver, [], _headers, _req_type), do: :ok
  def route_clove(dest, [data | tail], headers, req_type) do
    IO.puts("[+] Delivering to data processor")
    IO.inspect(data, label: "RECEIVED:")
    # TODO lookup global process naming rather than PID (in case of crash)
    # TODO implement DataProcessor.deliver
    # DataProcessor.deliver(dest, req_type, data, headers)
    route_clove(dest, tail, headers, req_type)
  end
end
