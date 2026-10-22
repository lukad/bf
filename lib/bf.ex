defmodule Bf do
  import Bitwise

  @moduledoc """
  Interprets brainfuck programs.

  ## Examples

      {:ok, program} = Bf.parse("--[>--->->->++>-<<<<<-------]>--.>---------.>--..+++.")
      Bf.run(program)
      Hello
  """

  @typedoc """
  A brainfuck instruction.

  The parser only emits `:add`, `:move`, `:read`, `:write` and `:loop`.
  `:set` and `:scan` are introduced by `Bf.Optimizer`.
  """
  @type instruction ::
          {:add, integer}
          | {:move, integer}
          | {:set, integer}
          | {:scan, integer}
          | {:mul_run, [{integer, integer}]}
          | :read
          | :write
          | {:loop, program}

  @typedoc "A list of brainfuck instructions"
  @type program :: [instruction]

  @typedoc """
  The state returned by the interpreter.

  It is the current cell index and the memory.
  """
  @type state :: {non_neg_integer, [byte()]}

  @mem_size 30_000

  @compile {:inline, get: 2, put: 3, wrap: 1}

  @doc """
  Parses and optimizes a brainfuck program from a string.

  ## Examples

      iex> Bf.parse("+++++++++[>++++++++<-]>.")
      {:ok, [{:add, 9}, {:mul_run, [{1, 8}]}, {:move, 1}, :write]}

  """
  @spec parse(String.t()) :: {:ok, program} | {:error, term()}
  def parse(source) do
    with {:ok, program} <- Bf.Parser.parse(source) do
      {:ok, Bf.Optimizer.optimize(program)}
    end
  end

  @doc """
  Executes a brainfuck program. Returns the machine's state.

  ## Examples

      {:ok, program} = Bf.parse("++++++++++[->++++++++++<]>++.+++++++++.." <>
                                "<+++++++++[->---------<]>-----------------.---.<")
      Bf.run(program)
      foo

  """
  @spec run(program) :: state
  def run(program) do
    mem = :atomics.new(@mem_size, signed: false)
    ptr = run(program, 0, mem)
    {ptr, for(i <- 1..@mem_size, do: :atomics.get(mem, i))}
  end

  # Memory is mutable, so run/3 only returns the pointer.
  defp run([{:add, x} | rest], ptr, mem) do
    put(mem, ptr, get(mem, ptr) + x &&& 0xFF)
    run(rest, ptr, mem)
  end

  defp run([{:move, x} | rest], ptr, mem) do
    run(rest, wrap(ptr + x), mem)
  end

  defp run([{:set, x} | rest], ptr, mem) do
    put(mem, ptr, x &&& 0xFF)
    run(rest, ptr, mem)
  end

  defp run([{:scan, step} | rest], ptr, mem) do
    run(rest, scan(ptr, mem, step), mem)
  end

  defp run([{:mul_run, transfers} | rest], ptr, mem) do
    mul_run(transfers, ptr, get(mem, ptr), mem)
    put(mem, ptr, 0)
    run(rest, ptr, mem)
  end

  defp run([:write | rest], ptr, mem) do
    putc(ptr, mem)
    run(rest, ptr, mem)
  end

  defp run([:read | rest], ptr, mem) do
    case readc() do
      :eof -> :ok
      char -> put(mem, ptr, char &&& 0xFF)
    end

    run(rest, ptr, mem)
  end

  defp run([{:loop, body} | rest] = program, ptr, mem) do
    case get(mem, ptr) do
      0 -> run(rest, ptr, mem)
      _ -> run(program, run(body, ptr, mem), mem)
    end
  end

  defp run([], ptr, _mem), do: ptr

  defp mul_run([], _ptr, _cell, _mem), do: :ok

  defp mul_run([{offset, factor} | transfers], ptr, cell, mem) do
    target = wrap(ptr + offset)
    put(mem, target, get(mem, target) + cell * factor &&& 0xFF)
    mul_run(transfers, ptr, cell, mem)
  end

  defp putc(ptr, mem) do
    cell = get(mem, ptr)
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
    cell = get(mem, ptr)

    case cell do
      0 -> ptr
      _ -> scan(wrap(ptr + step), mem, step)
    end
  end

  defp get(mem, ptr), do: :atomics.get(mem, ptr + 1)
  defp put(mem, ptr, value), do: :atomics.put(mem, ptr + 1, value)

  defp wrap(ptr) when ptr >= 0 and ptr < @mem_size, do: ptr
  defp wrap(ptr) when ptr < 0 and ptr >= -@mem_size, do: ptr + @mem_size

  defp wrap(ptr) do
    case rem(ptr, @mem_size) do
      value when value < 0 -> value + @mem_size
      value -> value
    end
  end
end
