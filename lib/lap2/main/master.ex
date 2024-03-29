defmodule LAP2.Main.Master do
  @moduledoc """
  Module for sending/receiving data via the network.
  """

  use GenServer
  require Logger
  alias LAP2.Main.ProxyManager
  alias LAP2.Main.ConnectionSupervisor
  alias LAP2.Main.Helpers.HostBuffer
  alias LAP2.Networking.Resolver
  alias LAP2.Networking.Sockets.Lap2Socket

  @doc """
  Start the Master process.
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
    # Ensure that the ETS gets cleaned up on exit
    Process.flag(:trap_exit, true)
    # Initialise data handler state
    Logger.info("[i] Master (#{config.name}): Starting GenServer")

    state = %{
      query_cache: :ets.new(:query_cache, [:set]),
      dht_requests: [],
      services: %{},
      listeners: %{},
      return_map: %{},
      config: config
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_cast({:discover_proxy}, map) :: {:noreply, map}
  def handle_cast({:discover_proxy}, state) do
    ProxyManager.init_proxy(state.config.registry_table.proxy_manager)
    {:noreply, state}
  end

  @spec handle_call({:deliver, binary, String.t()}, any, map) ::
    {:reply, {:ok, atom | tuple} | {:error, atom}, map}
  def handle_call({:deliver, listener_id}, _from, state) do
    {:reply, get_listener(listener_id, state), state}
  end

  @spec handle_call({:register_dht_request, non_neg_integer}, any, map) ::
    {:reply, :ok, map}
  def handle_call({:register_dht_request, query_id}, _from, state) do
    new_state = Map.put(state, :dht_requests, [query_id | state.dht_requests])
    {:reply, :ok, new_state}
  end

  @spec handle_call({:verify_dht_response, non_neg_integer}, any, map) ::
    {:reply, boolean, map}
  def handle_call({:verify_dht_response, query_id}, _from, state) do
    cond do
      Enum.member?(state.dht_requests, query_id) ->
        new_state = Map.put(state, :dht_requests, List.delete(state.dht_requests, query_id))
        {:reply, true, new_state}
      true -> {:reply, false, state}
    end
  end

  @spec handle_call({:register_listener, String.t(), atom | tuple}, any, map) :: {:noreply, map}
  def handle_call({:register_listener, listener_id, listener}, _from, state) do
    #Logger.info("[+] Registering listener: #{inspect(listener)} for stream ID: #{inspect(listener_id)}")
    new_state = %{state | listeners: Map.put(state.listeners, listener_id, listener)}
    {:reply, :ok, new_state}
  end

  @spec handle_call({:get_listener_struct, String.t()}, any, map) ::
    {:reply, {:ok, atom | tuple} | {:error, atom}, map}
  def handle_call({:get_listener_struct, listener_id}, _from, state) when is_map_key(state.listeners, listener_id) do
    {:reply, Map.get(state.listeners, listener_id), state}
  end
  def handle_call({:get_listener_struct, _}, _from, state), do: {:reply, {:error, :missing_listener}, state}

  @spec handle_call({:deregister_listener, String.t()}, any, map) :: {:reply, :ok, map}
  def handle_call({:deregister_listener, listener_id}, _from, state) do
    #Logger.info("[+] Deregistering listener for stream ID: #{inspect(listener_id)}")
    new_state = %{state | listeners: Map.delete(state.listeners, listener_id)}
    {:reply, :ok, new_state}
  end

  @spec handle_call({:register_return, String.t(), String.t()}, any, map) :: {:reply, :ok, map}
  def handle_call({:register_return, query_id, service_id}, _from, state) do
    new_state = Map.put(state, :return_map, Map.put(state.return_map, query_id, service_id))
    {:reply, :ok, new_state}
  end

  @spec handle_call({:pop_return, String.t()}, any, map) :: {:reply, String.t() | :error, map}
  def handle_call({:pop_return, query_id}, _from, state) do
    case Map.get(state.return_map, query_id, :error) do
      :error -> {:reply, :error, state}
      service_id ->
        new_state = Map.put(state, :return_map, Map.delete(state.return_map, query_id))
        {:reply, service_id, new_state}
    end
  end

  @spec handle_call(:get_registry_table, any, map) :: {:reply, map, map}
  def handle_call(:get_registry_table, _from, state) do
    {:reply, state.config.registry_table, state}
  end

  @spec handle_call({:register_service, String.t(), String.t()}, any, map) :: {:reply, {:ok, String.t()} | {:error, atom}, map}
  def handle_call({:register_service, service_id, listener_id}, _from, state) do
    cond do
      not is_map_key(state.services, service_id) ->
        secret = crypto_gen(32)
        serv_construct = %{
          hash: :crypto.hash(:sha256, secret),
          listener_id: listener_id
        }
        new_serv = Map.put(state.services, service_id, serv_construct)
        new_state = Map.put(state, :services, new_serv)
        {:reply, {:ok, secret}, new_state}

      true ->
        {:reply, {:error, :exists}, state}
    end
  end

  # TODO DELETE THIS
  def handle_call(:debug, _from, state), do: {:reply, state, state}

  @spec handle_call({:service_lookup, String.t()}, any, map) :: {:reply, {:ok, binary} | {:error, atom}, map}
  def handle_call({:service_lookup, service_id}, _from, state) when is_map_key(state.services, service_id) do
    {:reply, {:ok, state.services[service_id].listener_id}, state}
  end
  def handle_call({:service_lookup, _service_id}, _from, state), do: {:reply, {:error, :not_found}, state}

  @spec handle_call({:deregister_service, String.t(), String.t()}, any, map) :: {:reply, :ok | :error, map}
  def handle_call({:deregister_service, service_id, secret}, _from, state) when is_map_key(state.services, service_id) do
    cond do
      valid_secret?(secret, state.services[service_id].hash) ->
        new_serv = Map.delete(state.services, service_id)
        new_state = Map.put(state, :services, new_serv)
        delete_ets_service(state.query_cache, service_id)
        {:reply, :ok, new_state}
      true ->
        Logger.error("[-] MASTER: Invalid secret key for service ID: #{inspect(service_id)}")
        {:reply, :error, state}
    end
  end
  def handle_call({:deregister_service, _service_id, _secret}, _from, state), do: {:reply, :error, state}

  @spec handle_call({:cache_query, Query.t(), map, String.t()}, any, map) :: {:reply, :ok | :error, map}
  def handle_call({:cache_query, query, routing_info, service_id}, _from, state) do
    cleaned_query = Map.put(query, :data, <<>>)
    cached_struct = %{
      query: cleaned_query,
      routing_info: routing_info
    }
    {:reply, cache_ets(state.query_cache, cached_struct, service_id), state}
  end

  @spec handle_call({:discard_query, String.t(), non_neg_integer, String.t()}, any, map) :: {:reply, :ok | :error, map}
  def handle_call({:discard_query, service_id, query_id, secret}, _from, state) when is_map_key(state.services, service_id) do
    cond do
      valid_secret?(secret, state.services[service_id].hash) ->
        delete_ets_query(state.query_cache, service_id, query_id)
        {:reply, :ok, state}
      true ->
        {:reply, :error, state}
    end
  end
  def handle_call({:discard_query, _service_id, _query_id, _secret}, _from, state), do: {:reply, :error, state}

  @spec handle_call({:pop_queries, String.t(), list(non_neg_integer), String.t()}, any, map) :: {:reply, {:ok, list(map)} | {:error, atom}, map}
  def handle_call({:pop_queries, service_id, query_ids, secret}, _from, state) when is_map_key(state.services, service_id) do
    cond do
      valid_secret?(secret, state.services[service_id].hash) ->
        response_list = Enum.map(query_ids, fn qid ->
          case pop_ets(state.query_cache, service_id, qid) do
            {:ok, qid} -> qid
            {:error, :not_found} -> nil
          end
        end)
        |> List.delete(nil)
        {:reply, {:ok, response_list}, state}
      true ->
        Logger.error("[-] MASTER: Invalid secret key for service ID: #{inspect(service_id)}")
        {:reply, {:error, :unauthorised}, state}
    end
  end
  def handle_call({:pop_queries, _service_id, _query_id, _secret}, _from, state), do: {:reply, {:error, :not_found}, state}

  # Cleanup the ETS table on exit
  @spec terminate(any, map) :: :ok
  def terminate(_reason, state) do
    :ets.delete(state.query_cache)
    :ok
  end

  # ---- Public Non-API functions ----
  @doc """
  Send a response to the appropriate listener socket.
  """
  @spec get_service_target(String.t(), atom) :: {:ok, atom | tuple} | {:error, atom}
  def get_service_target(listener_id, master_name) do
    Logger.info("[+] MASTER (#{master_name}): Delivering response to Listener ID: #{inspect(listener_id)}")
    GenServer.call({:global, master_name}, {:deliver, listener_id})
  end

  @spec get_listener_struct(String.t(), atom) :: {:ok, map} | {:error, atom}
  def get_listener_struct(listener_id, master_name) do
    GenServer.call({:global, master_name}, {:get_listener_struct, listener_id})
  end

  @doc """
  Add a query to the cache so it can be retrieved for a response.
  """
  @spec cache_query(Query.t(), map, String.t(), atom) :: :ok | :error
  def cache_query(query, routing_info, service_id, name) do
    GenServer.call({:global, name}, {:cache_query, query, routing_info, service_id})
  end

  @doc """
  Remember a query ID for a DHT request to verify the response
  """
  @spec register_dht_request(non_neg_integer, atom) :: :ok
  def register_dht_request(query_id, name) do
    GenServer.call({:global, name}, {:register_dht_request, query_id})
  end

  @doc """
  Verify if a query ID is valid for a DHT request
  """
  @spec valid_dht_request?(non_neg_integer, atom) :: boolean
  def valid_dht_request?(query_id, name) do
    GenServer.call({:global, name}, {:verify_dht_response, query_id})
  end

  # ---- Public API ----
  @doc """
  Register a listener with a unique stream ID.
  :stdout for STDOUT
  {:tcp, {ip, port}} for TCP
  {:native, funct, service_id} for a native listener function
  """
  @spec register_listener(atom | tuple, atom) :: {:ok, String.t()}
  def register_listener(listener, master_name) do
    listener_id = crypto_gen(16)
    GenServer.call({:global, master_name}, {:register_listener, listener_id, listener})
    {:ok, listener_id}
  end

  @doc """
  Deregister a listener with a given stream ID.
  """
  @spec deregister_listener(String.t(), atom) :: :ok
  def deregister_listener(listener_id, master_name) do
    GenServer.call({:global, master_name}, {:deregister_listener, listener_id})
  end

  @doc """
  Register a service with a given stream ID.
  This function returs a secret key needed to modify the registered service.
  """
  @spec register_service(String.t(), String.t(), atom) :: {:ok, String.t()} | {:error, atom}
  def register_service(service_id, listener_id, master_name) do
    GenServer.call({:global, master_name}, {:register_service, service_id, listener_id})
  end

  @doc """
  Lookup a service to get its associated stream ID.
  """
  @spec service_lookup(String.t(), atom) :: {:ok, String.t()} | {:error, atom}
  def service_lookup(service_id, master_name) do
    GenServer.call({:global, master_name}, {:service_lookup, service_id})
  end

  @doc """
  Attempt to deregister a service with a given stream ID and its associated secret key.
  """
  @spec deregister_service(String.t(), String.t(), atom) :: :ok | :error
  def deregister_service(service_id, secret, master_name) do
    GenServer.call({:global, master_name}, {:deregister_service, service_id, secret})
  end

  @spec register_return(non_neg_integer, String.t(), atom) :: :ok
  def register_return(query_id, listener_id, name) do
    GenServer.call({:global, name}, {:register_return, query_id, listener_id})
  end

  @spec pop_return(non_neg_integer, atom) :: String.t() | :error
  def pop_return(query_id, name) do
    GenServer.call({:global, name}, {:pop_return, query_id})
  end

  @doc """
  Delete a query from the cache.
  Used if a service does not wish to respond to a query.
  """
  @spec discard_query(String.t(), non_neg_integer, String.t(), atom) :: :ok | :error
  def discard_query(service_id, query_id, secret, name) do
    GenServer.call({:global, name}, {:discard_query, service_id, query_id, secret})
  end

  @doc """
  Respond to a query with a given query ID.
  """
  @spec respond(String.t(), list(non_neg_integer), String.t(), binary, atom) :: :ok | :error
  def respond(service_id, query_ids, secret, data, name) do
    registry_table = get_registry_table(name)
    case GenServer.call({:global, name}, {:pop_queries, service_id, query_ids, secret}) do
      {:ok, response_list} ->
        HostBuffer.disperse_response(response_list, data, registry_table)

      {:error, reason} ->
        Logger.error("[-] MASTER (#{name}) has encountered a error: #{inspect(reason)}")
        :error
    end
  end

  @doc """
  Initialise the proxy discovery process.
  """
  @spec discover_proxy(atom) :: :ok
  def discover_proxy(master_name) do
    GenServer.cast({:global, master_name}, {:discover_proxy})
  end

  @doc """
  Bootstrap the DHT table with a request to a known network node.
  """
  @spec bootstrap_dht({String.t(), non_neg_integer}, atom) :: :ok | :error
  def bootstrap_dht(bootstrap_addr, master_name) do
    query = Resolver.build_dht_query()
    register_dht_request(query.query_id, master_name)
    Lap2Socket.send_tcp(bootstrap_addr, query, get_registry_table(master_name))
  end

  @doc """
  Get the registry table for a given master name.
  """
  @spec setup_introduction_point(list(String.t()), atom) :: :ok | :error
  def setup_introduction_point(service_ids, name) do
    # TODO advertise service IDs via introduction points
    registry_table = get_registry_table(name)
    ConnectionSupervisor.request_introduction_point(service_ids, registry_table)
  end

  @spec request_remote(list({String.t(), non_neg_integer}), binary, String.t(), String.t(), atom) ::
    :ok | :error
  def request_remote(intro_points, data, service_id, listener_id, name) do
    HostBuffer.request_remote(intro_points, data, service_id, listener_id, get_registry_table(name))
  end

  @spec get_registry_table(atom) :: map
  def get_registry_table(name) do
    GenServer.call({:global, name}, :get_registry_table)
  end

  # ---- Private Functions ----
  @spec get_listener(binary, map) :: {:ok, any} | {:error, any}
  defp get_listener(listener_id, state) when is_map_key(state.listeners, listener_id) do
    {:ok, Map.get(state.listeners, listener_id)}
  end
  defp get_listener(_listener_id, _state), do: {:error, :no_listener}

  @spec crypto_gen(non_neg_integer) :: String.t()
  defp crypto_gen(bytes) do
    :crypto.strong_rand_bytes(bytes) |> Base.encode16(case: :lower)
  end

  @spec valid_secret?(binary, binary) :: boolean
  defp valid_secret?(secret, hash) do
    :crypto.hash(:sha256, secret) == hash
  end

  @spec cache_ets(:ets.tid(), %{query: Query.t(), routing_info: map}, String.t()) :: :ok | :error
  defp cache_ets(ets, cache_struct, service_id) do
    qid = cache_struct.query.query_id
    case :ets.lookup(ets, service_id) do
      [{_, %{^qid => _}}] -> # If query ID is cached, return an error
        :error

      [{_, cached}] ->
        new_cache = Map.put(cached, cache_struct.query.query_id, cache_struct)
        :ets.insert(ets, {service_id, new_cache})
        :ok

      [] ->
        cache = %{cache_struct.query.query_id => cache_struct}
        :ets.insert(ets, {service_id, cache})
        :ok
    end
  end

  @spec pop_ets(:ets.tid(), String.t(), non_neg_integer) :: {:ok, map} | {:error, atom}
  defp pop_ets(ets, service_id, query_id) do
    case :ets.lookup(ets, service_id) do
      [{_, query_map}] ->
        cond do
          is_map_key(query_map, query_id) ->
            query = Map.get(query_map, query_id)
            :ets.insert(ets, {service_id, Map.delete(query_map, query_id)})
            {:ok, query}

          true ->
            {:error, :not_found}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @spec delete_ets_query(:ets.tid(), String.t(), non_neg_integer) :: :ok
  defp delete_ets_query(ets, service_id, query_id) do
    case :ets.lookup(ets, service_id) do
      [{_, query_map}] ->
        :ets.insert(ets, {service_id, Map.delete(query_map, query_id)})
        :ok

      _ ->
        :ok
    end
  end

  @spec delete_ets_service(:ets.tid(), String.t()) :: :ok
  defp delete_ets_service(ets, service_id) do
    :ets.delete(ets, service_id)
    :ok
  end
end
