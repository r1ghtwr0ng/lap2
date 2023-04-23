defmodule LAP2.Networking.Routing.Local do
  @moduledoc """
  Module for routing cloves to the local share handler.
  """

  require Logger
  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Networking.Routing.State
  alias LAP2.Main.StructHandlers.ShareHandler

  # ---- Public functions ----
  @doc """
  Relay a clove to the local share handler.
  """
  @spec relay_clove(map, map) :: map
  def relay_clove(state, %Clove{
        data: data,
        headers: {:regular_proxy, %RegularProxyHeader{proxy_seq: pseq}}
      }) do
    # TODO remove debug print
    Logger.info("[+] Local: Relaying clove to share handler")
    aux_data = %{request_type: :regular_proxy, proxy_seq: pseq}
    processor_name = state.config.registry_table.share_handler
    route_clove(processor_name, [data], aux_data)
    State.update_relay_timestamp(state, pseq)
  end

  @doc """
  Handle a discovery response from a remote node.
  """
  @spec receive_discovery_response(map, {binary, integer}, map) :: map
  def receive_discovery_response(state, source, %Clove{
        data: data,
        headers: {:proxy_response, %ProxyResponseHeader{proxy_seq: pseq, clove_seq: cseq, hop_count: hops}}
      }) do
    # TODO remove debug print
    Logger.info("[+] Local: Relaying discovery response to share handler")

    aux_data = %{
      request_type: :discovery_response,
      proxy_seq: pseq,
      clove_seq: cseq,
      relays: source,
      hop_count: hops
    }

    # Route the clove
    processor_name = state.config.registry_table.share_handler
    route_clove(processor_name, [data], aux_data)

    # Update the clove cache expiry timestamp
    State.update_clove_timestamp(state, cseq)
  end

  @doc """
  Handle a proxy request from a remote node.
  """
  @spec handle_proxy_request(map, {binary, integer}, map) :: map
  def handle_proxy_request(state, source, %Clove{
        data: data,
        headers: {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: cseq}}
      }) do
    # TODO remove debug print
    Logger.info("[+] Local: Relaying via proxy request from #{inspect(source)}")
    prev_hop = state.clove_cache[cseq].prev_hop
    proxy_seq = CloveHelper.gen_seq_num()

    aux_data = %{
      request_type: :proxy_request,
      clove_seq: cseq,
      proxy_seq: proxy_seq,
      relays: [source, prev_hop]
    }

    # Route the clove
    processor_name = state.config.registry_table.share_handler
    route_clove(processor_name, [data], aux_data)

    # Update and return Router state
    state
    |> State.evict_clove(cseq)
    |> State.ban_clove(cseq)
  end

  # ---- Private functions ----
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove(atom, list, map) :: :ok
  defp route_clove(_receiver, [], _aux_data), do: :ok
  defp route_clove(processor_name, [data | tail], aux_data) do
    # TODO remove debug print
    Logger.info("[+] Local: Delivering to share handler")
    Task.async(fn -> ShareHandler.deliver(data, aux_data, processor_name) end)
    route_clove(processor_name, tail, aux_data)
  end
end
