defmodule Bf do
  alias Bf.State

  def run(program) do
    {:ok, tokens, _} = String.to_charlist(program) |> :lexer.string
    {:ok, ast} = :parser.parse(tokens)
    ast
    |> State.new
    |> do_run
  end

  defp do_run(state = %State{program: [{:inc, x}|rest], ptr: ptr, mem: mem}) do
    %{state | program: rest, mem: List.update_at(mem, ptr, &(&1 + x))}
    |> do_run
  end

  defp do_run(state = %State{program: [{:dec, x}|rest], ptr: ptr, mem: mem}) do
    %{state | program: rest, mem: List.update_at(mem, ptr, &(&1 - x))}
    |> do_run
  end

  defp do_run(state = %State{program: [{:right, x}|rest], ptr: ptr}) do
    %{state | program: rest, ptr: ptr + x}
    |> do_run
  end

  defp do_run(state = %State{program: [{:left, x}|rest], ptr: ptr}) do
    %{state | program: rest, ptr: ptr - x}
    |> do_run
  end

  defp do_run(state = %State{program: [{:write}|rest]}) do
    state
    |> putc
    |> Map.put(:program, rest)
    |> do_run
  end

  defp do_run(state = %State{program: [{:read}|rest], mem: mem, ptr: ptr}) do
    %{state | program: rest, mem: List.replace_at(mem, ptr, readc)}
    |> do_run
  end

  defp do_run(state = %State{program: [{:loop, body}|rest], mem: mem, ptr: ptr}) do
    case Enum.at(mem, ptr) do
      0 ->
        do_run(%{state | program: rest})
      _ ->
        %{mem: mem, ptr: ptr} = do_run(%{state | program: body})
        do_run(%{state | mem: mem, ptr: ptr})
    end
  end

  defp do_run(state = %State{program: []}), do: state

  defp putc(state = %State{mem: mem, ptr: ptr}) do
    [Enum.at(mem, ptr)]
    |> to_string
    |> IO.write
    state
  end

  defp readc do
    case IO.getn("", 1) do
      :eof -> 0
      char -> char |> to_charlist |> List.first
    end
  end
end
