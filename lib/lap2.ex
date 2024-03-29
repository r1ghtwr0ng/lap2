defmodule LAP2 do
  @moduledoc """
  The main module of the LAP2 server. This module is responsible for starting the supervision tree,
  loading the config and setting the log level.
  """
  alias LAP2.Utils.ConfigParser
  require Logger

  @doc """
  Start the server without a config file.
  The config files`dev_config.json` and `prod_config.json` can be found in the config dir.
  By default, the DEBUG config is used, if the environment variable `LAP2_ENV` is set to
  `PROD`, the prod config is used. To use a custom config file, set the environment variable
  `LAP2_PROD_CONFIG_PATH` or `LAP2_DEV_CONFIG_PATH` to the path of the config file.
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
  def terminate_child(supervisor_name, pid) do
    Task.Supervisor.terminate_child({:global, supervisor_name}, pid)
  end

  @doc """
  Kill main process supervisor (this stops the whole supervision tree)
  """
  @spec kill(pid) :: :ok
  def kill(pid), do: Supervisor.stop(pid)

  # Load the config file and handle thrown errors
  @spec load_config :: {:ok, map} | :init.stop()
  def load_config() do
    try do
      # Selects appropriate config for DEBUG or PROD environment
      env = System.get_env("LAP2_ENV") || "DEV"
      # Get coonfig
      ConfigParser.get_config(env)
    rescue
      e in Jason.DecodeError ->
        Logger.error("Error parsing JSON config: #{inspect(e)}")

      e in File.Error ->
        Logger.error("Error opening config file: #{inspect(e)}")
        :init.stop()
    end
  end

  # Starts the supervisor tree
  @spec start_supervisor(map) :: {:ok, pid} | {:error, any}
  defp start_supervisor(config) do
    opts = [strategy: :one_for_one, name: {:global, config.main_supervisor.name}]

    children = [
      {Task.Supervisor,
       [
         name: {:global, config.task_supervisor.name},
         max_children: config.task_supervisor.max_children || 10
       ]},
      {LAP2.Main.Master, config.master},
      {LAP2.Main.ProxyManager, config.proxy_manager},
      {LAP2.Main.ConnectionSupervisor, config.conn_supervisor},
      {LAP2.Main.StructHandlers.ShareHandler, config.share_handler},
      {LAP2.Crypto.CryptoManager, config.crypto_manager},
      {LAP2.Networking.Router, config.router},
      {LAP2.Networking.Sockets.UdpServer, config.udp_server},
      {LAP2.Networking.Sockets.TcpServer, config.tcp_server}
    ]

    Supervisor.start_link(children, opts)
  end
end
