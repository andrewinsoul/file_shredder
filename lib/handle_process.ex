defmodule FileShredder.HandleProcess do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_file_shredding(receiver_pid, file_path) do
    IO.puts(60000)
    GenServer.cast(receiver_pid, {:process_file, file_path})
  end

  def handle_cast({:process_file, file_path}, state) do
    IO.puts("9000 >>>>>> #{file_path}")
    # File.rm!(file_path)
    :timer.sleep(2000)
    IO.puts("#{file_path} was successfully shredded...")
    {:noreply, state}
  end
end
