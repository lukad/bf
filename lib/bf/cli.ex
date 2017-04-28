defmodule Bf.CLI do
  @moduledoc false

  def main(args) do
    optimus_parser()
    |> Optimus.parse!(args)
    |> read_program
    |> run_program
  end

  defp optimus_parser do
    Optimus.new!(
      name: "bf",
      description: "Brainfuck interpreter",
      version: version(),
      args: [
        program_file: [
          value_name: "PROGRAM_FILE",
          help: "Brainfuck program file to execute",
          required: true,
        ]
      ]
    )
  end

  defp read_program(%{args: %{program_file: program_file}}) do
    program_file
    |> File.read
  end

  defp run_program({:ok, program}) do
    Bf.run(program)
  end

  defp run_program({:error, reason}) do
    IO.puts("Could not read program: #{reason}")
    System.halt(1)
  end

  defp version do
    {:ok, vsn} = :application.get_key(:bf, :vsn)
    List.to_string(vsn)
  end
end
