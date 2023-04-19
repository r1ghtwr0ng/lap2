defmodule LAP2.Main.Master do
  @moduledoc """
  Module for sending/receiving data via the network.
  """
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
    IO.puts("[i] ShareHandler: Starting GenServer")

    state = %{
      listeners: %{},
      config: config
    }

    {:ok, state}
  end

  @spec handle_call({:deliver_response, binary, binary}, any, map) :: {:noreply, map}
  def handle_call({:deliver_response, data, stream_id}, _from, state) do
    case get_listener(stream_id, state) do
      # TODO send data to TCP listener
      {:ok, listener} -> IO.puts("[+] Delivering data: #{inspect(data)} to: #{inspect(listener)}")
      {:error, _} -> Logger.error("No listener registered for stream ID #{stream_id}")
    end

    {:noreply, state}
  end

  # TODO specify listener type
  @spec handle_call({:register_listener, binary, any}, any, map) :: {:noreply, map}
  def handle_call({:register_listener, stream_id, listener}, _from, state) do
    IO.puts("[+] Registering listener: #{inspect(listener)} for stream ID: #{inspect(stream_id)}")
    new_state = %{state | listeners: Map.put(state.listeners, stream_id, listener)}
    {:noreply, new_state}
  end

  # TODO specify listener type
  @spec handle_call({:deregister_listener, binary}, any, map) :: {:noreply, map}
  def handle_call({:deregister_listener, stream_id}, _from, state) do
    IO.puts("[+] Deregistering listener for stream ID: #{inspect(stream_id)}")
    new_state = %{state | listeners: Map.delete(state.listeners, stream_id)}
    {:noreply, new_state}
  end

  @doc """
  Send a response to the appropriate listener socket.
  """
  @spec deliver_response(binary, binary, atom) :: :ok
  def deliver_response(data, stream_id, master_name \\ :master) do
    GenServer.cast({:global, master_name}, {:deliver_response, data, stream_id})
    :ok
  end

  @doc """
  Send a request to the appropriate listener socket.
  """
  @spec deliver_request(binary, binary, atom) :: :ok
  def deliver_request(data, stream_id, master_name \\ :master) do
    GenServer.cast({:global, master_name}, {:deliver_request, data, stream_id})
    :ok
  end

  @doc """
  Register a listener with a unique stream ID.
  """
  # TODO specify listener type
  @spec register_listener(binary, any, atom) :: :ok
  def register_listener(stream_id, listener, master_name \\ :master) do
    GenServer.call({:global, master_name}, {:register_listener, stream_id, listener})
  end

  # ---- Private Functions ----
  @spec get_listener(binary, map) :: {:ok, any} | {:error, any}
  defp get_listener(stream_id, state) when is_map_key(state.listeners, stream_id) do
    {:ok, Map.get(state.listeners, stream_id)}
  end

  defp get_listener(_stream_id, _state), do: {:error, :no_listener}
end
