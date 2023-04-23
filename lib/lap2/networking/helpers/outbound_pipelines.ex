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
  def send_proxy_discovery(enc_request, random_neighbors, clove_limit \\ 20, router_name \\ :router) do
    Logger.info("[i] OutboundPipelines: Sending proxy discovery")
    clove_seq = CloveHelper.gen_seq_num()

    case RequestHelper.serialise(enc_request) do
      {:ok, data} ->
        RelaySelector.cast_proxy_discovery(data, clove_seq, random_neighbors, clove_limit, router_name)

      _ ->
        Logger.error("Failed to serialise EncryptedRequest: OutboundPipeleines.send_proxy_discovery/2")
        :error
    end
  end

  @doc """
  Disperse and send out a proxy request acknowledgement.
  """
  @spec send_proxy_accept(EncryptedRequest.t(), non_neg_integer, non_neg_integer, list, atom) :: :ok | :error
  def send_proxy_accept(enc_request, proxy_seq, clove_seq, relay_pool, router_name \\ :router) do
    Logger.info("[i] OutboundPipelines: Sending proxy response")

    case RequestHelper.serialise(enc_request) do
      {:ok, data} ->
        response_header = %{proxy_seq: proxy_seq, clove_seq: clove_seq, hop_count: 0}
        RelaySelector.disperse_and_send(data, response_header, relay_pool, router_name)

      _ ->
        Logger.error("Failed to serialise EncryptedRequest: OutboundPipeleines.send_proxy_accept/4")
        :error
    end
  end

  @doc """
  Send out data to a proxy via anonymous routes.
  """
  @spec send_regular_response(EncryptedRequest.t(), non_neg_integer, list, atom) :: :ok
  def send_regular_response(enc_request, proxy_seq, relay_pool, router_name) do
    Logger.info("[i] OutboundPipelines: Sending regular response")

    case RequestHelper.serialise(enc_request) do
      {:ok, data} ->
        regular_header = %{proxy_seq: proxy_seq}
        RelaySelector.disperse_and_send(data, regular_header, relay_pool, router_name)

      _ ->
        Logger.error("Failed to serialise EncryptedRequest: OutboundPipelines.fin_key_exchange/3")
        :error
    end
  end
end
