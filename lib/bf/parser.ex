# credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart

defmodule Bf.Parser do
  @moduledoc """
  Parses brainfuck programs.

  ## Examples
      iex> Bf.Parser.parse("++++[-.]>--")
      {:ok, [{:add, 4},
             {:loop, [{:add, -1}, {:write}]},
             {:move, 1},
             {:add, -2}]}
  """

  use Combine, parsers: [:text]
  import Combine.Helpers
  alias Combine.ParserState

  @valid_tokens ["+", "-", "<", ">", ",", ".", "[", "]"]

  @typedoc "All possible brainfuck instructions."
  @type instruction ::
          {:add, integer}
          | {:move, integer}
          | {:set, integer}
          | {:scan, integer}
          | {:read}
          | {:write}
          | {:loop, program}

  @typedoc "A list of brainfuck instructions."
  @type program :: list(instruction)

  @doc """
  Parses a brainfuck program into and returns a list of instructions.

  ## Examples

      iex> "--[>--->->->++>-<<<<<-------]>--.>---------.>--..+++."
      ...> |> Bf.Parser.parse()
      {:ok,
       [{:add, -2},
        {:loop,
         [move: 1, add: -3, move: 1, add: -1, move: 1, add: -1,
          move: 1, add: 2, move: 1, add: -1, move: -5, add: -7]},
        {:move, 1}, {:add, -2}, {:write}, {:move, 1}, {:add, -9},
        {:write}, {:move, 1}, {:add, -2}, {:write}, {:write},
        {:add, 3}, {:write}]}
  """
  @spec parse(String.t()) :: {:ok, program} | {:error, term}
  def parse(source) do
    result = Combine.parse(source, program())

    case result do
      {:error, _} -> result
      _ -> {:ok, result |> List.flatten() |> optimize()}
    end
  end

  defp optimize(ast), do: optimize(ast, opt(ast))
  defp optimize(a, a), do: a
  defp optimize(_, b), do: optimize(b, opt(b))

  defp opt([]), do: []

  defp opt([{:loop, [{:add, -1}]} | rest]), do: opt([{:set, 0} | rest])
  defp opt([{:loop, [{:move, n}]} | rest]), do: opt([{:scan, n} | rest])
  defp opt([{:loop, body}, {:loop, _body} | rest]), do: [{:loop, opt(body)} | rest]
  defp opt([{:loop, body} | rest]), do: [{:loop, opt(body)} | opt(rest)]

  defp opt([{:add, a}, {:add, b} | rest]), do: opt([{:add, a + b} | rest])
  defp opt([{:move, a}, {:move, b} | rest]), do: opt([{:move, a + b} | rest])

  defp opt([{:set, a}, {:set, b} | rest]), do: opt([{:set, a + b} | rest])
  defp opt([{:set, 0}, {:loop, _} | rest]), do: [{:set, 0} | opt(rest)]
  defp opt([{:set, 0}, {:add, add} | rest]), do: opt([{:set, add} | rest])
  defp opt([{:add, _}, {:set, x} | rest]), do: opt([{:set, x} | rest])

  defp opt([{:add, 0} | rest]), do: opt(rest)
  defp opt([{:move, 0} | rest]), do: opt(rest)

  defp opt([ins | rest]), do: [ins | opt(rest)]

  defp program do
    skip(comment())
    |> many(instruction())
    |> eof()
  end

  defp instruction do
    skip(comment())
    |> choice([add(), move(), read(), write(), loop()])
    |> skip(comment())
  end

  defp comment, do: many(none_of(char(), @valid_tokens))
  defp read, do: char(",") |> map(fn _ -> {:read} end)
  defp write, do: char(".") |> map(fn _ -> {:write} end)
  defp add, do: sum_instruction(:add, "+", "-")
  defp move, do: sum_instruction(:move, ">", "<")

  @doc false
  defparser lazy(%ParserState{status: :ok} = state, generator) do
    generator.().(state)
  end

  defp loop do
    between(char("["), many(lazy(fn -> instruction() end)) |> skip(comment()), char("]"))
    |> map(&{:loop, &1})
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
