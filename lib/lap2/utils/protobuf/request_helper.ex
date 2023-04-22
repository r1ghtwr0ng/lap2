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
  Build the key exchange initialisation struct
  """
  @spec build_init_crypto(binary, binary, binary, binary, binary) :: {:init_ke, KeyExchangeInit.t()}
  def build_init_crypto(identity, ephem_pk, generator, ring_pk, signature) do
    {:init_ke, %KeyExchangeInit{
      identity: identity,
      ephemeral_pk: ephem_pk,
      generator: generator,
      ring_pk: ring_pk,
      signature: signature,
      hmac_key: nil
    }}
  end

  @doc """
  Build the key exchange response struct
  """
  @spec build_resp_crypto(binary, binary, binary, binary, binary, binary) :: {:resp_ke, KeyExchangeResponse.t()}
  def build_resp_crypto(identity, ephem_pk, generator, ring_pk, signature, ring_sign) do
    {:resp_ke, %KeyExchangeResponse{
      identity: identity,
      ephemeral_pk: ephem_pk,
      generator: generator,
      ring_pk: ring_pk,
      signature: signature,
      ring_signature: ring_sign,
      hmac_key: nil
    }}
  end

  @doc """
  Build the key exchange finalisation struct
  """
  @spec build_fin_crypto(binary) :: {:fin_ke, KeyExchangeFinal.t()}
  def build_fin_crypto(ring_sign) do
    {:fin_ke, %KeyExchangeFinal{
      ring_signature: ring_sign,
      hmac_key: nil
    }}
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

  @spec build_request({atom, struct()}, binary, binary, non_neg_integer) :: Request.t()
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
      {:ok, data} -> %EncryptedRequest{is_encrypted: false, iv: <<>>, data: data}
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
    case ProtoBuf.serialise(request) do
      {:ok, data} -> {:ok, IO.iodata_to_binary(data)}
      err -> err
    end
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
