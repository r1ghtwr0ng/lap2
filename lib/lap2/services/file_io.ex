defmodule LAP2.Services.FileIO do
  @moduledoc """
  Example service provider for file transfer.
  """

  require Logger
  alias LAP2.Main.Master

  @doc """
  Start the Master process.
  """
  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: {:global, name})
  end

  @doc """
  Initialise the data handler GenServer.
  """
  @spec init(list) :: {:ok, map}
  def init(_) do
    # Initialise data handler state
    Logger.info("[i] File IO: Starting GenServer")

    state = %{
      secret: nil,
      service_id: nil,
      listener_id: nil
    }

    {:ok, state}
  end

  @spec handle_call({:register, String.t(), String.t(), String.t()}, any, map) :: {:reply, :ok, map}
  def handle_call({:register, secret, serv_id, listener_id}, _from, state) do
    {:reply, :ok, %{state | secret: secret, service_id: serv_id, listener_id: listener_id}}
  end

  @spec handle_call(:get_state, any, map) :: {:reply, map, map}
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @doc """
  Register and start the File IO listener service.
  """
  @spec run_service(Strint.t(), atom) :: :ok | :error
  def run_service(serv_id, master_name) do
    start_link(serv_id)
    funct = fn cmd, master, serv_id -> LAP2.Services.FileIO.parse_cmd(cmd, master, serv_id) end
    {:ok, listener_id} = Master.register_listener({:native, funct, serv_id}, master_name)
    case Master.register_service(serv_id, listener_id, master_name) do
      {:ok, secret} ->
        register(secret, serv_id, listener_id)
        :ok
      {:error, reason} ->
        Logger.error("[!] File IO: Failed to register service: #{inspect reason}")
        :error
    end
  end

  @doc """
  Stop the service.
  """
  @spec stop_service(String.t(), atom) :: :ok | :error
  def stop_service(serv_id, master_name) do
    %{
      secret: secret,
      listener_id: listener_id
    } = get_state(serv_id)
    Master.deregister_service(serv_id, secret, master_name)
    Master.deregister_listener(listener_id, master_name)
    GenServer.stop({:global, serv_id})
  end

  @doc """
  Parse a JSON request for a file and return the file contents.
  """
  @spec parse_cmd(map | binary, atom, String.t()) :: :ok | :error
  def parse_cmd(json_data, master_name, serv_id) when is_binary(json_data) do
    case Jason.decode(json_data) do
      {:ok, decoded_map} ->
        parse_cmd(decoded_map, master_name, serv_id)
      {:error, _} ->
        {:error, :invalid_json}
    end
  end
  def parse_cmd(%{
    "query_ids" => qids,
    "type" => "query",
    "data" => json_data
  }, master_name, serv_id) do
    Logger.info("[i] File IO: Parsing query")
    case Jason.decode(json_data) do
      {:ok, decoded_map} ->
        filename = decoded_map["filename"]
        case File.read(filename) do
          {:ok, file_data} ->
            %{
              secret: secret,
              service_id: ^serv_id
            } = get_state(serv_id)
            Master.respond(serv_id, qids, secret, file_data, master_name)

          {:error, _} ->
            {:error, :file_not_found}
        end
      {:error, _} ->
        {:error, :invalid_json}
    end
  end
  def parse_cmd(%{
    "type" => "response",
    "data" => response_data
  }) do
    IO.inspect(response_data, label: "[RESPONSE]")
  end

  # ---- Private Util Functions ----
  @spec register(String.t(), String.t(), String.t()) :: :ok | :error
  defp register(secret, serv_id, listener_id) do
    GenServer.call({:global, serv_id}, {:register, secret, serv_id, listener_id})
  end

  @spec get_state(String.t()) :: map
  defp get_state(name) do
    GenServer.call({:global, name}, :get_state)
  end
end
