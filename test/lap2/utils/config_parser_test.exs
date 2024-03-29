defmodule LAP2.Utils.ConfigParserTest do
  use ExUnit.Case

  alias LAP2.Utils.ConfigParser

  describe "get_config/1" do
    test "Read config from file" do
      expected_config = %{
        crypto_manager: %{name: :crypto_manager,
        identity: "IDENTITY",
        registry_table: %{
          conn_supervisor: :conn_supervisor,
          master: :master,
          proxy_manager: :proxy_manager,
          main_supervisor: :lap2_deamon,
          router: :router,
          share_handler: :share_handler,
          task_supervisor: :lap2_superv,
          tcp_server: :tcp_server,
          udp_server: :udp_server,
          crypto_manager: :crypto_manager
        }},
        conn_supervisor: %{
          name: :conn_supervisor,
          registry_table: %{
            conn_supervisor: :conn_supervisor,
            master: :master,
            proxy_manager: :proxy_manager,
            main_supervisor: :lap2_deamon,
            router: :router,
            share_handler: :share_handler,
            task_supervisor: :lap2_superv,
            tcp_server: :tcp_server,
            udp_server: :udp_server,
            crypto_manager: :crypto_manager
          },
          max_service_providers: 10
        },
        master: %{
          name: :master,
          registry_table: %{
            conn_supervisor: :conn_supervisor,
            master: :master,
            proxy_manager: :proxy_manager,
            main_supervisor: :lap2_deamon,
            router: :router,
            share_handler: :share_handler,
            task_supervisor: :lap2_superv,
            tcp_server: :tcp_server,
            udp_server: :udp_server,
            crypto_manager: :crypto_manager
          }
        },
        main_supervisor: %{name: :lap2_deamon},
        proxy_manager: %{
          name: :proxy_manager,
          registry_table: %{
            conn_supervisor: :conn_supervisor,
            master: :master,
            proxy_manager: :proxy_manager,
            main_supervisor: :lap2_deamon,
            router: :router,
            share_handler: :share_handler,
            task_supervisor: :lap2_superv,
            tcp_server: :tcp_server,
            udp_server: :udp_server,
            crypto_manager: :crypto_manager
          },
          clove_casts: 32,
          max_hops: 25,
          min_hops: 3,
          proxy_limit: 25,
          proxy_ttl: 60000
        },
        router: %{
          clove_cache_size: 1000,
          clove_cache_ttl: 30_000,
          lap2_addr: "test",
          name: :router,
          proxy_limit: 20,
          proxy_policy: true,
          registry_table: %{
            conn_supervisor: :conn_supervisor,
            master: :master,
            proxy_manager: :proxy_manager,
            main_supervisor: :lap2_deamon,
            router: :router,
            share_handler: :share_handler,
            task_supervisor: :lap2_superv,
            tcp_server: :tcp_server,
            udp_server: :udp_server,
            crypto_manager: :crypto_manager
          },
          relay_table_size: 5000,
          relay_table_ttl: 1_800_000
        },
        share_handler: %{
          name: :share_handler,
          registry_table: %{
            conn_supervisor: :conn_supervisor,
            master: :master,
            proxy_manager: :proxy_manager,
            main_supervisor: :lap2_deamon,
            router: :router,
            share_handler: :share_handler,
            task_supervisor: :lap2_superv,
            tcp_server: :tcp_server,
            udp_server: :udp_server,
            crypto_manager: :crypto_manager
          },
          share_ttl: 60_000
        },
        task_supervisor: %{max_children: 10, name: :lap2_superv},
        tcp_server: %{
          max_queue_size: 1000,
          name: :tcp_server,
          queue_interval: 100,
          registry_table: %{
            conn_supervisor: :conn_supervisor,
            master: :master,
            proxy_manager: :proxy_manager,
            main_supervisor: :lap2_deamon,
            router: :router,
            share_handler: :share_handler,
            task_supervisor: :lap2_superv,
            tcp_server: :tcp_server,
            udp_server: :udp_server,
            crypto_manager: :crypto_manager
          },
          req_timeout: 50_000,
          tcp_port: 3001
        },
        udp_server: %{
          max_dgram_handlers: 10,
          max_queue_size: 1000,
          name: :udp_server,
          queue_interval: 100,
          registry_table: %{
            conn_supervisor: :conn_supervisor,
            master: :master,
            proxy_manager: :proxy_manager,
            main_supervisor: :lap2_deamon,
            router: :router,
            share_handler: :share_handler,
            task_supervisor: :lap2_superv,
            tcp_server: :tcp_server,
            udp_server: :udp_server,
            crypto_manager: :crypto_manager
          },
          req_timeout: 50_000,
          udp_port: 1447
        }
      }

      # Unset environment variable
      System.delete_env("LAP2_TEST_CONFIG_PATH")

      assert ConfigParser.get_config("TEST") == expected_config
    end
  end
end
