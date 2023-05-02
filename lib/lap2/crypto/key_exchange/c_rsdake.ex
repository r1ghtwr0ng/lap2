defmodule LAP2.Crypto.KeyExchange.C_RSDAKE do
  @moduledoc """
  This module implements the C-RSDAKE key exchange protocol.
  """

  # Type definitions
  @type sag() :: %{
    chal: charlist,
    ring: list(charlist),
    resp: list(charlist)
  }
  @type crypto_state() :: %{
    lt_keys: {{charlist, charlist}, charlist, charlist, charlist},
    rs_keys: {{charlist, charlist}, charlist, charlist, charlist},
    ephem_sign_keys: {charlist, charlist},
    dh_keys: {binary, binary},
    shared_secret: binary,
    recv_struct: map
  }
  @type rsdake_init() :: %{
    identity: charlist,
    pk_lt: {charlist, charlist},
    pk_rs: {charlist, charlist},
    pk_ephem_sign: charlist,
    pk_dh: binary,
    signature: charlist
  }
  @type rsdake_resp() :: %{
    identity: charlist,
    pk_lt: {charlist, charlist},
    pk_rs: {charlist, charlist},
    pk_ephem_sign: charlist,
    pk_dh: binary,
    signature: charlist,
    ring_signature: {sag(), charlist}
  }
  @type rsdake_final() :: %{
    ring_signature: {sag(), charlist}
  }

  require Logger
  alias LAP2.Crypto.Constructions.CryptoNifs
  alias LAP2.Crypto.Constructions.ClaimableRS

  @doc """
  Implements RSDAKE's key exchange protocol initialisation phase.
  """
  @spec initialise(charlist) :: {:ok, {crypto_state(), rsdake_init()}}
  def initialise(identity) when is_list(identity) do
    # Generate the key pairs
    %{sk: sk_lt, vk: vk_lt} = ClaimableRS.crs_gen()
    %{sk: sk_rs, vk: vk_rs} = ClaimableRS.crs_gen()
    {sk_ephem_sign, pk_ephem_sign} = CryptoNifs.standard_signature_gen()
    {sk_dh, pk_dh} = Curve25519.generate_key_pair()

    # Generate seed for probabilistic signature schem
    rng = :crypto.strong_rand_bytes(32) |> :binary.bin_to_list()
    # Generate the signature
    msg = List.flatten([:binary.bin_to_list(pk_dh), Tuple.to_list(vk_rs)])
    signature = CryptoNifs.standard_signature_sign(sk_ephem_sign, msg, rng)
    crypto_state = %{
      lt_keys: sk_lt,
      rs_keys: sk_rs,
      ephem_sign_keys: {sk_ephem_sign, pk_ephem_sign},
      dh_keys: {sk_dh, pk_dh},
      recv_struct: %{},
      shared_secret: <<>>
    }
    init_struct =
    %{
      identity: identity,
      pk_lt: vk_lt,
      pk_rs: vk_rs,
      pk_ephem_sign: pk_ephem_sign,
      pk_dh: pk_dh,
      signature: signature
    }
    {:ok, {crypto_state, init_struct}}
  end
  def initialise(_), do: {:error, :invalid_identity}

  @doc """
  Implements RSDAKE's response phase.
  """
  @spec respond(charlist, map, rsdake_init()) ::
    {:ok, {crypto_state(), rsdake_resp()}} | {:error, atom}
  def respond(identity, %{sk: sk_lt, vk: {vk_rs_lt, vk_sig_lt}}, recv_init) when is_list(identity) do
    # Generate key pairs
    %{sk: sk_rs, vk: {vk_rs_ephem, vk_sig_ephem}} = ClaimableRS.crs_gen()
    {sk_ephem_sign, pk_ephem_sign} = CryptoNifs.standard_signature_gen()
    {sk_dh, pk_dh} = Curve25519.generate_key_pair()

    # Deconstruct maps
    %{
      identity: recv_identity,
      pk_lt: {recv_vk_rs_lt, _},
      pk_rs: {recv_vk_rs, recv_vk_sig},
      pk_ephem_sign: recv_pk_ephem_sign,
      pk_dh: recv_pk_dh,
      signature: recv_signature
    } = recv_init

    # Verify signature
    msg = List.flatten([:binary.bin_to_list(recv_pk_dh), recv_vk_rs, recv_vk_sig])
    cond do
      CryptoNifs.standard_signature_vrfy(recv_signature, recv_pk_ephem_sign, msg) ->
        # Generate seed for probabilistic signature schem
        rng = :crypto.strong_rand_bytes(32) |> :binary.bin_to_list()
        # Generate signatures
        sig_msg = List.flatten([:binary.bin_to_list(pk_dh), vk_rs_ephem, vk_sig_ephem])
        signature = CryptoNifs.standard_signature_sign(sk_ephem_sign, sig_msg, rng)

        # Generate ring and ring signature
        ring = [recv_vk_rs_lt, vk_rs_lt, vk_rs_ephem]
        rsig_msg = List.flatten([0, recv_identity, recv_pk_ephem_sign, pk_ephem_sign])
        {:ok, ring_signature} = ClaimableRS.crs_sign(1, sk_lt, ring, rsig_msg)

        # Compute shared secret
        shared_secret = Curve25519.derive_shared_secret(sk_dh, recv_pk_dh)

        # Build response
        response_struct = %{
          identity: identity,
          pk_lt: {vk_rs_lt, vk_sig_lt},
          pk_rs: {vk_rs_ephem, vk_sig_ephem},
          pk_ephem_sign: pk_ephem_sign,
          pk_dh: pk_dh,
          signature: signature,
          ring_signature: ring_signature
        }
        crypto_state = %{
          lt_keys: sk_lt,
          rs_keys: sk_rs,
          ephem_sign_keys: {sk_ephem_sign, pk_ephem_sign},
          dh_keys: {sk_dh, pk_dh},
          shared_secret: shared_secret,
          recv_struct: recv_init
        }
        {:ok, {crypto_state, response_struct}}

      true ->
        {:error, :invalid_signature}
    end
  end
  def respond(_identity, _lt_keys, _recv_init), do: {:error, :invalid_arguments}

  @doc """
  Implements RSDAKE's finalisation phase.
  """
  @spec finalise(charlist, crypto_state(), rsdake_resp()) ::
  {:ok, {crypto_state(), rsdake_final()}} | {:error, atom}
  def finalise(identity, crypto_state, recv_resp) when is_list(identity) do
    # Deconstruct maps
    %{
      identity: recv_identity,
      pk_lt: {recv_vk_rs_lt, _},
      pk_rs: {recv_vk_rs_ephem, recv_vk_sig_ephem},
      pk_ephem_sign: recv_pk_ephem_sign,
      pk_dh: recv_pk_dh,
      signature: recv_signature,
      ring_signature: recv_ring_signature
    } = recv_resp
    %{
      lt_keys: {{vk_rs_lt, _vk_sig_lt}, _sk_rs_lt, _sk_sig_lt, _sk_prf_lt},
      rs_keys: {{vk_rs_ephem, _vk_sig_ephem}, _sk_rs_ephem, _sk_sig_ephem, _sk_prf_ephem},
      ephem_sign_keys: {_, pk_ephem_sign},
      dh_keys: {sk_dh, _}
    } = crypto_state

    # Verify signature
    msg = List.flatten([:binary.bin_to_list(recv_pk_dh), recv_vk_rs_ephem, recv_vk_sig_ephem])
    cond do
      CryptoNifs.standard_signature_vrfy(recv_signature, recv_pk_ephem_sign, msg) ->
        # Verify ring signature
        rsig_msg = List.flatten([0, identity, recv_pk_ephem_sign, pk_ephem_sign])
        cond do
          ClaimableRS.crs_vrfy(recv_ring_signature, rsig_msg) ->
            # Generate ring and ring signature
            ring = [vk_rs_lt, recv_vk_rs_lt, vk_rs_ephem]
            rsig_msg = List.flatten([1, recv_identity, recv_pk_ephem_sign, pk_ephem_sign])
            {:ok, ring_signature} = ClaimableRS.crs_sign(0, crypto_state.lt_keys, ring, rsig_msg)

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
  def finalise(_identity, _crypto_state, _recv_resp), do: {:error, :invalid_identity}

  @doc """
  Implements RSDAKE's final response verification phase.
  """
  @spec verify_final(charlist, crypto_state(), rsdake_final()) ::
    {:ok, boolean} | {:error, atom}
  def verify_final(identity, crypto_state, %{ring_signature: rs}) when is_list(identity) do
    # Deconstruct maps
    %{
      ephem_sign_keys: {_, pk_ephem_sign},
      recv_struct: %{
        pk_ephem_sign: recv_pk_ephem_sign,
      }
    } = crypto_state

    # Verify ring signature
    rsig_msg = List.flatten([1, identity, pk_ephem_sign, recv_pk_ephem_sign])
    ClaimableRS.crs_vrfy(rs, rsig_msg)
  end
  def verify_final(_identity, _crypto_state, _recv_resp), do: {:error, :invalid_arguments}
end
