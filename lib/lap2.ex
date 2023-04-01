defmodule LAP2 do
  @moduledoc """
  Documentation for `LAP2`.
  """
  require Logger


  @doc """
  Start the server without a config file.
  The config files`debug_config.json` and `prod_config.json` can be found in the config dir.
  By default, the DEBUG config is used, if the environment variable `LAP2_ENV` is set to
  `PROD`, the prod config is used. To use a custom config file, set the environment variable
  `LAP2_PROD_CONFIG_PATH` or `LAP2_DEBUG_CONFIG_PATH` to the path of the config file.
  """
  @spec start :: {:error, any} | {:ok, pid}
  def start() do
    # Start server, load config from file
    {:ok, config} = load_config()
    start_supervisor(config)
  end
  @doc """
  Start the server with a config map. This is useful for testing.
  """
  @spec start(map) :: {:error, any} | {:ok, pid}
  def start(config) do
    start_supervisor(config)
  end

  @doc """
  Kill supervisor and its children
  """
  @spec kill :: :ok
  def kill() do
    Supervisor.stop(LAP2.Supervisor)
  end

  # Load the config file and handle thrown errors (by dying lol)
  @spec load_config :: {:ok, map} | :init.stop()
  def load_config() do
    try do
      # Selects appropriate config for DEBUG or PROD environment
      env = System.get_env("LAP2_ENV") || "DEBUG"
      config = env
      |> get_config_path()
      |> LAP2.Utils.ConfigParser.parse_json()
      Logger.configure(level: config_log_level(env))
      {:ok, config}
    rescue
      e in Jason.DecodeError -> Logger.error("Error parsing JSON config: #{inspect e}")
      e in File.Error -> Logger.error("Error opening config file: #{inspect e}")
      :init.stop()
    end
  end

  # Start the supervisor and spawns the children
  @spec start_supervisor(map) :: {:ok, pid}
  defp start_supervisor(%{name: name} = config) do
    opts = [strategy: :one_for_one, name: name]
    children = [
      {Task.Supervisor, [name: LAP2.TaskSupervisor, max_children: config.udp_server.max_dgram_handlers || 10]},
      {LAP2.Networking.UdpServer, config.udp_server},
      {LAP2.Networking.Router, config.router},
      #{LAP2.DataProcessor, config[:data_processor]} TODO
      #{LAP2.Networking.LAP2Socket, [config]} TODO
    ]
    Supervisor.start_link(children, opts)
  end

  # Get the config path based on the environment, default to DEBUG if not PROD
  defp get_config_path("PROD") do
    System.get_env("LAP2_PROD_CONFIG_PATH") || "./config/prod_config.json"
  end
  defp get_config_path(_), do: System.get_env("LAP2_DEBUG_CONFIG_PATH") || "./config/debug_config.json"

  # Set the log level based on the environment, default to debug if not PROD
  defp config_log_level("PROD"), do: :info
  defp config_log_level(_), do: :debug
end
