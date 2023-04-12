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
  @spec deserialise(binary) :: {:ok, map} | {:error, any}
  def deserialise(data) do
    # Deserialise the request
    case ProtoBuf.deserialise(data, Request) do
      {:ok, request} -> {:ok, request}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deserialise an encrypted request struct.
  """
  @spec deserialise_encrypted(binary, non_neg_integer, atom) :: {:ok, map} | {:error, any}
  def deserialise_encrypted(enc_request, proxy_seqm, crypto_mgr_name \\ :crypto_manager)

  def deserialise_encrypted(
        %EncryptedRequest{is_encrypted: false, data: data},
        _proxy_seq,
        _crypto_mgr_name
      ) do
    deserialise(data)
  end

  def deserialise_encrypted(enc_request, proxy_seq, crypto_mgr_name) do
    # Decrypt the request
    case CryptoManager.decrypt_request(enc_request, proxy_seq, crypto_mgr_name) do
      {:ok, data} -> deserialise(data)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Serialise a request struct.
  """
  @spec serialise(Request) :: {:ok, binary} | {:error, any}
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
  @spec serialise_encrypted(Request, non_neg_integer, atom) :: {:ok, binary} | {:error, any}
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
