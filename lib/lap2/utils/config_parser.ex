defmodule LAP2.Utils.ConfigParser do
  @moduledoc """
  Parses a JSON file into a map.
  """

  alias LAP2.Utils.JsonUtils

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
    |> JsonUtils.parse_json()
    |> JsonUtils.keys_to_atoms()
    |> JsonUtils.values_to_atoms(:name)
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

  # Get the config path based on the environment, default to DEBUG if not PROD
  @spec get_config_path(String.t()) :: String.t()
  defp get_config_path("PROD"),
    do: System.get_env("LAP2_PROD_CONFIG_PATH") || "./config/prod_config.json"

  defp get_config_path(_),
    do: System.get_env("LAP2_DEBUG_CONFIG_PATH") || "./config/debug_config.json"
end
