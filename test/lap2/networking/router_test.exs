defmodule LAP2.Networking.RouterTest do
  use ExUnit.Case
  alias LAP2.Networking.Router

  setup do
    config = %{
      name: :router,
      lap2_addr: "127.0.0.1",
      registry_table: :test_table,
      clove_cache_size: 10,
      clove_cache_ttl: 1000,
      relay_table_size: 10,
      relay_table_ttl: 1000,
      proxy_policy: :test_policy,
      proxy_limit: 3
    }

    {:ok, router} = Router.start_link(config)
    {:ok, router: router, config: config}
  end

  describe "accept_proxy/4" do
    test "Accept proxy request and update state", _context do
      # Prepare the necessary data and expected state
      proxy_seq = 1
      node_1 = {"127.0.0.2", 12345}
      node_2 = {"127.0.0.3", 12346}
      Router.accept_proxy(proxy_seq, node_1, node_2, :router)
      # Verify that the state has been updated as expected
      state = Router.debug(:router)
      assert is_map_key(state.relay_table, proxy_seq)
    end
  end

  describe "append_dht/3" do
    test "Update the DHT with a new entry in the state", _context do
      # Prepare the necessary data and expected state
      lap2_addr = "lap2_addr_example"
      dest = {"127.0.0.2", 12345}
      Router.append_dht(lap2_addr, dest, :router)
      # Verify that the state has been updated as expected
      state = Router.debug(:router)
      assert state.routing_table == %{lap2_addr => dest}
    end
  end

  describe "update_config/2" do
    test "Update the configuration in the state", context do
      # Prepare the necessary data and expected state
      new_config =
        context.config
        |> Map.put(:proxy_limit, 5)
        |> Map.delete(:name)

      Router.update_config(new_config, :router)

      # Verify that the state has been updated as expected
      state = Router.debug(:router)
      assert state.config == new_config
    end
  end

  describe "debug/1" do
    test "Inspect the router state", _context do
      state = Router.debug(:router)

      # Verify that the output is a map
      assert is_map(state)
    end
  end
end
