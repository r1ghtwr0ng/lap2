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
        |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
    end
end
