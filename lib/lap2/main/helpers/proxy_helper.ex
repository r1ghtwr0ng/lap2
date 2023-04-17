defmodule LAP2.Main.Helpers.ProxyHelper do
  @moduledoc """
  Contains helper functions for processing common proxy requests and responses
  """

  require Logger
  alias LAP2.Utils.EtsHelper
  alias LAP2.Main.Helpers.SendPipelines

  @doc """
  Accept a proxy request.
  Respond with an acknowledgement.
  Add the relays to the proxy pool and return updated Proxy GenServer state.
  """
  @spec accept_proxy_request(Request.t, map, map) :: map
  def accept_proxy_request(request, %{proxy_seq: pseq, relays: relays}, state) do
    Logger.info("[i] Accepting proxy request")
    new_pool = add_relays(state.proxy_pool, pseq, relays)
    SendPipelines.ack_proxy_request(request, pseq, new_pool)
    Map.put(state, :proxy_pool, new_pool)
  end

  @doc """
  Validate the length of the anonymous path.
  """
  @spec handle_discovery_response(Request.t, map, map) :: {:ok, map} | {:error, atom}
  def handle_discovery_response(request, %{
    proxy_seq: pseq,
    relay: source,
    hop_count: hops
    }, state) do
    Logger.info("[i] Handling discovery response")
    cond do
      hops < state.config.max_hops and hops > state.config.min_hops ->
        Logger.warn("[!] Proxy response hop count not within bounds")
        {:error, :hop_count}
      true ->
        new_relay = add_relays(state.proxy_pool, pseq, [source])
        SendPipelines.fin_key_exchange(request, pseq, new_relay)
        {:ok, Map.put(state, :proxy_pool, new_relay)}
    end
  end

  # This is going to be a pain, many of the requests are application-specific
  # I think I'll expose an interface for this so devs can add their own
  @spec handle_proxy_request(Request.t, map, atom) :: :ok
  def handle_proxy_request(_request, _aux_data, _proxy_name) do
    # TODO send to application interface for handling
    Logger.info("[i] Handling proxy request")
  end

  @spec handle_proxy_response(non_neg_integer, binary, :ets.tid, atom) :: :ok | :error
  def handle_proxy_response(rid, _data, ets, _master_name) do
    case EtsHelper.get_value(ets, rid) do
      {:ok, _stream_id} ->
        #Master.deliver_response(data, stream_id, master_name)
        :ok
      {:error, :not_found} ->
        Logger.error("No stream ID for request ID: #{rid}")
        :error
    end
  end

  # ---- State Helpers ----
  @spec remove_proxy(map, map) :: map
  def remove_proxy(state, %{proxy_seq: proxy_id}) do
    Map.put(state, :proxy_pool, Map.delete(state.proxy_pool, proxy_id))
  end

  # Add a proxy to the proxy pool
  @spec add_relays(map, non_neg_integer, list) :: map
  defp add_relays(proxy_pool, _proxy_id, []), do: proxy_pool
  defp add_relays(proxy_pool, proxy_id, [proxy | tail]) when is_map_key(proxy_pool, proxy_id) do
    new_state = cond do
      Enum.member?(proxy_pool[proxy_id], proxy) ->
        Logger.warn("[!] Proxy already in pool: #{inspect(proxy)}")
        proxy_pool
      true ->
        Map.put(proxy_pool, proxy_id, [proxy | proxy_pool[proxy_id]])
    end
    add_relays(new_state, proxy_id, tail)
  end
  defp add_relays(proxy_pool, proxy_id, [proxy | tail]) do
    new_state = Map.put(proxy_pool, proxy_id, [proxy])
    add_relays(new_state, proxy_id, tail)
  end
end
