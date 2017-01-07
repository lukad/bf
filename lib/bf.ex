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

  defp do_run(state = %State{program: [{:loop, body}|rest], mem: mem, ptr: ptr, loop: loops, rest: rests}) do
    if Enum.at(mem, ptr) == 0 do
      do_run(%{state | program: rest})
    else
      do_run(%{state | program: body, loop: [body] ++ loops, rest: [rest] ++ rests})
    end
  end

  defp do_run(state = %State{program: [], loop: [loop|loops], rest: [rest|rests], mem: mem, ptr: ptr}) do
    if Enum.at(mem, ptr) == 0 do
      %{state | program: rest, loop: loops, rest: rests}
    else
      %{state | program: loop}
    end
    |> do_run
  end

  defp do_run(state = %State{program: [], loop: [loop|loops], rest: [], mem: mem, ptr: ptr}) do
    if Enum.at(mem, ptr) == 0 do
      state
    else
      %{state | program: loop, loop: loops}
      |> do_run
    end
  end

  defp do_run(state = %State{program: [], loop: [], rest: []}), do: state

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
