defmodule LAP2.Utils.ConfigParser do
  @moduledoc """
  Parses a JSON file into a map.
  """

  @doc """
  Parses a JSON file into a map.
  """
  @spec get_config(String.t()) :: map()
  def get_config(env) do
    env
    |> get_config_path()
    |> parse_json()
    |> gen_registry_table()
  end

  # ---- Private Functions ----
  # Parses a JSON file into a map with atoms as keys.
  @spec parse_json(String.t()) :: map()
  defp parse_json(filename) do
    filename
    |> File.read!()
    |> Jason.decode!()
    |> keys_to_atoms()
    |> names_to_atoms()
  end

  # Generate the registry table and add it to the config.
  defp gen_registry_table(config) do
    registry_table =
      Enum.reduce(config, %{}, fn
        {k, %{name: name}}, acc -> Map.put(acc, k, name)
        _, acc -> acc
      end)

    add_registry_table(config, registry_table)
  end

  # Recursively adds the registry table to the appropriate fields in the config map.
  @spec add_registry_table(map, map) :: map
  defp add_registry_table(config, registry_table) do
    Enum.into(config, %{}, fn
      {:registry_table, _} -> {:registry_table, registry_table}
      {k, v} when is_map(v) -> {k, add_registry_table(v, registry_table)}
      {k, v} -> {k, v}
    end)
  end

  # Function for recursively converting a map's keys to atoms.
  @spec keys_to_atoms(map) :: map
  defp keys_to_atoms(map) do
    Enum.into(map, %{}, fn
      {k, v} when is_map(v) -> {String.to_atom(k), keys_to_atoms(v)}
      {k, v} -> {String.to_atom(k), v}
    end)
  end

  # Function for recursively converting the config names to atoms.
  @spec names_to_atoms(map) :: map
  defp names_to_atoms(map) do
    Enum.into(map, %{}, fn
      {:name, v} -> {:name, String.to_atom(v)}
      {k, v} when is_map(v) -> {k, names_to_atoms(v)}
      {k, v} -> {k, v}
    end)
  end

  # Get the config path based on the environment, default to DEBUG if not PROD
  @spec get_config_path(String.t()) :: String.t()
  defp get_config_path("PROD"),
    do: System.get_env("LAP2_PROD_CONFIG_PATH") || "./config/prod_config.json"

  defp get_config_path(_),
    do: System.get_env("LAP2_DEBUG_CONFIG_PATH") || "./config/debug_config.json"
end
