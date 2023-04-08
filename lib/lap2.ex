defmodule LAP2 do
  @moduledoc """
  Documentation for `LAP2`.
  """
  alias LAP2.Utils.ConfigParser
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
    load_config()
    |> start_supervisor()
  end
  @doc """
  Start the server with a config map. This is useful for testing.
  """
  @spec start(map) :: {:error, any} | {:ok, pid}
  def start(config) do
    start_supervisor(config)
  end

  @doc """
  Kill the child task
  """
  def terminaste_child(supervisor_name, pid) do
    Task.Supervisor.terminate_child({:global, supervisor_name}, pid)
  end

  @doc """
  Kill supervisor and its children
  """
  @spec kill :: :ok
  def kill(name \\ :lap2_daemon) do
    Supervisor.stop({:global, name})
  end

  # Load the config file and handle thrown errors (by dying lol)
  @spec load_config :: {:ok, map} | :init.stop()
  def load_config() do
    try do
      # Selects appropriate config for DEBUG or PROD environment
      env = System.get_env("LAP2_ENV") || "DEBUG"
      # Set logging level
      Logger.configure(level: config_log_level(env))
      # Get coonfig
      ConfigParser.get_config(env)
    rescue
      e in Jason.DecodeError -> Logger.error("Error parsing JSON config: #{inspect e}")
      e in File.Error -> Logger.error("Error opening config file: #{inspect e}")
      :init.stop()
    end
  end

  # Start the supervisor and spawns the children
  @spec start_supervisor(map) :: {:ok, pid} | {:error, any}
  defp start_supervisor(config) do
    opts = [strategy: :one_for_one, name: {:global, config.main_supervisor.name}]
    children = [
      {Task.Supervisor, [name: {:global, config.task_supervisor.name}, max_children: config.task_supervisor.max_children || 10]},
      {LAP2.Networking.UdpServer, config.udp_server},
      {LAP2.Networking.Router, config.router},
      #{LAP2.DataProcessor, config.data_processor} TODO
    ]
    Supervisor.start_link(children, opts)
  end

  # Set the log level based on the environment, default to debug if not PROD
  defp config_log_level("PROD"), do: :info
  defp config_log_level(_), do: :debug
end
