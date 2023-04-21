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
  def check_hmac(%Request{hmac: hmac, data: data, crypto: {crypto_type, crypto_struct}} = req) do
    hmac_key = crypto_struct.hmac_key
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
    # TODO generate cryptographic primitives:
    ephem_pk = <<>>
    generator = <<>>
    ring_pk = <<>>
    signature = <<>>
    RequestHelper.build_init_crypto(identity, ephem_pk, generator, ring_pk, signature)
  end

  @spec gen_resp_crypto(:ets.tid(), binary, Request.t(), non_neg_integer) :: {:resp_ke, KeyExchangeResponse.t()}
  def gen_resp_crypto(_ets, identity, _request, _proxy_seq) do
    # TODO
    ephem_pk = <<>>
    generator = <<>>
    ring_pk = <<>>
    signature = <<>>
    ring_signature = <<>>
    {:ok, RequestHelper.build_resp_crypto(identity, ephem_pk, generator, ring_pk, signature, ring_signature)}
  end

  @spec gen_fin_crypto(:ets.tid(), binary, Request.t(), non_neg_integer) :: {:fin_ke, KeyExchangeFinal.t()}
  def gen_fin_crypto(_ets, _identity, _request, _proxy_seq) do
    # TODO generate
    ring_signature = <<>>
    {:ok, RequestHelper.build_fin_crypto(ring_signature)}
  end

  @spec gen_key_rotation() :: {:key_rot, KeyRotation.t()}
  def gen_key_rotation() do
    aes_key = :crypto.strong_rand_bytes(32)
    {:ok, RequestHelper.build_key_rotation(aes_key)}
  end
end
