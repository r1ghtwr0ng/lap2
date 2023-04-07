defmodule LAP2.Math.Matrix do
  @moduledoc """
  Module for performing mathematical matrix operations.
  The functions used for performing the vandermonde matrix operations are based on the
  follwoing repository: https://github.com/mmtan/IDA
  """

  @doc """
  Calculate the dot product of two matrices.
  """
  @spec matrix_dot_product(list, list, non_neg_integer) :: integer
  def matrix_dot_product(a, b, field_limit) do
    # TODO verify that a and b are the same length
    Enum.map(a, fn a_row ->
      Enum.map(b, fn b_row ->
        vector_dot_product(a_row, b_row, field_limit)
      end)
    end)
  end

  @doc """
  Generate Vandermonde matrix of size n x m
  """
  @spec gen_vandermonde_matrix(non_neg_integer, non_neg_integer, non_neg_integer) :: list
  def gen_vandermonde_matrix(n, m, field_limit) do
    # Start at 1 because we want to skip the 0th power
    1..n
    |> Enum.map(fn i ->
      0..(m-1)
      |> Enum.map(fn j -> :math.pow(i, j) |> round() |> rem(field_limit); end)
    end)
  end

  @doc """
  Perform modular inverse of a vandermonde matrix, ensuring that the matrix elements are
  within the finite field limit.
  """
  @spec vandermonde_inverse(list, non_neg_integer) :: list
  def vandermonde_inverse(basis, field_limit) do
    # TODO Generate the modular inverse of a matrix
    basis
  end

  def modulo_inverse(element, field_limit) do
    # TODO Generate the modular inverse of an element
    {g, x} = extended_gcd(element, field_limit)
    if g != 1, do: raise "Element #{element} not invertible"
    rem(x+field_limit, field_limit)
  end

  @spec elementary_symmetric_functions(non_neg_integer, list, non_neg_integer) :: list
  def elementary_symmetric_functions(m, l, p) do
    el = List.duplicate(0, length(l) + 1)
    |> List.duplicate(m + 1)
    new_el = Enum.reduce(1..length(l), el, fn j, acc ->
      List.update_at(acc, 1, fn row ->
        List.update_at(row, j, fn _ ->
          Enum.at(row, j-1) + Enum.at(l, j-1)
        end)
      end)
    end)
    Enum.reduce(2..m, new_el, fn i, acc ->
      List.update_at(acc, i, fn row ->
        Enum.reduce(2..length(l), row, fn j, acc2 ->
          List.update_at(acc2, j, fn _ ->
            (Enum.at(acc, i-1) |> Enum.at(j-1)) * Enum.at(l, j-1) + Enum.at(acc2, j-1)
          end)
        end)
      end)
    end)
    |> Enum.map(fn row -> List.last(row) |> rem(p) end)
  end

  @doc """
  Calculate the extended GCD of two numbers.
  """
  @spec extended_gcd(non_neg_integer, non_neg_integer) :: {non_neg_integer, non_neg_integer}
  def extended_gcd(a, b) do
    {last_remainder, last_x} = extended_gcd(abs(a), abs(b), 1, 0, 0, 1)
    {last_remainder, last_x * (if a < 0, do: -1, else: 1)}
  end

  # Calculate the dot product of two vectors
  @spec vector_dot_product(list, list, non_neg_integer) :: non_neg_integer
  def vector_dot_product(vector_a, vector_b, field_limit) do
    # TODO verify that vector_a and vector_b are the same length
    Enum.zip(vector_a, vector_b)
    |> Enum.map(fn {a, b} -> a * b; end)
    |> Enum.sum()
    |> rem(field_limit)
  end

  # Perform matrix transposition
  @spec transpose(list) :: list
  def transpose([]), do: []
  def transpose([[] | _]), do: []
  def transpose(a) do
    [Enum.map(a, &hd/1) | transpose(Enum.map(a, &tl/1))]
  end

  # ---- Private Functions ----
  @spec extended_gcd(non_neg_integer, non_neg_integer, non_neg_integer, non_neg_integer, non_neg_integer, non_neg_integer) :: {non_neg_integer, non_neg_integer}
  defp extended_gcd(last_remainder, 0, last_x, _, _, _), do: {last_remainder, last_x}
  defp extended_gcd(last_remainder, remainder, last_x, x, last_y, y) do
    quotient   = div(last_remainder, remainder)
    remainder2 = rem(last_remainder, remainder)
    extended_gcd(remainder, remainder2, x, last_x - quotient*x, y, last_y - quotient*y)
  end
end
