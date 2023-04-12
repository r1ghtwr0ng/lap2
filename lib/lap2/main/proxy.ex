defmodule LAP2.Main.Proxy do
  @moduledoc """
  Module for handling Proxy requests.
  """
  use GenServer
  require Logger
  alias LAP2.Main.Master

  @doc """
  Start the Proxy process.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, config.name})
  end

  @doc """
  Initialise the data handler GenServer.
  """
  @spec init(map) :: {:ok, map}
  def init(config) do
    # Initialise data handler state
    IO.puts("[i] ShareHandler: Starting GenServer")

    state = %{
      proxy_pool: %{},

      config: config
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----

  # Cleanup the ETS table on exit
  @spec terminate(any, map) :: :ok
  def terminate(_reason, _state) do
    :ok
  end

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
  @spec handle_regular_proxy(Request) :: {:noreply, map}
  def handle_regular_proxy(request) when request.request_type == "regular_proxy_request" do
    # TODO: Handle regular proxy
    IO.inspect(request)
  end
  def handle_regular_proxy(request) when request.request_type == "regular_proxy_response" do
    Master.deliver_response(request)
  end
  def handle_regular_proxy(request) do
    Logger.error("Invalid request type: #{request.request_type}")
  end
end
