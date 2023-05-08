defmodule LAP2.Main.Master do
  @moduledoc """
  Module for sending/receiving data via the network.
  """

  use GenServer
  require Logger
  alias LAP2.Main.ConnectionSupervisor
  alias ExCrypto.Hash
  alias LAP2.Main.ProxyManager
  alias LAP2.Main.Helpers.HostBuffer

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
      services: %{},
      listeners: %{},
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

  @spec handle_cast({:deliver, binary, String.t()}, map) :: {:noreply, map}
  def handle_cast({:deliver, data, stream_id}, state) do
    case get_listener(stream_id, state) do
      {:ok, :stdout} -> IO.inspect(data, label: "[STDOUT]")
      {:ok, {:tcp, addr}} -> IO.inspect(data, label: "[TCP] #{inspect(addr)}") # TODO implement TCP listener
      {:error, _} -> Logger.error("No listener registered for stream ID #{stream_id}")
    end
    {:noreply, state}
  end

  # TODO specify listener type
  @spec handle_call({:register_listener, String.t(), atom | tuple}, any, map) :: {:noreply, map}
  def handle_call({:register_listener, stream_id, listener}, _from, state) do
    #Logger.info("[+] Registering listener: #{inspect(listener)} for stream ID: #{inspect(stream_id)}")
    new_state = %{state | listeners: Map.put(state.listeners, stream_id, listener)}
    {:reply, :ok, new_state}
  end

  # TODO specify listener type
  @spec handle_call({:deregister_listener, String.t()}, any, map) :: {:reply, :ok, map}
  def handle_call({:deregister_listener, stream_id}, _from, state) do
    #Logger.info("[+] Deregistering listener for stream ID: #{inspect(stream_id)}")
    new_state = %{state | listeners: Map.delete(state.listeners, stream_id)}
    {:reply, :ok, new_state}
  end

  @spec handle_call(:get_registry_table, any, map) :: {:reply, map, map}
  def handle_call(:get_registry_table, _from, state) do
    {:reply, state.config.registry_table, state}
  end

  @spec handle_call({:register_service, String.t(), String.t()}, any, map) :: {:reply, {:ok, String.t()} | {:error, atom}, map}
  def handle_call({:register_service, service_id, stream_id}, _from, state) do
    cond do
      not is_map_key(state.services, service_id) ->
        secret = crypto_gen(32)
        serv_construct = %{
          hash: Hash.sha256!(secret),
          stream_id: stream_id
        }
        new_serv = Map.put(state.services, service_id, serv_construct)
        new_state = Map.put(state, :services, new_serv)
        {:reply, {:ok, secret}, new_state}

      true ->
        {:reply, {:error, :exists}, state}
    end
  end

  @spec handle_call({:service_lookup, String.t()}, any, map) :: {:reply, {:ok, binary} | {:error, atom}, map}
  def handle_call({:service_lookup, service_id}, _from, state) when is_map_key(state.services, service_id) do
    {:reply, {:ok, state.services[service_id].stream_id}, state}
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
          pop_ets(state.query_cache, service_id, qid)
        end)
        {:reply, response_list, state}
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
  @spec deliver(binary, String.t(), atom) :: :ok
  def deliver(data, stream_id, master_name) do
    Logger.info("[+] MASTER (#{master_name}): Delivering response: #{inspect(data)} to stream ID: #{inspect(stream_id)}")
    GenServer.cast({:global, master_name}, {:deliver, data, stream_id})
    :ok
  end

  @doc """
  Deliver data to a service.
  """
  @spec deliver_to_service(binary, String.t(), atom) :: :ok | :error
  def deliver_to_service(data, service_id, master_name) do
    case service_lookup(service_id, master_name) do
      {:ok, stream_id} ->
        deliver(data, stream_id, master_name)

      {:error, _} ->
        Logger.error("[-] MASTER (#{master_name}): No service registered for service ID: #{inspect(service_id)}")
        :error
    end
  end

  @doc """
  Add a query to the cache so it can be retrieved for a response.
  """
  @spec cache_query(Query.t(), map, String.t(), atom) :: :ok | :error
  def cache_query(query, routing_info, service_id, name) do
    GenServer.call({:global, name}, {:cache_query, query, routing_info, service_id})
  end

  # ---- Public API ----
  @doc """
  Register a listener with a unique stream ID.
  :stdout for STDOUT
  {:tcp, {ip, port}} for TCP
  """
  @spec register_listener(atom | {atom, {String.t(), non_neg_integer}}, atom) :: {:ok, String.t()}
  def register_listener(listener, master_name) do
    stream_id = crypto_gen(16)
    GenServer.call({:global, master_name}, {:register_listener, stream_id, listener})
    {:ok, stream_id}
  end

  @doc """
  Deregister a listener with a given stream ID.
  """
  @spec deregister_listener(String.t(), atom) :: :ok
  def deregister_listener(stream_id, master_name) do
    GenServer.cast({:global, master_name}, {:deregister_listener, stream_id})
  end

  @doc """
  Register a service with a given stream ID.
  This function returs a secret key needed to modify the registered service.
  """
  @spec register_service(String.t(), String.t(), atom) :: {:ok, String.t()} | {:error, atom}
  def register_service(service_id, stream_id, master_name) do
    GenServer.call({:global, master_name}, {:register_service, service_id, stream_id})
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
  Get the registry table for a given master name.
  """
  @spec setup_introduction_point(list(String.t()), atom) :: :ok | :error
  def setup_introduction_point(service_ids, name) do
    # TODO advertise service IDs via introduction points
    registry_table = get_registry_table(name)
    ConnectionSupervisor.request_introduction_point(service_ids, registry_table)
  end

  @spec request_remote(list({String.t(), non_neg_integer}), binary, String.t(), atom) ::
    :ok | :error
  def request_remote(intro_points, data, service_id, name) do
    HostBuffer.request_remote(intro_points, data, service_id, get_registry_table(name))
  end

  # ---- Private Functions ----
  @spec get_listener(binary, map) :: {:ok, any} | {:error, any}
  defp get_listener(stream_id, state) when is_map_key(state.listeners, stream_id) do
    {:ok, Map.get(state.listeners, stream_id)}
  end
  defp get_listener(_stream_id, _state), do: {:error, :no_listener}

  @spec crypto_gen(non_neg_integer) :: String.t()
  defp crypto_gen(bytes) do
    :crypto.strong_rand_bytes(bytes) |> Base.encode16(case: :lower)
  end

  @spec valid_secret?(binary, binary) :: boolean
  defp valid_secret?(secret, hash) do
    Hash.sha256!(secret) == hash
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

  @spec get_registry_table(atom) :: map
  defp get_registry_table(name) do
    GenServer.call({:global, name}, :get_registry_table)
  end
end
