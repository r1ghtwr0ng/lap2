defmodule LAP2.Networking.Resolver do
  @moduledoc """
  This module contains helper function for resolving addresses.
  """

  require Logger
  alias LAP2.Networking.Router
  alias LAP2.Utils.Generator
  alias LAP2.Utils.ProtoBuf.QueryHelper

  # ---- Public functions ----
  @doc """
  Build a DHT update query
  """
  @spec build_dht_query() :: Query.t()
  def build_dht_query() do
    # TODO build query
    QueryHelper.build_dht_request_header()
    |> QueryHelper.build_query(Generator.generate_integer(8), <<>>)
  end

  @doc """
  Fetch the DHT from the router
  """
  @spec distribute_dht(Query.t(), atom) :: {:ok, Query.t()} | {:error, :bad_dht}
  def distribute_dht(query, router_name) do
    # TODO fetch DHT from router
    # TODO decide if there is enough entries to distribute
    dht = Router.get_dht(router_name)
    cond do
      map_size(dht) < 10 -> # Insufficient entries
        {:error, :bad_dht}
      true ->
        {:ok, QueryHelper.build_response(query, export_dht(dht))}
    end
  end

  @doc """
  Update the DHT in the router
  """
  @spec update_dht(binary, atom) :: :ok
  def update_dht(dht_data, router_name) do
    # TODO update DHT in router
    import_dht(dht_data)
    |> Enum.each(fn {lap2_addr, ip_addr} ->
      Router.append_dht(lap2_addr, ip_addr, router_name)
    end)
  end

  # ---- Helper functions ----
  @spec resolve_addr(String.t(), map) :: {:ok, {String.t(), non_neg_integer}} | {:error, :not_found}
  def resolve_addr(addr, dht) when is_map_key(dht, addr), do: {:ok, dht[addr]}
  def resolve_addr(_addr, _dht), do: {:error, :not_found}

  # ---- Private Utility Functions ----
  @spec export_dht(map) :: binary
  defp export_dht(dht) do
    Enum.reduce(dht, %{}, fn {lap2_addr, {ip_addr, port}}, acc ->
      Map.put(acc, lap2_addr, [ip_addr, port])
    end)
    |> Jason.encode!()
  end

  @spec import_dht(binary) :: map
  defp import_dht(dht) do
    Jason.decode!(dht)
    |> Enum.reduce(%{}, fn {lap2_addr, [ip_addr, port]}, acc ->
      Map.put(acc, lap2_addr, {ip_addr, port})
    end)
  end
end
