defmodule LAP2.Crypto.KeyExchange.CryptoNifs do
  use Rustler, otp_app: :lap2, crate: "c_rsdake"

  @doc """
  Generate n-bit randomness (floored to nearest byte).
  """
  @spec prf_gen(non_neg_integer) :: charlist
  def prf_gen(_n), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate pseudo-random function (PRF) output.
  The PRF uses AES128-CMAC.
  """
  @spec prf_eval(charlist, charlist) :: charlist
  def prf_eval(_sk, _data), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate a hash-based (SHA256) commitment of a message.
  """
  @spec commit_gen(charlist, charlist) :: charlist
  def commit_gen(_sk, _rand), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Verify a hash-based (SHA256) commitment.
  """
  @spec commit_vrfy(charlist, charlist, charlist) :: boolean
  def commit_vrfy(_sk, _rand, _com), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Sign a message using a Spontaneous Anonymous Group (SAG) ring signature.
  """
  @spec rs_nif_sign(non_neg_integer, charlist, list(charlist), charlist) ::
    {charlist, list(charlist), list(charlist)}
  def rs_nif_sign(_idx, _sk, _ring, _msg), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Verify a Spontaneous Anonymous Group (SAG) ring signature.
  """
  @spec rs_nif_vrfy(charlist, list(charlist), list(charlist), charlist) :: boolean
  def rs_nif_vrfy(_chal, _ring, _resp, _msg), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate a secret and public key pair tuple for
  a Spontaneous Anonymous Group (SAG) ring signature scheme.
  """
  @spec rs_nif_gen() :: {charlist, charlist}
  def rs_nif_gen(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate a secret and public key pair tuple for
  a ed25519_dalek signature scheme.
  """
  @spec standard_signature_gen() :: {charlist, charlist}
  def standard_signature_gen(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Sign a message using a ed25519_dalek signature scheme.
  """
  @spec standard_signature_sign(charlist, charlist, charlist) :: charlist
  def standard_signature_sign(_sk, _pk, _msg), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Verify a ed25519_dalek signature.
  """
  @spec standard_signature_vrfy(charlist, charlist, charlist) :: boolean
  def standard_signature_vrfy(_sig, _pk, _msg), do: :erlang.nif_error(:nif_not_loaded)
end
