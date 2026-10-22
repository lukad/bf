if Code.ensure_loaded?(Optimus) do
  defmodule Bf.CLI do
    @moduledoc false

    def main(args) do
      status =
        optimus_parser()
        |> Optimus.parse!(args)
        |> run()

      if status != 0, do: System.halt(status)
    end

    @doc false
    @spec run(Optimus.ParseResult.t() | {[atom], Optimus.ParseResult.t()}) :: non_neg_integer
    def run({[:ast], %{args: %{program_file: program_file}}}), do: print_ast(program_file)
    def run(%{args: %{program_file: program_file}}), do: run_program(program_file)

    defp optimus_parser do
      Optimus.new!(
        name: "bf",
        description: "Brainfuck interpreter",
        version: version(),
        args: [
          program_file: [
            value_name: "PROGRAM_FILE",
            help: "The brainfuck program file to execute",
            required: true
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

    defp load_program(program_file) do
      with {:read, {:ok, source}} <- {:read, File.read(program_file)},
           {:parse, {:ok, program}} <- {:parse, Bf.parse(source)} do
        {:ok, program}
      else
        {:read, {:error, reason}} ->
          IO.puts(:stderr, "Could not read program: #{:file.format_error(reason)}")
          1

        {:parse, {:error, error}} ->
          IO.puts(:stderr, "Could not parse program: #{Exception.message(error)}")
          1
      end
    end

    defp run_program(program_file) do
      with {:ok, program} <- load_program(program_file) do
        :logger.set_module_level(:user_drv, :none)

        try do
          Bf.run(program, IO.binstream(:stdio, 1), IO.binstream(:stdio, 1))
          0
        catch
          :error, :terminated -> 141
        end
      end
    end

    defp print_ast(program_file) do
      with {:ok, program} <- load_program(program_file) do
        # credo:disable-for-next-line Credo.Check.Warning.IoInspect
        IO.inspect(program, limit: :infinity)
        0
      end
    end

    defp version do
      {:ok, vsn} = :application.get_key(:bf, :vsn)
      List.to_string(vsn)
    end
  end
end
