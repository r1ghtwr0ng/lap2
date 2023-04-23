defmodule LAP2.Networking.Resolver do
  require Logger

  @moduledoc """
  This module contains helper function for resolving addresses.
  """

  # ---- Public functions ----
  @doc """
  Build a DHT update query
  """
  @spec build_query(String.t()) :: :ok | :error
  def build_query(addr) do
    # TODO build query
    Logger.info("[+] Resolver: remote lookup for #{addr}")
  end

  # ---- Helper functions ----
  @spec resolve_addr(String.t(), map) :: {:ok, {String.t(), non_neg_integer}} | {:error, :not_found}
  def resolve_addr(addr, dht) when is_map_key(dht, addr), do: {:ok, dht[addr]}
  def resolve_addr(_addr, _dht), do: {:error, :not_found}
end
