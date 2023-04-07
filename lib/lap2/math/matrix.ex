defmodule LAP2.Math.Matrix do
  @moduledoc """
  Module for performing mathematical matrix operations.
  The functions used for performing the vandermonde matrix operations are based on the
  follwoing repository: https://github.com/mmtan/IDA
  """

  @doc """
  Calculate the dot product of two matrices, ensuring the result is within the finite field.
  """
  @spec matrix_dot_product(list, list, non_neg_integer) :: non_neg_integer
  def matrix_dot_product(a, b, field_limit) do
    # TODO verify that a and b are the same length
    Enum.map(a, fn a_row ->
      Enum.map(b, fn b_row ->
        vector_dot_product(a_row, b_row, field_limit)
      end)
    end)
  end

  @doc """
  Perform matrix multiplication of two matrices, ensuring the result is within the finite field.
  """
  @spec matrix_product(list, list, non_neg_integer) :: non_neg_integer
  def matrix_product(a, b, field_limit) do
    # TODO verify that a and b are the same length
    Enum.reduce(0..length(a)-1, [], fn i, result ->
      res_row = Enum.reduce(0..length(Enum.at(b, 0))-1, [], fn j, row ->
        res = Enum.reduce(0..length(Enum.at(a, 0))-1, 0, fn k, ans ->
          elem_a = Enum.at(Enum.at(a, i), k)
          elem_b = Enum.at(Enum.at(b, k), j)
          Integer.mod(ans + (elem_a * elem_b), field_limit)
        end)
        [res | row]
      end)
      |> Enum.reverse()
      [res_row | result]
    end)
    |> Enum.reverse()
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
      |> Enum.map(fn j -> :math.pow(i, j) |> round() |> Integer.mod(field_limit); end)
    end)
  end

  @doc """
  Perform modular inverse of a vandermonde matrix, ensuring that the matrix elements are
  within the finite field limit.
  """
  @spec vandermonde_inverse(list, non_neg_integer) :: list
  def vandermonde_inverse(basis, field_limit) do
    # Matrix dimensions
    m = length(basis)
    el = elementary_symmetric_functions(m, basis, field_limit)
    denominators = Enum.map(0..(m-1), fn i ->
      elt = Enum.at(basis, i)
      Enum.reduce(0..(m-1), 1, fn j, acc ->
        if i != j do
          Integer.mod(acc * (elt - Enum.at(basis, j)), field_limit)
        else
          acc
        end
      end)
    end)
    # Function for calculating the sign of a matrix number based on the index
    sign = fn a -> Bitwise.band(a, 1) * -2 + 1 end
    numerators = Enum.map(0..(m-1), fn i ->
      elt = Enum.at(basis, i)
      Enum.reduce(1..(m-1), [1], fn j, acc ->
        # Efficient way of calculating the sign without state
        numerator = Integer.mod(List.first(acc) * elt + sign.(j) * Enum.at(el, j), field_limit)
        [numerator | acc]
      end)
    end)
    # Calculate the inverse of the denominator
    Enum.reduce(0..(m-1), %{return: [], inverses: %{}}, fn i, acc ->
      denominator = Enum.at(denominators, i)
      {inv, inverses} = get_inverse(denominator, acc.inverses, field_limit)
      row = Enum.map(Enum.at(numerators, i), fn numerator ->
        Integer.mod(numerator * inv, field_limit)
      end)
      %{return: [row | acc.return], inverses: inverses}
    end)
    |> Map.get(:return)
    |> Enum.reverse()
    |> transpose()
  end

  @doc """
  Calculate the sum of the products of all possible subsets of the list l,
  with a specified size m. Ensure that the result is within the finite field limit.
  """
  @spec elementary_symmetric_functions(non_neg_integer, list, non_neg_integer) :: list
  def elementary_symmetric_functions(m, l, field_limit) do
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
    |> Enum.map(fn row -> List.last(row) |> Integer.mod(field_limit) end)
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
    |> Integer.mod(field_limit)
  end

  # Perform matrix transposition
  @spec transpose(list) :: list
  def transpose([]), do: []
  def transpose([[] | _]), do: []
  def transpose(a) do
    [Enum.map(a, &hd/1) | transpose(Enum.map(a, &tl/1))]
  end

  # ---- Private Functions ----
  # Calculate the extended GCD of two numbers, with the x and y values
  @spec extended_gcd(non_neg_integer, non_neg_integer, non_neg_integer, non_neg_integer, non_neg_integer, non_neg_integer) :: {non_neg_integer, non_neg_integer}
  defp extended_gcd(last_remainder, 0, last_x, _, _, _), do: {last_remainder, last_x}
  defp extended_gcd(last_remainder, remainder, last_x, x, last_y, y) do
    quotient   = div(last_remainder, remainder)
    remainder2 = Integer.mod(last_remainder, remainder)
    extended_gcd(remainder, remainder2, x, last_x - quotient*x, y, last_y - quotient*y)
  end

  # Get the modulo inverse of an element, or calculate it if it doesn't exist
  @spec get_inverse(non_neg_integer, map, non_neg_integer) :: {non_neg_integer, map}
  defp get_inverse(element, inverses, _) when is_map_key(inverses, element) do
    {Map.get(inverses, element), inverses}
  end
  defp get_inverse(element, inverses, field_limit) do
    inverse = modulo_inverse(element, field_limit)
    {inverse, Map.put(inverses, element, inverse)}
  end

  # Calculate the modulo inverse of an element
  @spec modulo_inverse(non_neg_integer, non_neg_integer) :: non_neg_integer
  defp modulo_inverse(element, field_limit) do
    # TODO Generate the modular inverse of an element
    {g, x} = extended_gcd(element, field_limit)
    if g != 1, do: raise "Element #{element} not invertible"
    Integer.mod(x+field_limit, field_limit)
  end
end
