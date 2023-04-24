alias LAP2.Networking.Router
alias LAP2.Networking.Helpers.OutboundPipelines
alias LAP2.Crypto.Helpers.CryptoStructHelper

defmodule ConfigBuilder do
  def make_config(addr, udp_port) do
    %{
      main_supervisor: %{name: String.to_atom("lap2_daemon_#{addr}")},
      task_supervisor: %{max_children: 10, name: String.to_atom("lap2_superv_#{addr}")},
      crypto_manager: %{name: String.to_atom("crypto_manager_#{addr}"),
        identity: "IDENT_#{addr}",
        registry_table: %{
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
        name: :tcp_server,
        queue_interval: 100,
        registry_table: %{
          share_handler: String.to_atom("share_handler_#{addr}"),
          router: String.to_atom("router_#{addr}"),
          main_supervisor: String.to_atom("lap2_daemon_#{addr}"),
          task_supervisor: String.to_atom("lap2_superv_#{addr}"),
          tcp_server: String.to_atom("tcp_server_#{addr}"),
          udp_server: String.to_atom("udp_server_#{addr}"),
          crypto_manager: String.to_atom("crypto_manager_#{addr}")
        },
        req_timeout: 50000,
        tcp_port: 3001
      },
      udp_server: %{
        max_dgram_handlers: 10,
        max_queue_size: 1000,
        name: String.to_atom("udp_server_#{addr}"),
        queue_interval: 100,
        registry_table: %{
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

configs = Enum.map(12000..12010, fn port -> ConfigBuilder.make_config("#{port}", port); end)
pids = Enum.map(configs, fn config -> {:ok, pid} = LAP2.start(config); pid; end)
addresses = Enum.map(configs, fn config -> {config[:router][:lap2_addr], {"127.0.0.1", config[:udp_server][:udp_port]}}; end)

# Register DHT entries
Enum.each(configs, fn config ->
  Enum.each(Enum.take_random(addresses, 5), fn {lap2_addr, ip_addr} -> Router.append_dht(lap2_addr, ip_addr, config.router.name); end)
end)

cfg_0 = Enum.at(configs, 0)
identity_0 = cfg_0.crypto_manager.identity
%{encrypted_request: enc_req} = CryptoStructHelper.gen_init_crypto(identity_0)

current_conf_0 = Router.debug(cfg_0.router.name)
OutboundPipelines.send_proxy_discovery(enc_req, current_conf_0.random_neighbors, 4, cfg_0.router.name)