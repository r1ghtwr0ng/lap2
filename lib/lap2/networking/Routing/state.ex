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
  Evict a clove from the cache.
  """
  @spec evict_clove(map, binary) :: map
  def evict_clove(state, clove_seq) do
    Map.put(state, :clove_cache, Map.delete(state.clove_cache, clove_seq))
  end

  @doc """
  Add a drop rule for the clove_Seq.
  """
  @spec ban_clove(map, binary) :: map
  def ban_clove(state, clove_seq) do
    Map.put(state, :drop_rules, Map.put(state.drop_rules, :clove_seq, {clove_seq, :os.system_time(:millisecond)}))
  end

  @doc """
  Add a clove to the local cache.
  """
  @spec cache_clove(map, {binary, integer}, {binary, integer}, map) :: map
  def cache_clove(%{clove_cache: cache} = state, source, dest, %{seq_num: seq_num, data: data}) do
    cache_entry = %{hash: :erlang.phash2(data), # TODO use xxHash NIF
      data: data,
      prev_hop: source,
      next_hop: dest,
      timestamp: :os.system_time(:millisecond)}
    new_cache = Map.put(cache, seq_num, cache_entry)
    Map.put(state, :clove_cache, new_cache)
  end

  # Add entry to relay table
  @spec add_relay(map, binary, {binary, integer}, {binary, integer}, atom) :: map
  def add_relay(state, relay_seq, relay_1, relay_2, :proxy) do
    # TODO drop unused routes, based on priority values (first introduce priority values in the route struct)
    IO.puts("[+] Added route #{inspect {relay_1, relay_2}} to relay table as proxy")
    data_processor = state.config.data_processor
    relay_entry = %{type: :proxy,
      relays: %{relay_1 => data_processor, relay_2 => data_processor},
      timestamp: :os.system_time(:millisecond)}
    Map.put(state, :relay_routes, Map.put(state.relay_table, relay_seq, relay_entry)) # TODO check if this is correct
  end
  def add_relay(state, relay_seq, relay_1, relay_2, :relay) do
    # TODO drop unused routes, based on priority values (first introduce priority values in the route struct)
    IO.puts("[+] Added route #{inspect {relay_1, relay_2}} to routing table as relay")
    relay_entry = %{type: :relay,
      relays: %{relay_1 => relay_2, relay_2 => relay_1},
      timestamp: :os.system_time(:millisecond)}
    updated_relays = Map.put(state.relay_table, relay_seq, relay_entry)
    Map.put(state, :relay_routes, updated_relays) # TODO check if this is correct
  end

  @doc """
  Get routing information from state
  """
  @spec get_route(map, {binary, integer}, map) :: atom | {atom, {binary, integer} | pid | binary}
  def get_route(state, source, clove) do
    cond do
      drop?(state, source, clove) -> :drop
      true -> handle_clove(state, source, clove)
    end
  end

  def remove_neighbor(state, neighbor) do
    Map.put(state, :rand_neighbors, List.delete(state.rand_neighbors, neighbor))
  end

  # ---- Private handler functions ----
  # Handle proxy discovery clove
  @spec handle_clove(map, {binary, integer}, map) :: atom | {atom, any}
  defp handle_clove(state, _source, %{clove_seq: clove_seq, drop_probab: _, data: data}) do
    case Map.get(state.clove_cache, clove_seq) do
      nil -> {:random_walk, random_neighbor(state)}
      cached_clove -> handle_clove_cache_hit(:erlang.phash2(data), cached_clove)
    end
  end
  # Handle proxy discovery response clove
  defp handle_clove(state, _source, %{clove_seq: clove_seq,  proxy_seq: _, hop_count: _}) do
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
  defp handle_clove(state, source, %{proxy_seq: proxy_seq}) do
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
    IO.puts("[+] Deleting outdated clove cache entries")
    updated_cache = cache
    |> Enum.filter(fn {_clove_seq, %{timestamp: timestamp}} -> timestamp > :os.system_time(:millisecond) - cache_ttl; end)
    |> Map.new()
    Map.put(state, :clove_cache, updated_cache)
  end

  # Get rid of outdated clove cache entries
  @spec clean_relay_table(map) :: map
  defp clean_relay_table(%{relay_routes: relay_routes, config: %{relay_routes_ttl: relay_ttl}} = state) do
    IO.puts("[+] Deleting outdated relay table entries")
    updated_relay_routes = relay_routes
    |> Enum.filter(fn {_relay_seq, %{timestamp: timestamp}} -> timestamp > :os.system_time(:millisecond) - relay_ttl; end)
    |> Map.new()
    Map.put(state, :relay_routes, updated_relay_routes)
  end

  # ---- Clove drop rules ----
  @spec drop?(map, {binary, integer}, map) :: boolean
  defp drop?(state, {ip_addr, _}, %{clove_seq: clove_seq, drop_probab: drop_probab}) do
    can_drop = clove_seq not in state.own_cloves or ip_addr in state.drop_rules.ip_addr
    can_drop and (clove_seq in state.drop_rules.clove_seq or drop_probab > :rand.uniform)
  end
  defp drop?(state, {ip_addr, _}, %{clove_seq: _clove_seq, proxy_seq: proxy_seq}) do
    proxy_seq in state.drop_rules.proxy_seq or ip_addr in state.drop_rules.ip_addr
  end
  defp drop?(state, {ip_addr, _}, %{proxy_seq: proxy_seq}) do
    proxy_seq in state.drop_rules.proxy_seq or ip_addr in state.drop_rules.ip_addr
  end

  # ---- Misc functions ----
  # Select random neighbor
  @spec random_neighbor(map) :: binary
  defp random_neighbor(state), do: Enum.random(state.rand_neighbors)
end
