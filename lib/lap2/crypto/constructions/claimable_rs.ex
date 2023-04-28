defmodule LAP2.Crypto.Constructions.ClaimableRS do
  @moduledoc """
  This module implements a Claimable Ring Signature (CRS) scheme.
  The scheme allows a member to claim their signature after the fact by
  revealing a commitment secret.

  This encryption scheme is based on the specification from the following paper:

  Park, S. and Sealfon, A., 2019.
  It wasn’t me! Repudiability and claimability of ring signatures.
  In Advances in Cryptology–CRYPTO 2019: 39th Annual International
  Cryptology Conference, Santa Barbara, CA, USA, August 18–22, 2019,
  Proceedings, Part III 39 (pp. 159-190). Springer International Publishing.
  """

  # SAG type definition
  @type sag() :: %{
    chal: charlist,
    ring: list(charlist),
    resp: list(charlist)
  }

  require Logger
  alias LAP2.Crypto.Constructions.CryptoNifs


  @doc """
  Generate a secret and public key pair tuple for
  a Claimable Ring Signature (CRS) scheme.
  """
  @spec rs_gen() :: {charlist, charlist}
  def rs_gen() do
    CryptoNifs.rs_nif_gen()
  end

  @doc """
  Generate an SAG ring signature for a message.
  This function verifies the validity of the arguments before
  calling the Rust NIF.
  """
  @spec rs_sign(non_neg_integer, charlist, list(charlist), charlist) ::
    {:error, atom} | {:ok, sag()}
  def rs_sign(ring_idx, sk, ring, msg) do
    # Verify if the arguments are valid before using unsafe functions
    case verify_args(ring_idx, ring, [sk]) do
      :ok -> {:ok, rs_sign_wrap(ring_idx, sk, ring, msg)}

      {:error, reason} ->
        Logger.error("Error in LAP2.Crypto.Constructions.ClaimableRS.rs_sign: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Verify an SAG ring signature for a message.
  """
  @spec rs_vrfy(sag(), charlist) ::
    {:error, atom} | {:ok, boolean}
  def rs_vrfy(sag, msg) do
    # Using ring_idx = 1 to ensure that the ring has > 1 members
    case verify_args(1, sag.ring, [sag.chal | sag.resp]) do
      :ok -> {:ok, rs_vrfy_wrap(sag, msg)}

      {:error, reason} ->
        Logger.error("Error in LAP2.Crypto.Constructions.ClaimableRS.rs_vrfy: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Generate a Claimable RS (C-RS) key pair.
  """
  @spec crs_gen() :: %{vk: {charlist, charlist},
    sk: {{charlist, charlist}, charlist, charlist, charlist}}
  def crs_gen() do
    k = 256 # 256-bit security level for the PRF secret
    {sk_rs, pk_rs} = rs_gen()
    {sk_sig, pk_sig} = CryptoNifs.standard_signature_gen()
    sk_prf = CryptoNifs.prf_gen(k)
    vk = {pk_rs, pk_sig}
    sk = {vk, sk_rs, sk_sig, sk_prf}
    %{
      vk: vk,
      sk: sk
    }
  end

  @doc """
  Generate a C-RS signature.
  """
  @spec crs_sign(non_neg_integer, list(charlist), {{charlist, charlist}, charlist, charlist, charlist}, charlist) ::
    {:ok, {sag(), charlist}} | {:error, atom}
  def crs_sign(ring_idx, ring, {{pk_rs, pk_sig}, sk_rs, sk_sig, sk_prf}, msg) do
    # Verify the arguments before using unsafe functions
    crypto_structs = [sk_rs, sk_sig, sk_prf, pk_rs, pk_sig]
    case verify_args(ring_idx, ring, crypto_structs) do
      :ok ->
        # Generate ring signature on a message, then flatten it to a charlist
        ring_sig = rs_sign_wrap(ring_idx, sk_rs, ring, msg)

        # Generate pseudo-random seed from PRF
        prf_construct = List.flatten([pk_rs, pk_sig, sag_to_charlist(ring_sig), 0])
        rand_sig = CryptoNifs.prf_eval(sk_prf, prf_construct)

        # Generate a signature on the PRF randomness
        # TODO The paper says to use the prf randomness for the signature,
        # but there is no randomness there, just append to the message
        sign_construct = List.flatten([pk_rs, pk_sig, sag_to_charlist(ring_sig), rand_sig])
        regular_sig = CryptoNifs.standard_signature_sign(sk_sig, pk_sig, sign_construct)

        # Generate randomness from commitment
        prf_construct = List.flatten([pk_rs, pk_sig, sag_to_charlist(ring_sig), 1])
        rand_com = CryptoNifs.prf_eval(sk_prf, prf_construct)

        # Generate commitment
        com_construct = List.flatten([pk_rs, pk_sig, regular_sig])
        commitment = CryptoNifs.commit_gen(com_construct, rand_com)

        # Form signature
        signature = {ring_sig, commitment}
        {:ok, signature}

      {:error, reason} ->
        Logger.error("Error in LAP2.Crypto.Constructions.ClaimableRS.crs_sign: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Verify a C-RS signature.
  """
  @spec crs_vrfy({sag(), charlist}, charlist) ::
    {:ok, boolean} | {:error, atom}
  def crs_vrfy({sag, commitment}, msg) do
    # Verify the arguments before using unsafe functions
    crypto_structs = Enum.reduce(sag.resp, [sag.chal, commitment], fn x, acc -> [x | acc]; end)
    case verify_args(1, sag.ring, crypto_structs) do
      :ok -> {:ok, rs_vrfy_wrap(sag, msg)}

      {:error, reason} ->
        Logger.error("Error in LAP2.Crypto.Constructions.ClaimableRS.crs_vrfy: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Generate a claim for a C-RS signature.
  """
  @spec crs_claim(non_neg_integer, {{charlist, charlist}, charlist, charlist, charlist}, {sag(), charlist}) ::
    {:ok, {charlist, charlist, charlist} | :invalid_commitment} | {:error, atom}
  def crs_claim(ring_idx, {{pk_rs, pk_sig}, sk_rs, sk_sig, sk_prf}, {sag, commitment}) do
    # Verify the arguments before using unsafe functions
    crypto_structs = Enum.reduce(sag.resp, [pk_rs, pk_sig, sk_rs, sk_sig, sk_prf, sag.chal, commitment],
    fn x, acc ->
      [x | acc]
    end)
    case verify_args(ring_idx, sag.ring, crypto_structs) do
      :ok ->
        # Generate pseudo-randomness from PRF
        prf_sig_construct = List.flatten([pk_rs, pk_sig, sag_to_charlist(sag), 0])
        rand_sig = CryptoNifs.prf_eval(sk_prf, prf_sig_construct)
        prf_com_construct = List.flatten([pk_rs, pk_sig, sag_to_charlist(sag), 1])
        rand_com = CryptoNifs.prf_eval(sk_prf, prf_com_construct)

        # Generate standard signature
        sign_construct = List.flatten([pk_rs, pk_sig, sag_to_charlist(sag), rand_sig])
        regular_sig = CryptoNifs.standard_signature_sign(sk_sig, pk_sig, sign_construct)

        # Generate commitment
        com_construct = List.flatten([pk_rs, pk_sig, regular_sig])
        cond do
          commitment == CryptoNifs.commit_gen(com_construct, rand_com) ->
            # Valid commitment, return claim
            {:ok, {rand_com, rand_sig, regular_sig}}

          true ->
            # Invalid commitment, return empty set
            {:ok, :invalid_commitment}
        end
      {:error, reason} ->
        Logger.error("Error in LAP2.Crypto.Constructions.ClaimableRS.crs_claim: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Verify the validity of a claim for a C-RS signature.
  """
  @spec crs_vrfy_claim({charlist, charlist}, {sag(), charlist}, {charlist, charlist, charlist}) ::
    {:ok, boolean} | {:error, atom}
  def crs_vrfy_claim({pk_rs, pk_sig}, {sag, commitment}, {rand_com, rand_sig, regular_sig}) do
    # Verify the arguments before using unsafe functions
    crypto_structs = Enum.reduce(sag.resp, [pk_rs, pk_sig, sag.chal, commitment],
    fn x, acc ->
      [x | acc]
    end)
    # Ring index is set to 1 to verify the ring size
    case verify_args(1, sag.ring, crypto_structs) do
      :ok ->
        cond do
          length(rand_sig) == 16 and
          length(rand_com) == 16 and
          length(regular_sig) == 64 ->
            # Generate commitment from claim
            com_construct = List.flatten([pk_rs, pk_sig, regular_sig])
            ver_com = CryptoNifs.commit_gen(com_construct, rand_com) == commitment

            # Verify signature
            sig_construct = List.flatten([pk_rs, pk_sig, sag_to_charlist(sag), rand_sig])
            ver_sig = CryptoNifs.standard_signature_vrfy(regular_sig, pk_sig, sig_construct)
            {:ok, ver_com and ver_sig}

          true -> {:error, :invalid_claim}
        end
      {:error, reason} ->
        Logger.error("Error in LAP2.Crypto.Constructions.ClaimableRS.crs_vrfy_claim: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Merge a SAG struct to a flat charlist.
  """
  @spec sag_to_charlist(sag()) :: charlist
  def sag_to_charlist(sag) do
    List.flatten([sag.chal, sag.ring, sag.resp])
  end

  # ---- Argument Verification ----
  @spec verify_args(non_neg_integer(), list(charlist), list(charlist)) ::
    {:error, atom} | :ok
  defp verify_args(idx, ring, crypto_structs) do
    cond do
      # Verify index is within ring range
      idx >= length(ring) -> {:error, :invalid_index}
      # Verify that all the ring and crypto keys are 32 bytes long
      Enum.any?(ring, fn pk -> length(pk) != 32; end) -> {:error, :invalid_ring}
      Enum.any?(crypto_structs, fn cs -> length(cs) != 32; end) -> {:error, :invalid_struct}
      true -> :ok
    end
  end

  # ---- Private Wrappers, called after argument verification ----
  # NIF wrapper for generating a ring signature.
  @spec rs_sign_wrap(non_neg_integer, charlist, list(charlist), charlist) :: sag()
  defp rs_sign_wrap(ring_idx, sk, ring, msg) do
    {_own_pk, new_ring} = List.pop_at(ring, ring_idx)
    {chal, ring, resp} = CryptoNifs.rs_nif_sign(ring_idx, sk, new_ring, msg)
    %{
      chal: chal,
      ring: ring,
      resp: resp
    }
  end

  # NIF wrapper for verifying a ring signature.
  # TODO change the map to an SAG struct once I make one
  @spec rs_vrfy_wrap(sag(), charlist) :: boolean
  defp rs_vrfy_wrap(sag, msg) do
    CryptoNifs.rs_nif_vrfy(sag.chal, sag.ring, sag.resp, msg)
  end
end
