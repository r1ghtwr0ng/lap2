defmodule LAP2.Networking.Routing.Local do
  @moduledoc """
  Module for routing cloves to the local share handler.
  """
  require Logger
  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Networking.Routing.State
  alias LAP2.Main.ShareHandler

  # ---- Public functions ----
  @doc """
  Relay a clove to the local share handler.
  """
  @spec relay_clove(map, map) :: {:noreply, map}
  def relay_clove(state, %Clove{data: data, headers:
  {:regular_proxy, %RegularProxyHeader{proxy_seq: pseq}}}) do
    IO.puts("[+] Local: Relaying clove to share handler") # Debug
    aux_data = %{request_type: :regular_proxy}
    processor_name = state.config.registry_table.share_handler
    route_clove(processor_name, [data], aux_data)
    new_state = State.update_relay_timestamp(state, pseq)
    {:noreply, new_state}
  end

  @doc """
  Handle a discovery response from a remote node.
  """
  @spec receive_discovery_response(map, {binary, integer}, map) :: {:noreply, map}
  def receive_discovery_response(state, source, %Clove{data: data, headers:
  {:proxy_response, %ProxyResponseHeader{proxy_seq: pseq, hop_count: hops}}}) do
    IO.puts("[+] Local: Relaying discovery response to share handler")
    aux_data = %{
      request_type: :discovery_response,
      proxy_seq: pseq,
      relay: source,
      hop_count: hops
    }
    processor_name = state.config.registry_table.share_handler
    route_clove(processor_name, [data], aux_data)
    {:noreply, state}
  end

  @doc """
  Handle a proxy request from a remote node.
  """
  @spec handle_proxy_request(map, {binary, integer}, map) :: {:noreply, map}
  def handle_proxy_request(state, source, %Clove{data: data, headers:
  {:proxy_response, %ProxyResponseHeader{clove_seq: cseq}}}) do
    IO.puts("[+] Local: Relaying via proxy request from #{inspect source}")
    prev_hop = state.clove_cache[cseq].prv_hop
    proxy_seq = CloveHelper.gen_seq_num()
    aux_data = %{
      request_type: :proxy_request,
      proxy_seq: proxy_seq,
      prv_hop: source,
      nxt_hop: prev_hop
    }
    processor_name = state.config.registry_table.share_handler
    new_state = state
    |> State.evict_clove(cseq)
    |> State.ban_clove(cseq)
    route_clove(processor_name, [data], aux_data)
    {:noreply, new_state}
  end

  # ---- Private functions ----
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove(atom, list, map) :: :ok
  defp route_clove(_receiver, [], _aux_data), do: :ok
  defp route_clove(processor_name, [data | tail], aux_data) do
    IO.puts("[+] Local: Delivering to share handler")
    IO.inspect(data, label: "LOCAL - RECEIVED:")
    Task.async(fn -> ShareHandler.deliver(data, aux_data, processor_name); end)
    route_clove(processor_name, tail, aux_data)
  end
end
