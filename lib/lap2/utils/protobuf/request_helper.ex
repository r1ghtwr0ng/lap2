defmodule LAP2.Utils.ProtoBuf.RequestHelper do
  @moduledoc """
  Helper functions for processing LAP2 requests.
  Verifies integrity, serves as interface for serialising/deserialising with ProtoBuf.
  """

  require Logger
  alias LAP2.Networking.ProtoBuf
  alias LAP2.Crypto.CryptoManager
  alias LAP2.Crypto.Helpers.CryptoStructHelper

  # ---- Build Requests ----
  @doc """
  Initiate a key exchange with a remote proxy.
  """
  @spec init_exchange(non_neg_integer, atom) ::
    {:ok, EncryptedRequest.t()} | {:error, atom}
  def init_exchange(clove_seq, crypto_mgr \\ :crypto_manager) do
    case CryptoStructHelper.gen_init_crypto(clove_seq, crypto_mgr) do
      {:ok, %{
        crypto_struct: temp_crypto_struct,
        encrypted_request: enc_req
      }} ->
        # Update the temporary crypto state for a given clove_seq.
        # If a response is received, its migrated to long-term ETS storage
        Logger.info("[+] HIT CHECKPOINT RequestHelper.init_exchange/2 ADDING TEMP CRYPTO STATE")
        CryptoManager.add_temp_crypto_struct(temp_crypto_struct, clove_seq, crypto_mgr)
        {:ok, enc_req}

      err -> err
    end
  end

  @doc """
  Respond to a key exchange request from a remote proxy.
  """
  @spec gen_response(Request.t(), non_neg_integer, atom) ::
    {:ok, EncryptedRequest.t()} | {:error, atom}
  def gen_response(request, proxy_seq, crypto_mgr \\ :crypto_manager) do
    # TODO trace the proxy_seq number, make sure its generated and not the clove_seq
    # Generate cryptography primitives
    case CryptoStructHelper.gen_resp_crypto(request.crypto, crypto_mgr) do
      {:ok, %{
        crypto_struct: crypto_struct,
        encrypted_request: enc_req
      }} ->
        # Build and add crypto struct to long-term ETS storage
        CryptoManager.add_crypto_struct(crypto_struct, proxy_seq, crypto_mgr)
        {:ok, enc_req}

      err -> err
    end
  end

  @doc """
  Finish a key exchange with a remote proxy.
  Different from recv_finalise_exchange as this is called by the initiator.
  """
  @spec gen_finalise_exchange(Request.t(), non_neg_integer, non_neg_integer, atom) ::
    {:ok, EncryptedRequest.t()} | {:error, atom}
  def gen_finalise_exchange(request, proxy_seq, clove_seq, crypto_mgr \\ :crypto_manager) do
    Logger.info("[+] HIT CHECKPOINT RequestHelper.gen_finalise_exchange/4")
    temp_crypto_struct = CryptoManager.get_temp_crypto_struct(clove_seq, crypto_mgr)
    case CryptoStructHelper.gen_fin_crypto(request.crypto, temp_crypto_struct, crypto_mgr) do
      {:ok, %{
        crypto_struct: crypto_struct,
        encrypted_request: enc_req
      }} ->
        # Delete the temporary crypto record from the CryptoManager state
        CryptoManager.delete_temp_crypto(clove_seq, crypto_mgr)
        CryptoManager.add_crypto_struct(crypto_struct, proxy_seq, crypto_mgr)
        {:ok, enc_req}

      err -> err
    end

  end

  @doc """
  Finish a key exchange with a remote proxy.
  Different from gen_finalise_exchange as this is called by the receiver proxy.
  """
  @spec recv_finalise_exchange(Request.t(), non_neg_integer, atom) ::
    {:ok, EncryptedRequest.t()} | {:error, :invalid_signature}
  def recv_finalise_exchange(request, proxy_seq, crypto_mgr \\ :crypto_manager) do
    # Verify the validity of the signature
    cond do
      CryptoStructHelper.verify_ring_signature(request.crypto, proxy_seq) ->
        # Initiate key rotation
        init_key_rotation(proxy_seq, crypto_mgr)

      true -> {:error, :invalid_signature}
    end
  end

  @doc """
  Initiate key rotation with a remote proxy.
  """
  @spec init_key_rotation(non_neg_integer, atom) ::
    {:ok, EncryptedRequest.t()} | {:error, atom}
  def init_key_rotation(proxy_seq, crypto_mgr \\ :crypto_manager) do
    case CryptoStructHelper.gen_key_rotation(proxy_seq, crypto_mgr) do
      {:ok, %{
        crypto_struct: crypto_struct,
        encrypted_request: enc_req
      }} ->
        # Rotate the keys in the ETS table
        CryptoManager.rotate_keys(crypto_struct, proxy_seq, crypto_mgr)
        {:ok, enc_req}

      err -> err
    end
  end

  @doc """
  Perform key rotation request with a remote proxy.
  """
  @spec rotate_keys(Request.t(), non_neg_integer, atom) ::
    {:ok, EncryptedRequest.t()} | {:error, :invalid}
  def rotate_keys(%Request{crypto: {:key_rot, crypto_hdr}} = request, proxy_seq,
    crypto_mgr \\ :crypto_manager) do
    # TODO sanitise the request and get the appropraite map
    crypto_struct = %{
      symmetric_key: crypto_hdr.new_key,
    }

    case CryptoStructHelper.ack_key_rotation(proxy_seq, request.request_id, crypto_mgr) do
      {:ok, enc_req} -> # Rotate the keys in the ETS table
        CryptoManager.rotate_keys(crypto_struct, proxy_seq, crypto_mgr)
        {:ok, enc_req}

      err -> err
    end
  end

  @doc """
  Build the key exchange initialisation struct
  """
  @spec build_init_claimable(charlist, charlist, binary, charlist, {charlist, charlist},
    {charlist, charlist}) :: {:init_ke, KeyExchangeInit.t()}
  def build_init_claimable(identity, pk_ephem_sign, pk_dh, signature, {rs_ep, sig_ep},
    {rs_lt, sig_lt}) do
    {:init_ke, %KeyExchangeInit{
      identity: identity,
      pk_ephem_sign: pk_ephem_sign,
      signature: signature,
      pk_dh: pk_dh,
      pk_rs: {:crs_ephem, %CrsVerKey{rs_vk: rs_ep, sig_vk: sig_ep}},
      pk_lt: {:crs_lt, %CrsVerKey{rs_vk: rs_lt, sig_vk: sig_lt}},
      hmac_key: nil
    } |> format_export()}
  end

  @doc """
  Build the key exchange response struct
  """
  @spec build_resp_claimable(charlist, charlist, binary, charlist, {charlist, charlist},
    {charlist, charlist}, SAG.t()) :: {:resp_ke, KeyExchangeResponse.t()}
  def build_resp_claimable(identity, pk_ephem_sign, pk_dh, signature,  {rs_ep, sig_ep},
    {rs_lt, sig_lt}, ring_sig) do
    {:resp_ke, %KeyExchangeResponse{
      identity: identity,
      pk_ephem_sign: pk_ephem_sign,
      signature: signature,
      pk_dh: pk_dh,
      pk_rs: {:crs_ephem, %CrsVerKey{rs_vk: rs_ep, sig_vk: sig_ep}},
      pk_lt: {:crs_lt, %CrsVerKey{rs_vk: rs_lt, sig_vk: sig_lt}},
      ring_signature: format_sag_export(ring_sig),
      hmac_key: nil
    } |> format_export()}
  end

  @doc """
  Build the key exchange finalisation struct
  """
  @spec build_fin_claimable(SAG.t()) :: {:fin_ke, KeyExchangeFinal.t()}
  def build_fin_claimable(ring_sig) do
    {:fin_ke, %KeyExchangeFinal{
      ring_signature: format_sag_export(ring_sig),
      hmac_key: nil
    } |> format_export()}
  end

  @doc """
  Build a regular symmetric key struct
  Note: HMAC key is set when the HMAC is computed
  """
  @spec build_symmetric_crypto() :: {:sym_key, SymmetricKey.t()}
  def build_symmetric_crypto() do
    {:sym_key, %SymmetricKey{hmac_key: nil}}
  end

  @doc """
  Build a key rotation request struct
  """
  @spec build_key_rotation(binary) :: {:key_rot, KeyRotation.t()}
  def build_key_rotation(new_key) do
    {:key_rot, %KeyRotation{
      new_key: new_key,
      hmac_key: nil
    }}
  end

  @spec build_request({atom, struct}, binary, binary, non_neg_integer) :: Request.t()
  def build_request(crypto, data, req_type, req_id) do
    %Request{
      hmac: nil,
      request_id: req_id,
      request_type: req_type,
      data: data,
      crypto: crypto
    }
    |> CryptoStructHelper.set_hmac()
  end

  @spec wrap_unencrypted(Request.t()) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def wrap_unencrypted(request) do
    case serialise(request) do
      {:ok, data} -> {:ok, %EncryptedRequest{is_encrypted: false, iv: <<>>, data: data}}
      err -> err
    end
  end

  # ---- ProtoBuf wrappers ----
  @doc """
  Deserialise a request struct.
  """
  @spec deserialise(binary, Request | EncryptedRequest) ::
          {:ok, Request.t() | EncryptedRequest.t()} | {:error, any}
  def deserialise(data, struct) do
    # Deserialise the request
    ProtoBuf.deserialise(data, struct)
  end

  @doc """
  Deserialise to EncryptedRequest then finally to Request struct.
  If unencrypted, deserialise wrapped data.
  If encrypted, unwrap and decrypt request.
  """
  @spec deserialise_and_unwrap(binary) :: {:ok, Request.t()} | {:error, atom}
  def deserialise_and_unwrap(enc_request) do
    case deserialise(enc_request, EncryptedRequest) do
      {:ok, enc_req_struct} ->
        cond do
          enc_req_struct.is_encrypted -> # Encrypted (shouldn't happen)
            Logger.error("Invalid request: encrypted request received without proxy sequence")
            {:error, :encrypted}
          true -> # Unencrypted
            deserialise(enc_req_struct.data, Request)
        end
      err -> err
    end
  end
  @spec deserialise_and_unwrap(binary, integer, atom) :: {:ok, Request.t()} | {:error, atom}
  def deserialise_and_unwrap(enc_request, proxy_seq, crypto_mgr_name \\ :crypto_manager) do
    case deserialise(enc_request, EncryptedRequest) do
      {:ok, enc_req_struct} ->
        cond do
          enc_req_struct.is_encrypted -> # Encrypted
            decrypt_and_deserialise(enc_req_struct, proxy_seq, crypto_mgr_name)

          true -> # Unencrypted
            deserialise(enc_req_struct.data, Request)
        end
      err -> err
    end
  end

  @doc """
  Serialise a request struct.
  """
  @spec serialise(Request.t() | EncryptedRequest.t()) :: {:ok, binary} | {:error, any}
  def serialise(request) do
    # Serialise the request
    ProtoBuf.serialise(request)
  end

  @doc """
  Encrypt a Request struct and serialise to EncryptedRequest struct.
  """
  @spec encrypt_and_wrap(Request.t(), non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def encrypt_and_wrap(request, proxy_seq, crypto_mgr_name \\ :crypto_manager) do
    # Serialise the request
    case ProtoBuf.serialise(request) do
      {:ok, data} ->
        # Encrypt the request
        CryptoManager.encrypt_request(data, proxy_seq, crypto_mgr_name)

        err -> err
    end
  end

  # ---- Encoding/Decoding utilities ----
    # Convert a map to the appropriate struct
  @spec format_export(struct) :: struct
  def format_export(struct) do
    struct_type = struct.__struct__
    formatted = Enum.reduce(Map.from_struct(struct), %{}, fn
      {:__uf__, val}, acc -> Map.put(acc, :__uf__, val)
      {key, val}, acc when is_list(val) ->
        Map.put(acc, key, :binary.list_to_bin(val))

      {key, {atom, val}}, acc when is_map(val) -> # Recurse
        Map.put(acc, key, {atom, format_export(val)})

      {key, val}, acc -> Map.put(acc, key, val)
    end)
    struct(struct_type, formatted)
  end

  # Convert all fields in the struct to lists
  @spec format_import(struct) :: struct
  def format_import(struct) do
    struct_type = struct.__struct__
    formatted = Enum.reduce(Map.from_struct(struct), %{}, fn
      {:__uf__, val}, acc -> Map.put(acc, :__uf__, val)
      {key, val}, acc when is_binary(val) ->
        Map.put(acc, key, :binary.bin_to_list(val))

      {key, {atom, val}}, acc when is_map(val) -> # Recurse
        Map.put(acc, key, {atom, format_import(val)})

      {key, val}, acc -> Map.put(acc, key, val)
    end)
    struct(struct_type, formatted)
  end

  @spec format_sag_export(SAG.t() | {SAG.t(), list}) :: SAG.t() | {SAG.t(), list}
  def format_sag_export({sag, commit}), do: {format_sag_export(sag), commit}
  def format_sag_export(sag) do
    Enum.reduce(Map.from_struct(sag), %SAG{}, fn
      {:__uf__, val}, acc -> Map.put(acc, :__uf__, val)
      {key, [h | _] = val}, acc when is_list(h) -> # Format nested signatures
        Map.put(acc, key, Enum.map(val, & :binary.list_to_bin/1))

      {key, val}, acc when is_list(val) -> Map.put(acc, key, :binary.list_to_bin(val))

      {key, val}, acc -> Map.put(acc, key, val) # Default case
    end)
  end

  @spec format_sag_import(SAG.t() | {SAG.t(), list}) :: SAG.t() | {SAG.t(), list}
  def format_sag_import({sag, commit}), do: {format_sag_import(sag), commit}
  def format_sag_import(sag) do
    Enum.reduce(Map.from_struct(sag), %SAG{}, fn
      {:__uf__, val}, acc -> Map.put(acc, :__uf__, val)
      {key, [h | _] = val}, acc when is_binary(h) -> # Format nested signatures
        Map.put(acc, key, Enum.map(val, & :binary.bin_to_list/1))

      {key, val}, acc when is_binary(val) -> Map.put(acc, key, :binary.bin_to_list(val))

      {key, val}, acc -> Map.put(acc, key, val) # Default case
    end)
  end

  # ---- Private functions ----
  # Decrypts an EncryptedRequest wrapper struct and deserialises its data to Request struct
  @spec decrypt_and_deserialise(EncryptedRequest.t(), non_neg_integer, atom) :: {:ok, Request.t()} | {:error, atom}
  defp decrypt_and_deserialise(enc_req_struct, proxy_seq, crypto_mgr_name) do
    case CryptoManager.decrypt_request(enc_req_struct, proxy_seq, crypto_mgr_name) do
      {:ok, data} ->
        case deserialise(data, Request) do
          # Verify the validity of the HMAC
          {:ok, request} -> CryptoStructHelper.check_hmac(request)

          err -> err
        end
      err -> err
    end
  end
end
