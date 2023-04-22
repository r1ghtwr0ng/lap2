defmodule LAP2.Crypto.CryptoManager do
  @moduledoc """
  Module for managing the state of cryptographic information for proxy connections.
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
      temp_crypto: %{},
      config: config,
    }
    {:ok, state}
  end

  # ---- GenServer Callbacks (Key Exchange) ----
  @spec handle_call({:init_exchange, non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:init_exchange, clove_seq}, state) do
    %{temp_crypto_struct: temp_crypto_struct, encrypted_request: resp} = CryptoStructHelper.gen_init_crypto(state.config.identity)
    # Update the temporary crypto state for a given clove_seq.
    # If a response is received, its migrated to long-term ETS storage
    new_state = set_temp_crypto(state, temp_crypto_struct, clove_seq)
    {:reply, resp, new_state}
  end

  @spec handle_call({:gen_response, Request.t(), non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:gen_response, request, proxy_seq}, state) do
    # TODO trace the proxy_seq number, make sure its generated and not the clove_seq
    # Generate cryptography primitives
    %{crypto_struct: crypto_struct, encrypted_request: resp} = CryptoStructHelper.gen_resp_crypto(state.config.identity, request.crypto)

    # Update proxy crypto state in ETS
    recv_init(state.ets, crypto_struct, proxy_seq)
    {:reply, resp, state}
  end

  @spec handle_call({:gen_finalise_exchange, Request.t(), non_neg_integer, non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:gen_finalise_exchange, request, clove_seq, proxy_seq}, state) do
    %{crypto_struct: crypto_struct, encrypted_request: resp} = CryptoStructHelper.gen_fin_crypto(request.crypto)
    # TODO migrate the temporary crypto state (clove_seq key) to the long-term ETS storage (proxy_seq)
    new_state = delete_temp_crypto(state, clove_seq)
    recv_resp(state.ets, crypto_struct, proxy_seq)
    {:reply, resp, new_state}
  end

  @spec handle_call({:recv_finalise_exchange, Request.t(), non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:recv_finalise_exchange, request, proxy_seq}, state) do
    # Verify the validity of the signature
    cond do
      CryptoStructHelper.verify_ring_signature(request.crypto, proxy_seq) ->
        # Initiate key rotation
        resp = GenServer.call({:global, state.config.name}, {:init_key_rotation, proxy_seq})
        {:reply, resp, state}
      true -> {:reply, {:error, :invalid_signature}, state}
    end

  end

  @spec handle_call({:init_key_rotation, non_neg_integer}, map) :: {:reply, tuple, map}
  def handle_call({:init_key_rotation, proxy_seq}, state) do
    %{crypto_struct: crypto_struct, encrypted_request: resp} = CryptoStructHelper.gen_key_rotation(proxy_seq, state.config.registry_table.crypto_manager)
    rot_keys(state.ets, crypto_struct, proxy_seq)
    {:reply, resp, state}
  end

  @spec handle_call({:rotate_keys, Request.t(), non_neg_integer}, map) :: {:noreply, tuple, map}
  def handle_call({:rotate_keys, request, proxy_seq}, state) do
    # TODO sanitise the request and get the appropraite map
    crypto_struct = %{
      symmetric_key: request.crypto.symmetric_key,
    }
    rot_keys(state.ets, crypto_struct, proxy_seq)
    resp = CryptoStructHelper.ack_key_rotation(proxy_seq, request.request_id, state.config.registry_table.crypto_manager)
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

  # TODO important: for debugging only, remove once finished
  def handle_call({:add_crypto_struct, key, proxy_seq}, state) do
    ets_add_crypto_struct(state.ets, key, proxy_seq)
    {:noreply, state}
  end

  @spec handle_cast({:remove_crypto_struct, non_neg_integer}, map) :: {:noreply, map}
  def handle_cast({:remove_crypto_struct, proxy_seq}, state) do
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
  def init_exchange(request, clove_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:init_exchange, request, clove_seq})
  end

  @doc """
  Respond to a key exchange request from a remote proxy.
  """
  @spec gen_response(Request.t(), non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def gen_response(request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:gen_response, request, proxy_seq})
  end

  @doc """
  Finish a key exchange with a remote proxy.
  Different from recv_finalise_exchange as this is called by the initiator.
  """
  @spec gen_finalise_exchange(Request.t(), non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def gen_finalise_exchange(request, proxy_seq, clove_seq, name \\ :crypto_manager) do
    # TODO trace the clove_seq number
    GenServer.call({:global, name}, {:gen_finalise_exchange, request, clove_seq, proxy_seq})
  end

  @doc """
  Finish a key exchange with a remote proxy.
  Different from gen_finalise_exchange as this is called by the receiver proxy.
  """
  @spec recv_finalise_exchange(Request.t(), non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def recv_finalise_exchange(request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:recv_finalise_exchange, request, proxy_seq})
  end

  @doc """
  Initiate key rotation with a remote proxy.
  """
  @spec init_key_rotation(non_neg_integer, atom) :: {:ok, EncryptedRequest.t()} | {:error, atom}
  def init_key_rotation(proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:init_key_rotation, proxy_seq})
  end

  @doc """
  Perform key rotation request with a remote proxy.
  """
  @spec rotate_keys(Request.t(), non_neg_integer, atom) :: :ok
  def rotate_keys(request, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:rotate_keys, request, proxy_seq})
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
  @spec recv_init(:ets.tid(), map, non_neg_integer) :: :ok
  defp recv_init(ets, crypto_struct, proxy_seq) do
    # TODO, also figure out whats up with the proxy sequence
    new_struct = %{
      identity: crypto_struct.identity,
      long_term_rs_pk: crypto_struct.long_term_rs_pk,
      ephemeral_dh_pk: crypto_struct.ephemeral_dh_pk,
      asymmetric_key: crypto_struct.asymmetric_key
    }
    ets_add_crypto_struct(ets, new_struct, proxy_seq)
    :ok
  end

  # Update ETS with key exchange response info
  @spec recv_resp(:ets.tid(), map, non_neg_integer) :: :ok
  defp recv_resp(ets, crypto_struct, proxy_seq) do
    # Append info to crypto struct
    new_struct = %{
      identity: crypto_struct.identity,
      long_term_rs_pk: crypto_struct.long_term_rs_pk,
      ephemeral_dh_pk: crypto_struct.ephemeral_dh_pk,
      asymmetric_key: crypto_struct.asymmetric_key
    }
    ets_add_crypto_struct(ets, new_struct, proxy_seq)
    :ok
  end

  # Update ETS with key rotation request info
  @spec rot_keys(:ets.tid(), map, non_neg_integer) :: :ok
  defp rot_keys(ets, %{symmetric_key: _} = crypto_struct, proxy_seq) do
    ets_update_crypto_struct(ets, crypto_struct, proxy_seq)
    :ok
  end

  # ---- Private Functions (State Operations) ----
  # Set the temp crypto struct inside the state map
  @spec set_temp_crypto(map, map, non_neg_integer) :: map
  defp set_temp_crypto(state, temp_crypto, clove_seq) do
    Map.put(state, :temp_crypto, Map.put(state.temp_crypto, clove_seq, temp_crypto))
  end

  # Delete the temp crypto struct from the state map
  @spec delete_temp_crypto(map, non_neg_integer) :: map
  defp delete_temp_crypto(state, clove_seq) do
    # TODO figure out if the old crypto state is needed
    _temp_crypto = Map.get(state.temp_crypto, clove_seq)
    Map.put(state, :temp_crypto, Map.delete(state.temp_crypto, clove_seq))
  end
end
