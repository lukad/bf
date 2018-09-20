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
    mem = for i <- List.duplicate(0, 30_000), do: <<i::8>>, into: <<>>
    {ptr, mem} = run(program, 0, mem)
    {ptr, :binary.bin_to_list(mem)}
  end

  defp run([{:add, x} | rest], ptr, mem) do
    <<head::binary-size(ptr), cell, tail::binary>> = mem
    run(rest, ptr, head <> <<cell + x>> <> tail)
  end

  defp run([{:move, x} | rest], ptr, mem) do
    run(rest, wrap(ptr + x, @mem_size), mem)
  end

  defp run([{:set, x} | rest], ptr, mem) do
    <<head::binary-size(ptr), _cell, tail::binary>> = mem
    run(rest, ptr, head <> <<x>> <> tail)
  end

  defp run([{:mul, muls} | rest], ptr, mem) do
    <<_head::binary-size(ptr), cell, _tail::binary>> = mem

    mem =
      Enum.reduce(muls, mem, fn {offset, times}, acc ->
        target = wrap(ptr + offset, @mem_size)
        <<head::binary-size(target), target, tail::binary>> = acc
        value = target + cell * times
        head <> <<value>> <> tail
      end)

    <<head::binary-size(ptr), _cell, tail::binary>> = mem
    run(rest, ptr, head <> <<0>> <> tail)
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
        <<head::binary-size(ptr), _cell, tail::binary>> = mem
        run(rest, ptr, head <> char <> tail)
    end
  end

  defp run(program = [{:loop, body} | rest], ptr, mem) do
    <<_head::binary-size(ptr), cell, _tail::binary>> = mem

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
    <<_head::binary-size(ptr), cell, _tail::binary>> = mem
    IO.binwrite(<<cell>>)
  end

  defp readc do
    case IO.getn("", 1) do
      {:error, _reason} -> :eof
      char -> char
    end
  end

  defp scan(ptr, mem, step) do
    <<_head::binary-size(ptr), cell, _tail::binary>> = mem

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
