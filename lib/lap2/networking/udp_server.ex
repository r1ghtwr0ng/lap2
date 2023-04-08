defmodule LAP2.Networking.UdpServer do
  # Wrapper around basic UDP socket, adding checksum, sequence number, etc.
  use GenServer
  require Logger
  alias LAP2.Networking.LAP2Socket

  # ---- GenServer callbacks ----
  @doc """
  Start the UDP server.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, config.name})
  end

  @spec init(map) :: {:ok, map} | {:stop, atom}
  def init(config) do
    # Open UDP socket
    IO.puts("[i] UDP: Starting UDP server")
    # TODO test the default values
    state = %{
      port: config[:udp_port] || 1442,
      queue_interval: config[:queue_interval] || 100,
      max_queue_size: config[:max_queue_size] || 100,
      queue: :queue.new(),
      registry_table: config[:registry_table],
      udp_sock: nil
    }
    case :gen_udp.open(config[:udp_port], [active: true]) do
      {:ok, udp_sock} -> {:ok, %{state | udp_sock: udp_sock}}
      {:error, e} ->
        Logger.error("Error opening UDP socket: #{inspect e}")
        {:stop, :udp_open_error}
    end
  end

  # Handle received UDP datagrams
  @spec handle_info({:udp, any, tuple, non_neg_integer, list}, map) :: {:noreply, map}
  def handle_info({:udp, _socket, ip_tuple, src_port, dgram}, state) do
    src_ip = ip_tuple
    |> :inet.ntoa()
    |> to_string()
    source = {src_ip, src_port}
    task_supervisor = {:global, state.registry_table.task_supervisor}
    bin_dgram = :erlang.list_to_binary(dgram)
    case Task.Supervisor.start_child(task_supervisor, fn ->
      LAP2Socket.parse_dgram(source, bin_dgram, state.registry_table.router) end) do
      {:ok, _pid} ->
        #Logger.debug("Started task to parse datagram")
        {:noreply, state}

      {:error, :max_children} ->
        #Logger.debug("Max children reached, dropping datagram")
        Process.send_after(self(), :check_queue, state.queue_interval)
        cond do
          :queue.len(state.queue) < state.max_queue_size ->
            #Logger.debug("Adding datagram to queue")
            {:noreply, %{state | queue: :queue.in({source, bin_dgram}, state.queue)}}
          true ->
            #Logger.debug("Queue full, dropping datagram")
            {:noreply, state}
        end

      {:error, reason} ->
        Logger.error("Error starting task to parse datagram #{inspect reason}")
        {:noreply, state}
    end
  end

  # Send UDP datagrams
  @spec handle_cast({:send_dgram, {String.t, non_neg_integer}, binary}, map) :: {:noreply, map}
  def handle_cast({:send_dgram, {dest_ip, dest_port}, dgram}, state) do
    # Convert String IP to tuple
    dest_ip
    |> String.to_charlist()
    |> :inet.parse_address()
    |> case do
      {:ok, ip_tuple} ->
        case :gen_udp.send(state.udp_sock, ip_tuple, dest_port, dgram) do
          :ok ->
            IO.puts("[+] UDP: Sent datagram successfully to #{dest_ip}:#{dest_port}") # Debug
            {:noreply, state}
          {:error, reason} ->
            Logger.error("Error sending datagram: #{inspect reason}")
            {:noreply, state}
        end
      {:error, _reason} ->
        Logger.error("Invalid IP address: #{dest_ip}")
        {:noreply, state}
    end
  end

  # Function called by self() to check if there are any datagrams in the queue
  # and if so, start a task to parse them
  @spec handle_cast(:check_queue, map) :: {:noreply, map}
  def handle_cast(:check_queue, %{queue: {[], []}} = state), do: {:noreply, state}
  def handle_cast(:check_queue, %{queue: queue, queue_interval: queue_interval} = state) do
    {{:value, {source, bin_dgram}}, tail} = :queue.out(queue)
    case Task.Supervisor.start_child(LAP2.TaskSupervisor, fn -> LAP2Socket.parse_dgram(source, bin_dgram, state.registry_table.router) end) do
      {:ok, _pid} ->
        #Logger.debug("Started task to parse datagrams")
        {:noreply, %{state | queue: tail}}

      {:error, :max_children} ->
        #Logger.debug("Cannot send datagram from queue, max children reached")
        Process.send_after(self(), :check_queue, queue_interval)
        {:noreply, state}

      {:error, reason} ->
        Logger.error("Error starting task to parse datagram #{inspect reason}}")
        {:noreply, %{state | queue: tail}}
    end
  end

  @doc """
  Terminate the UDP server.
  """
  @spec terminate(any, map) :: :ok
  def terminate(reason, %{udp_sock: nil}) do
    Logger.error("UDP socket terminated unexpectedly. Reason: #{inspect reason}")
  end
  def terminate(_reason, %{udp_sock: udp_sock}) do
    :gen_udp.close(udp_sock)
  end

  # ---- Public functions ----
  @spec send_dgram(atom, binary, {binary, non_neg_integer}) :: :ok | {:error, atom}
  def send_dgram(udp_name, dgram, dest) do
    GenServer.cast({:global, udp_name}, {:send_dgram, dest, dgram})
  end
end
