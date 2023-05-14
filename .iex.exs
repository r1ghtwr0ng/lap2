# Setup aliases
require Logger

alias LAP2.Main.Master
alias LAP2.Main.ProxyManager
alias LAP2.Main.ConnectionSupervisor
alias LAP2.Networking.Router
alias LAP2.Networking.Helpers.OutboundPipelines
alias LAP2.Crypto.InformationDispersal.RabinIDA
alias LAP2.Crypto.InformationDispersal.SecureIDA
alias LAP2.Crypto.KeyExchange.C_RSDAKE
alias LAP2.Crypto.Constructions.CryptoNifs
alias LAP2.Crypto.Constructions.ClaimableRS
alias LAP2.Services.FileIO
alias LAP2.Utils.Generator

defmodule Utilities do
  @spec make_registry_table(String.t) :: map
  def make_registry_table(addr) do
    %{
      conn_supervisor: String.to_atom("conn_supervisor_#{addr}"),
      master: String.to_atom("master_#{addr}"),
      proxy_manager: String.to_atom("proxy_manager_#{addr}"),
      share_handler: String.to_atom("share_handler_#{addr}"),
      router: String.to_atom("router_#{addr}"),
      main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
      task_supervisor: String.to_atom("lap2_superv_#{addr}"),
      tcp_server: String.to_atom("tcp_server_#{addr}"),
      udp_server: String.to_atom("udp_server_#{addr}"),
      crypto_manager: String.to_atom("crypto_manager_#{addr}")
    }
  end

  @spec make_config(String.t, non_neg_integer, non_neg_integer) :: map
  def make_config(addr, udp_port, tcp_port) do
    registry_table = make_registry_table(addr)
    %{
      main_supervisor: %{name: String.to_atom("lap2_daemon_#{addr}")},
      task_supervisor: %{max_children: 10, name: String.to_atom("lap2_superv_#{addr}")},
      conn_supervisor: %{
        name: String.to_atom("conn_supervisor_#{addr}"),
        registry_table: registry_table,
        max_service_providers: 10
      },
      master: %{
        name: String.to_atom("master_#{addr}"),
        registry_table: registry_table
      },
      proxy_manager: %{
        name: String.to_atom("proxy_manager_#{addr}"),
        registry_table: registry_table,
        clove_casts: 6,
        max_hops: 10,
        min_hops: 1,
        proxy_limit: 20,
        proxy_ttl: 60000
      },
      crypto_manager: %{name: String.to_atom("crypto_manager_#{addr}"),
        identity: "IDENT_#{addr}",
        registry_table: registry_table},
      router: %{
        clove_cache_size: 1000,
        clove_cache_ttl: 30000,
        lap2_addr: "LAP2_ADDR_#{addr}",
        name: String.to_atom("router_#{addr}"),
        proxy_limit: 20,
        proxy_policy: true,
        registry_table: registry_table,
        relay_table_size: 5000,
        relay_table_ttl: 1_800_000
      },
      tcp_server: %{
        max_queue_size: 1000,
        name: String.to_atom("tcp_server_#{addr}"),
        queue_interval: 100,
        registry_table: registry_table,
        req_timeout: 50000,
        tcp_port: tcp_port
      },
      udp_server: %{
        max_dgram_handlers: 10,
        max_queue_size: 1000,
        name: String.to_atom("udp_server_#{addr}"),
        queue_interval: 100,
        registry_table: registry_table,
        req_timeout: 50000,
        udp_port: udp_port
      },
      share_handler: %{
        name: String.to_atom("share_handler_#{addr}"),
        registry_table: registry_table,
        share_ttl: 60000
      }
    }
  end

  # Spawn a node
  def spawn_node(:verbose, cfg) do
    case LAP2.start(cfg) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Failed to start node: #{inspect(reason)}")
    end
  end
  def spawn_node(:silent, cfg) do
    # TODO
    LAP2.start(cfg)
  end

  # Spawn a network of nodes
  def spawn_network(mode, nodes, starting_port) do
    :ets.new(:network_registry, [:named_table, :set, :public])
    case starting_port do
      0 ->
        Enum.map(0..nodes, fn _ ->
          lap2_addr = Generator.generate_hex(8)
          cfg = make_config(lap2_addr, 0, 0)
          spawn_node(mode, cfg)
        end)
      _ ->
        Enum.map(0..nodes, fn i ->
          lap2_addr = Generator.generate_hex(8)
          cfg = make_config(lap2_addr, starting_port + i, starting_port + i)
          spawn_node(mode, cfg)
        end)
    end
  end
end
