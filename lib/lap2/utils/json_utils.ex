defmodule LAP2.Utils.JsonUtils do
  @moduledoc """
  A collection of functions for working with JSON.
  """

  require Logger

  @doc """
  Parses a JSON file into a map.
  """
  @spec parse_json(binary) :: map()
  def parse_json(json) do
    case Jason.decode(json) do
      {:ok, map} -> map
      {:error, _} -> Logger.error("Invalid JSON file")
        %{}
    end
  end

  @doc """
  Function for recursively converting a map's keys to atoms.
  """
  @spec keys_to_atoms(map) :: map
  def keys_to_atoms(map) do
    Enum.into(map, %{}, fn
      {k, v} when is_map(v) -> {String.to_atom(k), keys_to_atoms(v)}
      {k, v} -> {String.to_atom(k), v}
    end)
  end

  @doc """
  Function for recursively converting the config names to atoms.
  """
  @spec values_to_atoms(map, atom) :: map
  def values_to_atoms(map, key) do
    Enum.into(map, %{}, fn
      {^key, v} -> {key, String.to_atom(v)}
      {k, v} when is_map(v) -> {k, values_to_atoms(v, key)}
      {k, v} -> {k, v}
    end)
  end
end
