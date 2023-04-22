defmodule LAP2.Main.Helpers.SendPipelines do
  @moduledoc """
  Contains pipelines for creating, serialising, encrypting
  and sending requests and responses.
  """

  require Logger
  # alias LAP2.Utils.ProtoBuf.RequestHelper

  @doc """
  Create and send a proxy discovery packet.
  """
  @spec send_proxy_discovery(EncryptedRequest.t(), map, map) :: :ok
  def send_proxy_discovery(_request, _aux_data, _registry_table) do
    # TODO
    Logger.info("[i] Sending proxy discovery")
  end

  @doc """
  Build and send a proxy accept acknowledgement.
  """
  @spec ack_proxy_request(EncryptedRequest.t(), non_neg_integer, non_neg_integer, map) :: :ok
  def ack_proxy_request(_request, _proxy_seq, _clove_seq, _proxy_pool) do
    # TODO
    Logger.info("[i] Acking proxy request")
  end

  @doc """
  Finish the key exchange process.
  """
  @spec fin_key_exchange(EncryptedRequest.t(), non_neg_integer, map) :: :ok
  def fin_key_exchange(_request, proxy_seq, proxy_pool) do
    cond do
      length(proxy_pool[proxy_seq]) < 2 ->
        Logger.info("[i] Not enough proxies to finish key exchange")
        :ok

      true ->
        Logger.info("[i] Finishing key exchange")
        # TODO finish key exchange
        :ok
    end
  end

  @doc """
  Acknowledge the key exchange process.
  """
  @spec ack_key_exchange(EncryptedRequest.t(), non_neg_integer, map) :: :ok
  def ack_key_exchange(_request, _proxy_seq, _proxy_pool) do
    # TODO
    Logger.info("[i] Acking key exchange")
  end

  @doc """
  Acknowledge the key rotation process.
  """
  @spec ack_key_rotation(EncryptedRequest.t(), non_neg_integer) :: :ok
  def ack_key_rotation(_response, _proxy_seq) do
    # TODO
    Logger.info("[i] Acking key rotation")
  end

  @doc """
  Send a regular proxy request.
  """
  @spec send_regular_proxy(EncryptedRequest.t(), non_neg_integer, map, atom) :: :ok
  def send_regular_proxy(_request, _proxy_seq, _proxy_pool, :rotate_key) do
    # TODO
    Logger.info("[i] Sending regular proxy (key rotation)")
  end

  def send_regular_proxy(_request, _proxy_seq, _proxy_pool, :same_key) do
    # TODO
    Logger.info("[i] Sending regular proxy (same key)")
  end
end
