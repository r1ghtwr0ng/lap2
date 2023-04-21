defmodule LAP2.Crypto.CryptoManager do
  @moduledoc """
  Module for managing cryptographic keys and operations.
  """

  use GenServer
  require Logger
  alias LAP2.Crypto.Padding.PKCS7
  alias LAP2.Crypto.Helpers.CryptoStructHelper

  @ets_crypto_struct %{
    asymmetric_key: nil,
    symmetric_key: nil,
    identity: nil,
    long_term_rs_pk: nil,
    ephemeral_dh_pk: nil
  }

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
  def init(config) do
    # Ensure that the ETS gets cleaned up on exit
    Process.flag(:trap_exit, true)
    # Initialise data handler state
    IO.puts("[i] CryptoManager: Starting GenServer")
    state = %{
      ets: :ets.new(:key_manager, [:set, :private]),
      identity: config.identity}
    {:ok, state}
  end

  # ---- GenServer Callbacks (Key Exchange) ----
  @spec handle_call({:init_exchange, Request.t(), non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:init_exchange, request, proxy_seq}, state) do
    {_crypt_type, _crypt_struct} = CryptoStructHelper.gen_init_crypto(state.identity, request, proxy_seq)
    resp = {:ok, %EncryptedRequest{}} # TODO
    {:reply, resp, state}
  end

  @spec handle_call({:respond_exchange, Request.t(), non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:respond_exchange, request, proxy_seq}, state) do
    # Generate cryptography primitives
    crypto_struct = CryptoStructHelper.gen_resp_crypto(state.identity, request.crypto)
    # Update proxy crypto state in ETS
    recv_init(state.ets, request.crypto, proxy_seq, crypto_struct.asymmetric_key)
    # TODO generate response
    resp = {:ok, %EncryptedRequest{}} # TODO
    {:reply, resp, state}
  end

  @spec handle_call({:send_finalise_exchange, Request.t(), non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:send_finalise_exchange, request, proxy_seq}, state) do
    crypto_struct = CryptoStructHelper.gen_fin_crypto(request.crypto)
    recv_resp(state.ets, request.crypto, proxy_seq, crypto_struct.asymmetric_key)
    resp = {:ok, %EncryptedRequest{}} # TODO
    {:reply, resp, state}
  end

  @spec handle_call({:recv_finalise_exchange, Request.t(), non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:recv_finalise_exchange, _request, proxy_seq}, state) do
    # TODO sanitise the request and get the appropraite map
    {_crypt_type, crypt_struct} = CryptoStructHelper.gen_key_rotation()
    recv_rot(state.ets, crypt_struct, proxy_seq)
    resp = {:ok, %EncryptedRequest{}} # TODO
    {:reply, resp, state}
  end

  # ---- GenServer Callbacks (Crypto Operations) ----
  @spec handle_call({:decrypt, EncryptedRequest.t(), non_neg_integer}, map) ::
          {:reply, {:ok, binary} | {:error, :no_key}, map}
  def handle_call({:decrypt, encrypted_req, proxy_seq}, state) do
    {:ok, decrypted} = fetch_and_decrypt(state.ets, encrypted_req, proxy_seq)
    # {_crypto, _response} = Map.pop(encrypted_req, :crypto)
    # TODO handle crypto request
    # Delete crypto information from response to avoid leaking keys
    {:reply, decrypted, state}
  end

  @spec handle_call({:encrypt, binary, non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:encrypt, data, proxy_seq}, state) do
    response = fetch_and_encrypt(state.ets, data, proxy_seq)
    {:reply, response, state}
  end

  def handle_call({:add_crypto_struct, key, proxy_seq}, state) do
    # TODO important: for debugging only, remove once finished
    ets_add_crypto_struct(state.ets, key, proxy_seq)
    {:noreply, state}
  end

  def handle_call({:remove_crypto_struct, proxy_seq}, state) do
    ets_remove_crypto_struct(state.ets, proxy_seq)
    {:noreply, state}
  end

  # Cleanup the ETS table on exit
  @spec terminate(any, map) :: :ok
  def terminate(_reason, state) do
    :ets.delete(state.ets)
    :ok
  end

  # ---- Public Functions (Key Exchange) ----
  @doc """
  Initiate a key exchange with a remote proxy.
  """
  @spec init_exchange(Request.t(), non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def init_exchange(request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:init_exchange, proxy_seq, request})
  end

  @doc """
  Respond to a key exchange request from a remote proxy.
  """
  @spec respond_exchange(Request.t(), non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def respond_exchange(request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:respond_exchange, proxy_seq, request})
  end

  @doc """
  Finish a key exchange with a remote proxy.
  Different from recv_finalise_exchange as this is called by the initiator.
  """
  @spec send_finalise_exchange(Request.t(), non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def send_finalise_exchange(request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:send_finalise_exchange, request, proxy_seq})
  end

  @doc """
  Finish a key exchange with a remote proxy.
  Different from send_finalise_exchange as this is called by the receiver proxy.
  """
  @spec recv_finalise_exchange(Request.t(), non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def recv_finalise_exchange(request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:recv_finalise_exchange, request, proxy_seq})
  end

  @doc """
  Generate new keys and create key rotation request struct with them.
  """
  @spec rotate_keys(non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def rotate_keys(proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:rotate_keys, proxy_seq})
  end

  # ---- Public Functions (Crypto Operations) ----
  @doc """
  Decrypt a request using the key stored in the ETS table.
  Return binary for deserialisation.
  """
  @spec decrypt_request(EncryptedRequest.t(), non_neg_integer, atom) :: {:ok, binary} | {:error, atom}
  def decrypt_request(enc_request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:decrypt, enc_request, proxy_seq})
  end

  @doc """
  Encrypt a serialised (binary) request, returning an EncryptedRequest struct.
  """
  @spec encrypt_request(binary, non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, :no_key}
  def encrypt_request(data, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:encrypt, data, proxy_seq})
  end

  @doc """
  Add a crypto struct to the ETS table.
  TODO this is for testing ONLY, remove for final version (as well as its genserver call)
  """
  @spec add_crypto_struct(binary, non_neg_integer, atom) :: :ok
  def add_crypto_struct(key, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:add_crypto_struct, key, proxy_seq})
  end

  @doc """
  Remove a crypto struct from the ETS table.
  """
  @spec remove_crypto_struct(non_neg_integer, atom) :: :ok
  def remove_crypto_struct(proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:remove_crypto_struct, proxy_seq})
  end

  # ---- Private ETS Functions (Crypto Operations) ----
  # Fetch the key from the ETS table and decrypt the request
  @spec fetch_and_decrypt(:ets.tid(), binary, non_neg_integer) :: {:ok, binary} | {:error, atom}
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
  @spec fetch_and_encrypt(:ets.tid(), binary, non_neg_integer) ::
          {:ok, EncryptedRequest.t()} | {:error, :no_key}
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
  @spec ets_add_crypto_struct(:ets.tid(), map, non_neg_integer) :: true
  defp ets_add_crypto_struct(ets, crypto_struct, proxy_seq), do: :ets.insert(ets, {proxy_seq, crypto_struct})

  # Remove a key from the ETS table
  @spec ets_remove_crypto_struct(:ets.tid(), non_neg_integer) :: true
  defp ets_remove_crypto_struct(ets, proxy_seq), do: :ets.delete(ets, proxy_seq)

  # Update a part of an ETS crypto struct
  @spec ets_update_crypto_struct(:ets.tid(), map, non_neg_integer) :: :ok | {:error, :no_key}
  defp ets_update_crypto_struct(ets, new_struct, proxy_seq) do
    case :ets.lookup(ets, proxy_seq) do
      [{_proxy_seq, current_struct}] ->
        :ets.insert(ets, {proxy_seq, Map.merge(current_struct, new_struct)})
        :ok

      [] ->
        Logger.info("[i] No key found for proxy request")
        {:error, :no_key}
    end
  end

  # Update ETS with key exchange initialisation info
  @spec recv_init(:ets.tid(), KeyExchangeInit.t(), non_neg_integer, binary) :: :ok
  defp recv_init(ets, %KeyExchangeInit{} = crypto_struct, proxy_seq, asymmetric_key) do
    # TODO, also figure out whats up with the proxy sequence
    new_struct = %{
      identity: crypto_struct.identity,
      long_term_rs_pk: crypto_struct.ring_pk,
      ephemeral_dh_pk: crypto_struct.ephemeral_pk,
      asymmetric_key: asymmetric_key
    }
    ets_add_crypto_struct(ets, new_struct, proxy_seq)
    :ok
  end

  # Update ETS with key exchange response info
  @spec recv_resp(:ets.tid(), KeyExchangeResponse.t(), non_neg_integer, binary) :: :ok
  defp recv_resp(ets, %KeyExchangeResponse{} = crypto_struct, proxy_seq, asymmetric_key) do
    # Append info to crypto struct
    new_struct = %{
      identity: crypto_struct.identity,
      long_term_rs_pk: crypto_struct.ring_pk,
      ephemeral_dh_pk: crypto_struct.ephemeral_pk,
      asymmetric_key: asymmetric_key
    }
    ets_add_crypto_struct(ets, new_struct, proxy_seq)
    :ok
  end

  # Update ETS with key rotation request info
  @spec recv_rot(:ets.tid(), KeyRotation.t(), non_neg_integer) :: :ok
  defp recv_rot(ets, %KeyRotation{} = crypto_struct, proxy_seq) do
    new_struct = %{
      symmetric_key: crypto_struct.new_key,
    }
    ets_update_crypto_struct(ets, new_struct, proxy_seq)
    :ok
  end
end
