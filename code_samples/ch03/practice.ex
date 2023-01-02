defmodule Practice do
  def list_len_recursive([]), do: 0
  def list_len_recursive([_ | tail]), do: 1 + list_len_recursive(tail)

  def list_len(list), do: do_list_len(0, list)

  defp do_list_len(n, []), do: n
  defp do_list_len(n, [_ | tail]), do: do_list_len(n + 1, tail)

  def range_recursive(last, last), do: [last | []]
  def range_recursive(n, last), do: [n | range_recursive(n + 1, last)]

  def range(first, last), do: do_range([], first, last)

  defp do_range(list, first, first), do: [first | list]
  defp do_range(list, first, n), do: do_range([n | list], first, n - 1)

  def positive(list), do: do_positive([], list)

  defp do_positive(result, []), do: reverse_list(result)

  defp do_positive(result, [head | tail]) when head > 0,
    do: do_positive([head | result], tail)

  defp do_positive(result, [_ | tail]), do: do_positive(result, tail)

  def positive_recursive([]), do: []
  def positive_recursive([head | tail]) when head > 0, do:
    [head | positive_recursive(tail)]
  def positive_recursive([_ | tail]), do: positive_recursive(tail)

  def reverse_list(list), do: do_reverse_list([], list)

  defp do_reverse_list(result, []), do: result
  defp do_reverse_list(result, [head | tail]), do: do_reverse_list([head | result], tail)

  def lines_lengths!(path) do
    File.stream!(path)
    |> Stream.map(&String.replace(&1, "\n", ""))
    |> Stream.map(&String.length/1)
  end

  def longest_line_length!(path) do
    lines_lengths!(path)
    |> Enum.max()
  end

  def words_per_line!(path) do
    File.stream!(path)
    |> Stream.map(&String.split/1)
    |> String.map(&length/1)
  end
end
