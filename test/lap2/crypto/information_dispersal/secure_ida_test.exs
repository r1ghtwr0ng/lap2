defmodule LAP2.Crypto.InformationDispersal.SecureIDATest do

  use ExUnit.Case
  alias LAP2.Crypto.InformationDispersal.SecureIDA
  doctest LAP2.Crypto.InformationDispersal.SecureIDA

  test "disperse and reconstruct" do
    data_1 = "Testing data, case 1"
    data_2 = "Testing data, longer string, case 2"
    data_3 = "Short string"
    n_1 = 4
    n_2 = 12
    n_3 = 10
    m_1 = 3
    m_2 = 6
    m_3 = 10
    shares_1 = Enum.take_random(SecureIDA.disperse(data_1, n_1, m_1), m_1)
    shares_2 = Enum.take_random(SecureIDA.disperse(data_2, n_2, m_2), m_2)
    shares_3 = Enum.take_random(SecureIDA.disperse(data_3, n_3, m_3), m_3)

    assert {:ok, data_1} == SecureIDA.reconstruct(shares_1)
    assert {:ok, data_2} == SecureIDA.reconstruct(shares_2)
    assert {:ok, data_3} == SecureIDA.reconstruct(shares_3)
  end
end
