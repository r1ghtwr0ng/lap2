defmodule LAP2.Main.Helpers.ProxyHelper do
  @moduledoc """
  Contains helper functions for processing common proxy requests and responses
  """

  require Logger
  alias LAP2.Main.Master
  alias LAP2.Utils.EtsHelper
  alias LAP2.Crypto.CryptoManager
  alias LAP2.Main.Helpers.SendPipelines

  @doc """
  Accept a proxy request.
  Respond with an acknowledgement.
  Add the relays to the proxy pool and return updated Proxy GenServer state.
  """
  @spec accept_proxy_request(Request.t(), map, map) :: map
  def accept_proxy_request(request, %{proxy_seq: pseq, clove_seq: cseq, relays: relays}, state) do
    Logger.info("[i] Accepting proxy request")
    new_pool = add_relays(state.proxy_pool, pseq, relays)
    case CryptoManager.gen_response(request, pseq, state.config.registry_table.crypto_manager) do
      {:ok, response} -> # Successfully updated crypto state and generated response
        SendPipelines.ack_proxy_request(response, pseq, cseq, new_pool) # TODO update send pipeline to set cseq on response
        Map.put(state, :proxy_pool, new_pool)
      {:error, reason} -> # Failed to update crypto state or generate response
        Logger.error("Error occured while responding to proxy: #{pseq}, Request type: PROXY_REQUEST")
        Logger.error("Error: #{reason}")
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
          proxy_seq: pseq,
          clove_seq: cseq,
          relay: source,
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
        new_relay = add_relays(state.proxy_pool, pseq, [source])
        case CryptoManager.gen_finalise_exchange(request, pseq, cseq, state.config.registry_table.crypto_manager) do
          {:ok, enc_response} ->
            SendPipelines.fin_key_exchange(enc_response, pseq, new_relay)
            {:ok, Map.put(state, :proxy_pool, new_relay)}
          err ->
          Logger.error("Error occured while responding to proxy: #{pseq}, Request type: FIN_KEY_REQUEST")
          err
        end
    end
  end

  @doc """
  Finalise the key exchange.
  """
  @spec handle_fin_key_exhange(Request.t(), non_neg_integer, map) :: :ok | :error
  def handle_fin_key_exhange(request, pseq, state) do
    Logger.info("[i] Handling key exchange finalisation")
    #new_pool = remove_proxy(state.proxy_pool, pseq)
    crypt_name = state.config.registry_table.crypto_manager
    case CryptoManager.recv_finalise_exchange(request, pseq, crypt_name) do
      {:ok, response} ->
        SendPipelines.ack_key_exchange(response, pseq, state.new_pool)
        #Map.put(state, :proxy_pool, new_pool) This doesn't make sense but maybe I'm missing something
        :ok
      _ ->
        Logger.error("Error occured while responding to proxy: #{pseq}, Request type: FIN_KEY_REQUEST")
        :error
    end
  end

  @doc """
  Handle a key rotation request.
  """
  @spec handle_key_rotation(Request.t(), non_neg_integer, atom) :: :ok | :error
  def handle_key_rotation(request, proxy_seq, crypto_manager) do
    Logger.info("[i] Handling key rotation request")
    case CryptoManager.rotate_keys(request, proxy_seq, crypto_manager) do
      {:ok, response} ->
        SendPipelines.ack_key_rotation(response, proxy_seq)
        :ok
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
  def remove_proxy(state, pseq) do
    Map.put(state, :proxy_pool, Map.delete(state.proxy_pool, pseq))
  end

  # Add a proxy to the proxy pool
  @spec add_relays(map, non_neg_integer, list) :: map
  defp add_relays(proxy_pool, _proxy_id, []), do: proxy_pool

  defp add_relays(proxy_pool, proxy_id, [proxy | tail]) when is_map_key(proxy_pool, proxy_id) do
    new_state =
      cond do
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
