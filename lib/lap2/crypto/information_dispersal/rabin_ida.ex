defmodule LAP2.Crypto.InformationDispersal.RabinIDA do
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
  ## Arguments
    * `data` - The data to split (binary)
    * `n` - The number of shares to generate (non-negative integer)
    * `m` - The size of each share (non-negative integer)
  ## Returns
    * A list of shares, each containing the share data and its index (list(map))
  """
  @spec split(binary, non_neg_integer, non_neg_integer) :: list(map)
  def split(data, n, m) do
    # Pad the data to be a multiple of m and split it into n chunks of size m
    byte_chunks =
      data
      |> PKCS7.pad(m)
      |> :erlang.binary_to_list()
      |> Enum.chunk_every(m)

    # Generate the Vandermonde matrix
    vand_matrix = Matrix.gen_vandermonde_matrix(n, m, @prime)

    # Calculate the shares
    Matrix.matrix_dot_product(vand_matrix, byte_chunks, @prime)
    |> Enum.map(&encode_double_byte/1)
    |> Enum.with_index(fn binary_chunk, idx ->
      %{data: binary_chunk, share_idx: idx + 1}
    end)
  end

  @doc """
  Reconstruct the data from the given shares.
  Generates the reassembly matrix and performs matrix multiplication with the data in the shares.
  Finally, the data is un-padded and returned.
  ## Arguments
    * `shares` - The shares to reconstruct the data from (list(map))
  ## Returns
    * `{:ok, binary}` - The reconstructed data
    * `{:error, nil}` - The shares are not enough to reconstruct the data
  """
  @spec reconstruct(list(map)) :: {:ok, binary} | {:error, nil}
  def reconstruct(shares) do
    # Fetch the data from the shares
    byte_chunks = Enum.map(shares, fn share -> decode_double_byte(share.data) end)

    # Fetch the ids from the shares and use them to generate the reassembly matrix
    try do
      reconstructed =
        Enum.map(shares, fn share -> share.share_idx end)
        |> Matrix.vandermonde_inverse(@prime)
        |> Matrix.matrix_nif_product(byte_chunks, @prime)
        |> Matrix.transpose()
        |> Enum.concat()
        |> :erlang.list_to_binary()
        |> PKCS7.unpad()

      {:ok, reconstructed}
    rescue
      # If the shares are not enough to reconstruct the data, return nil
      ArgumentError -> {:error, nil}
    end
  end

  # ---- Private Functions ----
  # Encode a list of integers into a binary where each element is 2 bytes
  @spec encode_double_byte(list(non_neg_integer)) :: list(non_neg_integer)
  def encode_double_byte(bytes) do
    Enum.reduce(bytes, <<>>, fn byte, acc -> acc <> <<byte::size(16)>> end)
  end

  # Decode a binary into a list of integers where each element is 2 bytes
  @spec decode_double_byte(binary) :: list(non_neg_integer)
  def decode_double_byte(bytes) do
    bytes
    |> :binary.bin_to_list()
    |> Stream.chunk_every(2)
    |> Stream.map(fn [byte1, byte2] -> byte1 * 256 + byte2 end)
    |> Enum.to_list()
  end
end
