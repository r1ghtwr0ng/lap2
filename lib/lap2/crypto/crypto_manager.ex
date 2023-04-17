defmodule LAP2.Crypto.CryptoManager do
  @moduledoc """
  Module for managing cryptographic keys and operations.
  """

  use GenServer
  require Logger
  alias LAP2.Crypto.Padding.PKCS7

  @doc """
  Start the CryptoManager process.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: {:global, config.name})
  end

  @doc """
  Initialise the data handler GenServer.
  """
  @spec init(map) :: {:ok, map}
  def init(_config) do
    # Ensure that the ETS gets cleaned up on exit
    Process.flag(:trap_exit, true)
    # Initialise data handler state
    IO.puts("[i] CryptoManager: Starting GenServer")
    state = %{ets: :ets.new(:key_manager, [:set, :private])}
    {:ok, state}
  end

  # ---- GenServer Callbacks ----
  @spec handle_call({:decrypt, EncryptedRequest.t, non_neg_integer}, map) ::
    {:reply, {:ok, binary} | {:error, :no_key}, map}
  def handle_call({:decrypt, encrypted_req, proxy_seq}, state) do
    {:ok, decrypted} = fetch_and_decrypt(state.ets, encrypted_req, proxy_seq)
    #{_crypto, _response} = Map.pop(encrypted_req, :crypto)
    # TODO handle crypto request
    # Delete crypto information from response to avoid leaking keys
    {:reply, decrypted, state}
  end

  @spec handle_call({:encrypt, binary, non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:encrypt, data, proxy_seq}, state) do
    response = fetch_and_encrypt(state.ets, data, proxy_seq)
    {:reply, response, state}
  end

  def handle_call({:add_key, key, proxy_seq}, state) do
    ets_add_key(state.ets, key, proxy_seq)
    {:noreply, state}
  end

  def handle_call({:remove_key, proxy_seq}, state) do
    ets_remove_key(state.ets, proxy_seq)
    {:noreply, state}
  end

  # Cleanup the ETS table on exit
  @spec terminate(any, map) :: :ok
  def terminate(_reason, state) do
    :ets.delete(state.ets)
    :ok
  end

  # ---- Public Functions ----
  @doc """
  Decrypt a request using the key stored in the ETS table.
  Return binary for deserialisation.
  """
  @spec decrypt_request(EncryptedRequest.t, non_neg_integer, atom) :: {:ok, binary} | {:error, atom}
  def decrypt_request(enc_request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:decrypt, enc_request, proxy_seq})
  end

  @doc """
  Encrypt a serialised (binary) request, returning an EncryptedRequest struct.
  """
  @spec encrypt_request(binary, non_neg_integer, atom) :: {:ok, EncryptedRequest.t} | {:error, :no_key}
  def encrypt_request(data, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:encrypt, data, proxy_seq})
  end

  @doc """
  Add a key to the ETS table.
  """
  @spec add_key(binary, non_neg_integer, atom) :: :ok
  def add_key(key, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:add_key, key, proxy_seq})
  end

  @doc """
  Remove a key from the ETS table.
  """
  @spec remove_key(non_neg_integer, atom) :: :ok
  def remove_key(proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:remove_key, proxy_seq})
  end

  # ---- Private ETS Functions ----
  # Fetch the key from the ETS table and decrypt the request
  @spec fetch_and_decrypt(:ets.tid, binary, non_neg_integer) :: {:ok, binary} | {:error, atom}
  defp fetch_and_decrypt(ets, encrypted_req, proxy_seq) do
    case :ets.lookup(ets, proxy_seq) do
      [{_proxy_seq, key}] ->
        Logger.info("[i] Decrypting proxy request")

        pt =
          :crypto.crypto_one_time(:aes_256_cbc, key, encrypted_req.iv, encrypted_req.data, false)

        {:ok, PKCS7.unpad(pt)}

      [] ->
        Logger.info("[i] No key found for proxy request")
        {:error, :no_key}
    end
  end

  # Encrypt the request data and add to EncryptedRequest struct
  @spec fetch_and_encrypt(:ets.tid, binary, non_neg_integer) ::
          {:ok, EncryptedRequest} | {:error, :no_key}
  defp fetch_and_encrypt(ets, data, proxy_seq) do
    case :ets.lookup(ets, proxy_seq) do
      [{_proxy_seq, key}] ->
        Logger.info("[i] Encrypting proxy request")
        iv = :crypto.strong_rand_bytes(16)
        ct = :crypto.crypto_one_time(:aes_256_cbc, key, iv, PKCS7.pad(data, 16), true)

        encrypted_req = %EncryptedRequest{
          is_encrypted: true,
          iv: iv,
          data: ct
        }

        {:ok, encrypted_req}

      [] ->
        Logger.info("[i] No key found for proxy request")
        {:error, :no_key}
    end
  end

  # Add a key to the ETS table
  @spec add_key(:ets.tid, binary, non_neg_integer) :: :ok
  defp ets_add_key(ets, key, proxy_seq), do: :ets.insert(ets, {proxy_seq, key})

  # Remove a key from the ETS table
  @spec remove_key(:ets.tid, non_neg_integer) :: :ok
  defp ets_remove_key(ets, proxy_seq), do: :ets.delete(ets, proxy_seq)
end
