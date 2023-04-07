defmodule LAP2.Crypto.Padding.PKCS7 do
  @moduledoc """
  PKCS7 padding and unpadding.
  """

  @doc """
  Pad the given data to the block size of 16.
  """
  @spec pad(binary, non_neg_integer) :: binary
  def pad(data, len) do
    padding_length = len - rem(byte_size(data), len)
    padding = String.duplicate(<<padding_length>>, padding_length)
    data <> padding
  end

  @doc """
  Unpad the given data.
  """
  @spec unpad(binary) :: binary
  def unpad(data) do
    last_byte = byte_size(data) - 1
    padding_length = :binary.at(data, last_byte)
    :binary.part(data, 0, byte_size(data) - padding_length)
  end
end
