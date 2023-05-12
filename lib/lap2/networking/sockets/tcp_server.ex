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
        Task.async(fn -> accept_connections(listener, config.registry_table); end)
        {:ok, %{state | tcp_sock: listener}}

      {:error, e} ->
        Logger.error("Error opening TCP socket: #{inspect(e)}")
        {:stop, :tcp_open_error}
    end
  end

  def handle_call({:cache_conn, conn_id, socket}, _from, state) do
    new_state = Map.put(state, :connections, Map.put(state.connections, conn_id, socket))
    {:reply, :ok, new_state}
  end

  def handle_call({:get_conn, conn_id}, _from, state) do
    socket = Map.get(state.connections, conn_id)
    {:reply, socket, state}
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

  # Handle incoming TCP connections by creating a new socket.
  @spec accept_connections(any, map) :: :ok | :error
  defp accept_connections(listener, regisry_table) do
    Logger.info("Accepting connections")
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        # Loop to handle incoming messages
        Task.async(fn -> handle_conn(socket, regisry_table); end)

        # Recurse to accept new connections
        accept_connections(listener, regisry_table)

      {:error, :closed} ->
        Logger.info("Listener closed")
    end
  end

  @spec handle_conn(any, map) :: :ok | :error
  defp handle_conn(socket, regisry_table) do
    Logger.info("Handling connection")
    case :gen_tcp.recv(socket, 0, 10_000) do
      {:ok, msg} ->
        conn_id = cache_conn(socket, regisry_table.tcp_server)
        spawn_worker(conn_id, msg, regisry_table)

      {:error, _} ->
        Logger.info("Connection closed")
        :error
    end
  end

  @spec handle_round_trip(String.t(), non_neg_integer, binary, map) :: :ok | :error
  defp handle_round_trip(addr, port, data, registry_table) do
    IO.inspect(addr, label: "[TCP] SENDING MESSAGE TO:")
    addr
    |> String.to_charlist()
    |> :inet.parse_address()
    |> case do
      {:ok, ip_tuple} ->
        case :gen_tcp.connect(ip_tuple, port, [:binary, active: false, reuseaddr: true]) do
          {:ok, socket} ->
            Logger.info("Sending message")
            :gen_tcp.send(socket, data)
            case recv_data(socket, 10_000, []) do
              {:ok, msg} ->
                IO.inspect(msg, label: "[TCP] Received message (HOST: #{registry_table.tcp_server})")
                cid = :crypto.strong_rand_bytes(16) |> Base.encode16()
                spawn_worker(cid, msg, registry_table)

              {:error, e} ->
                Logger.error("Error receiving TCP data: #{inspect(e)}")
                :error
            end

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
  @spec send({String.t(), non_neg_integer}, binary, map) :: :ok
  def send({addr, port}, data, registry_table) do
    Logger.info("[TCP] Sending message")
    Task.async(fn -> handle_round_trip(addr, port, data, registry_table); end)
    :ok
  end

  @spec respond(String.t(), binary, atom) :: :ok | {:error, atom}
  def respond(conn_id, data, name) do
    Logger.info("[TCP] Responding to message")
    socket = get_conn(conn_id, name)
    :gen_tcp.send(socket, data)
    :gen_tcp.close(socket)
  end

  # ---- Private functions ----
  @spec spawn_worker(String.t(), binary, map) :: :ok | :error
  defp spawn_worker(conn_id, msg, registry_table) do
    Task.async(fn ->
      Logger.debug("[TCP] Starting task to parse TCP segment")
      Lap2Socket.parse_segment(conn_id, msg, registry_table)
    end)
    :ok
  end

  @spec cache_conn(any, atom) :: String.t()
  defp cache_conn(socket, name) do
    Logger.info("Caching connection")
    conn_id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    GenServer.call({:global, name}, {:cache_conn, conn_id, socket})
    conn_id
  end

  @spec get_conn(String.t(), atom) :: any
  defp get_conn(conn_id, name) do
    GenServer.call({:global, name}, {:get_conn, conn_id})
  end

  # Receive and reassemble all TCP segments
  @spec recv_data(any, non_neg_integer, list) :: {:ok, binary} | {:error, any}
  defp recv_data(socket, timeout, acc) do
    case :gen_tcp.recv(socket, 0, timeout) do
      {:ok, data} ->
        recv_data(socket, timeout, [data | acc])

      {:error, :closed} ->
        reconstructed = Enum.reverse(acc)
        |> Enum.reduce(<<>>, fn bitstr, acc -> acc <> bitstr; end)
        {:ok, reconstructed}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
