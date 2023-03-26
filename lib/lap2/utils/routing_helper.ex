defmodule LAP2.Utils.RoutingHelper do
  @moduledoc """
  Helper functions for routing packets.
  """
  require Logger

  # ---- Public functions ----
  # TODO write a function that moves the entries from clove_cache to local_cloves and cleans up the clove_cache
  def get_route(state, source, %{seq_num: seq_num, checksum: checksum}) do
    IO.puts("[+] Getting route")

    case state_lookup(seq_num, state.local_cloves) do
      {:map_hit, checksums} ->
        handle_local_cloves_hit(checksum, checksums)

      {:map_miss, _} ->
        case state_lookup(seq_num, state.clove_cache) do
          {:map_hit, cached} -> handle_cache_hit(cached, checksum)
          {:map_miss, _} -> handle_cache_miss(source, state)
        end
    end
  end

  # Deliver the data to the data processing process
  def deliver_data([], _seq_num, _receiver), do: :ok
  def deliver_data([data | tail], seq_num, receiver) do
    IO.puts("[+] Delivering data")
    # TODO lookup global process naming rather than PID (in case of crash)
    send(receiver, {:clove, data, seq_num})
    deliver_data(tail, seq_num, receiver)
  end

  # ---- Cache handling functions ----
  # Drop duplicate cloves, route to self if new
  defp handle_local_cloves_hit(checksum, checksums) do
    if Enum.member?(checksums, checksum) do
      IO.puts("[+] Local clove duplicate, dropping packet")
      :drop
    else
      IO.puts("[+] New clove, routing to self")
      :local_exists
    end
  end

  # Perform cache hit handling by checking if checksum matches
  defp handle_cache_hit(cached, checksum) do
    if cached.checksum == checksum do
      IO.puts("[+] Clove duplicate, dropping packet")
      :drop
    else
      IO.puts("[+] Clove cache hit, routing to self")
      :local_new
    end
  end

  # Perform cache miss handling by doing a lookup source in relay routes map
  # If found, relay as described, otherwise route to random neighbor
  defp handle_cache_miss(source, state) do
    case state_lookup(source, state.relay_routes) do
      {:map_hit, dest} ->
        IO.puts("[+] Relay route hit, routing to #{dest}")
        {:remote, dest}

      {:map_miss, _} ->
        IO.puts("[+] Relay route miss, routing to random neighbor")
        {:remote, random_neighbor(state)}
    end
  end
  def add_route(state, source, dest) do
    # TODO drop unused routes, based on priority values (first introduce priority values in the route struct)
    IO.puts("[+] Added route #{inspect {source, dest}} to routing table")
    timestamp = :os.system_time(:millisecond)
    updated_relays = state.relay_routes
    |> Map.put(source, %{dest: dest, timestamp: timestamp}) # Forward relay route
    |> Map.put(dest, %{dest: source, timestamp: timestamp}) # Backward relay route
    Map.put(state, :relay_routes, updated_relays) # TODO check if this is correct
  end

  # Get rid of outdated clove cache entries
  def clean_relay_routes(%{relay_routes: relay_routes, config: %{relay_routes_ttl: relay_ttl}} = state) do
    IO.puts("[+] Deleting outdated clove cache entries")
    updated_relay_routes = relay_routes
    |> Enum.filter(fn {_seq_num, %{timestamp: timestamp}} -> timestamp > :os.system_time(:millisecond) - relay_ttl; end)
    |> Map.new()
    Map.put(state, :relay_routes, updated_relay_routes)
  end

  @doc """
  Add clove to clove_cache in the state
  """
  def cache_clove(%{clove_cache: cache} = state, %{seq_num: seq_num, checksum: checksum, data: data}) do
    IO.puts("[+] Caching clove clove #{seq_num}")
    new_cache = Map.put(cache, seq_num, %{timestamp: :os.system_time(:millisecond), data: data, checksum: checksum})
    Map.put(state, :clove_cache, new_cache)
  end

  # Get rid of outdated clove cache entries
  def clean_clove_cache(%{clove_cache: cache, config: %{clove_cache_ttl: cache_ttl}} = state) do
    IO.puts("[+] Deleting outdated clove cache entries")
    updated_cache = cache
    |> Enum.filter(fn {_seq_num, %{timestamp: timestamp}} -> timestamp > :os.system_time(:millisecond) - cache_ttl; end)
    |> Map.new()
    Map.put(state, :clove_cache, updated_cache)
  end

  @doc """
  Migrate clove from clove_cache to local_cloves
  """
  def migrate_clove(state, seq_num) do
    IO.puts("[+] Adding clove #{inspect seq_num} to local clove cache")
    %{checksum: checksum} = state.local_cloves[seq_num]

    # Evict cloves from cache
    state
    |> add_local_clove(seq_num, checksum)
    |> evict_clove_cache(seq_num)
  end

  # Get rid of clove from local clove cache
  def delete_local_clove(state, seq_num) do
    IO.puts("[+] Deleting clove #{seq_num} from local clove cache")
    Map.put(state, :local_cloves, Map.delete(state.local_cloves, seq_num))
  end

  # ---- Update state caches ----
  def add_local_clove(state, seq_num, checksum) do
    IO.puts("[+] Adding clove #{inspect seq_num} to local clove cache")
    updated_local = cond do
      Map.has_key?(state.local_cloves, seq_num) ->
        Map.put(state.local_cloves, seq_num, [checksum | state.local_cloves[seq_num]])
      true ->
        Map.put(state.local_cloves, seq_num, [checksum])
    end
    Map.put(state, :local_cloves, updated_local)
  end

  # Get rid of cached clove by seq_num
  defp evict_clove_cache(state, seq_num) do
    IO.puts("[+] Deleting clove #{seq_num} from cache")
    Map.put(state, :clove_cache, Map.delete(state.clove_cache, seq_num))
  end

  # ---- State lookup functions ----
  # Return value from state table if key exists
  defp state_lookup(key, state_table) when is_map_key(state_table, key) do
    IO.puts("[+] Hashmap lookup hit")
    {:map_hit, state_table[key]}
  end

  # Map lookup miss
  defp state_lookup(_key, _state_table) do
    IO.puts("[+] Hashmap lookup miss")
    {:map_miss, nil}
  end

  # Select random neighbor
  defp random_neighbor(_dht) do
    # TODO select random neighbor, set appropriate port
    dest = {"127.0.0.1", 6666}
    IO.puts("[+] Selected random neighbor #{inspect dest}")
    {:remote, dest}
  end
end
