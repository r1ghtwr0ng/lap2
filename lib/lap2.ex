defmodule LAP2 do
  @moduledoc """
  Documentation for `LAP2`.
  """
  require Logger

  def start() do
    # Start server, load config from file
    {:ok, config}   = load_config()
    start_supervisor(config)
  end

  @doc """
  Kill supervisor and its children
  """
  def kill() do
    Supervisor.stop(LAP2.Supervisor)
  end

  # Load the config file and handle thrown errors (by dying lol)
  defp load_config() do
    try do
      filepath = System.get_env("LAP2_CONFIG_PATH") || "./config/config.json"
      config = LAP2.Utils.ConfigParser.parse_json(filepath)
      {:ok, config}
    rescue
      e in Jason.DecodeError -> Logger.error("Error parsing JSON config: #{inspect e}")
      e in File.Error -> Logger.error("Error opening config file: #{inspect e}")
      :init.stop()
    end
  end

  # Start the supervisor and spawns the children
  defp start_supervisor(config) do
    opts = [strategy: :one_for_one, name: LAP2.Supervisor]
    children = [
      {Task.Supervisor, [name: LAP2.TaskSupervisor, max_children: config[:max_dgram_handlers] || 10]},
      {LAP2.Networking.UdpServer, config},
      #{LAP2.Networking.LAP2Socket, [config]}
    ]
    Supervisor.start_link(children, opts)
  end
end
