defmodule LAP2.Networking.Sockets.TcpServer do
  # Wrapper around basic TCP socket

  use GenServer
  require Logger
  alias LAP2.Networking.Sockets.Lap2Socket

  # ---- GenServer callbacks ----
  @doc """
  Start the TCP server.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, config.name})
  end

  @spec init(map) :: {:ok, map} | {:stop, atom}
  def init(config) do
    # Open TCP socket
    Logger.info("[i] TCP (#{inspect config.name}): Starting TCP server")

    state = %{
      port: config[:tcp_port] || 9999,
      connections: %{},
      registry_table: config[:registry_table],
      tcp_sock: nil
    }

    case :gen_tcp.listen(config[:tcp_port], [:binary, active: false, reuseaddr: true]) do
      {:ok, listener} ->
        Task.async(fn -> accept_connections(listener, config.name); end)
        {:ok, %{state | tcp_sock: listener}}

      {:error, e} ->
        Logger.error("Error opening TCP socket: #{inspect(e)}")
        {:stop, :tcp_open_error}
    end
  end

  def handle_call({:cache_conn, conn_id, socket}, _from, state) do
    {:reply, :ok, %{state | connections: Map.put(state.connections, conn_id, socket)}}
  end

  def handle_call({:pop_conn, conn_id}, _from, state) do
    socket = Map.get(state.connections, conn_id)
    new_state =  Map.put(state, :connections, Map.delete(state.connections, conn_id))
    {:reply, socket, new_state}
  end

  @doc """
  Terminate the TCP server.
  """
  @spec terminate(any, map) :: :ok
  def terminate(reason, %{tcp_sock: nil}) do
    Logger.error("TCP socket terminated unexpectedly. Reason: #{inspect(reason)}")
  end

  def terminate(_reason, %{tcp_sock: tcp_sock}) do
    #Logger.info("[i] TCP: Stopping TCP server")
    :gen_tcp.close(tcp_sock)
  end

  defp accept_connections(listener, name) do
    Logger.info("Accepting connections")
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        # Loop to handle incoming messages
        Task.async(fn -> handle_conn(socket, name); end)

        # Recurse to accept new connections
        accept_connections(listener, name)

      {:error, :closed} ->
        Logger.info("Listener closed")
    end
  end

  @spec handle_conn(any, atom) :: :ok | :error
  defp handle_conn(socket, name) do
    Logger.info("Handling connection")
    case :gen_tcp.recv(socket, 0, 10_000) do
      {:ok, msg} ->
        Logger.info("Received message: #{inspect msg}")
        conn_id = cache_conn(socket, name)
        spawn_worker(conn_id, msg, name)

      {:error, _} ->
        Logger.info("Connection closed")
        :error
    end
  end

  @spec handle_round_trip(String.t(), non_neg_integer, binary, atom) :: :ok | :error
  defp handle_round_trip(addr, port, data, _name) do
    addr
    |> String.to_charlist()
    |> :inet.parse_address()
    |> case do
      {:ok, ip_tuple} ->
        case :gen_tcp.connect(ip_tuple, port, [:binary, active: false, reuseaddr: true]) do
          {:ok, socket} ->
            Logger.info("Sending message")
            :gen_tcp.send(socket, data)
            {:ok, msg} = :gen_tcp.recv(socket, 0, 10_000)
            IO.inspect(msg, label: "Received message")
            :gen_tcp.close(socket)

          {:error, e} ->
            Logger.error("Error opening TCP socket: #{inspect(e)}")
            :error
        end

      {:error, _} ->
        Logger.error("Error parsing IP address")
        :error
    end
  end
  # ---- Public functions ----
  @spec send({String.t(), non_neg_integer}, binary, atom) :: :ok
  def send({addr, port}, data, name) do
    Logger.info("Sending message")
    Task.async(fn -> handle_round_trip(addr, port, data, name); end)
    :ok
  end

  @spec respond(String.t(), binary, atom) :: :ok | {:error, atom}
  def respond(conn_id, data, name) do
    Logger.info("Responding to message")
    socket = pop_conn(conn_id, name)
    :gen_tcp.send(socket, data)
  end

  # ---- Private functions ----
  @spec spawn_worker(String.t(), binary, atom) :: :ok | :error
  defp spawn_worker(conn_id, msg, router) do
    Task.async(fn ->
      Logger.debug("Starting task to parse TCP segment")
      Lap2Socket.parse_segment(conn_id, msg, router)
    end)
    :ok
  end

  @spec cache_conn(any, atom) :: String.t()
  defp cache_conn(socket, name) do
    Logger.info("Caching connection")
    conn_id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    IO.inspect(conn_id, label: "Connection ID")
    GenServer.call({:global, name}, {:cache_conn, conn_id, socket})
    conn_id
  end

  @spec pop_conn(String.t(), atom) :: any
  defp pop_conn(conn_id, name) do
    GenServer.call({:global, name}, {:pop_conn, conn_id})
  end
end
