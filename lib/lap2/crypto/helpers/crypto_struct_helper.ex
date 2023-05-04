defmodule LAP2.Crypto.Helpers.CryptoStructHelper do
  @moduledoc """
  Contains helper functions for various cryptographic ops
  """

  alias LAP2.Crypto.CryptoManager
  alias LAP2.Crypto.KeyExchange.C_RSDAKE
  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Utils.ProtoBuf.RequestHelper
  alias LAP2.Crypto.Constructions.ClaimableRS

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
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, atom}
  def gen_init_crypto(crypto_mgr \\ :crypto_manager) do
    # Generate (un)encrypted request struct
    identity = get_identity(crypto_mgr)
    case C_RSDAKE.initialise(identity) do
      {:ok, {temp_crypto_struct, init_hdr}} ->
        RequestHelper.build_request(init_hdr, <<>>, "key_exchange_init", CloveHelper.gen_seq_num())
        |> RequestHelper.wrap_unencrypted()
        |> build_return(temp_crypto_struct)
      err -> err
    end
  end

  @doc """
  Generate key exchange response primitives and response (EncryptedRequest struct)
  """
  @spec gen_resp_crypto({:init_ke, KeyExchangeInit.t()}, atom) ::
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, atom}
  def gen_resp_crypto({:init_ke, init_hdr}, crypto_mgr) do
    # Get the identity and crypto keys
    identity = get_identity(crypto_mgr)
    lt_keys = get_lt_keys(crypto_mgr)

    # Generate (un)encrypted request struct
    case C_RSDAKE.respond(identity, lt_keys, init_hdr) do
      {:ok, {crypto_struct, resp_hdr}} -> # We'll see if it won't match Dialyzer
        RequestHelper.build_request(resp_hdr, <<>>, "key_exchange_resp", CloveHelper.gen_seq_num())
        |> RequestHelper.wrap_unencrypted()
        |> build_return(crypto_struct)
      err -> err
    end
  end
  def gen_resp_crypto(_, _), do: {:error, :invalid}

  @doc """
  Generate final key exchange primitives and response (EncryptedRequest struct)
  """
  @spec gen_fin_crypto({:resp_ke, KeyExchangeResponse.t()}, map, atom) ::
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, :invalid}
  def gen_fin_crypto({:resp_ke, crypto_hdr}, temp_struct, crypto_mgr) do
    # TODO generate asymmetric key and signature
    identity = get_identity(crypto_mgr)

    # Generate (un)encrypted request struct
    case C_RSDAKE.finalise(identity, temp_struct, crypto_hdr) do
      {:ok, {crypto_struct, fin_hdr}} ->
        RequestHelper.build_request(fin_hdr, <<>>, "key_exchange_fin", CloveHelper.gen_seq_num())
        |> RequestHelper.wrap_unencrypted()
        |> build_return(crypto_struct)
      err -> err
    end
  end
  def gen_fin_crypto(_, _, _), do: {:error, :invalid}

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
  @spec get_identity(atom) :: charlist
  defp get_identity(crypto_mgr) do
    CryptoManager.get_identity(crypto_mgr)
  end

  # Fetches the long term keys from the crypto manager
  @spec get_lt_keys(atom) :: map
  defp get_lt_keys(_crypto_mgr) do
    # TODO get the keys from the crypto manager
    ClaimableRS.crs_gen()
    #CryptoManager.get_lt_keys(crypto_mgr)
  end

  # Builds the return value for the crypto functions
  @spec build_return({:ok, EncryptedRequest.t()} | {:error, atom}, map) ::
    {:ok, %{crypto_struct: map, encrypted_request: EncryptedRequest.t()}} | {:error, :invalid}
  defp build_return({:ok, enc_req}, crypto_struct) do
    {:ok, %{crypto_struct: crypto_struct, encrypted_request: enc_req}}
  end
  defp build_return({:error, _} = err, _), do: err
end
