defmodule LAP2.Services.FileIO do
  @moduledoc """
  Example service provider for file transfer.
  """

  require Logger
  alias LAP2.Networking.Router
  alias LAP2.Networking.Resolver
  alias LAP2.Main.Master
  alias LAP2.Utils.JsonUtils
  alias LAP2.Utils.Generator

  @max_fragment_size 4096

  @doc """
  Start the Master process.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config.registry_table, name: {:global, config.name})
  end

  @doc """
  Initialise the data handler GenServer.
  """
  @spec init(map) :: {:ok, map}
  def init(registry_table) do
    # Initialise data handler state
    Logger.info("[i] File IO: Starting GenServer")

    state = %{
      secret: nil,
      service_id: nil,
      listener_id: nil,
      request_status: %{},
      registry_table: registry_table
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

  @spec handle_call({:set_status, map, String.t()}, any, map) :: {:reply, :ok, map}
  def handle_call({:set_status, _status, request_id}, _from, state) when is_map_key(state.request_status, request_id) do
    {:reply, :ok, state}
  end
  def handle_call({:set_status, status, request_id}, _from, state) do
    new_state = Map.put(state, :request_status, Map.put(state.request_status, request_id, status))
    {:reply, :ok, new_state}
  end

  @spec handle_call({:get_status, String.t()}, any, map) ::
    {:reply, {:ok, map} | {:error, atom}, map}
  def handle_call({:get_status, request_id}, _from, state) do
    case Map.get(state.request_status, request_id, nil) do
      nil -> {:reply, {:error, :no_status}, state}
      status -> {:reply, {:ok, status}, state}
    end
  end

  @spec handle_call(:get_registry_table, any, map) :: {:reply, map, map}
  def handle_call(:get_registry_table, _from, state) do
    {:reply, state.registry_table, state}
  end

  @doc """
  Register and start the File IO listener service.
  """
  @spec run_service(atom) :: {:ok, String.t()} | :error
  def run_service(master_name) do
    registry_table = Master.get_registry_table(master_name)
    serv_id = Generator.generate_hex(8)
    config = %{
      name: serv_id,
      registry_table: registry_table
    }
    start_link(config)
    funct = fn cmd, serv_id -> LAP2.Services.FileIO.parse_cmd(cmd, serv_id) end
    {:ok, listener_id} = Master.register_listener({:native, funct, serv_id}, master_name)
    case Master.register_service(serv_id, listener_id, master_name) do
      {:ok, secret} ->
        register(secret, serv_id, listener_id)
        {:ok, serv_id}
      {:error, reason} ->
        Logger.warn("[!] File IO: Failed to register service: #{inspect reason}")
        :error
    end
  end

  @doc """
  Stop the service.
  """
  @spec stop_service(String.t()) :: :ok | :error
  def stop_service(serv_id) do
    master_name = Map.get(get_registry_table(serv_id), :master)
    %{
      secret: secret,
      listener_id: listener_id
    } = get_state(serv_id)
    Master.deregister_service(serv_id, secret, master_name)
    Master.deregister_listener(listener_id, master_name)
    GenServer.stop({:global, serv_id})
  end

  @doc """
  Request a file from a remote FileIO service.
  Provide a list of introduction points to the remote service.
  """
  @spec request_file(list(String.t()), String.t(), String.t(), String.t(), String.t(), non_neg_integer) :: :ok | :error
  def request_file(intro_points, remote_serv_id, filename, save_location, serv_id, fragment_idx \\ 0) do
    registry_table = get_registry_table(serv_id)
    dht = Router.debug(registry_table.router).routing_table
    Enum.map(intro_points, fn intro_point ->
      case Resolver.resolve_addr(intro_point, dht) do
        {:error, :not_found} -> nil
        {:ok, intro_point} -> intro_point
      end
    end)
    |> Enum.filter(fn intro_point -> intro_point != nil; end)
    |> case do
      [] ->
        Logger.warn("[!] File IO: Failed to resolve remote addresses")
        :error

      intro_point_addr ->
        %{listener_id: listener_id} = get_state(serv_id)
        # Create the FileIO request
        request_id = Generator.generate_hex(8)
        request = %{
          filename: filename,
          request_id: request_id,
          type: "request",
          action: "read",
          fragment: fragment_idx
        } |> Jason.encode!()
        case Master.request_remote(intro_point_addr, request, remote_serv_id, listener_id, registry_table.master) do
          :ok ->
            status = %{
              data: <<>>,
              filename: filename,
              intro_points: intro_points,
              save_location: save_location,
              serv_id: remote_serv_id,
            }
            set_status(status, request_id, serv_id)

          :error ->
            Logger.error("[!] File IO: Master service failed to send request")
            :error
        end
    end
  end

  # ---- Internal functions ----
  @doc """
  Parse a JSON request/response for a file and return the file contents.
  """
  @spec parse_cmd(map | binary, String.t()) :: :ok | :error | {:error, atom}
  def parse_cmd(json_data, serv_id) when is_binary(json_data) do
    JsonUtils.parse_json(json_data)
    |> JsonUtils.keys_to_atoms()
    |> parse_cmd(serv_id)
  end
  def parse_cmd(%{
    query_ids: qids,
    type: "query",
    data: json_data
  }, serv_id) do
    Logger.info("[i] File IO: Parsing query")
    case Jason.decode(json_data) do
      {:ok, decoded_map} ->
        case gen_response(decoded_map) do
          {:ok, response} ->
            %{
              secret: secret,
              service_id: ^serv_id
            } = get_state(serv_id)
            master_name = Map.get(get_registry_table(serv_id), :master)
            IO.inspect(response, label: "[RESPONDING WITH RESPONSE]")
            Master.respond(serv_id, qids, secret, response, master_name)

          {:error, reason} ->
            Logger.error("[!] File IO: Failed to generate response: #{inspect reason}")
            :error
        end

      {:error, _} ->
        {:error, :invalid_json}
    end
  end
  # Parse the remote file response
  def parse_cmd(%{
    type: "response",
    data: response_data
  }, serv_id) do
    case Jason.decode(response_data) do
      {:ok, decoded_map} ->
        case get_status(decoded_map["request_id"], serv_id) do
          {:ok, status} -> handle_reconstruct(decoded_map, status, serv_id)

          {:error, _} -> :error
        end

      {:error, _} -> :error
    end
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

  @spec set_status(map, String.t(), String.t()) :: :ok | :error
  defp set_status(status, request_id, serv_id) do
    GenServer.call({:global, serv_id}, {:set_status, status, request_id})
  end

  @spec get_status(String.t(), String.t()) :: {:ok, map} | {:error, atom}
  defp get_status(request_id, serv_id) do
    GenServer.call({:global, serv_id}, {:get_status, request_id})
  end

  @spec get_registry_table(String.t()) :: map
  defp get_registry_table(serv_id) do
    GenServer.call({:global, serv_id}, :get_registry_table)
  end

  @spec gen_response(map) :: {:ok, binary} | {:error, atom}
  defp gen_response(decoded_json) do
    case decoded_json do
      %{
        "action" => "read",
        "filename" => filename,
        "fragment" => fragment_idx,
        "request_id" => request_id
      } -> read_file(filename, fragment_idx, request_id)

      %{
        "action" => "write",
        "filename" => filename,
        "data" => data,
        "auth" => auth,
        "request_id" => request_id
      } -> write_file(filename, data, auth, request_id)

      _ -> {:error, :invalid_request}
    end
  end

  # Read data from a file and return it as a response
  @spec read_file(String.t(), non_neg_integer, non_neg_integer) :: {:ok, map} | {:error, atom}
  defp read_file(filename, fragment, request_id) do
    case File.read(filename) do
      {:ok, file_data} ->
        split_data(file_data, fragment, request_id)

      {:error, _} ->
        {:error, :file_not_found}
    end
  end

  # Write data to a file and return a response
  @spec write_file(String.t(), String.t(), String.t(), non_neg_integer) :: {:ok, binary} | {:error, atom}
  defp write_file(filename, data, auth, request_id) do
    cond do
      check_auth(auth) ->
        case File.write(filename, data) do
          :ok ->
            response = %{
              filename: filename,
              auth: auth,
              status: "success",
              request_id: request_id
            } |> Jason.encode!()
            {:ok, response}

          {:error, _} ->
            {:error, :file_not_found}
        end
      true -> {:error, :unauthorized}
    end
  end

  # Check if the auth token is valid
  @spec check_auth(String.t()) :: boolean
  defp check_auth(_auth) do
    true # TODO
  end

  # Handle reconstruction of the response
  @spec handle_reconstruct(map, map, String.t()) :: :ok | :error
  defp handle_reconstruct(decoded_map, status, serv_id) do
    cond do
      decoded_map["eof"] ->
        save_location = status.save_location
        final_data = status.data <> decoded_map["data"]
        case File.write(save_location, final_data) do
          :ok ->
            Logger.info("[i] File IO: Successfully wrote file to #{save_location}")

          {:error, _} -> :error
        end

      true ->
        %{
          data: data,
          filename: filename,
          intro_points: intro_points,
          save_location: save_location,
          serv_id: remote_serv_id,
        } = status
        %{
          "request_id" => request_id,
          "data" => response_data,
          "fragment" => fragment_idx,
        } = decoded_map
        set_status(Map.put(status, :data, data <> response_data), request_id, serv_id)
        request_file(intro_points, remote_serv_id, filename, save_location, serv_id, fragment_idx + 1)
    end
  end

  # Split the data into fragments and return the response
  @spec split_data(binary, non_neg_integer, non_neg_integer) :: {:ok, map} | {:error, atom}
  defp split_data(data, fragment_idx, request_id) do
    IO.inspect(fragment_idx, label: "Fragment Index")
    cond do
      byte_size(data) > fragment_idx * @max_fragment_size ->
        fragment = get_fragment(data, fragment_idx)
        response = %{
          data: fragment,
          eof: byte_size(fragment) < @max_fragment_size,
          fragment: fragment_idx,
          request_id: request_id
        } |> Jason.encode!()
        {:ok, response}

      true -> {:error, :invalid_fragment}
    end
  end

  # Get a fragment of the data
  @spec get_fragment(binary, non_neg_integer) :: binary | :error
  defp get_fragment(data, _) when byte_size(data) < @max_fragment_size, do: data
  defp get_fragment(data, 0) do
    <<head::binary-size(@max_fragment_size), _::binary>> = data
    head
  end
  defp get_fragment(data, fragment_idx) when fragment_idx * @max_fragment_size <= byte_size(data) do
    <<_::binary-size(@max_fragment_size * fragment_idx), tail::binary>> = data
    get_fragment(tail, 0)
  end
  defp get_fragment(_, _), do: :error
end
