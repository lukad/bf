defmodule Bf do
  use Bitwise

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
    mem = :array.new(@mem_size, default: 0)
    {ptr, mem} = run(program, 0, mem)
    {ptr, :array.to_list(mem)}
  end

  defp run([{:add, x} | rest], ptr, mem) do
    cell = :array.get(ptr, mem)
    new_mem = :array.set(ptr, cell + x &&& 0xFF, mem)
    run(rest, ptr, new_mem)
  end

  defp run([{:move, x} | rest], ptr, mem) do
    run(rest, wrap(ptr + x, @mem_size), mem)
  end

  defp run([{:set, x} | rest], ptr, mem) do
    new_mem = :array.set(ptr, x &&& 0xFF, mem)
    run(rest, ptr, new_mem)
  end

  defp run([{:scan, step} | rest], ptr, mem) do
    run(rest, scan(ptr, mem, step), mem)
  end

  defp run([{:write} | rest], ptr, mem) do
    putc(ptr, mem)
    run(rest, ptr, mem)
  end

  defp run([{:read} | rest], ptr, mem) do
    case readc() do
      :eof ->
        run(rest, ptr, mem)

      char ->
        new_mem = :array.set(ptr, char &&& 0xFF, mem)
        run(rest, ptr, new_mem)
    end
  end

  defp run(program = [{:loop, body} | rest], ptr, mem) do
    cell = :array.get(ptr, mem)

    case cell do
      0 ->
        run(rest, ptr, mem)

      _ ->
        {p, m} = run(body, ptr, mem)
        run(program, p, m)
    end
  end

  defp run([], ptr, mem), do: {ptr, mem}

  defp putc(ptr, mem) do
    cell = :array.get(ptr, mem)
    IO.binwrite(<<cell>>)
  end

  defp readc do
    case IO.getn("", 1) do
      {:error, _reason} -> :eof
      :eof -> :eof
      <<char>> -> char
    end
  end

  defp scan(ptr, mem, step) do
    cell = :array.get(ptr, mem)

    case cell do
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
