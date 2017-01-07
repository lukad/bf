defmodule Bf.CLI do
  def main([]) do
    IO.puts("Please specify a brainfuck program to run")
  end

  def main([filename|_]) do
    filename
    |> File.read
    |> run(filename)
  end

  defp run({:ok, program}, _filename) do
    Bf.run(program)
  end

  defp run(_file, filename) do
    IO.puts("Could not read program \"#{filename}\"")
    System.halt(1)
  end
end
