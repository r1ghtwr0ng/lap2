defmodule LAP2.Utils.RoutingHelper do
  @moduledoc """
  Helper functions for routing packets.
  """
  require Logger

  # ---- Public functions ----
  def put_route(%{seq_num: seq_num, checksum: checksum} = packet, state) do
    IO.puts("[+] Putting route")

    # TODO update clove cache
    # TODO update relay routes

    # TODO update routing table
    # TODO update DHT

    # TODO return new state
    state
  end

  def get_route(%{seq_num: seq_num, checksum: checksum} = packet, state) do
    IO.puts("[+] Getting route")

    case state_lookup(seq_num, state.clove_cache) do
      {:map_hit, cached} -> handle_cache_hit(cached, checksum)
      {:map_miss, _} -> handle_cache_miss(seq_num, state)
      _ -> {:drop, nil}
    end
  end

  # ---- Cache handling functions ----
  defp handle_cache_hit(cached, checksum) do
    if cached.checksum == checksum do
      IO.puts("[+] Clove duplicate, dropping packet")
      {:drop, nil}
    else
      IO.puts("[+] Clove cache hit, routing to self")
      {:local, self()}
    end
  end

  defp handle_cache_miss(seq_num, state) do
    case state_lookup(seq_num, state.relay_routes) do
      {:map_hit, dest} ->
        IO.puts("[+] Relay route hit, routing to #{dest}")
        {:remote, dest}

      {:map_miss, _} ->
        IO.puts("[+] Relay route miss, routing to random neighbor")
        {:remote, random_neighbor(state)}
    end
  end

  # ---- State lookup functions ----
  defp state_lookup(key, state_table) when is_map_key(state_table, key) do
    IO.puts("[+] Hashmap lookup hit")
    {:map_hit, state_table[key]}
  end

  defp state_lookup(_key, _state_table) do
    IO.puts("[+] Hashmap lookup miss")
    {:map_miss, nil}
  end

  # Select random neighbor
  defp random_neighbor(state) do
    # TODO select random neighbor
    dest = {"127.0.0.1", 6666}
    IO.puts("[+] Selected random neighbor #{inspect dest}")
    {:remote, dest}
  end

  # ---- State update functions ----
  def add_route(state, source, dest) do
    # TODO drop unused routes, based on priority values (first introduce priority values in the route struct)
    IO.puts("[+] Added route #{inspect route} to routing table")
    timestamp = :os.system_time(:millisecond)
    updated_relays = state.relay_routes
    |> Map.put(source, %{dest: dest, timestamp: timestamp}) # Forward relay route
    |> Map.put(dest, %{dest: source, timestamp: timestamp}) # Backward relay route
    Map.put(state, :relay_routes, updated_relays) # TODO check if this is correct
  end

  # Get rid of outdated clove cache entries
  def clean_relay_routes(%{relay_routes: relay_routes, config: %{relay_routes_ttl: relay_ttl}} = state) do
    IO.puts("[+] Deleting outdated clove cache entries")
    Map.put(state, relay_routes:, Map.drop(relay_routes, fn {_seq_num, relay_data} ->
      relay_data.timestamp < :os.system_time(:millisecond) - relay_ttl; end))
  end

  # Add clove to cache
  def cache_clove(%{} = state, %{seseq_num, clove}) do
    IO.puts("[+] Caching clove clove #{seq_num}")
    timestamp = :os.system_time(:millisecond)
    Map.put(cache, seq_num, %{timestamp: timestamp, data: clove})
  end

  # Get rid of outdated clove cache entries
  def clean_clove_cache(%{clove_cache: cache, config: %{clove_cache_ttl: cache_ttl}} = state) do
    IO.puts("[+] Deleting outdated clove cache entries")
    Map.put(state, clove_cache:, Map.drop(cache, fn {_seq_num, clove} ->
      clove.timestamp < :os.system_time(:millisecond) - cache_ttl; end))
  end

  # Get rid of cached clove by seq_num
  def del_clove(state, seq_num) do
    IO.puts("[+] Deleting clove #{seq_num} from cache")
    Map.put(state, :clove_cache, Map.delete(state.clove_cache, seq_num))
  end
end
