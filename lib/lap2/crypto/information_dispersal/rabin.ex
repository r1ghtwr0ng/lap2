defmodule LAP2.Crypto.InformationDispersal.Rabin do
  @moduledoc """
  Rabin's Information Dispersal Algorithm, used to split and reconstruct data.
  """
  @prime 257

  require Logger
  alias LAP2.Math.Matrix
  alias LAP2.Crypto.Padding.PKCS7

  # ---- Public Functions ----
  @doc """
  Split the data into the given number of shares.
  n is the number of shares to split the data into.
  m is the number of shares required to reconstruct the data (threshold).
  """
  @spec split(binary, non_neg_integer, non_neg_integer) :: list(binary)
  def split(data, n, m) do
    # Pad the data to be a multiple of m
    padded_data = PKCS7.pad(data, m)

    # Split F into n chunks of size m
    byte_chunks = padded_data
    |> :erlang.binary_to_list()
    |> Enum.chunk_every(m)

    # Generate the Vandermonde matrix
    vand_matrix = Matrix.gen_vandermonde_matrix(n, m, @prime)

    # Calculate the shares
    Matrix.matrix_dot_product(vand_matrix, byte_chunks, @prime)
    |> Enum.map(fn chunk -> :erlang.list_to_binary(chunk); end)
  end

  @spec reconstruct(list(binary), non_neg_integer, non_neg_integer) :: binary
  def reconstruct(shares, n, m) do
    # Concatenate the reassembled_chunks and convert them back to the original message
    byte_chunks = Enum.map(shares, fn share -> :erlang.binary_to_list(share); end)
    reassembly_matrix = Matix.generate_reassembly_matrix(m, m)
    Matrix.dot_product(reassembly_matrix, byte_chunks, @prime)
  end
end
