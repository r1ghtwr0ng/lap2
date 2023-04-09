defmodule LAP2.Networking.Routing.Local do
  @moduledoc """
  Module for routing cloves to the local data processor.
  """
  require Logger
  alias LAP2.Utils.CloveHelper
  alias LAP2.Networking.Routing.State
  alias LAP2.Main.DataProcessor

  # ---- Public functions ----
  @doc """
  Relay a clove to the local data processor.
  """
  @spec relay_clove(map, map) :: {:noreply, map}
  def relay_clove(state, %Clove{data: data, headers:
  {:regular_proxy, %RegularProxyHeader{proxy_seq: pseq}}}) do
    IO.puts("[+] Local: Relaying clove to data processor") # Debug
    processor_name = state.config.registry_table.data_processor
    route_clove(processor_name, [data], %{proxy_seq: pseq}, :regular_proxy)
    {:noreply, state}
  end

  @doc """
  Handle a discovery response from a remote node.
  """
  @spec receive_discovery_response(map, {binary, integer}, map) :: {:noreply, map}
  def receive_discovery_response(state, source, %Clove{data: data, headers:
  {:proxy_response, %ProxyResponseHeader{clove_seq: cseq, proxy_seq: pseq, hop_count: hops}}}) do
    IO.puts("[+] Local: Relaying discovery response to data processor")
    processor_name = state.config.registry_table.data_processor
    headers = %{clove_seq: cseq, proxy_seq: pseq, hop_count: hops, relays: [source]}
    route_clove(processor_name, [data], headers, :proxy_response)
    {:noreply, state}
  end

  @doc """
  Handle a proxy request from a remote node.
  """
  @spec handle_proxy_request(map, {binary, integer}, map) :: {:noreply, map}
  def handle_proxy_request(state, source, %Clove{data: data, headers:
  {:proxy_response, %ProxyResponseHeader{clove_seq: cseq}}}) do
    # MAJOR-ish TODO: make this work
    IO.puts("[+] Local: Relaying via proxy request from #{inspect source}")
    prev_hop = state.clove_cache[cseq].prv_hop
    proxy_seq = CloveHelper.gen_seq_num()
    headers = %{clove_seq: cseq, proxy_seq: proxy_seq, relays: [source, prev_hop]}
    processor_name = state.config.registry_table.data_processor
    new_state = state
    |> State.evict_clove(cseq)
    |> State.ban_clove(cseq)
    route_clove(processor_name, [data], headers, :proxy_discovery)
    {:noreply, new_state}
  end

  # ---- Private functions ----
  # MAJOR TODO: Update timestamps whenever accessed to prevent deletion
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove(atom, list, map, atom) :: :ok
  defp route_clove(_receiver, [], _headers, _req_type), do: :ok
  defp route_clove(processor_name, [data | tail], headers, req_type) do
    IO.puts("[+] Local: Delivering to data processor")
    IO.inspect(data, label: "LOCAL - RECEIVED:")
    Task.async(fn -> DataProcessor.deliver(req_type, data, headers, processor_name); end)
    route_clove(processor_name, tail, headers, req_type)
  end
end
