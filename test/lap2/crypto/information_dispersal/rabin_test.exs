defmodule LAP2.Crypto.InformationDispersal.RabinIDATest do
  use ExUnit.Case
  alias LAP2.Crypto.InformationDispersal.RabinIDA
  doctest LAP2.Crypto.InformationDispersal.RabinIDA

  test "split/3" do
    data_1 = "Testing simple string data, not too short, not too long"
    data_2 = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 65, 42, 73, 42>>
    data_3 = "Short data"
    n_1 = 4
    n_2 = 8
    n_3 = 12
    m_1 = 3
    m_2 = 4
    m_3 = 12
    # Expected shares
    shares_1 = [
      %{
        data: <<43, 74, 250, 69, 241, 88, 61, 229, 0, 253, 7, 254, 73, 17, 253, 7,
          254, 72, 107>>,
        share_id: 1
      },
      %{
        data: <<232, 252, 113, 0, 181, 32, 223, 106, 229, 182, 130, 204, 253, 8,
          182, 130, 204, 255, 1, 115>>,
        share_id: 2
      },
      %{
        data: <<137, 136, 206, 155, 185, 204, 77, 177, 32, 76, 228, 218, 141, 87,
          76, 228, 218, 146, 127>>,
        share_id: 3
      },
      %{
        data: <<15, 240, 15, 20, 253, 90, 137, 185, 180, 192, 44, 39, 251, 254, 192,
          44, 39, 255, 1, 143>>,
        share_id: 4
      }
    ]
    shares_2 = [
      %{data: <<6, 22, 15, 59, 158>>, share_id: 1},
      %{data: <<34, 94, 10, 249, 107>>, share_id: 2},
      %{data: <<102, 5, 238, 187, 152>>, share_id: 3},
      %{data: <<228, 54, 173, 6, 42>>, share_id: 4},
      %{data: <<173, 26, 60, 96, 40>>, share_id: 5},
      %{data: <<212, 220, 144, 76, 152>>, share_id: 6},
      %{data: <<106, 164, 156, 79, 127>>, share_id: 7},
      %{data: <<130, 157, 84, 238, 228>>, share_id: 8}
    ]
    shares_3 = [
      %{data: "\xCB", share_id: 1},
      %{data: "\x88", share_id: 2},
      %{data: "\xCD", share_id: 3},
      %{data: "\d", share_id: 4},
      %{data: "\xD9", share_id: 5},
      %{data: "\x15", share_id: 6},
      %{data: "\x02", share_id: 7},
      %{data: "\xD7", share_id: 8},
      %{data: "c", share_id: 9},
      %{data: "\t", share_id: 10},
      %{data: <<25>>, share_id: 11},
      %{data: <<255, 1>>, share_id: 12}
    ]
    # Test splitting
    assert shares_1 == RabinIDA.split(data_1, n_1, m_1)
    assert shares_2 == RabinIDA.split(data_2, n_2, m_2)
    assert shares_3 == RabinIDA.split(data_3, n_3, m_3)
  end

  test "reconstruct/1" do
    shares_1 = Enum.take_random([
      %{
        data: <<43, 74, 250, 69, 241, 88, 61, 229, 0, 253, 7, 254, 73, 17, 253, 7,
          254, 72, 107>>,
        share_id: 1
      },
      %{
        data: <<232, 252, 113, 0, 181, 32, 223, 106, 229, 182, 130, 204, 253, 8,
          182, 130, 204, 255, 1, 115>>,
        share_id: 2
      },
      %{
        data: <<137, 136, 206, 155, 185, 204, 77, 177, 32, 76, 228, 218, 141, 87,
          76, 228, 218, 146, 127>>,
        share_id: 3
      },
      %{
        data: <<15, 240, 15, 20, 253, 90, 137, 185, 180, 192, 44, 39, 251, 254, 192,
          44, 39, 255, 1, 143>>,
        share_id: 4
      }
    ], 3)
    shares_2 = Enum.take_random([
      %{data: <<6, 22, 15, 59, 158>>, share_id: 1},
      %{data: <<34, 94, 10, 249, 107>>, share_id: 2},
      %{data: <<102, 5, 238, 187, 152>>, share_id: 3},
      %{data: <<228, 54, 173, 6, 42>>, share_id: 4},
      %{data: <<173, 26, 60, 96, 40>>, share_id: 5},
      %{data: <<212, 220, 144, 76, 152>>, share_id: 6},
      %{data: <<106, 164, 156, 79, 127>>, share_id: 7},
      %{data: <<130, 157, 84, 238, 228>>, share_id: 8}
    ], 4)
    shares_3 = [
      %{data: "\xCB", share_id: 1},
      %{data: "\x88", share_id: 2},
      %{data: "\xCD", share_id: 3},
      %{data: "\d", share_id: 4},
      %{data: "\xD9", share_id: 5},
      %{data: "\x15", share_id: 6},
      %{data: "\x02", share_id: 7},
      %{data: "\xD7", share_id: 8},
      %{data: "c", share_id: 9},
      %{data: "\t", share_id: 10},
      %{data: <<25>>, share_id: 11},
      %{data: <<255, 1>>, share_id: 12}
    ]
    # Expected data
    data_1 = "Testing simple string data, not too short, not too long"
    data_2 = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 65, 42, 73, 42>>
    data_3 = "Short data"
    # Test reconstruction
    assert {:ok, data_1} == RabinIDA.reconstruct(shares_1)
    assert {:ok, data_2} == RabinIDA.reconstruct(shares_2)
    assert {:ok, data_3} == RabinIDA.reconstruct(shares_3)
  end
end
