defmodule FileShredder.CLI do
  defp get_file_path do
    instruction =
      "Enter directory path relative to home that contain file(s) you wish to delete\nExample: movies/action: "

    file_path = IO.gets(instruction)

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

  defp collect_part_of_filename do
    filename = IO.gets("Enter part of filename you wish to shred? ") |> String.trim()
    filename |> String.downcase()
  end

  defp clear() do
    IO.puts("\e[2J")
  end

  defp display_list_of_files_that_will_be_shredded do
    # Elixir adds a new-line at the end of input, so we have to
    # replace that newline
    input = get_file_path() |> String.trim()

    filename = collect_part_of_filename()
    {:ok, dir_list} = File.ls(input)

    files_to_shred =
      dir_list
      |> Enum.filter(fn file -> String.contains?(String.downcase(file), filename) end)
      |> Enum.join("\n")

    IO.puts("LIST OF FILES THAT WILL BE SHREDDED: \n\n" <> files_to_shred)
    # clear()
    {input, files_to_shred}
  end

  defp confirmation_message({file_path, files_to_shred}) do
    user_response =
      IO.gets("Press Y if you wish to proceed with operation, else press N: ")
      |> String.trim()
      |> String.downcase()

    {user_response, files_to_shred, file_path}
  end

  defp handle_user_response_to_confirmation_prompt({response, files_to_shred, file_path}) do
    case response do
      "y" -> {"y", file_path, files_to_shred}

      "n" -> "n"

      _ ->
        clear()
        user_response = confirmation_message({file_path, files_to_shred})
        handle_user_response_to_confirmation_prompt(user_response)
    end
  end

  defp shred_files({"y", file_path, files_to_shred}) do
    clear()
    String.split(
      files_to_shred, "\n") |>
      Enum.each(fn file_name -> "#{file_path}/#{file_name}" |> File.rm! end)
    IO.puts("Files successfully shredded...")
  end

  defp shred_files("n") do
    IO.puts("Operation aborted...")
  end

  def main(_args) do
    display_list_of_files_that_will_be_shredded()
    |> confirmation_message()
    |> handle_user_response_to_confirmation_prompt()
    |> shred_files
  end
end
