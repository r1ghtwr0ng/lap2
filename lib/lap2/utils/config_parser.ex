defmodule LAP2.Utils.ConfigParser do
    @moduledoc """
    Parses a JSON file into a map.
    """

    @doc """
    Parses a JSON file into a map with atoms as keys.
    """
    @spec parse_json(String.t()) :: map()
    def parse_json(filename) do
      filename
      |> File.read!()
      |> Jason.decode!()
      |> keys_to_atoms()
      |> names_to_atoms()
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

    def names_to_atoms(map) do
      Enum.into(map, %{}, fn
        {:name, v} -> {:name, String.to_atom(v)}
        {k, v} when is_map(v) -> {k, names_to_atoms(v)}
        {k, v} -> {k, v}
      end)
    end
end
