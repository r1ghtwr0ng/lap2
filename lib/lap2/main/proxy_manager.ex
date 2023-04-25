defmodule LAP2.Main.ProxyManager do
  @moduledoc """
  Module for handling ProxyManager requests.
  """
  use GenServer
  require Logger
  alias LAP2.Main.Helpers.ProxyHelper

  @doc """
  Start the ProxyManager process.
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
    #Logger.info("[i] Proxy (#{config.name}): Starting GenServer")

    state = %{
      proxy_pool: %{},
      request_ets: :ets.new(:request_mapper, [:set, :protected]),
      config: config
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  # Cleanup the ETS table on exit
  @spec handle_call(:get_state, any, map) :: {:reply, map, map}
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @spec handle_cast({:proxy_request, Request.t(), %{
    proxy_seq: non_neg_integer,
    clove_seq: non_neg_integer,
    relays: list}}, map) :: {:noreply, map}
  def handle_cast({:proxy_request, request, aux_data}, state) do
    proxy_limit = state.config.proxy_limit

    cond do
      Enum.count(state.proxy_pool) < proxy_limit ->
        new_state = ProxyHelper.accept_proxy_request(request, aux_data, state)
        {:noreply, new_state}

      true ->
        {:noreply, state}
    end
  end

  # TODO below

  @spec handle_cast({:discovery_response, Request.t(), map}, map) :: {:noreply, map}
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

  # Cleanup the ETS table on exit
  @spec terminate(any, map) :: :ok
  def terminate(_reason, state) do
    :ets.delete(state.request_ets)
    :ok
  end

  # ---- Public Functions ----
  @doc """
  Handle a proxy request.
  """
  @spec handle_proxy_request(Request.t(), map, atom) :: :ok
  def handle_proxy_request(request, aux_data, proxy_name) do
    GenServer.cast({:global, proxy_name}, {:proxy_request, request, aux_data})
  end

  @doc """
  Handle a discovery response.
  """
  @spec handle_discovery_response(Request.t(), map, atom) :: :ok
  def handle_discovery_response(request, aux_data, proxy_name) do
    GenServer.cast({:global, proxy_name}, {:discovery_response, request, aux_data})
  end

  @doc """
  Handle a regular proxy request/response.
  """
  @spec handle_regular_proxy(Request.t(), non_neg_integer, atom) :: :ok | :error
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
      when request.request_type == "regular_proxy_request" do
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_proxy_query(request, state.request_ets, pseq, state.config.registry_table.crypto_manager)
    :ok
  end
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
      when request.request_type == "regular_proxy_response" do
    state = GenServer.call({:global, proxy_name}, :get_state)

    ProxyHelper.handle_proxy_response(
      request,
      state.request_ets,
      pseq,
      state.config.registry_table.crypto_manager
    )
    :ok
  end
  def handle_regular_proxy(%Request{crypto: {:fin_ke, _}} = request, pseq, proxy_name) do
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_fin_key_exhange(request, pseq, state)
  end
  def handle_regular_proxy(%Request{crypto: {:key_rot, _}} = request, pseq, proxy_name) do
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_key_rotation(request, pseq, state)
    :ok
  end
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
      when request.request_type == "ack_key_rotation" do
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_key_rotation_ack(request, pseq, state)
    :ok
  end
  def handle_regular_proxy(request, _, _) do
    Logger.error("Invalid request type: #{request.request_type}")
    :error
  end

  @doc """
  Remove a proxy from the pool.
  """
  @spec remove_proxy(non_neg_integer, atom) :: :ok
  def remove_proxy(proxy_seq, proxy_name) do
    GenServer.cast({:global, proxy_name}, {:remove_proxy, proxy_seq})
  end
end
