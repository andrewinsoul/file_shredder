alias FileShredder.HandleProcess

defmodule FileShredder.CLI do
  @moduledoc false
  @spec get_file_path(String.t()) :: String.t()

  defp get_file_path(file_path) do
    cond do
      String.starts_with?(file_path, "/") ->
        Path.expand(
          String.replace(
            file_path,
            "/",
            "",
            global: false
          )
        )

      true ->
        Path.expand(file_path, "~")
    end
  end

  @doc """
  Removes whitespaces from either side of the string & convert it to lowercase

  ## Parameters

    - file_name: String that represents input gotten from IO

  ## Examples

      iex> FileShredder.CLI.collect_part_of_filename("Sean")
      "sean"

      iex> FileShredder.CLI.collect_part_of_filename("     Nature      ")
      "nature"

  """
  @spec collect_part_of_filename(String.t()) :: String.t()
  def collect_part_of_filename(file_name) do
    file_name
    |> String.trim()
    |> String.downcase()
  end

  defp clear() do
    IO.puts("\e[2J")
  end

  @spec display_list_of_files_that_will_be_shredded(String.t(), String.t()) ::
          {String.t(), list(String.t())} | {:error, String.t()}
  defp display_list_of_files_that_will_be_shredded(file_path, file_name) do
    # Elixir adds a new-line at the end of input, so we have to
    # replace that newline
    input = get_file_path(file_path) |> String.trim()

    filename = collect_part_of_filename(file_name)

    case File.ls(input) do
      {:ok, dir_list} ->
        files_to_shred =
          dir_list
          |> Enum.filter(fn file -> String.contains?(String.downcase(file), filename) end)
          |> Enum.join("\n")

        if files_to_shred === "" do
          IO.puts("No file to shred...")
        else
          IO.puts("LIST OF FILES THAT WILL BE SHREDDED: \n\n" <> files_to_shred)
        end

        {input, files_to_shred}

      _ ->
        IO.puts("File path does not exist: " <> input)
        {:error, "file path not found"}
    end
  end

  @spec confirmation_message({atom() | String.t(), String.t()}) :: boolean()
  defp confirmation_message({:error, reason}) do
    Process.exit(self(), reason)
  end

  @spec confirmation_message({String.t(), String.t()}) ::
          {String.t(), list(String.t()), String.t()}
  defp confirmation_message({file_path, files_to_shred}) do
    if files_to_shred === "" do
      {:abort, [], ""}
    else
      user_response =
        IO.gets("Press Y if you wish to proceed with operation, else press N: ")
        |> String.trim()
        |> String.downcase()

      {user_response, files_to_shred, file_path}
    end
  end

  defp handle_user_response_to_confirmation_prompt({response, files_to_shred, file_path}) do
    case response do
      :abort ->
        {:abort, file_path}

      "y" ->
        {"y", file_path, files_to_shred}

      "n" ->
        "n"

      _ ->
        clear()
        user_response = confirmation_message({file_path, files_to_shred})
        handle_user_response_to_confirmation_prompt(user_response)
    end
  end

  defp shred_files({"y", file_path, files_to_shred}) do
    {:ok, pid} = HandleProcess.start_link()

    path_to_file =
      String.split(
        files_to_shred,
        "\n"
      )

    path_to_file = [:kill | path_to_file] |> Enum.reverse()

    Enum.each(path_to_file, fn file_name ->
      if file_name == :kill do
        HandleProcess.handle_file_shredding(pid, :kill)
      else
        path_to_file = "#{file_path}/#{file_name}"
        IO.puts("shredding #{path_to_file}")
        # {:ok, pid} = HandleProcess.start_link()
        HandleProcess.handle_file_shredding(pid, path_to_file)
      end
    end)

    # This ensures all async tasks are completed
    :timer.sleep(:infinity)
  end

  defp shred_files("n") do
    IO.puts("Operation aborted...")
  end

  defp shred_files({:abort, reason}) do
    IO.puts(reason)
  end

  def main(_args) do
    instruction =
      "Enter directory path relative to home that contain file(s) you wish to delete\nExample: movies/action: "

    file_path = IO.gets(instruction)
    filename = IO.gets("Enter part of filename you wish to shred? ")

    display_list_of_files_that_will_be_shredded(file_path, filename)
    |> confirmation_message()
    |> handle_user_response_to_confirmation_prompt()
    |> shred_files
  end
end
