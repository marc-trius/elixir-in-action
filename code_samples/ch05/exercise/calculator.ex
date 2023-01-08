defmodule Calculator do
  def start, do: spawn(fn -> loop(0) end)

  defp loop(total) do
    new_total =
      receive do
        message -> process_message(message)
      end

    loop(new_total)
  end

  process_message({:value, caller}) do
    send(caller, {:response total})
    total
  end
  process_message({:add, value}), do: total + value
  process_message({:sub, value}), do: total - value
  process_message({:mul, value}), do: total * value
  process_message({:div, value}), do: total / value
  process_message(invalid_request) do
    IO.puts("invalud request #{inspect invalid_request}")
    total
  end

  def value(pid) do
    send(pid, {:value, self()})
    receive do
      {:response, value} ->
        value
    end
  end

  def add(pid, value), do: send(pid, {:add, value})
  def sub(pid, value), do: send(pid, {:sub, value})
  def mul(pid, value), do: send(pid, {:mul, value})
  def div(pid, value), do: send(pid, {:div, value})
end
