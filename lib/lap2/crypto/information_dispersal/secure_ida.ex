defmodule LAP2.Crypto.InformationDispersal.SecureIDA do
  @moduledoc """
  Security enhanced Information Dispersal Algorithm, used to split and reconstruct data.
  # TODO actually make it use a proper IDA rather than splitting the data lol
  """
  @block_size 16

  require Logger
  alias LAP2.Crypto.Padding.PKCS7

  # ---- Public Functions ----
  @doc """
  Split the data into the given number of shares.
  m is the number of shares required to reconstruct the data (threshold).
  n is the number of shares to split the data into.
  """
  @spec disperse(binary, integer, integer) :: {:ok, list}
  def disperse(data, m, n) do
    padded = PKCS7.pad(data, @block_size)
    aes_key = :crypto.strong_rand_bytes(32)
    iv = :crypto.strong_rand_bytes(16)
    ct = :crypto.crypto_one_time(:aes_256_cbc, aes_key, iv, padded, true)

    # Encrypt data with AES and a random key
    # Split encrypted data with Rabin's IDA
    # Split key with Shamir's Secret Sharing
    # Add key share, data share, share number, share threshold and total shares to a share struct
    x = 1
    key_share = %KeyShare{
      aes_key: aes_key,
      iv: iv
    }

    share = %Share{total_shares: n,
      share_num: x,
      share_threshold: m,
      key_share: key_share,
      ciphertext: ct
    }

    {:ok, [share]}
  end

  @doc """
  Reconstruct the data from the given shares.
  m is the number of shares required to reconstruct the data (threshold).
  """
  @spec reconstruct(list, integer) :: {:ok, binary}
  def reconstruct(_shares, _m) do
    # Extract key and data shares from share structs
    # Reconstruct key with Shamir's Secret Sharing
    # Reconstruct encrypted data with Rabin's IDA
    # Decrypt data with the reconstructed AES key

    {:ok, ""}
  end
end
