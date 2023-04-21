defmodule LAP2.Crypto.Helpers.CryptoStructHelper do
  @moduledoc """
  Contains helper functions for various cryptographic ops
  """

  alias LAP2.Utils.ProtoBuf.RequestHelper

  # ---- HMAC functions ----
  @doc """
  Generate key, calculate HMAC and set appropriate Request fields
  """
  @spec set_hmac(Request.t()) :: Request.t()
  def set_hmac(request) do
    hmac_key = :crypto.strong_rand_bytes(32)
    hmac = <<>> # TODO calculate HMAC
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
  Generate initial key exchange primitives
  """
  @spec gen_init_crypto(binary, Request.t(), non_neg_integer) :: {:init_ke, KeyExchangeInit.t()}
  def gen_init_crypto(identity, _request, _proxy_seq) do
    # TODO remove crypto_struct if not needed
    ephem_pk = <<>>
    generator = <<>>
    ring_pk = <<>>
    signature = <<>>
    RequestHelper.build_init_crypto(identity, ephem_pk, generator, ring_pk, signature)
  end

  @spec gen_resp_crypto(binary, KeyExchangeInit.t()) :: %{crypto_headers: {:resp_ke, KeyExchangeResponse.t()}, asymmetric_key: binary}
  def gen_resp_crypto(identity, _crypto_struct) do
    # TODO generate asymmetric key and signatures
    asymm_key = <<>>
    ephem_pk = <<>>
    generator = <<>>
    ring_pk = <<>>
    signature = <<>>
    ring_signature = <<>>
    crypto_hdr = RequestHelper.build_resp_crypto(identity, ephem_pk, generator, ring_pk, signature, ring_signature)
    %{crypto_headers: crypto_hdr, asymmetric_key: asymm_key}
  end

  @spec gen_fin_crypto(KeyExchangeResponse.t()) :: %{crypto_headers: {:fin_ke, KeyExchangeFinal.t()}, asymmetric_key: binary}
  def gen_fin_crypto(_crypto_struct) do
    # TODO generate asymmetric key and signature
    asymm_key = <<>>
    ring_signature = <<>>
    crypto_hdr = RequestHelper.build_fin_crypto(ring_signature)
    %{crypto_headers: crypto_hdr, asymmetric_key: asymm_key}
  end

  @spec gen_key_rotation() :: {:key_rot, KeyRotation.t()}
  def gen_key_rotation() do
    aes_key = :crypto.strong_rand_bytes(32)
    RequestHelper.build_key_rotation(aes_key)
  end
end
