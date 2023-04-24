defmodule LAP2.Main.Helpers.ProxyHelper do
  @moduledoc """
  Contains helper functions for processing common proxy requests and responses
  """

  require Logger
  alias LAP2.Main.Master
  alias LAP2.Utils.EtsHelper
  alias LAP2.Utils.ProtoBuf.RequestHelper
  alias LAP2.Networking.Router
  alias LAP2.Networking.Helpers.OutboundPipelines

  @doc """
  Accept a proxy request.
  Respond with an acknowledgement.
  Add the relays to the proxy pool and return updated Proxy GenServer state.
  """
  @spec accept_proxy_request(Request.t(), %{
    proxy_seq: non_neg_integer,
    clove_seq: non_neg_integer,
    relays: list}, map) :: map
  def accept_proxy_request(request, %{proxy_seq: proxy_seq, clove_seq: clove_seq, relays: relays}, state) do
    Logger.info("[i] Accepting proxy request: #{proxy_seq}")
    router_name = state.config.registry_table.router
    new_pool = add_relays(state.proxy_pool, proxy_seq, relays, router_name)
    crypto_mgr = state.config.registry_table.crypto_manager
    case RequestHelper.gen_response(request, proxy_seq, crypto_mgr) do
      {:ok, enc_response} -> # Successfully updated crypto state and generated response
        relay_pool = Map.get(new_pool, proxy_seq, [])
        router_name = state.config.registry_table.router
        case OutboundPipelines.send_proxy_accept(enc_response, proxy_seq, clove_seq, relay_pool, router_name) do
          :ok ->
            Map.put(state, :proxy_pool, new_pool)

          :error -> state
        end
      {:error, reason} -> # Failed to update crypto state or generate response
        Logger.error("Error: #{reason} occured while responding to proxy: #{proxy_seq}, Request type: PROXY_REQUEST")
        state
    end
  end

  @doc """
  Validate the length of the anonymous path.
  """
  @spec handle_discovery_response(Request.t(), map, map) :: {:ok, map} | {:error, atom}
  def handle_discovery_response(
        request,
        %{
          proxy_seq: proxy_seq,
          clove_seq: clove_seq,
          relays: relays,
          hop_count: hops
        },
        state
      ) do
    Logger.info("[i] Handling discovery response")

    cond do
      hops < state.config.max_hops and hops > state.config.min_hops ->
        Logger.warn("[!] Proxy response hop count not within bounds")
        {:error, :hop_count}

      true ->
        router_name = state.config.registry_table.router
        new_pool = add_relays(state.proxy_pool, proxy_seq, relays, router_name)
        relay_pool = Map.get(new_pool, proxy_seq, [])
        router_name = state.config.registry_table.router
        case RequestHelper.gen_finalise_exchange(request, proxy_seq, clove_seq, state.config.registry_table.crypto_manager) do
          {:ok, enc_response} ->
            OutboundPipelines.send_regular_response(enc_response, proxy_seq, relay_pool, router_name)
            {:ok, Map.put(state, :proxy_pool, new_pool)}

          {:error, reason} ->
            Logger.error("Error: #{reason} occured while responding to proxy: #{proxy_seq}, Request type: DISCOVERY_RESPONSE")
            {:error, reason}
        end
    end
  end

  @doc """
  Finalise the key exchange.
  """
  @spec handle_fin_key_exhange(any, any, any) :: :ok | :error
  def handle_fin_key_exhange(request, proxy_seq, state) do
    Logger.info("[i] Handling key exchange finalisation")
    crypt_name = state.config.registry_table.crypto_manager
    case RequestHelper.recv_finalise_exchange(request, proxy_seq, crypt_name) do
      {:ok, response} ->
        relay_pool = Map.get(state.proxy_pool, proxy_seq, [])
        router_name = state.config.registry_table.router
        OutboundPipelines.send_regular_response(response, proxy_seq, relay_pool, router_name)

      {:error, reason} ->
        Logger.error("Error: #{reason} occured while responding to proxy: #{proxy_seq}, Request type: FIN_KEY_REQUEST")
        :error
    end
  end

  @doc """
  Handle a key rotation request.
  """
  @spec handle_key_rotation(Request.t(), non_neg_integer, map) :: :ok | :error
  def handle_key_rotation(request, proxy_seq, state) do
    Logger.info("[i] Handling key rotation request")
    crypt_name = state.config.registry_table.crypto_manager
    case RequestHelper.rotate_keys(request, proxy_seq, crypt_name) do
      {:ok, response} ->
        relay_pool = Map.get(state.proxy_pool, proxy_seq, [])
        router_name = state.config.registry_table.router
        OutboundPipelines.send_regular_response(response, proxy_seq, relay_pool, router_name)

      _ ->
        Logger.error("Error occured while responding to proxy: #{proxy_seq}, Request type: KEY_ROTATION")
        :error
    end
  end

  @doc """
  Handle a key rotation acknowledgement.
  """
  @spec handle_key_rotation_ack(Request.t(), non_neg_integer, atom) :: :ok | :error
  def handle_key_rotation_ack(_request, _proxy_seq, _crypto_manager) do
    # TODO not yet sure what to do, probably stop the retransmission timer (if it exists)
    # Potentially send to CryptoManager to update the keys (if it hasn't already)
    :ok
  end

  # TODO expose a TCP socket interface for this so devs can add their own
  @doc """
  Route proxy query to the correct application listener via the Master module.
  """
  @spec handle_proxy_query(Request.t(), :ets.tid(), non_neg_integer, atom) :: :ok | :error
  def handle_proxy_query(%Request{request_id: rid, data: data}, ets, _pseq, master_name) do
    Logger.info("[i] Handling proxy query")
    case EtsHelper.get_value(ets, rid) do
      {:ok, stream_id} ->
        Master.deliver_query(data, stream_id, master_name)
        :ok

      {:error, :not_found} ->
        Logger.error("No stream ID for request ID: #{rid}")
        :error
    end
  end

  @doc """
  Route proxy response to the correct listener via the Master module.
  """
  @spec handle_proxy_response(Request.t(), :ets.tid(), non_neg_integer, atom) :: :ok | :error
  def handle_proxy_response(%Request{request_id: rid, data: data}, ets, _pseq, master_name) do
    case EtsHelper.get_value(ets, rid) do
      {:ok, stream_id} ->
        Master.deliver_response(data, stream_id, master_name)
        :ok

      {:error, :not_found} ->
        Logger.error("No stream ID for request ID: #{rid}")
        :error
    end
  end

  # TODO responve typings and returns at CryptoManager (also CryptoManager calls in this module)

  # ---- State Helpers ----
  @spec remove_proxy(map, non_neg_integer) :: map
  def remove_proxy(state, proxy_seq) do
    Map.put(state, :proxy_pool, Map.delete(state.proxy_pool, proxy_seq))
  end

  # Add a proxy to the proxy pool
  @spec add_relays(map, non_neg_integer, list({String.t(), non_neg_integer}), atom) :: map
  defp add_relays(proxy_pool, _proxy_seq, [], _router_name), do: proxy_pool
  defp add_relays(proxy_pool, proxy_seq, relays, router_name) when is_map_key(proxy_pool, proxy_seq) do
    IO.inspect(relays, label: "The following relays will be added to the proxy pool:")
    Router.add_proxy_relays(proxy_seq, relays, router_name)
    Enum.reduce(relays, proxy_pool, fn relay, acc ->
      cond do
        Enum.member?(acc[proxy_seq], relay) ->
          Logger.warn("[!] Relay already in pool: #{inspect(relay)}")
          acc

        true ->
          Map.put(acc, proxy_seq, [relay | acc[proxy_seq]])
      end
    end)
  end
  defp add_relays(proxy_pool, proxy_seq, relays, router_name) do
    Router.add_proxy_relays(proxy_seq, relays, router_name)
    Map.put(proxy_pool, proxy_seq, relays)
  end
end
