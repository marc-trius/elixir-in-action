

defmodule TodoList do
  defmodule Entry do
    defstruct [:id, :date, :title]

    def new(date, title) do
      %Entry{date: date, title: title}
    end
  end

  defstruct auto_id: 1, entries: %{}

  def new(), do: %TodoList{}
  def new(entries) do
    Enum.reduce(
      entries,
      new(),
      &add_entry(&2, &1)
    )
  end

  def add_entry(todo_list, %Entry{} = entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)

    new_entries = Map.put(
      todo_list.entries,
      todo_list.auto_id,
      entry
    )

    %TodoList{todo_list |
      entries: new_entries,
      auto_id: todo_list.auto_id + 1
    }
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} -> entry.date == date end)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = %{} = updater_fun.(old_entry)
        entry_id = old_entry.id
        new_entries = %{id: ^entry_id } = Map.put(todo_list.entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def update_entry(todo_list, %Entry{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def delete_entry(todo_list,  entry_id) do
    %TodoList{todo_list | entries: Map.delete(todo_list.entries, entry_id)}
  end
end

defmodule TodoList.CsvImporter do
  def import(path) do
    path
    |> read_lines
    |> Stream.map(&parse_row/1)
    |> TodoList.new()
  end

  defp read_lines(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.replace(&1, "\n", ""))
  end

  defp parse_row(row) do
    [date, title] = String.split(row, ",")
    TodoList.Entry.new(parse_date(date), title)
  end

  defp parse_date(date_string) do
    [year, month, day] =
      date_string
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)
    {:ok, date} = Date.new(year, month, day)
    date
  end
end

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end
  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_, :halt), do: :ok
end
