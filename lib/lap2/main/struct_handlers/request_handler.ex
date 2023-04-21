defmodule LAP2.Main.StructHandlers.RequestHandler do
  @moduledoc """
  Module for handling reconstructed requests from the Share Handler.
  Route to Proxy or Master module.
  """
  require Logger
  alias LAP2.Main.Proxy
  alias LAP2.Utils.ProtoBuf.RequestHelper

  @doc """
  Handle a request from the Share Handler.
  """
  @spec handle_request(binary, map, map) :: {:ok, %{atom() => atom()}} | {:error, any}
  def handle_request(enc_request_bin, %{request_type: :proxy_request} = aux_data, registry_table) do
    Logger.info("[i] Handling proxy request")
    # Deserialise the request
    case RequestHelper.deserialise_and_unwrap(enc_request_bin) do
      {:ok, request} -> Proxy.handle_proxy_request(request, aux_data, registry_table.proxy)
      err -> err
    end
  end

  def handle_request(enc_request_bin, %{request_type: :discovery_response} = aux_data, registry_table) do
    Logger.info("[i] Handling discovery response")
    # Deserialise the request
    case RequestHelper.deserialise_and_unwrap(enc_request_bin) do
      {:ok, request} -> Proxy.handle_discovery_response(request, aux_data, registry_table.proxy)
      err -> err
    end
  end

  def handle_request(enc_request_bin,
        %{request_type: :regular_proxy, proxy_seq: pseq},
        %{proxy: proxy, crypto_manager: crypt_mgr}
      ) do
    Logger.info("[i] Handling regular proxy request")
    # Deserialise the request
    case RequestHelper.deserialise_and_unwrap(enc_request_bin, pseq, crypt_mgr) do
      {:ok, request} -> Proxy.handle_regular_proxy(request, pseq, proxy)
      err -> err
    end
  end
end
