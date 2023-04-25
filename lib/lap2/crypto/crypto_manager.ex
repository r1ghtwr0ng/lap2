defmodule LAP2.Crypto.CryptoManager do
  @moduledoc """
  Module for managing the state of cryptographic information for proxy connections.
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
  def init(config) do
    # Ensure that the ETS gets cleaned up on exit
    Process.flag(:trap_exit, true)
    # Initialise data handler state
    IO.puts("[i] CryptoManager (#{config.name}): Starting GenServer")
    state = %{
      ets: :ets.new(:key_manager, [:set, :private]),
      temp_crypto: %{},
      config: config,
    }
    {:ok, state}
  end

  # ---- GenServer Callbacks (Crypto Operations) ----
  @spec handle_call({:rotate_keys, %{symmetric_key: binary}, non_neg_integer}, any, map) :: {:reply, :ok, map}
  def handle_call({:rotate_keys, crypto_struct, proxy_seq}, _from, state) do
    rot_keys(state.ets, crypto_struct, proxy_seq)
    {:reply, :ok, state}
  end

  @spec handle_call({:decrypt, EncryptedRequest.t(), non_neg_integer}, any, map) ::
          {:reply, {:ok, binary} | {:error, :no_key}, map}
  def handle_call({:decrypt, encrypted_req, proxy_seq}, _from, state) do
    return = fetch_and_decrypt(state.ets, encrypted_req, proxy_seq)
    # {_crypto, _response} = Map.pop(encrypted_req, :crypto)
    # TODO handle crypto request
    # Delete crypto information from response to avoid leaking keys
    {:reply, return, state}
  end

  @spec handle_call({:encrypt, binary, non_neg_integer}, any, map) :: {:reply, tuple, map}
  def handle_call({:encrypt, data, proxy_seq}, _from, state) do
    response = fetch_and_encrypt(state.ets, data, proxy_seq)
    {:reply, response, state}
  end

  # ---- GenServer Callbacks (Struct Operations) ----
  # TODO important: for debugging only, remove once finished
  @spec handle_call({:add_crypto_struct, map, non_neg_integer}, any, map) :: {:reply, :ok, map}
  def handle_call({:add_crypto_struct, crypto_struct, proxy_seq}, _from, state) do
    ets_add_crypto_struct(state.ets, crypto_struct, proxy_seq)
    {:reply, :ok, state}
  end

  @spec handle_call({:remove_crypto_struct, non_neg_integer}, any, map) :: {:reply, :ok, map}
  def handle_call({:remove_crypto_struct, proxy_seq}, _from, state) do
    ets_remove_crypto_struct(state.ets, proxy_seq)
    {:reply, :ok, state}
  end

  @spec handle_call({:add_temp_crypto_struct, map, non_neg_integer}, any, map) :: {:reply, :ok, map}
  def handle_call({:add_temp_crypto_struct, crypto_struct, clove_seq}, _from, state) do
    new_state = set_temp_crypto(state, crypto_struct, clove_seq)
    {:reply, :ok, new_state}
  end

  @spec handle_call({:delete_temp_crypto, non_neg_integer}, any, map) :: {:reply, :ok, map}
  def handle_call({:delete_temp_crypto, clove_seq}, _from, state) do
    new_state = remove_temp_crypto(state, clove_seq)
    {:reply, :ok, new_state}
  end

  @spec handle_call({:get_identity}, any, map) :: {:reply, binary, map}
  def handle_call({:get_identity}, _from, state), do: {:reply, state.config.identity, state}

  # Cleanup the ETS table on exit
  @spec terminate(any, map) :: :ok
  def terminate(_reason, state) do
    :ets.delete(state.ets)
    :ok
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

  # ---- Public Functions (Struct Operations) ----
  @doc """
  Add a crypto struct to the ETS table.
  TODO this is for testing ONLY, remove for final version (as well as its genserver call)
  """
  @spec add_crypto_struct(map, non_neg_integer, atom) :: :ok
  def add_crypto_struct(crypto_struct, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:add_crypto_struct, crypto_struct, proxy_seq})
  end

  @doc """
  Add a temporary crypto struct to the ETS table.
  """
  @spec add_temp_crypto_struct(map, non_neg_integer, atom) :: :ok
  def add_temp_crypto_struct(crypto_struct, clove_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:add_temp_crypto_struct, crypto_struct, clove_seq})
  end

  @doc """
  Add a temporary crypto struct to the ETS table.
  """
  @spec delete_temp_crypto(non_neg_integer, atom) :: :ok
  def delete_temp_crypto(clove_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:delete_temp_crypto, clove_seq})
  end

  @doc """
  Remove a crypto struct from the ETS table.
  """
  @spec remove_crypto_struct(non_neg_integer, atom) :: :ok
  def remove_crypto_struct(proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:remove_crypto_struct, proxy_seq})
  end

  @doc """
  Perform key rotation request with a remote proxy.
  """
  @spec rotate_keys(map, non_neg_integer, atom) :: :ok
  def rotate_keys(crypto_struct, proxy_seq, name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:rotate_keys, crypto_struct, proxy_seq})
  end

  @doc """
  Fetch the crypto identity from the GenServer state.
  """
  @spec get_identity(atom) :: binary
  def get_identity(name \\ :crypto_manager) do
    GenServer.call({:global, name}, {:get_identity})
  end

  # ---- Private ETS Functions (Crypto Operations) ----
  # Fetch the key from the ETS table and decrypt the request
  @spec fetch_and_decrypt(:ets.tid(), binary, non_neg_integer) :: {:ok, binary} | {:error, atom}
  defp fetch_and_decrypt(ets, encrypted_req, proxy_seq) do
    case :ets.lookup(ets, proxy_seq) do
      [{_proxy_seq, _crypto_struct}] ->
        Logger.info("[i] Decrypting proxy request")

        pt = encrypted_req.data
        # :crypto.crypto_one_time(:aes_256_cbc, crypto_struct.symmetric_key, encrypted_req.iv, encrypted_req.data, false)
        #{:ok, PKCS7.unpad(pt)}
        {:ok, pt}

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
      [{_proxy_seq, _crypto_struct}] ->
        Logger.info("[i] Encrypting proxy request")
        iv = :crypto.strong_rand_bytes(16)
        ct = data
        # TODO once key exchange is implemented, use this
        #ct = :crypto.crypto_one_time(:aes_256_cbc, crypto_struct.symmetric_key, iv, PKCS7.pad(data, 16), true)

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
  defp ets_add_crypto_struct(ets, crypto_struct, proxy_seq) do
    :ets.insert(ets, {proxy_seq, crypto_struct})
  end

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
  @spec remove_temp_crypto(map, non_neg_integer) :: map
  defp remove_temp_crypto(state, clove_seq) do
    # TODO figure out if the old crypto state is needed
    Map.put(state, :temp_crypto, Map.delete(state.temp_crypto, clove_seq))
  end
end
