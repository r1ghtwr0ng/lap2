defmodule LAP2.Crypto.Constructions.ClaimableRSTest do
  use ExUnit.Case
  doctest LAP2.Crypto.Constructions.ClaimableRS

  alias LAP2.Crypto.Constructions.ClaimableRS

  describe "rs_gen/0" do
    test "Test ring key generation" do
      {sk, pk} = ClaimableRS.rs_gen()
      assert length(sk) == 32 and is_list(sk)
      assert length(pk) == 32 and is_list(pk)
    end
  end

  describe "rs_sign/4" do
    test "Test ring signature signing signature" do
      # Generate own key pair
      {sk, pk} = ClaimableRS.rs_gen()
      # Generate ring
      ring = [pk | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, %{
        chal: chal,
        ring: ring,
        resp: resp
      }} = ClaimableRS.rs_sign(0, sk, ring, msg)
      assert is_list(resp) and is_list(chal) and is_list(ring)
      assert length(chal) == 32
      assert length(resp) == length(ring)
    end

    test "Test invalid ring signature signing" do
      # Generate own key pair
      {sk, pk} = ClaimableRS.rs_gen()
      # Generate ring
      ring = [pk | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Kura mi qnko'
      assert {:error, :invalid_index} == ClaimableRS.rs_sign(5, sk, ring, msg)
    end
  end

  describe "rs_vrfy/2" do
    test "Test valid signature verification" do
      # Generate own key pair
      {sk, pk} = ClaimableRS.rs_gen()
      # Generate ring
      ring = [pk | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, sig} = ClaimableRS.rs_sign(0, sk, ring, msg)
      assert {:ok, true} == ClaimableRS.rs_vrfy(sig, msg)
    end

    test "Test invalid signature verification" do
      # Generate own key pair
      {sk, pk} = ClaimableRS.rs_gen()
      # Generate ring
      ring = [pk | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, sig} = ClaimableRS.rs_sign(0, sk, ring, msg)
      assert {:ok, false} == ClaimableRS.rs_vrfy(sig, 'Kura mi qnko')
    end
  end

  describe "crs_gen/0" do
    test "Test C-RS generation" do
      %{
        vk: {pk_rs, pk_sig} = vk,
        sk: {vk_2, sk_rs, sk_sig, sk_prf}
      } = ClaimableRS.crs_gen()
      assert length(pk_rs) == 32 and is_list(pk_rs)
      assert length(pk_sig) == 32 and is_list(pk_sig)
      assert length(sk_rs) == 32 and is_list(sk_rs)
      assert length(sk_sig) == 32 and is_list(sk_sig)
      assert length(sk_prf) == 32 and is_list(sk_prf)
      assert vk_2 == vk
    end
  end

  describe "crs_sign/4" do
    test "Test valid C-RS signing" do
      %{
        vk: {pk_rs, _},
        sk: sk
      } = ClaimableRS.crs_gen()
      # Generate ring
      ring = [pk_rs | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, {%{
        chal: chal,
        ring: ring,
        resp: resp
      }, com}} = ClaimableRS.crs_sign(0, sk, ring, msg)
      assert is_list(resp) and is_list(chal) and is_list(ring) and is_list(com)
      assert length(chal) == 32 and length(com) == 32
      assert length(resp) == length(ring)
    end

    test "Test invalid C-RS signing" do
      %{
        vk: {pk_rs, _},
        sk: sk
      } = ClaimableRS.crs_gen()
      # Generate ring
      ring = [pk_rs | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      assert {:error, :invalid_index} == ClaimableRS.crs_sign(5, sk, ring, msg)
    end
  end

  describe "crs_vrfy/2" do
    test "Test valid C-RS signature verification" do
      %{
        vk: {pk_rs, _},
        sk: sk
      } = ClaimableRS.crs_gen()
      # Generate ring
      ring = [pk_rs | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, sig} = ClaimableRS.crs_sign(0, sk, ring, msg)
      assert {:ok, true} == ClaimableRS.crs_vrfy(sig, msg)
    end

    test "Test invalid C-RS signature verification" do
      %{
        vk: {pk_rs, _},
        sk: sk
      } = ClaimableRS.crs_gen()
      # Generate ring
      ring = [pk_rs | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, sig} = ClaimableRS.crs_sign(0, sk, ring, msg)
      assert {:ok, false} == ClaimableRS.crs_vrfy(sig, 'Kura mi qnko')
    end
  end

  describe "crs_claim/3" do
    test "Test valid C-RS claim" do
      %{
        vk: {pk_rs, _},
        sk: sk
      } = ClaimableRS.crs_gen()
      # Generate ring
      ring = [pk_rs | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, sig} = ClaimableRS.crs_sign(0, sk, ring, msg)
      {:ok, {rand_com, rand_sig, regular_sig}} = ClaimableRS.crs_claim(0, sk, sig)
      assert is_list(rand_com) and is_list(rand_sig) and is_list(regular_sig)
      assert length(rand_com) == 16
      assert length(rand_sig) == 16
      assert length(regular_sig) == 64
    end

    test "Test invalid C-RS claim" do
      %{
        vk: {pk_rs, _},
        sk: sk
      } = ClaimableRS.crs_gen()
      # Generate ring
      ring = [pk_rs | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, {sag, commitment}} = ClaimableRS.crs_sign(0, sk, ring, msg)
      sig = {sag, Enum.map(commitment, fn _ -> 0 end)}
      assert {:ok, :invalid_commitment} == ClaimableRS.crs_claim(0, sk, sig)
    end
  end

  describe "crs_vrfy_claim/3" do
    test "Test valid claim verification" do
      %{
        vk: {pk_rs, _} = vk,
        sk: sk
      } = ClaimableRS.crs_gen()
      # Generate ring
      ring = [pk_rs | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, sig} = ClaimableRS.crs_sign(0, sk, ring, msg)
      {:ok, claim} = ClaimableRS.crs_claim(0, sk, sig)
      assert {:ok, true} == ClaimableRS.crs_vrfy_claim(vk, sig, claim)
    end

    test "Test invalid claim verification" do
      %{
        vk: {pk_rs, _} = vk,
        sk: sk
      } = ClaimableRS.crs_gen()
      # Generate ring
      ring = [pk_rs | Enum.map(0..1, fn _ ->
        {_sk, pk} = ClaimableRS.rs_gen()
        pk
      end)]
      msg = 'Test message'
      {:ok, {sag, commitment} = sig} = ClaimableRS.crs_sign(0, sk, ring, msg)
      {:ok, claim} = ClaimableRS.crs_claim(0, sk, sig)
      sig = {sag, Enum.map(commitment, fn _ -> 0 end)}
      assert {:ok, false} == ClaimableRS.crs_vrfy_claim(vk, sig, claim)
    end
  end
end
