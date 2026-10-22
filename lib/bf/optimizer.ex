defmodule Bf.Optimizer do
  @moduledoc false

  @doc """
  Optimizes a parsed brainfuck program.

  ## Examples

      iex> Bf.Optimizer.optimize([{:add, 1}, {:add, 2}, {:move, 1}, {:move, -1}, {:add, -2}])
      [{:add, 1}]

  """
  @spec optimize(Bf.Program.t()) :: Bf.Program.t()
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
  defp optimize_non_loop({:mul_run, _}, [{:set, 0} | _] = out), do: out

  defp optimize_non_loop(ins, out), do: [ins | out]

  defp optimize_loop([]), do: {:loop, []}
  defp optimize_loop([{:add, -1}]), do: {:set, 0}
  defp optimize_loop([{:move, n}]), do: {:scan, n}
  defp optimize_loop([{:set, 0}]), do: {:set, 0}
  defp optimize_loop(body), do: optimize_mul(body)

  defp optimize_mul(body) do
    with {:ok, 0, muls} <- collect_muls(body, 0, %{}),
         {-1, transfers} <- Map.pop(muls, 0) do
      case Enum.sort(transfers) do
        [] -> {:set, 0}
        transfers -> {:mul_run, transfers}
      end
    else
      _ -> {:loop, body}
    end
  end

  defp collect_muls([], offset, muls), do: {:ok, offset, muls}

  defp collect_muls([{:add, n} | rest], offset, muls) do
    collect_muls(rest, offset, Map.update(muls, offset, n, &(&1 + n)))
  end

  defp collect_muls([{:move, n} | rest], offset, muls) do
    collect_muls(rest, offset + n, muls)
  end

  defp collect_muls(_, _, _), do: :error
end
