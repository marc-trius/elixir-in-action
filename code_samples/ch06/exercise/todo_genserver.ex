  defmodule TodoServer do
    use GenServer

    # Implementations
    @impl GenServer
    def init(_) do
      {:ok, TodoList.new()}
    end

    @impl GenServer
    def handle_call({:entries, date}, _, todo_list) do
      {:reply, TodoList.entries(todo_list, date), todo_list}
    end

    @impl GenServer
    def handle_cast({:add_entry, new_entry}, todo_list) do
      {:noreply, TodoList.add_entry(todo_list, new_entry)}
    end

    @impl GenServer
    def handle_cast({:update_entry, new_entry}, todo_list) do
      {:noreply, TodoList.update_entry(todo_list, new_entry)}
    end

    @impl GenServer
    def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
      {:noreply, TodoList.update_entry(todo_list, entry_id, updater_fun)}
    end

    @impl GenServer
    def handle_cast({:delete_entry, entry_id}, todo_list) do
      {:noreply, TodoList.delete_entry(todo_list, entry_id)}
    end

    # Interface Functions
    def start() do
      GenServer.start(TodoServer, nil, name: __MODULE__)
    end

    def add_entry(%{} = new_entry) do
      GenServer.cast(__MODULE__, {:add_entry, new_entry})
    end

    def entries(date) do
      GenServer.call(__MODULE__, {:entries, date})
    end

    def update_entry(%{} = new_entry) do
      GenServer.cast(__MODULE__, {:update_entry, new_entry})
    end

    def update_entry(entry_id, updater_fun) do
      GenServer.cast(__MODULE__, {:update_entry, entry_id, updater_fun})
    end

    def delete_entry(entry_id) do
      GenServer.cast(__MODULE__, {:delete_entry, entry_id})
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
