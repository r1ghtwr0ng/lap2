defmodule LAP2.Main.Master do
  @moduledoc """
  Module for sending/receiving data via the network.
  """
  alias LAP2.Main.ProxyManager
  use GenServer
  require Logger

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
    # Initialise data handler state
    Logger.info("[i] Master (#{config.name}): Starting GenServer")

    state = %{
      listeners: %{},
      config: config
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_call({:discover_proxy, binary}, any, map) :: {:reply, :ok, map}
  def handle_call({:discover_proxy, stream_id}, _from, state) do
    ProxyManager.init_proxy(stream_id, state.config.registry_table.proxy_manager)
    {:reply, :ok, state}
  end

  @spec handle_cast({:deliver_query, binary, binary}, any, map) :: {:noreply, map}
  def handle_cast({:deliver_query, data, stream_id}, _from, state) do
    case get_listener(stream_id, state) do
      {:ok, :stdout} -> IO.inspect(data, label: "[STDOUT]")
      {:ok, {:tcp, addr}} -> IO.inspect(data, label: "[TCP] #{inspect(addr)}") # TODO implement TCP listener
      {:error, _} -> Logger.error("No listener registered for stream ID #{stream_id}")
    end
    {:noreply, state}
  end

  @spec handle_cast({:deliver_response, binary, binary}, any, map) :: {:noreply, map}
  def handle_cast({:deliver_response, data, stream_id}, _from, state) do
    case get_listener(stream_id, state) do
      {:ok, :stdout} -> IO.inspect(data, label: "[STDOUT]")
      {:ok, {:tcp, addr}} -> IO.inspect(data, label: "[TCP] #{inspect(addr)}") # TODO implement TCP listener
      {:error, _} -> Logger.error("No listener registered for stream ID #{stream_id}")
    end

    {:noreply, state}
  end

  # TODO specify listener type
  @spec handle_cast({:register_listener, binary, any}, any, map) :: {:noreply, map}
  def handle_cast({:register_listener, stream_id, listener}, _from, state) do
    #Logger.info("[+] Registering listener: #{inspect(listener)} for stream ID: #{inspect(stream_id)}")
    new_state = %{state | listeners: Map.put(state.listeners, stream_id, listener)}
    {:noreply, new_state}
  end

  # TODO specify listener type
  @spec handle_cast({:deregister_listener, binary}, any, map) :: {:noreply, map}
  def handle_cast({:deregister_listener, stream_id}, _from, state) do
    #Logger.info("[+] Deregistering listener for stream ID: #{inspect(stream_id)}")
    new_state = %{state | listeners: Map.delete(state.listeners, stream_id)}
    {:noreply, new_state}
  end

  @doc """
  Send a response to the appropriate listener socket.
  """
  @spec deliver_response(binary, binary, atom) :: :ok
  def deliver_response(data, stream_id, master_name \\ :master) do
    Logger.info("[+] MASTER (#{master_name}): Delivering response: #{inspect(data)} to stream ID: #{inspect(stream_id)}")
    GenServer.cast({:global, master_name}, {:deliver_response, data, stream_id})
    :ok
  end

  @doc """
  Send a query to the appropriate listener socket.
  """
  @spec deliver_query(binary, binary, atom) :: :ok
  def deliver_query(data, stream_id, master_name \\ :master) do
    Logger.info("[+] MASTER (#{master_name}): Delivering query: #{inspect(data)} to stream ID: #{inspect(stream_id)}")
    GenServer.cast({:global, master_name}, {:deliver_query, data, stream_id})
    :ok
  end

  @doc """
  Register a listener with a unique stream ID.
  """
  # TODO specify listener type
  @spec register_listener(binary, atom | {atom, {String.t(), non_neg_integer}}, atom) :: :ok
  def register_listener(stream_id, listener, master_name \\ :master) do
    GenServer.call({:global, master_name}, {:register_listener, stream_id, listener})
  end

  # ---- Public API ----
  @doc """
  Register a TCP listener with a randomly generated stream ID.
  """
  @spec register_tcp_listener({String.t(), non_neg_integer}, atom) :: {:ok, binary}
  def register_tcp_listener(address, master_name \\ :master) do
    stream_id = gen_stream_id()
    listener = {:tcp, address}
    register_listener(stream_id, listener, master_name)
    {:ok, stream_id}
  end

  @doc """
  Register STDOUT as a listener with a randomly generated stream ID.
  """
  @spec register_stdout_listener(atom) :: {:ok, binary}
  def register_stdout_listener(master_name \\ :master) do
    stream_id = gen_stream_id()
    register_listener(stream_id, :stdout, master_name)
    {:ok, stream_id}
  end

  @doc """
  Deregister a listener with a given stream ID.
  """
  @spec deregister_listener(binary, atom) :: :ok
  def deregister_listener(stream_id, master_name \\ :master) do
    GenServer.call({:global, master_name}, {:deregister_listener, stream_id})
  end

  @doc """
  Initialise the proxy discovery process
  """
  @spec discover_proxy(binary, atom) :: :ok
  def discover_proxy(stream_id, master_name \\ :master) do
    GenServer.call({:global, master_name}, {:discover_proxy, stream_id})
  end

  # ---- Private Functions ----
  @spec get_listener(binary, map) :: {:ok, any} | {:error, any}
  defp get_listener(stream_id, state) when is_map_key(state.listeners, stream_id) do
    {:ok, Map.get(state.listeners, stream_id)}
  end

  defp get_listener(_stream_id, _state), do: {:error, :no_listener}

  defp gen_stream_id() do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
