defmodule Bf.Parser do
  @moduledoc """
  Parses brainfuck programs.

  ## Examples

      iex> Bf.Parser.parse("++[-.]>-")
      {:ok, [add: 1, add: 1, loop: [{:add, -1}, :write], move: 1, add: -1]}

  """

  @typedoc "All possible brainfuck instructions"
  @type instruction ::
          {:add, integer}
          | {:move, integer}
          | {:set, integer}
          | {:scan, integer}
          | :read
          | :write
          | {:loop, program}

  @typedoc "A list of brainfuck instructions"
  @type program :: list(instruction)

  @doc """
  Parses a brainfuck program into and returns a list of instructions.

  ## Examples

      iex> Bf.Parser.parse("+[>,.<-]")
      {:ok, [add: 1, loop: [{:move, 1}, :read, :write, {:move, -1}, {:add, -1}]]}

      iex> Bf.Parser.parse("[")
      {:error, "unmatched ["}
  """

  @spec parse(String.t()) :: {:ok, program} | {:error, term}
  def parse(source) do
    chars = String.graphemes(source)
    parse(chars, [[]])
  end

  defp parse([], [program]), do: {:ok, Enum.reverse(program)}

  defp parse([], [_ | _]), do: {:error, "unmatched ["}

  defp parse(["+" | rest], [program | stack]) do
    parse(rest, [[{:add, 1} | program] | stack])
  end

  defp parse(["-" | rest], [program | stack]) do
    parse(rest, [[{:add, -1} | program] | stack])
  end

  defp parse([">" | rest], [program | stack]) do
    parse(rest, [[{:move, 1} | program] | stack])
  end

  defp parse(["<" | rest], [program | stack]) do
    parse(rest, [[{:move, -1} | program] | stack])
  end

  defp parse(["," | rest], [program | stack]) do
    parse(rest, [[:read | program] | stack])
  end

  defp parse(["." | rest], [program | stack]) do
    parse(rest, [[:write | program] | stack])
  end

  defp parse(["[" | rest], programs) do
    parse(rest, [[] | programs])
  end

  defp parse(["]" | _], [_]) do
    {:error, "unmatched ]"}
  end

  defp parse(["]" | rest], [body, parent | stack]) do
    parse(rest, [[{:loop, Enum.reverse(body)} | parent] | stack])
  end

  defp parse([_ | rest], stack), do: parse(rest, stack)
end
