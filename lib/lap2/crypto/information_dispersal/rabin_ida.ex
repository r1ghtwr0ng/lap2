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
    |> Enum.map(&encode_double_byte/1)
    |> Enum.with_index(fn chunk, idx -> %{data: :erlang.list_to_binary(chunk), share_idx: idx + 1}; end)
  end

  @doc """
  Reconstruct the data from the given shares.
  Generates the reassembly matrix and performs matrix multiplication with the dat
  a in the shares.
  Finally, the data is un-padded and returned.
  """
  @spec reconstruct(list(map)) :: binary
  def reconstruct(shares) do
    # Fetch the data from the shares
    byte_chunks = Enum.map(shares, fn share ->
      :erlang.binary_to_list(share.data)
      |> decode_double_byte()
    end)

    # Fetch the ids from the shares and use them to generate the reassembly matrix
    try do
      reconstructed = Enum.map(shares, fn share -> share.share_idx; end)
      |> Matrix.vandermonde_inverse(@prime)
      |> Matrix.matrix_product(byte_chunks, @prime)
      |> Matrix.transpose()
      |> Enum.concat()
      |> :erlang.list_to_binary()
      |> PKCS7.unpad()
      {:ok, reconstructed}
    rescue
      # If the shares are not enough to reconstruct the data, return nil
      ArgumentError -> {:err, nil}
    end
  end

  # ---- Private Functions ----
  @spec encode_double_byte(list(non_neg_integer)) :: list(non_neg_integer)
  defp encode_double_byte(bytes) do
    Enum.flat_map(bytes, fn
      255 -> [255, 0]
      256 -> [255, 1]
      byte -> [byte]
    end)
  end

  @spec decode_double_byte(list(non_neg_integer)) :: list(non_neg_integer)
  defp decode_double_byte(bytes) do
    {decoded_bytes, _skip_next} = Enum.reduce(bytes, {[], false}, fn byte, {acc, skip_next} ->
      case {byte, skip_next} do
        {255, false} -> {acc, true}
        {0, true} -> {acc ++ [255], false}
        {1, true} -> {acc ++ [256], false}
        {_, true} -> {acc, false}
        {other, false} -> {acc ++ [other], false}
      end
    end)
    decoded_bytes
  end
end
