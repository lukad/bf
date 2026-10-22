defmodule Bf do
  import Bitwise

  @moduledoc """
  Interprets brainfuck programs.

  ## Examples

      iex> {:ok, program} = Bf.parse("--[>--->->->++>-<<<<<-------]>--.>---------.>--..+++.")
      iex> Bf.run(program)
      "Hello"

  """

  @typedoc """
  A parsed and optimized brainfuck program.

  Its structure is internal and may change in any release. Create programs
  with `parse/1` and run them with `run/1`.
  """
  @opaque program :: Bf.Program.t()

  @mem_size 30_000

  @compile {:inline, get: 2, put: 3, wrap: 1}

  @doc """
  Parses and optimizes a brainfuck program from a string.

  Returns a `Bf.ParseError` if the program's brackets don't match.

  ## Examples

      iex> {:ok, _program} = Bf.parse("+++++++++[>++++++++<-]>.")

      iex> Bf.parse("+[")
      {:error, %Bf.ParseError{reason: :unmatched_open, line: 1, column: 2}}

  """
  @spec parse(String.t()) :: {:ok, program} | {:error, Bf.ParseError.t()}
  def parse(source) do
    with {:ok, program} <- Bf.Parser.parse(source) do
      {:ok, Bf.Optimizer.optimize(program)}
    end
  end

  @doc """
  Runs a brainfuck program with the given input and returns its output.

  Input and output are bytes. Reading at the end of the input sets the current
  cell to 0. See `run/3` to stream input and output.

  ## Examples

      iex> {:ok, program} = Bf.parse(",[.,]")
      iex> Bf.run(program, "hello")
      "hello"

  """
  @spec run(program, binary) :: binary
  def run(program, input \\ "") when is_binary(input) do
    run(program, [input], "")
  end

  @doc """
  Runs a brainfuck program, streaming its input and output.

  `input` is an enumerable of binaries. It is only consumed as far as the
  program reads, one byte per `,`. Each byte the program writes is put into the
  `output` collectable right away. Returns the collectable's result.

  Reading at the end of the input sets the current cell to 0.

  ## Examples

      iex> {:ok, program} = Bf.parse(",[.,]")
      iex> Bf.run(program, ["he", "llo"], "")
      "hello"

  To stream stdin and stdout, with stdio in latin1 mode so bytes pass through
  unchanged:

      Bf.run(program, IO.binstream(:stdio, 1), IO.binstream(:stdio, 1))

  """
  @spec run(program, Enumerable.t(), Collectable.t()) :: term
  def run(program, input, output) do
    {output, collector} = Collectable.into(output)

    {_ptr, {_chunk, input, output, collector}} =
      run(program, 0, new_memory(), {"", {:unstarted, input}, output, collector})

    if is_function(input), do: input.({:halt, nil})
    collector.(output, :done)
  end

  defp new_memory, do: :atomics.new(@mem_size, signed: false)

  defp run([{:add, x} | rest], ptr, mem, io) do
    put(mem, ptr, get(mem, ptr) + x &&& 0xFF)
    run(rest, ptr, mem, io)
  end

  defp run([{:move, x} | rest], ptr, mem, io) do
    run(rest, wrap(ptr + x), mem, io)
  end

  defp run([{:set, x} | rest], ptr, mem, io) do
    put(mem, ptr, x &&& 0xFF)
    run(rest, ptr, mem, io)
  end

  defp run([{:scan, step} | rest], ptr, mem, io) do
    run(rest, scan(ptr, mem, step), mem, io)
  end

  defp run([{:mul_run, transfers} | rest], ptr, mem, io) do
    mul_run(transfers, ptr, get(mem, ptr), mem)
    put(mem, ptr, 0)
    run(rest, ptr, mem, io)
  end

  defp run([:write | rest], ptr, mem, io) do
    run(rest, ptr, mem, write(io, get(mem, ptr)))
  end

  defp run([:read | rest], ptr, mem, io) do
    {byte, io} = read(io)
    put(mem, ptr, byte)
    run(rest, ptr, mem, io)
  end

  defp run([{:loop, body} | rest] = program, ptr, mem, io) do
    case get(mem, ptr) do
      0 ->
        run(rest, ptr, mem, io)

      _ ->
        {ptr, io} = run(body, ptr, mem, io)
        run(program, ptr, mem, io)
    end
  end

  defp run([], ptr, _mem, io), do: {ptr, io}

  defp read({<<byte, chunk::binary>>, input, output, collector}) do
    {byte, {chunk, input, output, collector}}
  end

  defp read({"", :done, _output, _collector} = io), do: {0, io}

  defp read({"", input, output, collector}) do
    case next_chunk(input) do
      {:suspended, chunk, input} -> read({chunk, input, output, collector})
      {_done_or_halted, nil} -> read({"", :done, output, collector})
    end
  end

  defp next_chunk({:unstarted, input}) do
    Enumerable.reduce(input, {:cont, nil}, fn chunk, nil -> {:suspend, chunk} end)
  end

  defp next_chunk(continuation), do: continuation.({:cont, nil})

  defp write({chunk, input, output, collector}, byte) do
    {chunk, input, collector.(output, {:cont, <<byte>>}), collector}
  end

  defp mul_run([], _ptr, _cell, _mem), do: :ok

  defp mul_run([{offset, factor} | transfers], ptr, cell, mem) do
    target = wrap(ptr + offset)
    put(mem, target, get(mem, target) + cell * factor &&& 0xFF)
    mul_run(transfers, ptr, cell, mem)
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
