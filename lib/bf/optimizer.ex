defmodule Bf.Optimizer do
  @moduledoc """
  Optimizes parsed brainfuck programs.
  """

  @doc """
  Optimizes a parsed brainfuck program.

  ## Examples

      iex> Bf.Optimizer.optimize([{:add, 1}, {:add, 2}, {:move, 1}, {:move, -1}, {:add, -2}])
      [{:add, 1}]

  """
  @spec optimize(Bf.Parser.program()) :: Bf.Parser.program()
  def optimize(program) do
    program
    |> Enum.reduce([], &optimize_instruction/2)
    |> Enum.reverse()
  end

  defp optimize_instruction({:add, 0}, out), do: out
  defp optimize_instruction({:move, 0}, out), do: out

  defp optimize_instruction({:loop, body}, out) do
    optimize_non_loop({:loop, optimize(body)}, out)
  end

  defp optimize_instruction(ins, out), do: optimize_non_loop(ins, out)

  defp optimize_non_loop({:add, b}, [{:add, a} | out]) do
    optimize_instruction({:add, a + b}, out)
  end

  defp optimize_non_loop({:move, b}, [{:move, a} | out]) do
    optimize_instruction({:move, a + b}, out)
  end

  defp optimize_non_loop(ins, out), do: [ins | out]
end
