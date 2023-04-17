defmodule LAP2.Utils.ProtoBuf.RequestHelper do
  @moduledoc """
  Helper functions for processing LAP2 requests.
  Verifies integrity, serves as interface for serialising/deserialising with ProtoBuf.
  """

  alias LAP2.Networking.ProtoBuf
  alias LAP2.Crypto.CryptoManager

  # ---- ProtoBuf wrappers ----
  @doc """
  Deserialise a request struct.
  """
  @spec deserialise(binary, Request | EncryptedRequest) :: {:ok, Request.t | EncryptedRequest.t} | {:error, any}
  def deserialise(data, struct) do
    # Deserialise the request
    ProtoBuf.deserialise(data, struct)
  end

  @doc """
  Deserialise an encrypted request struct.
  """
  @spec deserialise_encrypted(binary, integer, atom) :: any
  def deserialise_encrypted(enc_request, proxy_seq, crypto_mgr_name \\ :crypto_manager)
  def deserialise_encrypted(enc_request, proxy_seq, crypto_mgr_name) do
    enc_req_struct = deserialise(enc_request, EncryptedRequest)
    case CryptoManager.decrypt_request(enc_req_struct, proxy_seq, crypto_mgr_name) do
      {:ok, data} -> deserialise(data, Request)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Serialise a request struct.
  """
  @spec serialise(Request.t) :: {:ok, binary} | {:error, any}
  def serialise(request) do
    # Serialise the request
    case ProtoBuf.serialise(request) do
      {:ok, data} -> {:ok, IO.iodata_to_binary(data)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Encrypt a Request struct and serialise to EncryptedRequest struct.
  """
  @spec serialise_encrypted(Request.t, non_neg_integer, atom) :: {:ok, binary} | {:error, any}
  def serialise_encrypted(request, proxy_seq, crypto_mgr_name \\ :crypto_manager) do
    # Serialise the request
    case ProtoBuf.serialise(request) do
      {:ok, data} ->
        # Encrypt the request
        case CryptoManager.encrypt_request(data, proxy_seq, crypto_mgr_name) do
          {:ok, enc_request} -> ProtoBuf.serialise(enc_request)
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
