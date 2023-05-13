defmodule LAP2.Main.ProxyManager do
  @moduledoc """
  Module for handling ProxyManager requests.
  """

  use GenServer
  require Logger
  alias LAP2.Utils.Generator
  alias LAP2.Utils.ProtoBuf.RequestHelper
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
    Logger.info("[i] Proxy Manager (#{config.name}): Starting GenServer")

    state = %{
      proxy_pool: %{},
      config: config
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_call(:get_state, any, map) :: {:reply, map, map}
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  # TODO implement wrapper
  @spec handle_call({:send_to_proxy, binary, non_neg_integer}, any, map) :: {:reply, atom, map}
  def handle_call({:send_to_proxy, data, proxy_seq}, _from, state) do
    # Build request struct
    request_id = Generator.generate_integer(8)
    crypto_hdr = RequestHelper.build_symmetric_crypto()
    request = RequestHelper.build_request(crypto_hdr, data, "regular_proxy_request", request_id)
    relay_pool = Map.get(state.proxy_pool, proxy_seq, [])
    resp = ProxyHelper.send_to_proxy(request, proxy_seq, relay_pool, state.config.registry_table)
    {:reply, resp, state}
  end

  @spec handle_call({:respond_to_proxy, binary, non_neg_integer, non_neg_integer}, any, map) :: {:reply, atom, map}
  def handle_call({:respond_to_proxy, data, request_id, proxy_seq}, _from, state) do
    # Build request struct
    crypto_hdr = RequestHelper.build_symmetric_crypto()
    request = RequestHelper.build_request(crypto_hdr, data, "regular_proxy_response", request_id)
    relay_pool = Map.get(state.proxy_pool, proxy_seq, [])
    status = ProxyHelper.send_to_proxy(request, proxy_seq, relay_pool, state.config.registry_table)
    {:reply, status, state}
  end

  @spec handle_call({:init_proxy}, any, map) :: {:reply, atom, map}
  def handle_call({:init_proxy}, _from, state) do
    clove_seq = Generator.generate_integer(8)
    resp = ProxyHelper.init_proxy_request(state.config.registry_table, clove_seq, state.config.clove_casts)
    {:reply, resp, state}
  end

  @spec handle_call({:remove_proxy, non_neg_integer}, map) :: {:reply, atom, map}
  def handle_call({:remove_proxy, proxy_seq}, state) do
    new_state = ProxyHelper.remove_proxy(state, proxy_seq)
    {:reply, :ok, new_state}
  end

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

  @spec handle_cast({:discovery_response, Request.t(), map}, map) :: {:noreply, map}
  def handle_cast({:discovery_response, request, aux_data}, state) do
    case ProxyHelper.handle_discovery_response(request, aux_data, state) do
      {:ok, new_state} -> {:noreply, new_state}
      {:error, _} -> {:noreply, state}
    end
  end

  # ---- Public API Functions ----
  # TODO debug only
  @spec debug(atom) :: map
  def debug(name), do: GenServer.call({:global, name}, :get_state)

  @doc """
  Send a query to a specific proxy.
  """
  @spec send_request(binary, non_neg_integer, atom) :: :ok | :error
  def send_request(data, proxy_seq, name) do
    GenServer.call({:global, name}, {:send_to_proxy, data, proxy_seq})
  end

  @doc """
  Send a response to a specific proxy.
  """
  @spec send_response(binary, non_neg_integer, atom) :: :ok | :error
  def send_response(data, proxy_seq, name) do
    request_id = Generator.generate_integer(8)
    GenServer.call({:global, name}, {:respond_to_proxy, data, request_id, proxy_seq})
  end

  @doc """
  Initialise the proxy discovery process.
  """
  @spec init_proxy(atom) :: :ok
  def init_proxy(proxy_name) do
    GenServer.call({:global, proxy_name}, {:init_proxy})
  end

  @doc """
  Remove a proxy from the pool.
  """
  @spec remove_proxy(non_neg_integer, atom) :: :ok
  def remove_proxy(proxy_seq, proxy_name) do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Removing proxy #{proxy_seq}")
    GenServer.call({:global, proxy_name}, {:remove_proxy, proxy_seq})
  end

  # ---- Handler Functions ----
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
  # Handle regular proxy request
  @spec handle_regular_proxy(Request.t(), non_neg_integer, atom) :: :ok | :error
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
      when request.request_type == "regular_proxy_request" or request.request_type == "regular_proxy_response" do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Processing regular proxy request")
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_proxy_query(
      request,
      pseq,
      state.config.registry_table
    )
    :ok
  end
  # Handle final key exchange request
  def handle_regular_proxy(%Request{crypto: {:fin_ke, _}} = request, pseq, proxy_name) do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Processing final key exchange request")
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_fin_key_exhange(request, pseq, state)
  end
  # Handle key exchange acknowledgement
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
    when request.request_type == "ack_fin_ke" do
    # TODO it seems to work but might need to be checked
    Logger.info("[i] Proxy Manager (#{proxy_name}): Received key exchange acknowledgement")
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_key_exchange_ack(pseq, state.config.registry_table)
  end
  # Handle key rotation request
  def handle_regular_proxy(%Request{crypto: {:key_rot, _}} = request, pseq, proxy_name) do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Processing key rotation request")
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_key_rotation(request, pseq, state)
  end
  # Handle acknowledgement of key rotation
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
      when request.request_type == "ack_key_rotation" do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Received key rotation acknowledgement")
    state = GenServer.call({:global, proxy_name}, :get_state)
    conn_supervisor = state.config.registry_table.conn_supervisor
    ProxyHelper.handle_key_rotation_ack(pseq, conn_supervisor)
  end
  # Match all other requests
  def handle_regular_proxy(request, _, _) do
    Logger.error("Invalid request type: #{request.request_type}")
    :error
  end
end
