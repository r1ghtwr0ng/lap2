defmodule LAP2.Crypto.Padding.PKCS7Test do
  alias LAP2.Crypto.Padding.PKCS7
  use ExUnit.Case
  doctest LAP2.Crypto.Padding.PKCS7

  describe "pad/2" do
    test "Test string padding" do
      string = "Test string"
      len = 8
      # Expected padding results
      padded = <<84, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 5, 5, 5, 5, 5>>

      assert padded == PKCS7.pad(string, len)
    end

    test "Test binary padding" do
      bin = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 255, 255>>
      len = 8

      padded =
        <<1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 255, 255, 8, 8, 8, 8, 8, 8, 8, 8>>

      # Test padding
      assert padded == PKCS7.pad(bin, len)
    end

    test "Test longer string padding" do
      string = "0123456789abcdef"
      len = 16

      padded =
        <<48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102, 16, 16, 16, 16, 16, 16,
          16, 16, 16, 16, 16, 16, 16, 16, 16, 16>>

      # Test padding
      assert padded == PKCS7.pad(string, len)
    end
  end

  describe "unpad/1" do
    test "Test string unpadding" do
      # Padded binary
      padded = <<84, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 5, 5, 5, 5, 5>>

      # Expected unpadding results
      string = "Test string"

      # Test padding
      assert string == PKCS7.unpad(padded)
    end

    test "Test binary unpadding" do
      # Padded binary
      padded =
        <<1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 255, 255, 8, 8, 8, 8, 8, 8, 8, 8>>

      # Expected unpadding results
      bin = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 255, 255>>

      # Test padding
      assert bin == PKCS7.unpad(padded)
    end

    test "Test longer string unpadding" do
      # Padded binary
      padded =
        <<48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102, 16, 16, 16, 16, 16, 16,
          16, 16, 16, 16, 16, 16, 16, 16, 16, 16>>

      # Expected unpadding results

      string = "0123456789abcdef"
      # Test padding
      assert string == PKCS7.unpad(padded)
    end
  end
end
