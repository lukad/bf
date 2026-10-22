defmodule Bf.Parser do
  @moduledoc false

  alias Bf.ParseError

  @doc """
  Parses a brainfuck program into and returns a list of instructions.

  ## Examples

      iex> Bf.Parser.parse("+[>,.<-]")
      {:ok, [add: 1, loop: [{:move, 1}, :read, :write, {:move, -1}, {:add, -1}]]}

      iex> Bf.Parser.parse("+\\n [")
      {:error, %Bf.ParseError{reason: :unmatched_open, line: 2, column: 2}}

  """

  @spec parse(String.t()) :: {:ok, Bf.Program.t()} | {:error, ParseError.t()}
  def parse(source) do
    parse(String.graphemes(source), {1, 1}, [{[], nil}])
  end

  defp parse([], _pos, [{program, nil}]), do: {:ok, Enum.reverse(program)}
  defp parse([], _pos, [{_body, open} | _]), do: error(:unmatched_open, open)

  defp parse(["[" | rest], pos, stack) do
    parse(rest, advance(pos, "["), [{[], pos} | stack])
  end

  defp parse(["]" | _], pos, [{_program, nil}]), do: error(:unmatched_close, pos)

  defp parse(["]" | rest], pos, [{body, _open}, {parent, parent_open} | stack]) do
    loop = {:loop, Enum.reverse(body)}
    parse(rest, advance(pos, "]"), [{[loop | parent], parent_open} | stack])
  end

  defp parse([char | rest], pos, [{program, open} | stack]) do
    case instruction(char) do
      nil -> parse(rest, advance(pos, char), [{program, open} | stack])
      ins -> parse(rest, advance(pos, char), [{[ins | program], open} | stack])
    end
  end

  defp instruction("+"), do: {:add, 1}
  defp instruction("-"), do: {:add, -1}
  defp instruction(">"), do: {:move, 1}
  defp instruction("<"), do: {:move, -1}
  defp instruction(","), do: :read
  defp instruction("."), do: :write
  defp instruction(_comment), do: nil

  defp advance({line, _column}, newline) when newline in ["\n", "\r\n"], do: {line + 1, 1}
  defp advance({line, column}, _char), do: {line, column + 1}

  defp error(reason, {line, column}) do
    {:error, %ParseError{reason: reason, line: line, column: column}}
  end
end
