defmodule LAP2.Main.Proxy do
  @moduledoc """
  Module for handling Proxy requests.
  """

  @doc """
  Handle a proxy request.
  """
  @spec handle_proxy_request(Request, map) :: {:noreply, map}
  def handle_proxy_request(request, aux_data) do
    # TODO: Handle proxy request
    IO.inspect(request)
    IO.inspect(aux_data)
  end

  @doc """
  Handle a discovery response.
  """
  @spec handle_discovery_response(Request, map) :: {:noreply, map}
  def handle_discovery_response(request, aux_data) do
    # TODO: Handle discovery response
    IO.inspect(request)
    IO.inspect(aux_data)
  end

  @doc """
  Handle a regular proxy request.
  """
  @spec handle_regular_proxy(Request, map) :: {:noreply, map}
  def handle_regular_proxy(request, aux_data) do
    # TODO: Handle regular proxy
    IO.inspect(request)
    IO.inspect(aux_data)
  end
end
