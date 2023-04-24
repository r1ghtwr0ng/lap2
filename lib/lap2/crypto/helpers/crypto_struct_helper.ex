defmodule LAP2.Crypto.Helpers.CryptoStructHelper do
  @moduledoc """
  Contains helper functions for various cryptographic ops
  """

  alias LAP2.Crypto.CryptoManager
  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Utils.ProtoBuf.RequestHelper

  # ---- HMAC functions ----
  @doc """
  Generate key, calculate HMAC and set appropriate Request fields
  """
  @spec set_hmac(Request.t()) :: Request.t()
  def set_hmac(request) do
    hmac_key = :crypto.strong_rand_bytes(32)
    hmac = 0 # TODO calculate HMAC
    {crypto_type, crypto_struct} = request.crypto
    request
    |> Map.put(:crypto, {crypto_type, Map.put(crypto_struct, :hmac_key, hmac_key)})
    |> Map.put(:hmac, hmac)
  end

  @doc """
  Verify the validity of the HMAC
  """
  @spec check_hmac(Request.t()) :: {:ok, Request.t()} | {:error, :invalid_hmac}
  def check_hmac(%Request{hmac: hmac, data: _data, crypto: {_, crypto_struct}} = req) do
    _hmac_key = crypto_struct.hmac_key
    new_hmac = hmac # TODO replace to calculate and compare HMAC, currently always evaluates to true
    cond do
      new_hmac == hmac -> {:ok, req}
      true -> {:error, :invalid_hmac}
    end
  end

  # ---- Public key generation functions ----
  @doc """
  Generate initial key exchange primitives and response (EncryptedRequest struct)
  """
  @spec gen_init_crypto(atom) ::
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, :invalid}
  def gen_init_crypto(crypto_mgr \\ :crypto_manager) do
    # TODO remove crypto_struct if not needed
    {ephem_pk, ephem_sk} = {<<>>, <<>>} # TODO generate asymmetric key and signatures
    {ring_pk, ring_sk} = {<<>>, <<>>} # TODO generate ring keys
    generator = <<>>
    signature = <<>>

    temp_crypto_struct = %{
      ephemeral_pk: ephem_pk,
      ephemeral_sk: ephem_sk,
      ring_pk: ring_pk,
      ring_sk: ring_sk,
      generator: generator,
      signature: signature
    }

    # Generate (un)encrypted request struct
    get_identity(crypto_mgr)
    |> RequestHelper.build_init_crypto(ephem_pk, generator, ring_pk, signature)
    |> RequestHelper.build_request(<<>>, "key_exchange_init", CloveHelper.gen_seq_num())
    |> RequestHelper.wrap_unencrypted()
    |> build_return(temp_crypto_struct)
  end

  @doc """
  Generate key exchange response primitives and response (EncryptedRequest struct)
  """
  @spec gen_resp_crypto({:init_ke, KeyExchangeInit.t()}, atom) ::
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, atom}
  def gen_resp_crypto({:init_ke, crypto_hdr}, crypto_mgr) do
    # TODO generate asymmetric key and signatures
    identity = get_identity(crypto_mgr)
    asymm_key = <<>>
    ephem_pk = <<>>
    generator = <<>>
    ring_pk = <<>>
    signature = <<>>
    ring_signature = <<>>
    crypto_struct = %{
      identity: identity,
      long_term_rs_pk: ring_pk,
      ephemeral_dh_pk: crypto_hdr.ephemeral_pk,
      asymmetric_key: asymm_key
    }

    # Generate (un)encrypted request struct
    RequestHelper.build_resp_crypto(identity, ephem_pk, generator, ring_pk, signature, ring_signature)
    |> RequestHelper.build_request(<<>>, "key_exchange_resp", CloveHelper.gen_seq_num())
    |> RequestHelper.wrap_unencrypted()
    |> build_return(crypto_struct)
  end

  @doc """
  Generate final key exchange primitives and response (EncryptedRequest struct)
  """
  @spec gen_fin_crypto({:resp_ke, KeyExchangeResponse.t()}) ::
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, :invalid}
  def gen_fin_crypto({:resp_ke, crypto_hdr}) do
    # TODO generate asymmetric key and signature
    asymm_key = <<>>
    ring_signature = <<>>
    crypto_struct = %{
      identity: crypto_hdr.identity,
      long_term_rs_pk: crypto_hdr.long_term_rs_pk,
      ephemeral_dh_pk: crypto_hdr.ephemeral_dh_pk,
      asymmetric_key: asymm_key
    }

    # Generate (un)encrypted request struct
    RequestHelper.build_fin_crypto(ring_signature)
    |> RequestHelper.build_request(<<>>, "key_exchange_fin", CloveHelper.gen_seq_num())
    |> RequestHelper.wrap_unencrypted()
    |> build_return(crypto_struct)
  end

  @doc """
  Generate key rotation primitives and response (EncryptedRequest struct)
  """
  @spec gen_key_rotation(non_neg_integer, atom) ::
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, :invalid}
  def gen_key_rotation(proxy_seq, crypto_mgr_name) do
    # Generate new symmetric key
    aes_key = :crypto.strong_rand_bytes(32)
    crypto_struct = %{symmetric_key: aes_key}

    # Generate encrypted request struct
    RequestHelper.build_key_rotation(aes_key)
    |> RequestHelper.build_request(<<>>, "key_rotation", proxy_seq)
    |> RequestHelper.encrypt_and_wrap(proxy_seq, crypto_mgr_name)
    |> build_return(crypto_struct)
  end

  @doc """
  Generate key rotation acknowledgement  response (EncryptedRequest struct)
  """
  @spec ack_key_rotation(non_neg_integer, non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, :invalid}
  def ack_key_rotation(proxy_seq, request_id, crypto_manager) do
    # Generate encrypted request struct
    RequestHelper.build_symmetric_crypto()
    |> RequestHelper.build_request(<<>>, "ack_key_rotation", request_id)
    |> RequestHelper.encrypt_and_wrap(proxy_seq, crypto_manager)
  end

  @doc """
  Verify the validity of the ring signature
  """
  @spec verify_ring_signature({:fin_ke, KeyExchangeFinal.t()}, non_neg_integer) :: boolean
  def verify_ring_signature({:fin_ke, %KeyExchangeFinal{}}, _proxy_seq) do
    true # TODO verify ring signature
  end

  # ---- Private functions ----
  # Fetches the identity from the crypto manager
  @spec get_identity(atom) :: binary
  defp get_identity(crypto_mgr) do
    CryptoManager.get_identity(crypto_mgr)
  end

  # Builds the return value for the crypto functions
  @spec build_return({:ok, EncryptedRequest.t()} | {:error, atom}, map) ::
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, :invalid}
  defp build_return({:ok, enc_req}, crypto_struct) do
    {:ok, %{crypto_struct: crypto_struct, encrypted_request: enc_req}}
  end
  defp build_return({:error, _} = err, _), do: err
end
