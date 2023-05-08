alias LAP2.Networking.Router
alias LAP2.Main.Master
alias LAP2.Main.ProxyManager
alias LAP2.Networking.Helpers.OutboundPipelines
alias LAP2.Crypto.Helpers.CryptoStructHelper

defmodule ConfigBuilder do
  def make_config(addr, udp_port, tcp_port) do
    %{
      main_supervisor: %{name: String.to_atom("lap2_daemon_#{addr}")},
      task_supervisor: %{max_children: 10, name: String.to_atom("lap2_superv_#{addr}")},
      conn_supervisor: %{
        name: String.to_atom("conn_supervisor_#{addr}"),
        registry_table: %{
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
        },
        max_service_providers: 10
      },
      master: %{
        name: String.to_atom("master_#{addr}"),
        registry_table: %{
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
      },
      proxy_manager: %{
        name: String.to_atom("proxy_manager_#{addr}"),
        registry_table: %{
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
        },
        clove_casts: 6,
        max_hops: 10,
        min_hops: 1,
        proxy_limit: 20,
        proxy_ttl: 60000
      },
      crypto_manager: %{name: String.to_atom("crypto_manager_#{addr}"),
        identity: "IDENT_#{addr}",
        registry_table: %{
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
        }},
      router: %{
        clove_cache_size: 1000,
        clove_cache_ttl: 30000,
        lap2_addr: "LAP2_ADDR_#{addr}",
        name: String.to_atom("router_#{addr}"),
        proxy_limit: 20,
        proxy_policy: true,
        registry_table: %{
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
        },
        relay_table_size: 5000,
        relay_table_ttl: 1_800_000
      },
      tcp_server: %{
        max_queue_size: 1000,
        name: String.to_atom("tcp_server_#{addr}"),
        queue_interval: 100,
        registry_table: %{
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
        },
        req_timeout: 50000,
        tcp_port: tcp_port
      },
      udp_server: %{
        max_dgram_handlers: 10,
        max_queue_size: 1000,
        name: String.to_atom("udp_server_#{addr}"),
        queue_interval: 100,
        registry_table: %{
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
        },
        req_timeout: 50000,
        udp_port: udp_port
      },
      share_handler: %{
        name: String.to_atom("share_handler_#{addr}"),
        registry_table: %{
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
        },
        share_ttl: 60000
      }
    }
  end
end

configs = Enum.map(12000..12040, fn port -> ConfigBuilder.make_config("#{port}", port, port); end)
pids = Enum.map(configs, fn config -> {:ok, pid} = LAP2.start(config); pid; end)
addresses = Enum.map(configs, fn config -> {config[:router][:lap2_addr], {"127.0.0.1", config[:udp_server][:udp_port]}}; end)

# Register DHT entries
Enum.each(configs, fn config ->
  Enum.each(Enum.take_random(addresses, 25), fn {lap2_addr, ip_addr} -> Router.append_dht(lap2_addr, ip_addr, config.router.name); end)
end)

cfg_0 = Enum.at(configs, 0)
master = cfg_0.master.name
srv_id = "Test service id"
{:ok, stream_id} = Master.register_listener(:stdout, master)
{:ok, secret} = Master.register_service(srv_id, stream_id, master)
Master.discover_proxy(master)
Master.discover_proxy(master)
Master.discover_proxy(master)
Master.setup_introduction_point([srv_id], master)
