defmodule LAP2.Utils.ConfigParserTest do
  use ExUnit.Case

  alias LAP2.Utils.ConfigParser

  describe "get_config/1" do
    test "Read config from file" do
      expected_config = %{data_processor: %{name: :data_processor,
        registry_table: %{data_processor: :data_processor,
          main_supervisor: :lap2_deamon,
          router: :router,
          task_supervisor: :lap2_superv,
          tcp_server: :tcp_server,
          udp_server: :udp_server}},
      main_supervisor: %{name: :lap2_deamon},
      router: %{clove_cache_size: 1000,
        clove_cache_ttl: 30000,
        lap2_addr: "test",
        name: :router,
        proxy_limit: 20,
        proxy_policy: true,
        registry_table: %{data_processor: :data_processor,
          main_supervisor: :lap2_deamon,
          router: :router,
          task_supervisor: :lap2_superv,
          tcp_server: :tcp_server,
          udp_server: :udp_server},
        relay_table_size: 5000,
        relay_table_ttl: 1800000},
      task_supervisor: %{max_children: 10, name: :lap2_superv},
      tcp_server: %{max_queue_size: 1000,
        name: :tcp_server,
        queue_interval: 100,
        registry_table: %{data_processor: :data_processor,
          main_supervisor: :lap2_deamon,
          router: :router,
          task_supervisor: :lap2_superv,
          tcp_server: :tcp_server,
          udp_server: :udp_server},
        req_timeout: 50000,
        tcp_port: 3001},
      udp_server: %{max_dgram_handlers: 10,
        max_queue_size: 1000,
        name: :udp_server,
        queue_interval: 100,
        registry_table: %{data_processor: :data_processor,
          main_supervisor: :lap2_deamon,
          router: :router,
          task_supervisor: :lap2_superv,
          tcp_server: :tcp_server,
          udp_server: :udp_server},
        req_timeout: 50000, udp_port: 1447}}

      # Unset environment variable
      System.delete_env("LAP2_TEST_CONFIG_PATH")

      assert ConfigParser.get_config("TEST") == expected_config
    end
  end
end
