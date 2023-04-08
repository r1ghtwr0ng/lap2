defmodule LAP2.Crypto.Padding.PKCS7Test do
  alias LAP2.Crypto.Padding.PKCS7
  use ExUnit.Case
  doctest LAP2.Crypto.Padding.PKCS7

  test "pad" do
    string_1 = "Test string"
    string_2 = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 255, 255>>
    string_3 = "0123456789abcdef"
    len_1 = 8
    len_2 = 8
    len_3 = 16
    # Expected padding results
    padded_1 = <<84, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 5, 5, 5, 5, 5>>
    padded_2 = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 255, 255, 8, 8, 8, 8, 8, 8, 8, 8>>
    padded_3 = <<48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16>>
    # Test padding
    assert padded_1 == PKCS7.pad(string_1, len_1)
    assert padded_2 == PKCS7.pad(string_2, len_2)
    assert padded_3 == PKCS7.pad(string_3, len_3)
  end

  test "unpad" do
    # Padded binaries
    padded_1 = <<84, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 5, 5, 5, 5, 5>>
    padded_2 = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 255, 255, 8, 8, 8, 8, 8, 8, 8, 8>>
    padded_3 = <<48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16>>
    # Expected unpadding results
    string_1 = "Test string"
    string_2 = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 255, 255>>
    string_3 = "0123456789abcdef"
    # Test padding
    assert string_1 == PKCS7.unpad(padded_1)
    assert string_2 == PKCS7.unpad(padded_2)
    assert string_3 == PKCS7.unpad(padded_3)
  end
end
