defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      callback_module.init()
      |> loop(callback_module)
    end)
  end

  defp loop(current_state, callback_module) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)
        send(caller, {:response, response})
        new_state

      {:cast, request} ->
        callback_module.handle_cast(request, current_state)
    end
    |> loop(callback_module)
  end

  def call(pid, request, caller) do
    send(pid, {:call, request, caller})

    receive do
      {:response, response} ->
        response
    end
  end

  def cast(pid, request), do: send(pid, {:cast, request})
end

defmodule TodoServer do
  def start() do
    ServerProcess.start(TodoServer)
  end

  def init() do
    TodoList.new()
  end

  def add_entry(server_pid, %{} = new_entry) do
    ServerProcess.cast(server_pid, {:add_entry, new_entry})
  end

  def entries(server_pid, date) do
    ServerProcess.call(server_pid, {:entries, date}, self())
  end

  def update_entry(server_pid, %{} = new_entry) do
    ServerProcess.cast(server_pid, {:update_entry, new_entry})
  end

  def update_entry(server_pid, entry_id, updater_fun) do
    ServerProcess.cast(server_pid, {:update_entry, entry_id, updater_fun})
  end

  def delete_entry(server_pid, entry_id) do
    ServerProcess.cast(server_pid, {:delete, entry_id})
  end

  def handle_call({:entries, date}, todo_list) do
    {TodoList.entries(todo_list, date), todo_list}
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    TodoList.add_entry(todo_list, new_entry)
  end

  def handle_cast({:update_entry, new_entry}, todo_list) do
    TodoList.update_entry(todo_list, new_entry)
  end

  def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
    TodoList.update_entry(todo_list, entry_id, updater_fun)
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    TodoList.delete_entry(todo_list, entry_id)
  end
end

defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new(), do: %TodoList{}

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)
    new_entries = Map.put(todo_list.entries, todo_list.auto_id, entry)

    %TodoList{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} -> entry.date == date end)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def delete_entry(todo_list, entry_id) do
    %TodoList{todo_list | entries: Map.delete(todo_list.entries, entry_id)}
  end
end
