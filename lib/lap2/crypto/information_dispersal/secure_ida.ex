defmodule LAP2.Crypto.InformationDispersal.SecureIDA do
  @moduledoc """
  Security enhanced Information Dispersal Algorithm, used to split and reconstruct data.
  # TODO actually make it use a proper IDA rather than splitting the data lol
  """
  @block_size 16

  require Logger
  alias LAP2.Crypto.Padding.PKCS7
  alias LAP2.Crypto.InformationDispersal.RabinIDA

  # ---- Public Functions ----
  @doc """
  Split the data into the given number of shares.
  m is the number of shares required to reconstruct the data (threshold).
  n is the number of shares to split the data into.
  """
  @spec disperse(binary, integer, integer, integer) :: {:ok, list}
  def disperse(data, n, m, message_id) do
    # Generate and split an ephemeral AES key and IV
    # Split the key and IV with Shamir's Secret Sharing
    # Create a key share struct for each key share
    iv = :crypto.strong_rand_bytes(16)
    iv_shares = KeyX.Shamir.split_secret(m, n, iv)
    aes_key = :crypto.strong_rand_bytes(32)
    key_shares = KeyX.Shamir.split_secret(m, n, aes_key)
    |> Enum.zip(iv_shares)
    |> Enum.map(fn {key_share, iv_share} ->
      %KeyShare{
        aes_key: key_share,
        iv: iv_share
      }
    end)

    # Pad and encrypt data with AES and the ephemeral key
    # Split encrypted data with Rabin's IDA
    # Add key share, data share, share number, share threshold and total shares to a share struct
    data
    |> encrypt(aes_key, iv)
    |> RabinIDA.split(n, m)
    |> Enum.zip(key_shares)
    |> Enum.map(fn {d_share, key_share} ->
      %Share{total_shares: n,
        message_id: message_id,
        share_idx: d_share.share_idx,
        share_threshold: m,
        key_share: key_share,
        data: d_share.data
      }
    end)
  end

  @doc """
  Reconstruct the data from the given shares.
  m is the number of shares required to reconstruct the data (threshold).
  """
  @spec reconstruct(list(Share)) :: {:ok, binary}
  def reconstruct(shares) do
    # Check that there are enough shares to reconstruct the data
    threshold = Enum.at(shares, 0).share_threshold
    cond do
      length(shares) == threshold -> {:ok, reconstruct_data(shares)}
      length(shares) < threshold -> {:error, "Not enough shares to reconstruct data"}
      length(shares) > threshold ->
        shares = Enum.take_random(shares, threshold)
        {:ok, reconstruct_data(shares)}
    end
  end

  # ---- Private Functions ----
  @spec reconstruct_data(list(Share)) :: binary
  defp reconstruct_data(shares) do
    # Extract key and data shares from share structs
    {aes_key, iv} = shares
    |> Enum.map(fn share -> share.key_share; end)
    |> recover_aes_data()

    # Reconstruct data with Rabin's IDA
    {:ok, data} = RabinIDA.reconstruct(shares)

    # Decrypt data with AES and the ephemeral key
    decrypt(data, aes_key, iv)
  end

  # Reconstruct the AES key and IV from the given key shares
  @spec recover_aes_data(list) :: {binary, binary}
  defp recover_aes_data(key_shares) do
    # Extract key and data shares from share structs
    # Recover Key and IV with Shamir's Secret Sharing
    {aes_keys, iv_shares} = key_shares
    |> Enum.map(fn key_share -> {key_share.aes_key, key_share.iv}; end)
    |> Enum.unzip()
    aes_key = KeyX.Shamir.recover_secret(aes_keys)
    iv = KeyX.Shamir.recover_secret(iv_shares)
    {aes_key, iv}
  end

  # Pad and encrypt data with AES and the ephemeral key
  @spec encrypt(binary, binary, binary) :: binary
  defp encrypt(data, aes_key, iv) do
    padded = PKCS7.pad(data, @block_size)
    :crypto.crypto_one_time(:aes_256_cbc, aes_key, iv, padded, true)
  end

  # Decrypt data with AES and the ephemeral key
  @spec decrypt(binary, binary, binary) :: binary
  defp decrypt(data, aes_key, iv) do
    :crypto.crypto_one_time(:aes_256_cbc, aes_key, iv, data, false)
    |> PKCS7.unpad()
  end
end
