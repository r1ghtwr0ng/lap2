defmodule LAP2.Networking.Helpers.OutboundPipelines do
  @moduledoc """
  Contains outbound pipelines for dispersing and sending requests and responses.
  """

  require Logger
  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Utils.ProtoBuf.RequestHelper
  alias LAP2.Networking.Helpers.RelaySelector

  @doc """
  Disperse and cast out proxy discovery requests.
  """
  @spec send_proxy_discovery(EncryptedRequest.t(), list, non_neg_integer()) :: :ok
  def send_proxy_discovery(enc_request, random_neighbors, clove_limit \\ 20) do
    Logger.info("[i] Sending proxy discovery")
    clove_seq = CloveHelper.gen_seq_num()

    case RequestHelper.serialise(enc_request) do
      {:ok, data} ->
        RelaySelector.cast_proxy_discovery(data, clove_seq, random_neighbors, clove_limit)

      _ ->
        Logger.error("Failed to serialise EncryptedRequest: OutboundPipeleines.send_proxy_discovery/2")
        :error
    end
  end

  @doc """
  Disperse and send out a proxy request acknowledgement.
  """
  @spec send_proxy_accept(EncryptedRequest.t(), non_neg_integer, non_neg_integer, list) :: :ok | :error
  def send_proxy_accept(enc_request, proxy_seq, clove_seq, relay_pool) do
    Logger.info("[i] Sending proxy response")

    case RequestHelper.serialise(enc_request) do
      {:ok, data} ->
        RelaySelector.disperse_and_send(data, proxy_seq, clove_seq, relay_pool)

      _ ->
        Logger.error("Failed to serialise EncryptedRequest: OutboundPipeleines.send_proxy_accept/4")
        :error
    end
  end

  @doc """
  Send out data to a proxy via anonymous routes.
  """
  @spec send_regular_response(EncryptedRequest.t(), non_neg_integer, list) :: :ok
  def send_regular_response(enc_request, proxy_seq, relay_pool) do
    Logger.info("[i] Sending response")
    clove_seq = CloveHelper.gen_seq_num()

    case RequestHelper.serialise(enc_request) do
      {:ok, data} ->
        RelaySelector.disperse_and_send(data, proxy_seq, clove_seq, relay_pool)

      _ ->
        Logger.error("Failed to serialise EncryptedRequest: OutboundPipelines.fin_key_exchange/3")
        :error
    end
  end
end
