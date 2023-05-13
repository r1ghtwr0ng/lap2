defmodule LAP2.Networking.Routing.Local do
  @moduledoc """
  Module for routing cloves to the local share handler.
  """

  require Logger
  alias LAP2.Utils.Generator
  alias LAP2.Networking.Helpers.State
  alias LAP2.Main.StructHandlers.ShareHandler

  # ---- Public functions ----
  @doc """
  Relay a clove to the local share handler.
  """
  @spec relay_clove(map, Clove.t()) :: map
  def relay_clove(state, %Clove{
        headers: {:regular_proxy, %RegularProxyHeader{proxy_seq: pseq}}
      } = clove) do
    # TODO remove debug print
    #Logger.info("[+] Local: Relaying clove to share handler")
    aux_data = %{request_type: :regular_proxy, proxy_seq: pseq}
    processor_name = state.config.registry_table.share_handler
    route_clove(processor_name, clove, aux_data)
    State.update_relay_timestamp(state, pseq)
  end

  @doc """
  Handle a discovery response from a remote node.
  """
  @spec receive_discovery_response(map, {binary, integer}, Clove.t()) :: map
  def receive_discovery_response(state, source, %Clove{
        headers: {:proxy_response, %ProxyResponseHeader{proxy_seq: pseq, clove_seq: cseq, hop_count: hops}}
      } = clove) do
    # TODO remove debug print


    aux_data = %{
      request_type: :discovery_response,
      proxy_seq: pseq,
      clove_seq: cseq,
      relays: source,
      hop_count: hops
    }

    Logger.info("[+] Local: Relaying discovery response to share handler. Proxy seq: #{pseq}, clove seq: #{cseq}")

    # Route the clove
    processor_name = state.config.registry_table.share_handler
    route_clove(processor_name, clove, aux_data)

    # Update the clove cache expiry timestamp
    State.update_clove_timestamp(state, cseq)
  end

  @doc """
  Handle a proxy request from a remote node.
  """
  @spec handle_proxy_request(map, {binary, integer}, Clove.t()) :: map
  def handle_proxy_request(state, source, %Clove{
        headers: {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: cseq}}
      } = clove) do
    # TODO remove debug print
    #Logger.info("[+] Local: Relaying via proxy request from #{inspect(source)}")
    prev_hop = state.clove_cache[cseq].prev_hop
    proxy_seq = Generator.generate_integer(8)

    aux_data = %{
      request_type: :proxy_request,
      clove_seq: cseq,
      proxy_seq: proxy_seq,
      relays: [source, prev_hop]
    }

    # Route the clove
    processor_name = state.config.registry_table.share_handler
    route_clove(processor_name, clove, aux_data)

    case Map.get(state.clove_cache, cseq) do
      %{clove: cached_clove} -> # Route cached clove
        route_clove(processor_name, cached_clove, aux_data)

      _ -> # No cached cloves
        :ok
    end

    # Update and return Router state
    state
    |> State.evict_clove(cseq)
    |> State.ban_clove(cseq)
  end

  # ---- Private functions ----
  # Deliver the clove to the appropriate processor
  @spec route_clove(atom, Clove.t(), map) :: :ok
  defp route_clove(processor_name, clove, aux_data) do
    # TODO remove debug print
    #Logger.info("[+] Local: Delivering to share handler")
    #IO.inspect(aux_data, label: "Local clove routing (#{processor_name})")
    Task.async(fn -> ShareHandler.deliver(clove, aux_data, processor_name) end)
    :ok
  end
end
