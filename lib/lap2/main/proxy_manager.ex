defmodule LAP2.Main.ProxyManager do
  @moduledoc """
  Module for handling ProxyManager requests.
  """

  use GenServer
  require Logger
  alias LAP2.Utils.EtsHelper
  alias LAP2.Main.Helpers.ProxyHelper
  alias LAP2.Utils.ProtoBuf.CloveHelper

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
      temp_registry: %{},
      request_ets: :ets.new(:request_mapper, [:set, :protected]),
      config: config
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_call(:get_state, any, map) :: {:reply, map, map}
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @spec handle_cast({:init_proxy, binary}, map) :: {:noreply, map}
  def handle_cast({:init_proxy, stream_id}, state) do
    clove_seq = CloveHelper.gen_seq_num()
    case ProxyHelper.init_proxy_request(state.config.registry_table, clove_seq, state.config.clove_casts) do
      :ok ->
        new_state = Map.put(state, :temp_registry, Map.put(state.temp_registry, clove_seq, stream_id))
        {:noreply, new_state}
      :error -> {:noreply, state}
    end
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
      {:ok, updated_state} ->
        case register_stream(updated_state, aux_data.proxy_seq, aux_data.clove_seq) do
          {:ok, new_state} -> {:noreply, new_state}
          {:error, reason} ->
            Logger.error("[!] Proxy Manager (#{state.config.name}): Failed to register stream: #{inspect(reason)}")
            {:noreply, state}
        end
      {:error, _} -> {:noreply, state}
    end
  end

  @spec handle_cast({:remove_proxy, non_neg_integer}, map) :: {:noreply, map}
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

  # TODO debug
  @spec debug(atom) :: map
  def debug(name) do
    GenServer.call({:global, name}, :get_state)
  end

  @doc """
  Handle a discovery response.
  """
  @spec handle_discovery_response(Request.t(), map, atom) :: :ok
  def handle_discovery_response(request, aux_data, proxy_name) do
    GenServer.cast({:global, proxy_name}, {:discovery_response, request, aux_data})
  end

  @doc """
  Add a proxy to the pool.
  """
  @spec add_proxy(atom, non_neg_integer, pid) :: :ok
  def add_proxy(proxy_name, proxy_seq, proxy_pid) do
    GenServer.call({:global, proxy_name}, {:add_proxy, proxy_seq, proxy_pid})
  end

  @doc """
  Initialise the proxy discovery process.
  """
  @spec init_proxy(binary, atom) :: :ok
  def init_proxy(stream_id, proxy_name) do
    GenServer.cast({:global, proxy_name}, {:init_proxy, stream_id})
  end

  @doc """
  Handle a regular proxy request/response.
  """
  @spec handle_regular_proxy(Request.t(), non_neg_integer, atom) :: :ok | :error
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
      when request.request_type == "regular_proxy_request" do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Processing regular proxy request")
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_proxy_query(
      request,
      state.request_ets,
      pseq,
      state.config.registry_table.crypto_manager
    )
    :ok
  end
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
      when request.request_type == "regular_proxy_response" do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Processing regular proxy response")
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
    Logger.info("[i] Proxy Manager (#{proxy_name}): Processing final key exchange request")
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_fin_key_exhange(request, pseq, state)
  end
  def handle_regular_proxy(%Request{crypto: {:key_rot, _}} = request, pseq, proxy_name) do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Processing key rotation request")
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_key_rotation(request, pseq, state)
    :ok
  end
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, pseq, proxy_name)
      when request.request_type == "ack_key_rotation" do
    Logger.info("[i] Proxy Manager (#{proxy_name}): Received key rotation acknowledgement")
    state = GenServer.call({:global, proxy_name}, :get_state)
    ProxyHelper.handle_key_rotation_ack(request, pseq, state)
    :ok
  end
  def handle_regular_proxy(%Request{crypto: {:sym_key, _}} = request, _, proxy_name)
      when request.request_type == "ack_fin_ke" do
    # TODO it seems to work but might need to be checked
    Logger.info("[i] Proxy Manager (#{proxy_name}): Received key exchange acknowledgement")
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
    Logger.info("[i] Proxy Manager (#{proxy_name}): Removing proxy #{proxy_seq}")
    GenServer.cast({:global, proxy_name}, {:remove_proxy, proxy_seq})
  end

  # ---- Private Functions ----
  @spec register_stream(map, non_neg_integer, non_neg_integer) :: {:ok, map} | {:error, atom}
  defp register_stream(state, proxy_seq, clove_seq) do
    # Remove stream_id from temp_registry and register it in request_ets
    case Map.get(state.temp_registry, clove_seq) do
      nil -> {:error, :missing_stream}
      stream_id ->
        Logger.info("[i] Proxy Manager #{state.config.registry_table.proxy_manager}: Registering stream #{stream_id}")
        EtsHelper.insert_value(state.request_ets, proxy_seq, stream_id)
        {:ok, Map.put(state, :temp_registry, Map.delete(state.temp_registry, clove_seq))}
    end
  end
end
