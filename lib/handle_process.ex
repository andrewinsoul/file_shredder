defmodule FileShredder.HandleProcess do
  use GenServer

  def start_link do
    System.no_halt(true)
    GenServer.start_link(__MODULE__, [])
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_file_shredding(receiver_pid, file_path) do
    GenServer.cast(receiver_pid, {:process_file, file_path})
  end

  def handle_cast({:process_file, file_path}, state) do
    if file_path == :kill do
      IO.puts("Your files were successfully shredded")
      System.stop()
    else
      File.rm!(file_path)
      IO.puts("#{file_path} was successfully shredded...")
    end

    {:noreply, state}
  end
end
