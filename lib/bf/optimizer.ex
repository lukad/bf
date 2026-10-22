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
  @spec optimize(Bf.program()) :: Bf.program()
  def optimize(program) do
    program
    |> Enum.reduce([], &optimize_instruction/2)
    |> Enum.reverse()
  end

  defp optimize_instruction({:add, 0}, out), do: out
  defp optimize_instruction({:move, 0}, out), do: out

  defp optimize_instruction({:loop, body}, out) do
    optimize_non_loop(optimize_loop(optimize(body)), out)
  end

  defp optimize_instruction(ins, out), do: optimize_non_loop(ins, out)

  defp optimize_non_loop({:add, b}, [{:add, a} | out]) do
    optimize_instruction({:add, a + b}, out)
  end

  defp optimize_non_loop({:move, b}, [{:move, a} | out]) do
    optimize_instruction({:move, a + b}, out)
  end

  defp optimize_non_loop({:add, b}, [{:set, a} | out]) do
    optimize_non_loop({:set, a + b}, out)
  end

  defp optimize_non_loop({:set, n}, [{:add, _} | out]), do: optimize_non_loop({:set, n}, out)
  defp optimize_non_loop({:set, n}, [{:set, _} | out]), do: optimize_non_loop({:set, n}, out)
  defp optimize_non_loop({:loop, _}, [{:set, 0} | _] = out), do: out

  defp optimize_non_loop(ins, out), do: [ins | out]

  defp optimize_loop([{:add, -1}]), do: {:set, 0}
  defp optimize_loop([{:move, n}]), do: {:scan, n}
  defp optimize_loop([{:set, 0}]), do: {:set, 0}
  defp optimize_loop(body), do: {:loop, body}
end
