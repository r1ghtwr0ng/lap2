defmodule LAP2.Main.Helpers.ProxyHelper do
  @moduledoc """
  Contains helper functions for processing common proxy requests and responses
  """

  require Logger
  alias LAP2.Utils.EtsHelper

  # TODO
  def accept_proxy_request(request, aux_data, state) do
    Logger.info("[i] Accepting proxy request")
  end

  # Wowsers, I just made a mess in my trousers
  # This is going to be a pain, many of the requests are application-specific
  # I think I'll expose an interface for this so devs can add their own
  def handle_request(request, aux_data, proxy_name) do
    Logger.info("[i] Handling proxy request")
  end

  def handle_response(rid, data, ets, master_name) do
    case EtsHelper.get_value(ets, rid) do
      {:ok, stream_id} ->
        Master.deliver_response(data, stream_id, master_name)
      {:error, :not_found} ->
        Logger.error("No stream ID for request ID: #{rid}")
        :error
    end
  end
end
