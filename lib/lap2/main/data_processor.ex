defmodule LAP2.Main.DataProcessor do
  @moduledoc """
  Handle managing, sending and receiving data from the network.
  """
  use GenServer
  require Logger

  @doc """
  Start the Router process.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    {:ok, pid} = GenServer.start_link(__MODULE__, config, name: {:global, config.name})
    :global.re_register_name({:global, config.name}, pid)
    {:ok, pid}
  end

  @doc """
  Initialise the data handler GenServer.
  """
  @spec init(map) :: {:ok, map}
  def init(config) do
    # Initialise data handler state
    IO.puts("[i] Data Processor: Starting GenServer")
    state = %{
      config: config
    }
    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  def handle_cast({:deliver, :proxy_discovery, data, headers}, state) do

    {:noreply, state}
  end

  def handle_cast({:deliver, :proxy_response, data, headers}, state) do

    {:noreply, state}
  end

  def handle_cast({:deliver, :regular_proxy, data, headers}, state) do

    {:noreply, state}
  end

  # ---- Public Functions ----
  @doc """
  Receive a clove from the network.
  """
  @spec deliver(atom, map, map, atom) :: :ok
  def deliver(req_type, data, headers, name) do
    GenServer.cast({:global, name}, {:deliver, req_type, data, headers})
  end
end
