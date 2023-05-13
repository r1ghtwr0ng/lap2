defmodule LAP2.Utils.Generator do
  @moduledoc """
  This module is used to generate various secure tokens.
  """

  @doc """
  Generate a random hexadecimal string of a given byte length
  """
  @spec generate_hex(integer) :: String.t()
  def generate_hex(byte_length) do
    :crypto.strong_rand_bytes(byte_length)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Generate a random non-negative integer value of a given byte length
  """
  @spec generate_integer(integer) :: integer
  def generate_integer(byte_length) do
    :crypto.strong_rand_bytes(byte_length)
    |> :binary.decode_unsigned()
  end

  @doc """
  Generate a random float value between two given values
  """
  @spec generate_float(float, float) :: float
  def generate_float(min, max) do
    :rand.uniform() * (max - min) + min
  end
end
