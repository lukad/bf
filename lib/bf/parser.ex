defmodule Bf.Parser do
  @moduledoc """
  Parses brainfuck programs.

  ## Examples
      iex> Bf.Parser.parse("+++[]+[-]>--")
      {:ok, [{:change, 4},
             {:loop, [{:change, -1}]},
             {:move, 1},
             {:change, -2}]}
  """

  use Combine, parsers: [:text]
  import Combine.Helpers
  alias Combine.ParserState

  @valid_tokens ["+", "-", "<", ">", ",", ".", "[", "]"]

  @typedoc "All possible brainfuck instructions."
  @type instruction ::
    {:change, integer} |
    {:move, integer} |
    {:read} |
    {:write} |
    {:loop, program}

  @typedoc "A list of brainfuck instructions."
  @type program :: list(instruction)

  @doc """
  Parses a brainfuck program into and returns a list of instructions.

  ## Examples

      iex> "--[>--->->->++>-<<<<<-------]>--.>---------.>--..+++."
      ...> |> Bf.Parser.parse()
      {:ok,
       [{:change, -2},
        {:loop,
         [move: 1, change: -3, move: 1, change: -1, move: 1, change: -1,
          move: 1, change: 2, move: 1, change: -1, move: -5, change: -7]},
        {:move, 1}, {:change, -2}, {:write}, {:move, 1}, {:change, -9},
        {:write}, {:move, 1}, {:change, -2}, {:write}, {:write},
        {:change, 3}, {:write}]}
  """
  @spec parse(String.t) :: {:ok, program} | {:error, term}
  def parse(source) do
    result = Combine.parse(source, program())
    case result do
      {:error, _} -> result
      _ -> {:ok, result |> List.flatten() |> optimize()}
    end
  end

  defp optimize(ast), do: optimize(ast, opt(ast))
  defp optimize(a, b) when a == b, do: a
  defp optimize(_, b), do: optimize(b, opt(b))

  defp opt([]), do: []
  defp opt([{:change, 0} | rest]), do: opt(rest)
  defp opt([{:move, 0} | rest]), do: opt(rest)
  defp opt([{:loop, []} | rest]), do: opt(rest)
  defp opt([{:loop, body} | rest]), do: [{:loop, opt(body)} | opt(rest)]
  defp opt([{:change, a}, {:change, b} | rest]) do
    opt([{:change, a + b} | rest])
  end
  defp opt([{:move, a}, {:move, b} | rest]), do: opt([{:move, a + b} | rest])
  defp opt([ins | rest]), do: [ins | opt(rest)]

  defp program do
    skip(comment())
    |> many(instruction())
    |> eof()
  end

  defp instruction do
    skip(comment())
    |> choice([change(), move(), read(), write(), loop()])
    |> skip(comment())
  end

  defp comment, do: many(none_of(char(), @valid_tokens))
  defp read, do: char(",") |> map(fn _ -> {:read} end)
  defp write, do: char(".") |> map(fn _ -> {:write} end)
  defp change, do: sum_instruction(:change, "+", "-")
  defp move, do: sum_instruction(:move, ">", "<")

  @doc false
  defparser lazy(%ParserState{status: :ok} = state, generator) do
    (generator.()).(state)
  end

  defp loop do
    between(char("["), many(lazy(fn -> instruction() end)), char("]"))
    |> map(&({:loop, &1}))
  end

  defp sum_instruction(id, plus, minus) do
    one_of(char(), [plus, minus])
    |> many1()
    |> map(fn tokens -> {id, sum_tokens(tokens, plus, minus)} end)
  end

  defp sum_tokens(tokens, plus, minus) do
    tokens
    |> Enum.reduce(0, fn x, acc ->
      case x do
        ^plus -> acc + 1
        ^minus -> acc - 1
        _ -> acc
      end
    end)
  end
end
