defmodule Bf do
  @moduledoc """
  Interprets brainfuck programs.

  ## Examples

      Bf.Parser.parse("--[>--->->->++>-<<<<<-------]>--.>---------.>--..+++.")
      |> Bf.run()
      Hello
  """

  @typedoc """
  The state returned by the interpreter.

  It is the current cell index and the memory.
  """
  @type state :: {integer, list(integer)}

  @doc """
  Parses and executes a brainfuck program. Returns the machine's state.

  ## Examples

      Bf.Parser.parse("++++++++++[->++++++++++<]>++.+++++++++.." <>
                      "<+++++++++[->---------<]>-----------------.---.<")
      |> Bf.run
      foo
  """
  @spec run(Bf.Parser.program) :: state
  def run({:ok, program}) do
    run(program, 0, List.duplicate(0, 30_000))
  end

  defp run([{:add, x} | rest], ptr, mem) do
    run(rest, ptr, List.update_at(mem, ptr, &(wrap(&1 + x))))
  end

  defp run([{:move, x} | rest], ptr, mem) do
    run(rest, ptr + x, mem)
  end

  defp run([{:set, x} | rest], ptr, mem) do
    run(rest, ptr, List.update_at(mem, ptr, fn _ -> x end))
  end

  defp run([{:write} | rest], ptr, mem) do
    putc(ptr, mem)
    run(rest, ptr, mem)
  end

  defp run([{:read} | rest], ptr, mem) do
    run(rest, ptr, List.replace_at(mem, ptr, wrap(readc())))
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

  defp wrap(a, b \\ 256) do
    case rem(a, b) do
      value when value < 0 -> value + b
      value -> value
    end
  end
end
