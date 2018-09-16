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

  @cell_size 256
  @mem_size 30_000

  @doc """
  Parses and executes a brainfuck program. Returns the machine's state.

  ## Examples

      Bf.Parser.parse("++++++++++[->++++++++++<]>++.+++++++++.." <>
                      "<+++++++++[->---------<]>-----------------.---.<")
      |> Bf.run
      foo
  """
  @spec run({:ok, Bf.Parser.program()}) :: state
  def run({:ok, program}) do
    run(program, 0, List.duplicate(0, @mem_size))
  end

  defp run([{:add, x} | rest], ptr, mem) do
    run(rest, ptr, List.update_at(mem, ptr, &wrap(&1 + x, @cell_size)))
  end

  defp run([{:move, x} | rest], ptr, mem) do
    run(rest, wrap(ptr + x, @mem_size), mem)
  end

  defp run([{:set, x} | rest], ptr, mem) do
    run(rest, ptr, List.update_at(mem, ptr, fn _ -> x end))
  end

  defp run([{:scan, step} | rest], ptr, mem) do
    run(rest, scan(ptr, mem, step), mem)
  end

  defp run([{:write} | rest], ptr, mem) do
    putc(ptr, mem)
    run(rest, ptr, mem)
  end

  defp run([{:read} | rest], ptr, mem) do
    run(rest, ptr, List.replace_at(mem, ptr, wrap(readc(), @cell_size)))
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
    |> IO.write()
  end

  defp readc do
    case IO.getn("", 1) do
      :eof -> 0
      {:error, _reason} -> 0
      char -> char |> to_charlist |> List.first()
    end
  end

  defp scan(ptr, mem, step) do
    case Enum.at(mem, ptr) do
      0 -> ptr
      _ -> scan(wrap(ptr + step, @mem_size), mem, step)
    end
  end

  defp wrap(a, b) do
    case rem(a, b) do
      value when value < 0 -> value + b
      value -> value
    end
  end
end
