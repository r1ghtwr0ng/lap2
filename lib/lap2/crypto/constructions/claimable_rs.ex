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

  alias LAP2.Crypto.KeyExchange.CryptoNifs

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
  """
  @spec rs_sign(non_neg_integer, charlist, list(charlist), charlist) ::
    {:ok, %{chal: charlist, ring: list(charlist), resp: list(charlist)}} | {:error, :invalid_ring}
  def rs_sign(idx, sk, ring, msg) when idx <= length(ring) and  length(sk) == 32 do
    # Verify that all the ring keys are 32 bytes long
    cond do
      Enum.all?(ring, fn pk -> length(pk) == 32; end) ->
        {chal, ring, resp} = CryptoNifs.rs_nif_sign(idx, sk, ring, msg)
        sag = %{
          chal: chal,
          ring: ring,
          resp: resp
        }
        {:ok, sag}

      true -> {:error, :invalid_ring}
    end
  end
  def rs_sign(_idx, _sk, _ring, _msg), do: {:error, :invalid_input}

  @doc """
  Verify a ring signature.
  """
  # TODO change the map to an SAG struct once I make one
  @spec rs_vrfy(%{chal: charlist,
    resp: list(charlist),
    ring: list(charlist)}, charlist) :: boolean
  def rs_vrfy(sag, msg) do
    CryptoNifs.rs_nif_vrfy(sag.chal, sag.ring, sag.resp, msg)
  end
end
