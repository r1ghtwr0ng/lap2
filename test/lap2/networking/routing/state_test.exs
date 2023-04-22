defmodule LAP2.Networking.Routing.StateTest do
  use ExUnit.Case
  alias LAP2.Networking.Routing.State

  @valid_state %{
    own_cloves: [],
    clove_cache: %{},
    drop_rules: %{clove_seq: [], ip_addr: [], proxy_seq: []},
    routing_table: %{},
    relay_table: %{
      2 => %{relays: %{{"1.2.3.4", 1234} => :share_handler, {"1.1.1.1", 4444} => :share_handler}},
      timestamp: :os.system_time(:millisecond),
      type: :proxy
    },
    random_neighbors: [],
    config: %{
      clove_cache_ttl: 60_000,
      relay_table_ttl: 60_000
    }
  }

  describe "add_own_clove/2" do
    test "Add a clove_seq to the list of own cloves" do
      clove_seq = 1
      new_state = State.add_own_clove(@valid_state, clove_seq)
      assert new_state.own_cloves == [clove_seq]
    end
  end

  describe "clean_state/1" do
    test "Remove outdated entries from state" do
      # Set up an outdated state
      outdated_state = %{
        @valid_state
        | clove_cache: %{1 => %{timestamp: :os.system_time(:millisecond) - 61_000}},
          relay_table: %{
            1 => %{
              relays: %{{"1.2.3.4", 1234} => :share_handler, {"1.1.1.1", 4444} => :share_handler},
              timestamp: :os.system_time(:millisecond) - 61_000,
              type: :proxy
            }
          }
      }

      cleaned_state = State.clean_state(outdated_state)

      assert cleaned_state.clove_cache == %{}
      assert cleaned_state.relay_table == %{}
    end

    test "Leave valid entries in state" do
      # Set up a valid state
      valid_state = %{
        @valid_state
        | clove_cache: %{2 => %{timestamp: :os.system_time(:millisecond)}},
          relay_table: %{
            2 => %{
              relays: %{{"1.2.3.4", 1234} => :share_handler, {"1.1.1.1", 4444} => :share_handler},
              timestamp: :os.system_time(:millisecond),
              type: :proxy
            }
          }
      }

      cleaned_state = State.clean_state(valid_state)

      assert cleaned_state.clove_cache == valid_state.clove_cache
      assert cleaned_state.relay_table == valid_state.relay_table
    end
  end

  describe "delete_own_clove/2" do
    test "Remove a clove_seq from the list of own cloves" do
      clove_seq = 2
      new_state = State.delete_own_clove(@valid_state, clove_seq)
      assert new_state.own_cloves == []
    end
  end

  describe "evict_clove/2" do
    test "Remove a clove from the cache" do
      state = %{
        @valid_state
        | clove_cache: %{
            2 => %{
              hash: :erlang.phash2("Test data"),
              data: "Test data",
              prev_hop: {"10.10.10.1", 1111},
              next_hop: {"10.10.10.2", 2222},
              timestamp: :os.system_time(:millisecond)
            }
          }
      }

      clove_seq = 2
      new_state = State.evict_clove(state, clove_seq)
      assert new_state.clove_cache == %{}
    end
  end

  describe "ban_clove/2" do
    test "Add a drop rule for the clove_seq" do
      clove_seq = 1
      new_state = State.ban_clove(@valid_state, clove_seq)
      assert 1 in new_state.drop_rules.clove_seq
    end
  end

  describe "cache_clove/4" do
    test "Add a clove to the local cache" do
      source = {"1.2.3.4", 1234}
      dest = {"127.0.0.1", 5678}
      data = "data"
      clove_seq = 1
      proxy_discovery_header = %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: 0.5}
      clove = %Clove{data: data, headers: {:proxy_discovery, proxy_discovery_header}}

      new_state = State.cache_clove(@valid_state, source, dest, clove)

      assert is_map_key(new_state.clove_cache, clove_seq)
      assert new_state.clove_cache[clove_seq].data == data
      assert new_state.clove_cache[clove_seq].prev_hop == source
      assert new_state.clove_cache[clove_seq].next_hop == dest
    end
  end

  describe "add_proxy_relay/3" do
    test "Add one relay" do
      relay_seq = 1
      relay = {"1.2.3.4", 1234}
      state = %{@valid_state |
      routing_table: %{"NODE_1" => relay}}
      new_state = State.add_proxy_relay(state, relay_seq, relay)

      assert is_map_key(new_state.relay_table, relay_seq)
      assert new_state.relay_table[relay_seq].type == :proxy

      assert new_state.relay_table[relay_seq].relays == %{relay => :share_handler}
    end

    test "Add multiple relays" do
      relay_seq = 1
      relay_1 = {"1.2.3.4", 1234}
      relay_2 = {"127.0.0.1", 5678}
      relay_3 = {"0.0.0.0", 5678}

      state = %{@valid_state |
      routing_table: %{"NODE_1" => relay_1, "NODE_2" => relay_2, "NODE_3" => relay_3}}

      expected_map = %{relay_1 => :share_handler,
        relay_2 => :share_handler,
        relay_3 => :share_handler
      }

      new_state = State.add_proxy_relay(state, relay_seq, relay_1)
      |> State.add_proxy_relay(relay_seq, relay_2)
      |> State.add_proxy_relay(relay_seq, relay_3)

      assert is_map_key(new_state.relay_table, relay_seq)
      assert new_state.relay_table[relay_seq].type == :proxy
      assert new_state.relay_table[relay_seq].relays == expected_map
    end
  end

  describe "add_relay/4" do
    test "Add a relay route" do
      relay_seq = 1
      relay_1 = {"1.2.3.4", 1234}
      relay_2 = {"127.0.0.1", 5678}
      state = %{@valid_state |
      routing_table: %{"NODE_1" => relay_1, "NODE_2" => relay_2}}
      new_state = State.add_relay(state, relay_seq, relay_1, relay_2)

      assert is_map_key(new_state.relay_table, relay_seq)
      assert new_state.relay_table[relay_seq].type == :relay
      assert new_state.relay_table[relay_seq].relays == %{relay_1 => relay_2, relay_2 => relay_1}
    end
  end

  describe "get_route/3" do
    test "Return random walk" do
      state = %{@valid_state | random_neighbors: ["NEIGHBOR_ADDR"]}
      source = {"127.0.0.1", 1234}
      data = "data"
      clove_seq = 1
      header = %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: 1.0}
      clove = %Clove{data: data, headers: {:proxy_discovery, header}, checksum: CRC.crc_32(data)}

      assert State.get_route(state, source, clove) == {:random_walk, "NEIGHBOR_ADDR"}
    end

    test "Return proxy request" do
      state = %{
        @valid_state
        | clove_cache: %{
            1 => %{
              hash: :erlang.phash2("Test data"),
              data: "Test data",
              prev_hop: {"10.10.10.1", 1111},
              next_hop: {"10.10.10.2", 2222},
              timestamp: :os.system_time(:millisecond)
            }
          }
      }

      source = {"1.2.3.4", 1234}
      data = "Non-duplicate data"
      clove_seq = 1
      header = %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: 1.0}
      clove = %Clove{data: data, headers: {:proxy_discovery, header}, checksum: CRC.crc_32(data)}

      assert State.get_route(state, source, clove) == :proxy_request
    end

    test "Return proxy response" do
      state = %{@valid_state | own_cloves: [2]}
      source = {"1.2.3.4", 1234}
      data = "data"
      clove_seq = 2
      header = %ProxyResponseHeader{clove_seq: clove_seq, proxy_seq: 0, hop_count: 0}
      clove = %Clove{data: data, headers: {:proxy_response, header}, checksum: CRC.crc_32(data)}

      assert State.get_route(state, source, clove) == :recv_discovery
    end

    test "Return proxy response relay" do
      state = %{
        @valid_state
        | clove_cache: %{
            2 => %{
              hash: :erlang.phash2("Test data"),
              data: "Test data",
              prev_hop: {"10.10.10.1", 1111},
              next_hop: {"10.10.10.2", 2222},
              timestamp: :os.system_time(:millisecond)
            }
          }
      }

      source = {"10.10.10.2", 2222}
      data = "data"
      clove_seq = 2
      header = %ProxyResponseHeader{clove_seq: clove_seq, proxy_seq: 1, hop_count: 0}
      clove = %Clove{data: data, headers: {:proxy_response, header}, checksum: CRC.crc_32(data)}

      expected_route = {:discovery_response, {{"10.10.10.2", 2222}, {"10.10.10.1", 1111}}}
      assert State.get_route(state, source, clove) == expected_route
    end

    test "Return relay table entry" do
      state = %{
        @valid_state
        | relay_table: %{
            2 => %{
              type: :proxy,
              relays: %{
                {"10.10.10.1", 1111} => {"10.10.10.2", 2222},
                {"10.10.10.2", 2222} => {"10.10.10.1", 1111}
              },
              timestamp: :os.system_time(:millisecond)
            }
          }
      }

      source = {"10.10.10.2", 2222}
      data = "data"
      proxy_seq = 2
      header = %RegularProxyHeader{proxy_seq: proxy_seq}
      clove = %Clove{data: data, headers: {:regular_proxy, header}, checksum: CRC.crc_32(data)}

      assert State.get_route(state, source, clove) == {:relay, {"10.10.10.1", 1111}}
    end

    test "Drop duplicate clove" do
      state = %{
        @valid_state
        | clove_cache: %{
            2 => %{
              hash: :erlang.phash2("Test data"),
              data: "Test data",
              prev_hop: {"10.10.10.1", 1111},
              next_hop: {"10.10.10.2", 2222},
              timestamp: :os.system_time(:millisecond)
            }
          }
      }

      source = {"10.10.10.1", 1111}
      data = "Test data"
      clove_seq = 2
      proxy_discovery_header = %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: 1.0}

      clove = %Clove{
        data: data,
        headers: {:proxy_discovery, proxy_discovery_header},
        checksum: CRC.crc_32(data)
      }

      assert State.get_route(state, source, clove) == :drop
    end

    test "Drop by clove_seq" do
      state = %{@valid_state | drop_rules: %{clove_seq: [1], ip_addr: [], proxy_seq: []}}
      source = {"1.2.3.4", 1234}
      data = "data"
      clove_seq = 1
      proxy_discovery_header = %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: 1.0}

      clove = %Clove{
        data: data,
        headers: {:proxy_discovery, proxy_discovery_header},
        checksum: CRC.crc_32(data)
      }

      assert State.get_route(state, source, clove) == :drop
    end

    test "Drop by proxy_seq" do
      state = %{@valid_state | drop_rules: %{clove_seq: [], ip_addr: [], proxy_seq: [3]}}
      source = {"1.2.3.4", 1234}
      data = "data"
      proxy_seq = 3
      proxy_discovery_header = %RegularProxyHeader{proxy_seq: proxy_seq}

      clove = %Clove{
        data: data,
        headers: {:regular_proxy, proxy_discovery_header},
        checksum: CRC.crc_32(data)
      }

      assert State.get_route(state, source, clove) == :drop
    end

    test "Drop by source address" do
      state = %{@valid_state | drop_rules: %{clove_seq: [], ip_addr: ["1.2.3.4"], proxy_seq: []}}
      source = {"1.2.3.4", 1234}
      data = "data"
      clove_seq = 1
      proxy_discovery_header = %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: 1.0}

      clove = %Clove{
        data: data,
        headers: {:proxy_discovery, proxy_discovery_header},
        checksum: CRC.crc_32(data)
      }

      assert State.get_route(state, source, clove) == :drop
    end

    test "Drop low probability clove" do
      source = {"1.2.3.4", 1234}
      data = "data"
      clove_seq = 1
      proxy_discovery_header = %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: 0.0}

      clove = %Clove{
        data: data,
        headers: {:proxy_discovery, proxy_discovery_header},
        checksum: CRC.crc_32(data)
      }

      assert State.get_route(@valid_state, source, clove) == :drop
    end
  end

  describe "remove_neighbor/2" do
    test "Remove a neighbor from the list of random neighbors" do
      neighbor = "NEIGHBOR_ADDR"
      new_state = State.remove_neighbor(@valid_state, neighbor)

      assert new_state.random_neighbors == []
    end
  end
end
