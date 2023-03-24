defmodule LAP2.Networking.UdpServer do
  # Wrapper around basic UDP socket, adding checksum, sequence number, etc.
  use GenServer
  require Logger
  alias LAP2.Networking.LAP2Socket

  # ---- GenServer callbacks ----
  @doc """
  Start the UDP server.
  """
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, :udp_server})
  end

  def init(config) do
    # Open UDP socket
    IO.puts("Starting UDP server")
    state = %{
      port: config[:udp_port] || 1442,
      queue_interval: config[:queue_interval] || 100,
      max_queue_size: config[:max_queue_size] || 100,
      queue: :queue.new(),
      udp_sock: nil
    }
    case :gen_udp.open(config[:udp_port], [active: true]) do
      {:ok, udp_sock} -> {:ok, %{state | udp_sock: udp_sock}}
      {:error, e} ->
        Logger.error("Error opening UDP socket: #{inspect e}")
        {:stop, :udp_open_error}
    end
  end

  def handle_info({:send_packet, ip, port, pkt}, state) do
    case :gen_udp.send(state.udp_sock, ip, port, pkt) do
      :ok ->
        IO.puts("[+] Sent packet successfully to #{ip}:#{port}") # Debug
        {:noreply, state}
      {:error, reason} ->
        Logger.error("Error sending packet: #{inspect reason}")
        {:noreply, state}
    end
  end

  # Handle received UDP packets
  def handle_info({:udp, _socket, _ip, _port, pkt}, state) do
    case Task.Supervisor.start_child(LAP2.TaskSupervisor, fn -> LAP2Socket.parse_packet(pkt) end) do
      {:ok, _pid} ->
        #Logger.debug("Started task to parse packet")
        {:noreply, state}

      {:error, :max_children} ->
        #Logger.debug("Max children reached, dropping packet")
        Process.send_after(self(), :check_queue, state.queue_interval)
        cond do
          :queue.len(state.queue) < state.max_queue_size ->
            #Logger.debug("Adding packet to queue")
            {:noreply, %{state | queue: :queue.in(pkt, state.queue)}}
          true ->
            #Logger.debug("Queue full, dropping packet")
            {:noreply, state}
        end

      {:error, reason} ->
        Logger.error("Error starting task to parse packet #{inspect reason}")
        {:noreply, state}
    end
  end

  # Function called by self() to check if there are any packets in the queue
  # and if so, start a task to parse them
  def handle_info(:check_queue, %{queue: {[], []}} = state), do: {:noreply, state}

  def handle_info(:check_queue, %{queue: queue, queue_interval: queue_interval} = state) do
    {{:value, pkt}, tail} = :queue.out(queue)
    case Task.Supervisor.start_child(LAP2.TaskSupervisor, fn -> LAP2Socket.parse_packet(pkt) end) do
      {:ok, _pid} ->
        #Logger.debug("Started task to parse packet")
        {:noreply, %{state | queue: tail}}

      {:error, :max_children} ->
        #Logger.debug("Cannot send packet from queue, max children reached")
        Process.send_after(self(), :check_queue, queue_interval)
        {:noreply, state}

      {:error, reason} ->
        Logger.error("Error starting task to parse packet #{inspect reason}}")
        {:noreply, %{state | queue: tail}}
    end
  end

  @doc """
  Terminate the UDP server.
  """
  def terminate(_reason, %{udp_sock: nil}), do: Logger.error("UDP socket terminated unexpectedly")

  def terminate(_reason, %{udp_sock: udp_sock}) do
    :gen_udp.close(udp_sock)
  end

  # ---- Public functions ----
  def send_packet(pkt, {ip, port}) do
    GenServer.call({:global, :udp_server}, {:send_packet, ip, port, pkt})
  end
end
