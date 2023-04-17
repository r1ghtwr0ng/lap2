defmodule LAP2.Utils.EtsHelper do
  @moduledoc """
  Common helper functions for working with ETS tables.
  """

  @doc """
  Get a value from an ETS table.
  """
  @spec get_value(:ets.tid, any) :: {:ok, any} | {:error, :not_found}
  def get_value(table, key) do
    case :ets.lookup(table, key) do
      [{_, value}] -> {:ok, value}
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Insert a value into an ETS table.
  """
  @spec insert_value(:ets.tid, any, any) :: true
  def insert_value(table, key, value), do: :ets.insert(table, {key, value})

  @doc """
  Delete a value from an ETS table.
  """
  @spec delete_value(:ets.tid, any) :: true
  def delete_value(table, key), do: :ets.delete(table, key)
end
