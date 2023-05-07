defmodule LAP2.Main.ConnectionSupervisor do
  @moduledoc """
  Module for supervising the status of various network connections.
  Dispatches proxy requests via the ProxyManager.
  Encodes/decodes and routes data above the proxy abstraction layer.
  Receives commands directly from the Master module, interfaces with ProxyManager and IntroductionPoint modules.
  Relays are abstracted away by the ProxyManager, this module handles connections bound to proxy sequences.
  """

  use GenServer
  require Logger
  alias LAP2.Main.ProxyManager
  alias LAP2.Main.ServiceProviders
  alias LAP2.Main.Helpers.ListenerHandler
  alias LAP2.Utils.ProtoBuf.QueryHelper

  @doc """
  Start the ConnectionSupervisor process.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, config.name})
  end

  # TODO introduce a heartbeat mechanism to check if the proxy is still alive
  # TODO call ProxyManager.deregister_stream/2 once all the requests have been received/timeout
  def init(config) do
    # Initialise data handler state
    Logger.info("[i] Connection Supervisor (#{config.name}): Starting GenServer")

    state = %{
      connections: %{},
      service_providers: %{},
      config: config
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_call({:register_conn, non_neg_integer, atom}, any, map) :: {:reply, :ok, map}
  def handle_call({:register_conn, proxy_seq, conn_type}, _from, state) do
    # TODO implement heartbeat and timeout mechanisms to remove dead connections
    # This function is also used to change the connection type for established proxies
    status = %{
      type: conn_type,
      last_seen: :os.system_time(:millisecond)
    }
    new_conn = Map.put(state.connections, proxy_seq, status)
    new_state = Map.put(state, :connections, new_conn)
    {:reply, :ok, new_state}
  end

  @spec handle_call({:deregister_conn, non_neg_integer}, any, map) :: {:reply, :ok, map}
  def handle_call({:deregister_conn, proxy_seq}, _from, state) do
    new_conn = Map.delete(state.connections, proxy_seq)
    new_state = Map.put(state, :connections, new_conn)
    |> Map.put(:service_providers, Map.filter(state.service_providers, fn {_, sp} -> sp != proxy_seq; end))
    {:reply, :ok, new_state}
  end

  @spec handle_call({:register_sp, non_neg_integer, list(binary)}, any, map) ::
    {:reply, :ok | :error, map}
  def handle_call({:register_sp, proxy_seq, service_ids}, _from, state) do
    # Verify all service_ids for change belong to the proxy_seq
    cond do
      allow_registry?(proxy_seq, service_ids, state) ->
        # At least one service_id does not belong to the proxy_seq
        Logger.error("[!] Proxy (#{proxy_seq}) attempted to modify a service_id that does not belong to it")
        {:reply, :error, state}

      true ->
        # Add the service_ids to the proxy_seq
        updated_sps = Enum.reduce(service_ids, state.service_providers, fn sid, acc ->
          Map.put(acc, sid, proxy_seq)
        end)
        new_state = Map.put(state, :service_providers, updated_sps)
        {:reply, :ok, new_state}
    end
  end

  @spec handle_call({:get_connections, non_neg_integer, atom}, any, map) ::
    {:reply, {:ok, list(non_neg_integer)} | {:error, :insufficient_conns}, map}
  def handle_call({:get_connections, conns, conn_type}, _from, state) do
    # Fetch conns number of connections of type conn_type
    filtered = Map.filter(state.connections, fn {_, conn} -> conn.type == conn_type end)
    cond do
      map_size(filtered) >= conns ->
        conn_list = Enum.take_random(Map.keys(filtered), conns)
        {:reply, {:ok, conn_list}, state}

      map_size(filtered) < conns ->
        # Return an error
        {:reply, :error, state}
    end
  end

  # ---- Public API ----
  @doc """
  Attempt to establish a new anonymous proxy.
  """
  @spec establish_proxy(binary, map) :: :ok | :error
  def establish_proxy(stream_id, registry_table) do
    proxy_mgr = registry_table.proxy_manager
    ProxyManager.init_proxy(stream_id, proxy_mgr)
  end

  @doc """
  Removes a proxy connection from the ProxyManager and ConnectionSupervisor.
  """
  @spec remove_proxy(non_neg_integer, map) :: :ok | :error
  def remove_proxy(proxy_seq, registry_table) do
    proxy_mgr = registry_table.proxy_manager
    conn_sup = registry_table.conn_supervisor
    ProxyManager.remove_proxy(proxy_seq, proxy_mgr)
    GenServer.call({:global, conn_sup}, {:deregister_conn, proxy_seq})
  end

  @doc """
  Send a list of outbound queries via random connections.
  """
  @spec send_queries(list(Query.t()), binary, map) :: :ok | :error
  def send_queries(queries, stream_id, registry_table) do
    # TODO called from Master, calls ProxyManager.send_query/2
    conns = length(queries)
    conn_sup = registry_table.conn_supervisor
    proxy_mgr = registry_table.proxy_manager
    conn_type = :anon_proxy
    case get_conns(conns, conn_type, conn_sup) do
      {:ok, conn_list} ->
        Enum.zip(queries, conn_list)
        |> Enum.each(fn {query, pseq} ->
          case QueryHelper.serialise(query) do
            {:ok, data} ->
              ProxyManager.send_request(data, stream_id, pseq, proxy_mgr)
            {:error, reason} ->
              Logger.error("[!] Connection Supervisor (#{registry_table.conn_supervisor}) send_queries error: #{reason}")
            end
        end)

      {:error, reason} ->
        Logger.error("[!] Connection Supervisor (#{registry_table.conn_supervisor}) send_queries error: #{reason}")
        :error
    end
  end

  @doc """
  Send an introduction point request to an existing connection.
  A list of service identifiers are passed in the request.
  """
  @spec request_introduction_point(map) :: :ok | :error
  def request_introduction_point(registry_table) do
    # Select a connection and attempt to upgrade it to an introduction point
    conn_sup = registry_table.conn_supervisor
    get_conns(1, :anon_proxy, conn_sup)
  end

  @doc """
  Send an teardown request to an existing introduction point.
  Delete all associated state.
  """
  @spec teardown_introduction_point(non_neg_integer, map) :: :ok | :error
  def teardown_introduction_point(proxy_seq, registry_table) do
    # TODO called from Master, calls ProxyManager
    # TODO send teardown request to proxy_seq, then delete the data
    remove_proxy(proxy_seq, registry_table)
  end

  @doc """
  Modify an existing connection to an introduction point.
  """
  @spec modify_connection(non_neg_integer, atom, list(binary), map) :: :ok | :error
  def modify_connection(proxy_seq, :intro_point, service_ids, registry_table) do
    # Attempt to register the services, then modify proxy status if allowed
    conn_sup = registry_table.conn_supervisor
    case register_services(proxy_seq, service_ids, conn_sup) do
      :ok -> register_conn(proxy_seq, :intro_point, conn_sup)

      :error -> :error
    end
  end

  @doc """
  Deliver a response to the appropriate listener using their stream_id
  """
  @spec deliver_response(binary, binary, map) :: :ok | :error
  def deliver_response(data, stream_id, registry_table) do
    # TODO decode data, call ListenerHandler
    master_name = registry_table.master
    case QueryHelper.deserialise(data) do
      {:ok, query} ->
        ListenerHandler.deliver(stream_id, query, master_name)
        :ok
      {:error, reason} ->
        Logger.error("[!] Connection Supervisor (#{registry_table.conn_supervisor}): Error decoding response: #{reason}")
        :error
    end
  end

  @doc """
  Deserialise and deliver a Query to the appropriate route
  """
  @spec deliver_request(binary, non_neg_integer, map) :: :ok | :error
  def deliver_request(data, proxy_seq, registry_table) do
    # TODO decode data, call ListenerHandler
    case QueryHelper.deserialise(data) do
      {:ok, query} ->
        ServiceProviders.route(query, proxy_seq, registry_table)
        :ok
      {:error, reason} ->
        Logger.error("[!] Connection Supervisor (#{registry_table.conn_supervisor}): Error decoding response: #{reason}")
        :error
    end
  end

  @doc """
  Proxy establishment successful, notify listener using stream_id
  """
  @spec proxy_established(binary, non_neg_integer, map) :: :ok | :error
  def proxy_established(stream_id, proxy_seq, registry_table) do
    conn_sup = registry_table.conn_supervisor
    master_name = registry_table.master
    register_conn(:anon_proxy, proxy_seq, conn_sup)
    notification = "[DEBUG] Anonymous proxy established"
    ListenerHandler.notify(stream_id, notification, master_name)
  end

  @doc """
  Key rotation successful, notify listener using stream_id
  """
  @spec successful_key_rotation(binary, non_neg_integer, map) :: :ok | :error
  def successful_key_rotation(stream_id, proxy_seq, registry_table) do
    master_name = registry_table.master
    notification = "[DEBUG] Key rotation for proxy: #{proxy_seq} was successful"
    ListenerHandler.notify(stream_id, notification, master_name)
  end

  # ---- Private Functions ----
  # Wrapper for getting a random list of connections (proxy sequences)
  @spec get_conns(non_neg_integer, atom, atom) ::
    {:ok, list(non_neg_integer)} | {:error, :insufficient_conns}
  defp get_conns(conns, conn_type, name) do
    GenServer.call({:global, name}, {:get_connections, conns, conn_type})
  end

  # Wrapper for registering a new connection
  @spec register_conn(atom, non_neg_integer, atom) :: :ok
  defp register_conn(conn_type, proxy_seq, name) do
    GenServer.call({:global, name}, {:register_conn, proxy_seq, conn_type})
  end

  # Wrapper for registering services in introduction points
  @spec register_services(non_neg_integer, list(binary), atom) :: :ok | :error
  defp register_services(proxy_seq, service_ids, name) do
    GenServer.call({:global, name}, {:register_sp, proxy_seq, service_ids})
  end

  # Verify if a provider's request can be registered
  @spec allow_registry?(non_neg_integer, list(binary), map) :: boolean
  defp allow_registry?(proxy_seq, service_ids, state) do
    valid_req = Enum.any?(service_ids, fn sid ->
      Map.get(state.service_providers, sid, proxy_seq) != proxy_seq
    end)
    within_limit = Map.get(state.connections, proxy_seq, %{type: nil}).type == :intro_point or
    Map.value(state.service_providers) |> Enum.uniq() |> Enum.size() < state.config.provider_limit
    valid_req and within_limit
  end
end