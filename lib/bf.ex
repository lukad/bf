defmodule Bf do
  def run(program) do
    {:ok, tokens, _} = String.to_charlist(program) |> :lexer.string
    {:ok, ast} = :parser.parse(tokens)
    run(ast, 0, List.duplicate(0, 30_000))
  end

  defp run([{:change, x}|rest], ptr, mem) do
    run(rest, ptr, List.update_at(mem, ptr, &(&1 + x)))
  end

  defp run([{:move, x}|rest], ptr, mem) do
    run(rest, ptr + x, mem)
  end

  defp run([{:write}|rest], ptr, mem) do
    putc(ptr, mem)
    run(rest, ptr, mem)
  end

  defp run([{:read}|rest], ptr, mem) do
    run(rest, ptr, List.replace_at(mem, ptr, readc))
  end

  defp run(program = [{:loop, body}|rest], ptr, mem) do
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
    |> to_string
    |> IO.write
  end

  defp readc do
    case IO.getn("", 1) do
      :eof -> 0
      char -> char |> to_charlist |> List.first
    end
  end
end
