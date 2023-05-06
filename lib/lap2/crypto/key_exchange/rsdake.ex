defmodule LAP2.Crypto.KeyExchange.RSDAKE do
  @moduledoc """
  This module implements the RSDAKE key exchange protocol.
  TODO consider depricating this and just use C-RSDAKE.
  If the user doesn't wish to have claimability, they can
  just discard the PRF secret and RS commitments.
  """

  # Type definitions
  @type sag() :: %{
    chal: charlist,
    ring: list(charlist),
    resp: list(charlist)
  }
  @type crypto_state() :: %{
    lt_keys: {charlist, charlist},
    ephem_sign_keys: {charlist, charlist},
    dh_keys: {binary, binary},
    rs_keys: {charlist, charlist},
    shared_secret: binary,
    recv_struct: map
  }
  @type rsdake_init() :: %{
    identity: charlist,
    pk_lt: charlist,
    pk_ephem_sign: charlist,
    pk_dh: binary,
    pk_rs: charlist,
    signature: charlist
  }
  @type rsdake_resp() :: %{
    identity: charlist,
    pk_lt: charlist,
    pk_ephem_sign: charlist,
    pk_dh: binary,
    pk_rs: charlist,
    signature: charlist,
    ring_signature: sag()
  }
  @type rsdake_final() :: %{
    ring_signature: sag()
  }

  require Logger
  alias LAP2.Crypto.Constructions.CryptoNifs
  alias LAP2.Crypto.Constructions.ClaimableRS

  @doc """
  Implements RSDAKE's key exchange protocol initialisation phase.
  """
  @spec initialise(charlist) :: {crypto_state(), rsdake_init()}
  def initialise(identity) do
    # Generate the key pairs
    {sk_lt, pk_lt} = ClaimableRS.rs_gen()
    {sk_ephem_sign, pk_ephem_sign} = CryptoNifs.standard_signature_gen()
    {sk_dh, pk_dh} = Curve25519.generate_key_pair()
    {sk_rs, pk_rs} = ClaimableRS.rs_gen()

    # Generate the signature
    msg = List.flatten([:binary.bin_to_list(pk_dh), pk_rs])
    rng = :crypto.strong_rand_bytes(32)
    signature = CryptoNifs.standard_signature_sign(sk_ephem_sign, msg, rng)
    crypto_state = %{
      lt_keys: {sk_lt, pk_lt},
      ephem_sign_keys: {sk_ephem_sign, pk_ephem_sign},
      dh_keys: {sk_dh, pk_dh},
      rs_keys: {sk_rs, pk_rs},
      recv_struct: %{},
      shared_secret: <<>>
    }
    init_struct =
    %{
      identity: identity,
      pk_lt: pk_lt,
      pk_ephem_sign: pk_ephem_sign,
      pk_dh: pk_dh,
      pk_rs: pk_rs,
      signature: signature
    }
    {crypto_state, init_struct}
  end

  @doc """
  Implements RSDAKE's response phase.
  """
  @spec respond(charlist, map, rsdake_init()) ::
    {:ok, {crypto_state(), rsdake_resp()}} | {:error, atom}
  def respond(identity, _lt_keys, recv_init) do
    # Generate key pairs
    {sk_lt, pk_lt} = ClaimableRS.rs_gen()
    {sk_ephem_sign, pk_ephem_sign} = CryptoNifs.standard_signature_gen()
    {sk_dh, pk_dh} = Curve25519.generate_key_pair()
    {sk_rs, pk_rs} = ClaimableRS.rs_gen()

    # Deconstruct maps
    %{
      identity: recv_identity,
      pk_lt: recv_pk_lt,
      pk_ephem_sign: recv_pk_ephem_sign,
      pk_dh: recv_pk_dh,
      pk_rs: recv_pk_rs,
      signature: recv_signature
    } = recv_init

    # Verify signature
    msg = List.flatten([:binary.bin_to_list(recv_pk_dh), recv_pk_rs])
    cond do
      CryptoNifs.standard_signature_vrfy(recv_signature, recv_pk_ephem_sign, msg) ->
        # Generate signatures
        sig_msg = List.flatten([:binary.bin_to_list(pk_dh), pk_rs])
        rng = :crypto.strong_rand_bytes(32)
        signature = CryptoNifs.standard_signature_sign(sk_ephem_sign, sig_msg, rng)

        # Generate ring and ring signature
        ring = [recv_pk_lt, pk_lt, pk_rs]
        rsig_msg = List.flatten([0, recv_identity, recv_pk_ephem_sign, pk_ephem_sign])
        {:ok, ring_signature} = ClaimableRS.rs_sign(1, sk_lt, ring, rsig_msg)

        # Compute shared secret
        shared_secret = Curve25519.derive_shared_secret(sk_dh, recv_pk_dh)

        # Build response
        response_struct = %{
          identity: identity,
          pk_lt: pk_lt,
          pk_ephem_sign: pk_ephem_sign,
          pk_dh: pk_dh,
          pk_rs: pk_rs,
          signature: signature,
          ring_signature: ring_signature
        }
        crypto_state = %{
          lt_keys: {sk_lt, pk_lt},
          ephem_sign_keys: {sk_ephem_sign, pk_ephem_sign},
          dh_keys: {sk_dh, pk_dh},
          rs_keys: {sk_rs, pk_rs},
          shared_secret: shared_secret,
          recv_struct: recv_init
        }
        {:ok, {crypto_state, response_struct}}

      true ->
        {:error, :invalid_signature}
    end


  end

  @doc """
  Implements RSDAKE's finalisation phase.
  """
  @spec finalise(charlist, crypto_state(), rsdake_resp()) ::
    {:ok, {crypto_state(), rsdake_final()}} | {:error, atom}
  def finalise(identity, crypto_state, recv_resp) do
    # Deconstruct maps
    %{
      identity: recv_identity,
      pk_lt: recv_pk_lt,
      pk_ephem_sign: recv_pk_ephem_sign,
      pk_dh: recv_pk_dh,
      pk_rs: recv_pk_rs,
      signature: recv_signature,
      ring_signature: recv_ring_signature
    } = recv_resp
    %{
      lt_keys: {sk_lt, pk_lt},
      ephem_sign_keys: {_, pk_ephem_sign},
      dh_keys: {sk_dh, _},
      rs_keys: {_, pk_rs}
    } = crypto_state

    # Verify signature
    msg = List.flatten([:binary.bin_to_list(recv_pk_dh), recv_pk_rs])
    cond do
      CryptoNifs.standard_signature_vrfy(recv_signature, recv_pk_ephem_sign, msg) ->
        # Verify ring signature
        rsig_msg = List.flatten([0, identity, recv_pk_ephem_sign, pk_ephem_sign])
        cond do
          ClaimableRS.rs_vrfy(recv_ring_signature, rsig_msg) ->
            # Generate ring and ring signature
            ring = [pk_lt, recv_pk_lt, pk_rs]
            rsig_msg = List.flatten([1, recv_identity, pk_ephem_sign, recv_pk_ephem_sign])
            {:ok, ring_signature} = ClaimableRS.rs_sign(0, sk_lt, ring, rsig_msg)

            # Compute shared secret
            shared_secret = Curve25519.derive_shared_secret(sk_dh, recv_pk_dh)

            # Build response
            final = %{
              ring_signature: ring_signature
            }

            crypto_state = crypto_state
            |> Map.put(:shared_secret, shared_secret)
            |> Map.put(:recv_struct, recv_resp)

            {:ok, {crypto_state, final}}

          true ->
            {:error, :invalid_ring_signature}
        end

      true ->
        {:error, :invalid_signature}
    end
  end

  @doc """
  Implements RSDAKE's final response verification phase.
  """
  @spec verify_final(charlist, crypto_state(), rsdake_final()) ::
    {:ok, boolean} | {:error, atom}
  def verify_final(identity, crypto_state, %{ring_signature: rs}) do
    # Deconstruct maps
    %{
      ephem_sign_keys: {_, pk_ephem_sign},
      recv_struct: %{
        pk_ephem_sign: recv_pk_ephem_sign,
      }
    } = crypto_state

    # Verify ring signature
    rsig_msg = List.flatten([1, identity, pk_ephem_sign, recv_pk_ephem_sign])
    ClaimableRS.rs_vrfy(rs, rsig_msg)
  end
end
