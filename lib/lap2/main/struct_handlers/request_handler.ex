defmodule LAP2.Main.StructHandlers.RequestHandler do
  @moduledoc """
  Module for handling reconstructed requests from the Share Handler.
  Route to Proxy or Master module.
  """
  require Logger
  alias LAP2.Main.ProxyManager
  alias LAP2.Utils.ProtoBuf.RequestHelper

  @doc """
  Handle a request from the Share Handler.
  """
  @spec handle_request(binary, map, map) :: {:ok, %{atom() => atom()}} | {:error, any}
  def handle_request(enc_request_bin, %{request_type: :proxy_request} = aux_data, registry_table) do
    # Deserialise the request
    case RequestHelper.deserialise_and_unwrap(enc_request_bin) do
      {:ok, request} ->
        Logger.info("RequestHandler (#{registry_table.main_supervisor}): Handling proxy request")
        ProxyManager.handle_proxy_request(request, aux_data, registry_table.proxy_manager)
      err -> err
    end
  end

  def handle_request(enc_request_bin, %{request_type: :discovery_response} = aux_data, registry_table) do
    # Deserialise the request
    case RequestHelper.deserialise_and_unwrap(enc_request_bin) do
      {:ok, request} ->
        Logger.info("RequestHandler (#{registry_table.main_supervisor}): Handling discovery response")
        ProxyManager.handle_discovery_response(request, aux_data, registry_table.proxy_manager)
      err -> err
    end
  end

  def handle_request(enc_request_bin,
        %{request_type: :regular_proxy, proxy_seq: pseq},
        registry_table
      ) do
    # Deserialise the request
    case RequestHelper.deserialise_and_unwrap(enc_request_bin, pseq, registry_table.crypto_manager) do
      {:ok, request} ->
        Logger.info("RequestHandler (#{registry_table.main_supervisor}): Handling regular proxy request")
        ProxyManager.handle_regular_proxy(request, pseq, registry_table.proxy_manager)
      err -> err
    end
  end
end
