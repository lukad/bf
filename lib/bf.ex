defmodule Bf do
  @moduledoc """
  Parses and interprets brainfuck programs.

  ## Examples

      iex> Bf.run("--[>--->->->++>-<<<<<-------]>--.>---------.>--..+++.")
      Hello
  """

  @typedoc "All possible brainfuck instructions."
  @type instruction
  :: {:change, integer}
  | {:move, integer}
  | {:read}
  | {:write}
  | {:loop, program}

  @typedoc "A list of brainfuck instructions."
  @type program :: list(instruction)

  @doc """
  Parses a brainfuck program into and returns a list of instructions.

  ## Examples
      iex> Bf.run("--[>--->->->++>-<<<<<-------]>--.>---------.>--..+++.")
      [{:change, -2},
       {:loop, [move: 1, change: -3, move: 1, change: -1, move: 1, change: -1,
                move: 1, change: 2, move: 1, change: -1, move: -5, change: -7]},
       {:move, 1},
       {:change, -2}, {:write}, {:move, 1}, {:change, -9}, {:write}, {:move, 1},
       {:change, -2}, {:write}, {:write}, {:change, 3}, {:write}]
  """
  @spec parse(String.t | List.Chars.t) :: {:ok, program}
  def parse(program) when is_binary(program) do
    program
    |> to_charlist
    |> parse
  end

  def parse(program) when is_list(program) do
    {:ok, tokens, _} = :lexer.string(program)
    :parser.parse(tokens)
  end

  @typedoc """
  The state returned by the interpreter.

  It is the current cell index and the memory.
  """
  @type state :: {integer, list(integer)}

  @doc """
  Parses and executes a brainfuck program. Returns the machine's state.

  ## Examples

      iex> Bf.run("++++++++++[->++++++++++<]>++.+++++++++.." <>
                  "<+++++++++[->---------<]>-----------------.---.<")
      foo
      {0,
       [0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...]}
  """
  @spec run(String.t) :: state
  def run(program) do
    {:ok, ast} = program |> parse
    run(ast, 0, List.duplicate(0, 30_000))
  end

  defp run([{:change, x} | rest], ptr, mem) do
    run(rest, ptr, List.update_at(mem, ptr, &(&1 + x)))
  end

  defp run([{:move, x} | rest], ptr, mem) do
    run(rest, ptr + x, mem)
  end

  defp run([{:write} | rest], ptr, mem) do
    putc(ptr, mem)
    run(rest, ptr, mem)
  end

  defp run([{:read} | rest], ptr, mem) do
    run(rest, ptr, List.replace_at(mem, ptr, readc()))
  end

  defp run(program = [{:loop, body} | rest], ptr, mem) do
    case Enum.at(mem, ptr) do
      0 ->
        run(rest, ptr, mem)
      _ ->
        {p, m} = run(body, ptr, mem)
        run(program, p, m)
    end
  end

  defp run([], ptr, mem), do: {ptr, mem}

  defp putc(ptr, mem) do
    [Enum.at(mem, ptr)]
    |> IO.write
  end

  defp readc do
    case IO.getn("", 1) do
      :eof -> 0
      {:error, _reason} -> 0
      char -> char |> to_charlist |> List.first
    end
  end
end
