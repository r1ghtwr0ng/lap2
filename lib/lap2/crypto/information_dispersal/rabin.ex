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
    # Pad the data to be a multiple of m and split it into n chunks of size m
    byte_chunks = data
    |> PKCS7.pad(m)
    |> :erlang.binary_to_list()
    |> Enum.chunk_every(m)

    # Generate the Vandermonde matrix
    vand_matrix = Matrix.gen_vandermonde_matrix(n, m, @prime)

    # Calculate the shares
    Matrix.matrix_dot_product(vand_matrix, byte_chunks, @prime)
    |> Enum.with_index(fn chunk, idx -> %{data: :erlang.list_to_binary(chunk), id: idx + 1}; end)
  end

  @doc """
  Reconstruct the data from the given shares.
  Generates the reassembly matrix and performs matrix multiplication with the data in the shares.
  Finally, the data is un-padded and returned.
  """
  @spec reconstruct(list(map)) :: binary
  def reconstruct(shares) do
    # Fetch the data from the shares
    byte_chunks = Enum.map(shares, fn share -> :erlang.binary_to_list(share.data); end)

    # Fetch the ids from the shares and use them to generate the reassembly matrix
    Enum.map(shares, fn share -> share.id; end)
    |> Matrix.vandermonde_inverse(@prime)
    |> Matrix.matrix_product(byte_chunks, @prime)
    |> Matrix.transpose()
    |> Enum.concat()
    |> :erlang.list_to_binary()
    |> PKCS7.unpad()
  end
end
