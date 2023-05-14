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
    Logger.info("[i] ShareHandler (#{config.name}): Starting GenServer")

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
    {:ok, share} = ShareHelper.deserialise(clove.data)

    case ProcessorState.route_share(state, share) do
      :reassemble -> reassemble_and_cast(state, share, aux_data)

      :cache -> new_state = cache(state, share, aux_data)
        {:noreply, new_state}

      :drop -> {:noreply, state}
    end
  end

  @spec handle_call({:service_deliver, binary, map}, any, map) ::
    {:reply, {:reconstructed, binary, list(map)} | :cached | :dropped, map}
  def handle_call({:service_deliver, data, aux_data}, _from, state) do
    case ShareHelper.deserialise(data) do
      {:ok, share} ->
        case ProcessorState.route_share(state, share) do
          :reassemble -> response = reassemble(state, share, aux_data)
            {:reply, response, state}

          :cache -> new_state = cache(state, share, aux_data)
            {:reply, :cached, new_state}

          :drop -> {:reply, :dropped, state}
        end

      {:error, reason} ->
        Logger.error("Share deserialisation failed: #{reason}")
        {:reply, :dropped, state}
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
  Reassemble network received shares and route along pipeline.
  """
  @spec deliver(binary, map, atom) :: :ok
  def deliver(data, aux_data, name) do
    GenServer.cast({:global, name}, {:deliver, data, aux_data})
  end

  @doc """
  Reconstruct service request from shares.
  """
  @spec service_deliver(binary, map, atom) ::
    {:reconstructed, binary, list(map)} | :cached | :dropped
  def service_deliver(data, routing_info, name) do
    GenServer.call({:global, name}, {:service_deliver, data, routing_info})
  end

  # ---- Private Functions ----
  @spec reassemble(map, Share.t(), map) :: {:reconstructed, binary, list} | :dropped
  defp reassemble(state, share, aux_data) do
    case EtsHelper.get_value(state.ets, share.message_id) do
      {:ok, ets_struct} ->
        EtsHelper.delete_value(state.ets, share.message_id)
        all_shares = [share | ets_struct.shares]
        aux_list = [aux_data | ets_struct.aux_data]
        case ShareHelper.reconstruct(all_shares) do
          {:ok, reconstructed} ->
            {:reconstructed, reconstructed, aux_list}

          {:error, reason} ->
            Logger.error("Request reconstruction failed: #{reason}")
            :dropped
        end
      {:error, :not_found} ->
        Logger.warn("[+] ShareHandler: Share not found in ETS")
        :dropped
    end
  end

  # Reassemble shares and send to the request handler
  @spec reassemble_and_cast(map, Share.t(), map) :: {:noreply, map}
  defp reassemble_and_cast(state, share, aux_data) do
    case reassemble(state, share, aux_data) do
      {:reconstructed, reconstructed, aux_list} ->
        case ShareHelper.format_aux_data(aux_list) do
          {:ok, formatted_aux_data} ->
            #Logger.info("[+] Formatted AUX DATA: #{inspect formatted_aux_data} <<<<<<<<<<==============")
            cast_reconstructed(reconstructed, formatted_aux_data, state.config.registry_table)

          {:error, reason} ->
            Logger.error("Aux data formatting failed: #{reason}")
        end
      :dropped ->
        Logger.error("Request reconstruction failed")
    end

    new_state =
      state
      |> ProcessorState.delete_from_cache(share.message_id)
      |> ProcessorState.add_to_drop_list(share.message_id)

    {:noreply, new_state}
  end

  # Cast the reconstructed data to the listener
  @spec cast_reconstructed(binary, map, map) :: :ok
  defp cast_reconstructed(reconstructed_data, formatted_aux, registry_table) do
    # Verify and format the auxiliary data
    Task.async(fn ->
      RequestHandler.handle_request(
        reconstructed_data,
        formatted_aux,
        registry_table
      )
    end)
    :ok
    #Logger.info("[+] Reconstructed: #{inspect reconstructed_data} <<<<<<<<<<==================================")
  end

  # Cache a share inside ETS
  @spec cache(map, Share.t(), map) :: map
  defp cache(state, share, aux_data) do
    # Add the share to the cache
    ProcessorState.add_share_to_ets(state.ets, share, aux_data)
    ProcessorState.cache_share(state, share)
  end
end
