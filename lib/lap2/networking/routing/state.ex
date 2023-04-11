defmodule LAP2.Networking.Routing.State do
  @moduledoc """
  Module for managing the state of the routing module.
  """
  require Logger

  # ---- Public functions ----
  @doc """
  Remove outdated entries from the state based on their timestamps.
  """
  @spec clean_state(map) :: map
  def clean_state(state) do
    state
    |> clean_clove_cache()
    |> clean_relay_table()
    #|> RoutingHelper.clean_anon_pool() #TODO implement, might as well refactor the cleaning process too
  end

  @doc """
  Update the cache entry timestamp.
  """
  @spec update_clove_timestamp(map, non_neg_integer) :: map
  def update_clove_timestamp(state, clove_seq) do
    new_cache = Map.update(state.clove_cache, clove_seq, nil, fn entry -> Map.put(entry, :timestamp, :os.system_time(:millisecond)) end)
    Map.put(state, :clove_cache, new_cache)
  end

  @doc """
  Update the relay table entry timestamp.
  """
  @spec update_relay_timestamp(map, non_neg_integer) :: map
  def update_relay_timestamp(state, proxy_seq) do
    new_table = Map.update(state.relay_table, proxy_seq, nil, fn entry -> Map.put(entry, :timestamp, :os.system_time(:millisecond)) end)
    Map.put(state, :relay_table, new_table)
  end

  @doc """
  Add clove to list of own cloves.
  """
  @spec add_own_clove(map, non_neg_integer) :: map
  def add_own_clove(state, clove_seq) do
    Map.put(state, :own_cloves, [clove_seq | state.own_cloves])
  end

  @doc """
  Remove a clove from the list of own cloves.
  """
  @spec delete_own_clove(map, non_neg_integer) :: map
  def delete_own_clove(state, clove_seq) do
    Map.put(state, :own_cloves, List.delete(state.own_cloves, clove_seq))
  end

  @doc """
  Evict a clove from the cache.
  """
  @spec evict_clove(map, non_neg_integer) :: map
  def evict_clove(state, clove_seq) do
    Map.put(state, :clove_cache, Map.delete(state.clove_cache, clove_seq))
  end

  @doc """
  Add a drop rule for the clove_Seq.
  """
  @spec ban_clove(map, non_neg_integer) :: map
  def ban_clove(state, clove_seq) do
    Map.put(state, :drop_rules, Map.put(state.drop_rules, :clove_seq, [clove_seq | state.drop_rules.clove_seq]))
  end

  @doc """
  Add a clove to the local cache.
  """
  @spec cache_clove(map, {binary, integer}, {binary, integer}, Clove) :: map
  def cache_clove(%{clove_cache: cache} = state, source, dest, %Clove{data: data, headers: {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: clove_seq}}}) do
    cache_entry = %{hash: :erlang.phash2(data),
      data: data,
      prev_hop: source,
      next_hop: dest,
      timestamp: :os.system_time(:millisecond)}
    new_cache = Map.put(cache, clove_seq, cache_entry)
    Map.put(state, :clove_cache, new_cache)
  end

  # Add entry to relay table
  @spec add_relay(map, non_neg_integer, {binary, integer}, {binary, integer}, atom) :: map
  def add_relay(state, relay_seq, relay_1, relay_2, :proxy) do
    # TODO drop unused routes, based on priority values (first introduce priority values in the route struct)
    IO.puts("[+] State: Added route #{inspect {relay_1, relay_2}} to relay table as proxy")
    relay_entry = %{type: :proxy,
      relays: %{relay_1 => :share_handler, relay_2 => :share_handler},
      timestamp: :os.system_time(:millisecond)}
    Map.put(state, :relay_table, Map.put(state.relay_table, relay_seq, relay_entry)) # TODO check if this is correct
  end
  def add_relay(state, relay_seq, relay_1, relay_2, :relay) do
    # TODO drop unused routes, based on priority values (first introduce priority values in the route struct)
    IO.puts("[+] State: Added route #{inspect {relay_1, relay_2}} to routing table as relay")
    # TODO fix relay lookup
    relay_entry = %{type: :relay,
      relays: %{relay_1 => relay_2, relay_2 => relay_1},
      timestamp: :os.system_time(:millisecond)}
    updated_relays = Map.put(state.relay_table, relay_seq, relay_entry)
    Map.put(state, :relay_table, updated_relays) # TODO check if this is correct
  end

  @doc """
  Get routing information from state
  """
  @spec get_route(map, {String.t, non_neg_integer}, Clove) :: atom | {atom, {String.t, non_neg_integer} | atom | binary}
  def get_route(state, source, clove) do
    cond do
      drop?(state, source, clove) -> :drop
      true -> handle_clove(state, source, clove)
    end
    |> IO.inspect(label: "[+] State: get_route response")
  end

  @doc """
  Remove a neighbor from the list of random neighbors.
  """
  @spec remove_neighbor(map, String.t) :: map
  def remove_neighbor(state, neighbor) do
    Map.put(state, :random_neighbors, List.delete(state.random_neighbors, neighbor))
  end

  # ---- Private handler functions ----
  # Handle proxy discovery clove
  @spec handle_clove(map, {Strint.t, non_neg_integer}, Clove) :: atom | {atom, any}
  defp handle_clove(state, _source, %Clove{data: data, headers:
  {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: clove_seq}}}) do
    IO.puts("[+] State: Received proxy discovery clove [#{clove_seq}")
    case Map.get(state.clove_cache, clove_seq) do
      nil -> {:random_walk, random_neighbor(state)}
      cached_clove -> handle_clove_cache_hit(:erlang.phash2(data), cached_clove)
    end
  end
  # Handle proxy discovery response clove
  defp handle_clove(state, _source, %Clove{headers:
  {:proxy_response, %ProxyResponseHeader{clove_seq: clove_seq}}}) do
    IO.puts("[+] State: Received proxy response clove [#{clove_seq}")
    cond do
      clove_seq in state.own_cloves -> :recv_discovery
      true ->
        case Map.get(state.clove_cache, clove_seq) do
          nil -> :drop
          cached_clove -> {:discovery_response, {cached_clove.next_hop, cached_clove.prev_hop}}
        end
    end
  end
  # Handle proxy relay clove
  defp handle_clove(state, source, %Clove{headers:
  {:regular_proxy, %RegularProxyHeader{proxy_seq: proxy_seq}}}) do
    IO.puts("[+] State: Received regular proxy clove [#{proxy_seq}")
    case Map.get(state.relay_table, proxy_seq) do
      nil -> :drop
      relay_route -> {:relay, relay_route.relays[source]}
    end
  end

  # ---- Cache handling functions ----
  # Drop duplicate cloves, route to self if new
  @spec handle_clove_cache_hit(integer, map) :: atom
  defp handle_clove_cache_hit(hash, cached_clove) when hash == cached_clove.hash, do: :drop
  defp handle_clove_cache_hit(_hash, _cached_clove), do: :proxy_request

  # ---- State cleaning functions ----
  # Get rid of outdated clove cache entries
  @spec clean_clove_cache(map) :: map
  defp clean_clove_cache(%{clove_cache: cache, config: %{clove_cache_ttl: cache_ttl}} = state) do
    IO.puts("[+] State: Deleting outdated clove cache entries")
    updated_cache = cache
    |> Enum.filter(fn {_clove_seq, %{timestamp: timestamp}} -> timestamp > :os.system_time(:millisecond) - cache_ttl; end)
    |> Map.new()
    Map.put(state, :clove_cache, updated_cache)
  end

  # Get rid of outdated clove cache entries
  @spec clean_relay_table(map) :: map
  defp clean_relay_table(%{relay_table: relay_table, config: %{relay_table_ttl: relay_ttl}} = state) do
    IO.puts("[+] State: Deleting outdated relay table entries")
    updated_relay_table = relay_table
    |> Enum.filter(fn {_relay_seq, %{timestamp: timestamp}} -> timestamp > :os.system_time(:millisecond) - relay_ttl; end)
    |> Map.new()
    Map.put(state, :relay_table, updated_relay_table)
  end

  # ---- Clove drop rules ----
  # Drop rules for proxy discovery cloves
  @spec drop?(map, {String.t, non_neg_integer}, Clove) :: boolean
  defp drop?(state, {ip_addr, _}, %Clove{headers:
  {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: clove_seq, drop_probab: drop_probab}}}) do
    IO.puts("[+] State: Checking drop rules for proxy discovery clove [#{clove_seq}]")
    can_drop = clove_seq not in state.own_cloves
    can_drop and (clove_seq in state.drop_rules.clove_seq or ip_addr in state.drop_rules.ip_addr or drop_probab < :rand.uniform)
  end
  # Drop rules for proxy discovery response cloves
  defp drop?(state, {ip_addr, _}, %Clove{headers:
  {:proxy_response, %ProxyResponseHeader{proxy_seq: proxy_seq}}}) do
    IO.puts("[+] State: Checking drop rules for proxy response clove [#{proxy_seq}]")
    proxy_seq in state.drop_rules.proxy_seq or ip_addr in state.drop_rules.ip_addr
  end
  # Drop rules for proxy relay cloves
  defp drop?(state, {ip_addr, _}, %Clove{headers:
  {:regular_proxy, %RegularProxyHeader{proxy_seq: proxy_seq}}}) do
    IO.puts("[+] State: Checking drop rules for regular proxy clove [#{proxy_seq}]")
    proxy_seq in state.drop_rules.proxy_seq or ip_addr in state.drop_rules.ip_addr
  end

  # ---- Misc functions ----
  # Select random neighbor
  @spec random_neighbor(map) :: binary
  defp random_neighbor(%{random_neighbors: []}), do: nil
  defp random_neighbor(%{random_neighbors: random_neighbors}), do: Enum.random(random_neighbors)
end
