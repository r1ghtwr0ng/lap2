defmodule LAP2.Main.StructHandlers.ShareHandler do
  @moduledoc """
  Handle share caching and reassembly.
  """
  use GenServer
  require Logger
  alias LAP2.Utils.EtsHelper
  alias LAP2.Utils.ProtoBuf.ShareHelper
  alias LAP2.Main.Helpers.ProcessorState
  alias LAP2.Main.StructHandlers.RequestHandler

  @doc """
  Start the ShareHandler process.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, config.name})
  end

  @doc """
  Initialise the share handler GenServer.
  """
  @spec init(map) :: {:ok, map}
  def init(config) do
    # Ensure that the ETS gets cleaned up on exit
    Process.flag(:trap_exit, true)
    # Initialise data handler state
    IO.puts("[i] ShareHandler (#{config.name}): Starting GenServer")

    state = %{
      ets: :ets.new(:clove_ets, [:set, :private]),
      share_info: %{},
      drop_list: [],
      config: %{share_ttl: config.share_ttl, registry_table: config.registry_table}
    }

    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_cast({:deliver, Clove.t(), map}, map) :: {:noreply, map}
  def handle_cast({:deliver, clove, aux_data}, state) do
    # TODO send data for parsing
    Logger.info("[+] In share handler")
    {:ok, share} = ShareHelper.deserialise(clove.data)

    case ProcessorState.route_share(state, share) do
      :reassemble ->
        Logger.info("[+] ShareHandler (#{state.config.registry_table.share_handler}): Reassembling share #{share.message_id}")
        reassemble(state, share, aux_data)

      :cache ->
        Logger.info("[+] Caching clove by ShareHandler (#{state.config.registry_table.share_handler})")
        cache(state, share, aux_data)

      :drop ->
        Logger.error("[!] Dropping clove by ShareHandler (#{state.config.registry_table.share_handler})")
        {:noreply, state}
    end
  end

  @spec handle_info(any, map) :: {:noreply, map}
  def handle_info(_, state) do
    {:noreply, state}
  end

  @doc """
  Cleanup the ETS table on exit.
  """
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
    Logger.info("[+] ShareHandler (#{name}): Delivering data to GenServer")
    GenServer.cast({:global, name}, {:deliver, data, aux_data})
  end

  # ---- Private Functions ----
  # Reassemble shares and send to the request handler
  @spec reassemble(map, Share.t(), map) :: {:noreply, map}
  defp reassemble(state, share, aux_data) do
    {:ok, ets_struct} = EtsHelper.get_value(state.ets, share.message_id)
    EtsHelper.delete_value(state.ets, share.message_id)
    all_shares = [share | ets_struct.shares]
    aux_list = [aux_data | ets_struct.aux_data]
    case ShareHelper.format_aux_data(aux_list) do
      {:ok, formatted_aux_data} ->
        #Logger.info("[+] Formatted AUX DATA: #{inspect formatted_aux_data} <<<<<<<<<<==================================")
        cast_reconstructed(all_shares, formatted_aux_data, state.config.registry_table)

      {:error, _reason} ->
        Logger.error("Reconstruction failed")
    end

    new_state =
      state
      |> ProcessorState.delete_from_cache(share.message_id)
      |> ProcessorState.add_to_drop_list(share.message_id)

    {:noreply, new_state}
  end

  # Cast the reconstructed data to the listener
  @spec cast_reconstructed(list(Share.t()), map, map) :: :ok
  defp cast_reconstructed(all_shares, formatted_aux, registry_table) do
    case ShareHelper.reconstruct(all_shares) do
      {:ok, reconstructed_data} ->
        # Verify and format the auxiliary data
        Task.async(fn ->
          RequestHandler.handle_request(
            reconstructed_data,
            formatted_aux,
            registry_table
          )
        end)
        #Logger.info("[+] Reconstructed: #{inspect reconstructed_data} <<<<<<<<<<==================================")

      {:error, _reason} ->
        Logger.error("Reconstruction failed")
    end
  end

  # Cache a share inside ETS
  @spec cache(map, Share.t(), map) :: {:noreply, map}
  defp cache(state, share, aux_data) do
    # Add the share to the cache
    new_state = ProcessorState.cache_share(state, share)
    ProcessorState.add_share_to_ets(state.ets, share, aux_data)
    {:noreply, new_state}
  end
end
