defmodule LAP2.Crypto.KeyExchange.C_RSDAKETest do
  use ExUnit.Case
  alias LAP2.Crypto.KeyExchange.C_RSDAKE
  alias LAP2.Crypto.Constructions.ClaimableRS
  doctest LAP2.Crypto.KeyExchange.C_RSDAKE

  describe "initialise/1" do
    test "Initialise with valid identity" do
      ident = 'IDENTITY'
      {:ok, {init_state, init_send}} = C_RSDAKE.initialise(ident)

      # Verify crypto state structure
      assert verify_crypto_state(init_state)

      # Verify outbound message structure
      assert verify_init_struct(init_send)
    end

    test "Initialise with invalid identity" do
      ident = "IDENTITY"
      expected = {:error, :invalid_identity}
      # Verify error handling
      assert expected == C_RSDAKE.initialise(ident)
    end
  end

  describe "respond/3" do
    test "Test with valid identity and request" do
      # Setup arguments
      ident_i = 'IDENTITY_INITIATOR'
      ident_r = 'IDENTITY_RESPONDER'
      lt_keys = ClaimableRS.crs_gen()
      {:ok, {_, init_send}} = C_RSDAKE.initialise(ident_i)
      {:ok, {resp_state, resp_send}} = C_RSDAKE.respond(ident_r, lt_keys, init_send)

      assert verify_crypto_state(resp_state)
      assert verify_response_struct(resp_send)
    end

    test "Test with invalid identity" do
      # Setup arguments
      ident_i = 'IDENTITY_INITIATOR'
      ident_r = "IDENTITY_RESPONDER"
      lt_keys = ClaimableRS.crs_gen()
      {:ok, {_, init_send}} = C_RSDAKE.initialise(ident_i)

      expected = {:error, :invalid_arguments}
      assert expected == C_RSDAKE.respond(ident_r, lt_keys, init_send)
    end

    test "Test with invalid request" do
      # Setup arguments
      ident_r = 'IDENTITY_RESPONDER'
      lt_keys = ClaimableRS.crs_gen()

      expected = {:error, :invalid_arguments}
      assert expected == C_RSDAKE.respond(ident_r, %{}, %{})
    end
  end

  describe "finalise/3" do
    test "Test valid finalisation" do
      # Setup arguments
      ident_i = 'IDENTITY_INITIATOR'
      ident_r = 'IDENTITY_RESPONDER'
      lt_keys = ClaimableRS.crs_gen()
      {:ok, {init_state, init_send}} = C_RSDAKE.initialise(ident_i)
      {:ok, {_, resp_send}} = C_RSDAKE.respond(ident_r, lt_keys, init_send)
      {:ok, {fin_state, fin_send}} = C_RSDAKE.finalise(ident_i, init_state, resp_send)

      assert verify_crypto_state(fin_state)
      assert verify_final_struct(fin_send)
    end

    test "Test invalid arguments" do
      # Setup arguments
      ident_i = "IDENTITY_INITIATOR"
      expected = {:error, :invalid_arguments}

      assert expected == C_RSDAKE.respond(ident_i, %{}, %{})
    end
  end

  describe "verify_final/3" do
    test "Test valid exchange" do
      # Setup arguments
      ident_i = 'IDENTITY_INITIATOR'
      ident_r = 'IDENTITY_RESPONDER'
      lt_keys = ClaimableRS.crs_gen()
      {:ok, {init_state, init_send}} = C_RSDAKE.initialise(ident_i)
      {:ok, {resp_state, resp_send}} = C_RSDAKE.respond(ident_r, lt_keys, init_send)
      {:ok, {_, fin_send}} = C_RSDAKE.finalise(ident_i, init_state, resp_send)
      expected = {:ok, true}

      assert expected == C_RSDAKE.verify_final(ident_r, resp_state, fin_send)
    end

    test "Test invalid crypto struct" do
      # Setup arguments
      ident_i = 'IDENTITY_INITIATOR'
      ident_r = 'IDENTITY_RESPONDER'
      lt_keys = ClaimableRS.crs_gen()
      {:ok, {init_state, init_send}} = C_RSDAKE.initialise(ident_i)
      {:ok, {resp_state, resp_send}} = C_RSDAKE.respond(ident_r, lt_keys, init_send)
      {:ok, {_, fin_send}} = C_RSDAKE.finalise(ident_r, init_state, resp_send)

      # Modify crypto struct
      {sag, commitment} = Map.get(fin_send, :ring_signature)
      new_sag = Map.put(sag, :chal, Enum.map(sag.chal, fn x -> Integer.mod(x * 2, 255); end))
      fin_send = Map.put(fin_send, :ring_signature, {new_sag, commitment})
      expected = {:ok, false}

      assert expected == C_RSDAKE.verify_final(ident_r, resp_state, fin_send)
    end

    test "Test invalid arguments" do
      # Setup arguments
      ident_r = "IDENTITY_RESPONDER"
      expected = {:error, :invalid_arguments}

      assert expected == C_RSDAKE.verify_final(ident_r, %{}, %{})
    end
  end

  # ---- Utility Functions ----
  # Verify the crypto state structure
  @spec verify_crypto_state(map) :: boolean
  defp verify_crypto_state(crypto_state) when is_map(crypto_state) do
    is_map_key(crypto_state, :ephem_sign_keys) and
    is_map_key(crypto_state, :shared_secret) and
    is_map_key(crypto_state, :recv_struct) and
    is_map_key(crypto_state, :rs_keys) and
    is_map_key(crypto_state, :dh_keys) and
    is_map_key(crypto_state, :lt_keys)
  end
  defp verify_crypto_state(_), do: false

  # Verify the initial C-RSDAKE crypto structure
  @spec verify_init_struct(map) :: boolean
  defp verify_init_struct(init_struct) when is_map(init_struct) do
    is_map_key(init_struct, :pk_ephem_sign) and
    is_map_key(init_struct, :signature) and
    is_map_key(init_struct, :identity) and
    is_map_key(init_struct, :pk_lt) and
    is_map_key(init_struct, :pk_rs) and
    is_map_key(init_struct, :pk_dh)
  end
  defp verify_init_struct(_), do: false

  # Verify the initial C-RSDAKE crypto structure
  @spec verify_response_struct(map) :: boolean
  defp verify_response_struct(resp_struct) when is_map(resp_struct) do
    is_map_key(resp_struct, :ring_signature) and
    is_map_key(resp_struct, :pk_ephem_sign) and
    is_map_key(resp_struct, :signature) and
    is_map_key(resp_struct, :identity) and
    is_map_key(resp_struct, :pk_lt) and
    is_map_key(resp_struct, :pk_rs) and
    is_map_key(resp_struct, :pk_dh)
  end
  defp verify_response_struct(_), do: false

  # Verify the initial C-RSDAKE crypto structure
  @spec verify_final_struct(map) :: boolean
  defp verify_final_struct(fin_struct) when is_map(fin_struct) do
    is_map_key(fin_struct, :ring_signature)
  end
  defp verify_final_struct(_), do: false
end
