defmodule LAP2.Crypto.InformationDispersal.SecureIDATest do

  use ExUnit.Case
  alias LAP2.Crypto.InformationDispersal.SecureIDA
  doctest LAP2.Crypto.InformationDispersal.SecureIDA

  describe "disperse and reconstruct" do
    test "Test with regular ASCII data" do
      data = "Testing data, case 1"
      n = 4
      m = 3
      shares = Enum.take_random(SecureIDA.disperse(data, n, m, 1000), m)
      assert {:ok, data} == SecureIDA.reconstruct(shares)
    end

    test "Test with non-printable binary data" do
      data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 255, 255, 255, 255, 0, 0, 0, 0>>
      n = 12
      m = 6
      shares = Enum.take_random(SecureIDA.disperse(data, n, m, 1000), m)
      assert {:ok, data} == SecureIDA.reconstruct(shares)
    end

    test "Test with short data, more shares" do
      data = "Short string"
      n = 10
      m = 10
      shares = Enum.take_random(SecureIDA.disperse(data, n, m, 1000), m)
      assert {:ok, data} == SecureIDA.reconstruct(shares)
    end
  end
end
