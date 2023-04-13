defmodule LAP2.Utils.EtsHelper do
  @moduledoc """
  Common helper functions for working with ETS tables.
  """

  @doc """
  Get a value from an ETS table.
  """
  @spec get_value(reference, any) :: {:ok, any} | {:error, :not_found}
  def get_value(table, key) do
    case :ets.lookup(table, key) do
      [{_, value}] -> {:ok, value}
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Insert a value into an ETS table.
  """
  @spec insert_value(reference, any, any) :: :ok | :error
  def insert_value(table, key, value) do
    if :ets.insert(table, {key, value}), do: :ok, else: :error
  end

  @doc """
  Delete a value from an ETS table.
  """
  @spec delete_value(reference, any) :: :ok
  def delete_value(table, key), do: :ets.delete(table, key)
end
