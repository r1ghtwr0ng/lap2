defmodule LAP2.Crypto.Constructions.CryptoNifs do
  use Rustler, otp_app: :lap2, crate: "c_rsdake"

  @doc """
  Generate n-bit randomness (floored to nearest byte).
  ## Arguments
    * `n` - The number of bits of randomness to generate
  ## Returns
    * The generated randomness (charlist)
  """
  @spec prf_gen(non_neg_integer) :: charlist
  def prf_gen(_n), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate pseudo-random function (PRF) output.
  The PRF uses AES128-CMAC.
  ## Arguments
    * `sk` - Secret PRF key (charlist)
    * `data` - The data to be used as a random seed (charlist)
  ## Returns
    * The PRF output (charlist)
  """
  @spec prf_eval(charlist, charlist) :: charlist
  def prf_eval(_sk, _data), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate a hash-based (SHA256) commitment of a message.
  ## Arguments
    * `sk` - Secret commitment key (charlist)
    * `rand` - The randomness used to generate the commitment (charlist)
  ## Returns
    * The commitment (charlist)
  """
  @spec commit_gen(charlist, charlist) :: charlist
  def commit_gen(_sk, _rand), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Verify a hash-based (SHA256) commitment.
  ## Arguments
    * `sk` - Secret commitment key (charlist)
    * `rand` - The randomness used to generate the commitment (charlist)
    * `com` - The commitment to verify (charlist)
  ## Returns
    * `true` if the commitment is valid, `false` otherwise
  """
  @spec commit_vrfy(charlist, charlist, charlist) :: boolean
  def commit_vrfy(_sk, _rand, _com), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate a secret and public key pair tuple for
  a Spontaneous Anonymous Group (SAG) ring signature scheme.
  ## Returns
    * A tuple containing the secret and public keys (charlist, charlist)
  """
  @spec rs_nif_gen() :: {charlist, charlist}
  def rs_nif_gen(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Sign a message using a Spontaneous Anonymous Group (SAG) ring signature.
  ## Arguments
    * `idx` - The index of the signer in the ring (non-negative integer)
    * `sk` - The signer's secret key (charlist)
    * `ring` - The ring of public keys (list of charlists)
    * `msg` - The message to be signed (charlist)
  ## Returns
    * A ring signature tuple containing the signature challenge, response, and ring (charlist, list(charlist), list(charlist))
  """
  @spec rs_nif_sign(non_neg_integer, charlist, list(charlist), charlist) ::
    {charlist, list(charlist), list(charlist)}
  def rs_nif_sign(_idx, _sk, _ring, _msg), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Verify a Spontaneous Anonymous Group (SAG) ring signature.
  ## Arguments
    * `chal` - The signature challenge (charlist)
    * `ring` - The ring of public keys (list of charlists)
    * `resp` - The challenge responses (list of charlists)
    * `msg` - The message that was signed (charlist)
  ## Returns
    * `true` if the signature is valid, `false` otherwise
  """
  @spec rs_nif_vrfy(charlist, list(charlist), list(charlist), charlist) :: boolean
  def rs_nif_vrfy(_chal, _ring, _resp, _msg), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate a secret and public key pair tuple for
  a RSA-PSS signature scheme.
  ## Returns
    * A tuple containing the secret and public keys (charlist, charlist)
  """
  @spec standard_signature_gen() :: {charlist, charlist}
  def standard_signature_gen(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Sign a message using the RSA-PSS probabilistic signature scheme.
  ## Arguments
    * `sk` - The signer's secret key (charlist)
    * `msg` - The message to be signed (charlist)
    * `rand` - The randomness used to generate the signature (charlist)
  ## Returns
    * The signature (charlist)
  """
  @spec standard_signature_sign(charlist, charlist, charlist) :: charlist
  def standard_signature_sign(_sk, _msg, _rand), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Verify a RSA-PSS signature.
  ## Arguments
    * `sig` - The signature to verify (charlist)
    * `vk` - The signer's public key (charlist)
    * `msg` - The message to be signed (charlist)
  ## Returns
    * `true` if the signature is valid, `false` otherwise
  """
  @spec standard_signature_vrfy(charlist, charlist, charlist) :: boolean
  def standard_signature_vrfy(_sig, _vk, _msg), do: :erlang.nif_error(:nif_not_loaded)
end
