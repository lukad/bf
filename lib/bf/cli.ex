defmodule Bf.CLI do
  @moduledoc false

  def main(args) do
    optimus_parser()
    |> Optimus.parse!(args)
    |> run
  end

  defp run(%{args: %{program_file: program_file}}) do
    run_program(program_file)
  end

  defp run({[:ast], %{args: %{program_file: program_file}}}) do
    print_ast(program_file)
  end

  defp optimus_parser do
    Optimus.new!(
      name: "bf",
      description: "Brainfuck interpreter",
      version: version(),
      args: [
        program_file: [
          value_name: "PROGRAM_FILE",
          help: "The brainfuck program file to execute",
          required: true,
        ]
      ],
      subcommands: [
        ast: [
          name: "ast",
          about: "Prints the AST of the parsed program",
          args: [
            program_file: [
              value_name: "PROGRAM_FILE",
              help: "The brainfuck program file to parse",
              required: true
            ]
          ]
        ]
      ]
    )
  end

  defp read_program(program_file) do
    program_file
    |> File.read
    |> case do
         {:ok, program} -> program
         {:error, reason} ->
           IO.puts("Could not read prgram: #{reason}")
           System.halt(1)
       end
  end

  defp run_program(program_file) do
    program_file
    |> read_program
    |> Bf.run
  end

  defp print_ast(program_file) do
    program_file
    |> read_program
    |> to_char_list
    |> parse_program
    |> IO.inspect(limit: :infinity)
  end

  defp parse_program(program) do
    {:ok, tokens, _} = :lexer.string(program)
    {:ok, ast} = :parser.parse(tokens)
    ast
  end

  defp version do
    {:ok, vsn} = :application.get_key(:bf, :vsn)
    List.to_string(vsn)
  end
end
