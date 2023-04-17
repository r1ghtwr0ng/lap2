defmodule LAP2.Main.Proxy do
  @moduledoc """
  Module for handling Proxy requests.
  """
  use GenServer
  require Logger
  alias LAP2.Main.Helpers.ProxyHelper

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
      request_ets: :ets.new(:request_mapper, [:set, :protected]),
      config: config
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  # Cleanup the ETS table on exit
  @spec handle_call(:get_state, map) :: {:reply, map, map}
  def handle_call(:get_state, state), do: {:reply, state, state}

  @spec handle_cast({:proxy_request, Request.t, map}, map) :: {:noreply, map}
  def handle_cast({:proxy_request, request, aux_data}, state) do
    proxy_limit = state.config.proxy_limit
    case Enum.count(state.proxy_pool) < proxy_limit do
      true -> new_state = ProxyHelper.accept_proxy_request(request, aux_data, state)
        {:noreply, new_state}
      false -> {:noreply, state}
    end
  end

  @spec handle_cast({:discovery_response, Request.t, map}, map) :: {:noreply, map}
  def handle_cast({:discovery_response, request, aux_data}, state) do
    case ProxyHelper.handle_discovery_response(request, aux_data, state) do
      {:ok, new_state} -> {:noreply, new_state}
      {:error, _} -> {:noreply, state}
    end
  end

  def handle_cast({:remove_proxy, proxy_seq}, state) do
    new_state = ProxyHelper.remove_proxy(state, proxy_seq)
    {:noreply, new_state}
  end

  @spec terminate(any, map) :: :ok
  def terminate(_reason, _state) do
    :ok
  end

  # ---- Public Functions ----
  @doc """
  Handle a proxy request.
  """
  @spec handle_proxy_request(Request.t, map, atom) :: :ok
  def handle_proxy_request(request, aux_data, proxy_name) do
    GenServer.cast({:global, proxy_name}, {:proxy_request, request, aux_data})
  end

  @doc """
  Handle a discovery response.
  """
  @spec handle_discovery_response(Request.t, map, atom) :: :ok
  def handle_discovery_response(request, aux_data, proxy_name) do
    GenServer.cast({:global, proxy_name}, {:discovery_response, request, aux_data})
  end

  @doc """
  Handle a regular proxy request/response.
  """
  @spec handle_regular_proxy(Request.t, map, atom) :: :ok | :error
  def handle_regular_proxy(request, %{proxy_seq: pseq}, proxy_name)
    when request.request_type == "regular_proxy_request" do
    ProxyHelper.handle_proxy_request(request, pseq, proxy_name)
  end
  def handle_regular_proxy(%Request{request_id: rid, request_type: rtype, data: data}, _aux_data, proxy_name)
    when rtype == "regular_proxy_response" do
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_proxy_response(rid, data, state.request_ets, state.config.registry_table.crypto_manager)
  end
  def handle_regular_proxy(request, _aux_data, proxy_name) when request.request_type == "fin_key_exchange" do
    # TODO handle the proxy seq in aux_data argument
    _state = GenServer.call({:global, proxy_name}, :get_state)
    # TODO implement this
    :ok
  end
  def handle_regular_proxy(request, _, _) do
    Logger.error("Invalid request type: #{request.request_type}")
  end

  @doc """
  Remove a proxy from the pool.
  """
  @spec remove_proxy(non_neg_integer, atom) :: :ok
  def remove_proxy(proxy_seq, proxy_name) do
    GenServer.cast({:global, proxy_name}, {:remove_proxy, proxy_seq})
  end
end
