defmodule LAP2.Main.ShareHandler do
  @moduledoc """
  Handle managing, sending and receiving data from the network.
  """
  use GenServer
  require Logger
  alias LAP2.Utils.ShareHelper
  alias LAP2.Main.Helpers.ProcessorState

  @doc """
  Start the Router process.
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
    IO.puts("[i] Share Handler: Starting GenServer")
    state = %{
      ets: :ets.new(:clove_ets, [:set, :private]),
      share_info: %{},
      drop_list: [],
      config: %{share_ttl: config.share_ttl}
    }
    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_cast({:deliver, binary, map}, map) :: {:noreply, map}
  def handle_cast({:deliver, data, aux_data}, state) do
    # TODO send data for parsing
    share = ShareHelper.deserialise(data)
    case ProcessorState.route_share(state, share) do
      :reassemble ->
        ets_shares = ProcessorState.get_share_from_ets(state.ets, share.message_id)
        ProcessorState.delete_share_from_ets(state.ets, share.message_id)
        all_shares = [share | ets_shares]
        case ShareHelper.reconstruct(all_shares) do
          {:ok, reconstructed} ->
            IO.puts("Reconstructed: #{reconstructed}") # TODO send to other handler
          {:error, _} -> IO.puts("Reconstruction failed")
        end
        new_state = state
        |> ProcessorState.delete_from_cache(share.message_id)
        |> ProcessorState.add_to_drop_list(share.message_id)
        {:noreply, new_state}
      :cache ->
        new_state = ProcessorState.cache_share(state, share)
        ProcessorState.add_share_to_ets(state.ets, share, aux_data)
        {:noreply, new_state}
      :drop -> {:noreply, state}
    end
  end

  # Cleanup the ETS table on exit
  @spec terminate(any, map) :: :ok
  def terminate(_reason, state) do
    :ets.delete(state.ets)
    :ok
  end

  # ---- Public Functions ----
  @doc """
  Receive data from the network.
  """
  @spec deliver(binary, map, atom) :: :ok
  def deliver(data, aux_data, name) do
    GenServer.cast({:global, name}, {:deliver, data, aux_data})
  end
end
