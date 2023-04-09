defmodule LAP2.Math.MatrixTest do
  use ExUnit.Case
  alias LAP2.Math.Matrix

  describe "matrix_dot_product/3" do
    test "calculates the dot product of two matrices" do
      a = [[1, 2], [3, 4]]
      b = [[5, 6], [7, 8]]
      field_limit = 10
      result = Matrix.matrix_dot_product(a, b, field_limit)
      assert result == [[7, 3], [9, 3]]
    end
  end

  describe "matrix_product/3" do
    test "performs matrix multiplication of two matrices" do
      a = [[1, 2], [3, 4]]
      b = [[5, 6], [7, 8]]
      field_limit = 20
      result = Matrix.matrix_product(a, b, field_limit)
      assert result == [[19, 2], [3, 10]]
    end
  end

  describe "gen_vandermonde_matrix/3" do
    test "generates Vandermonde matrix of size n x m" do
      n = 3
      m = 4
      field_limit = 100
      result = Matrix.gen_vandermonde_matrix(n, m, field_limit)
      assert result == [[1, 1, 1, 1], [1, 2, 4, 8], [1, 3, 9, 27]]
    end
  end

  describe "vandermonde_inverse/2" do
    test "performs modular inverse of a vandermonde matrix" do
      basis = [1, 2, 3]
      field_limit = 5
      result = Matrix.vandermonde_inverse(basis, field_limit)
      assert result == [[3, 2, 1], [0, 4, 1], [3, 4, 3]]
    end
  end

  describe "elementary_symmetric_functions/3" do
    test "calculates the sum of the products of all possible subsets of the list l, with a specified size m" do
      m = 2
      l = [1, 2, 3]
      field_limit = 10
      result = Matrix.elementary_symmetric_functions(m, l, field_limit)
      assert result == [0, 6, 1]
    end
  end

  describe "extended_gcd/2" do
    test "calculates the extended GCD of two numbers" do
      a = 5
      b = 7
      result = Matrix.extended_gcd(a, b)
      assert result == {1, 3}
    end
  end

  describe "vector_dot_product/3" do
    test "calculates the dot product of two vectors" do
      vector_a = [1, 2, 3]
      vector_b = [4, 5, 6]
      field_limit = 10
      result = Matrix.vector_dot_product(vector_a, vector_b, field_limit)
      assert result == 2
    end
  end

  describe "transpose/1" do
    test "performs matrix transposition" do
      a = [[1, 2], [3, 4], [5, 6]]
      result = Matrix.transpose(a)
      assert result == [[1, 3, 5], [2, 4, 6]]
    end
  end
end
