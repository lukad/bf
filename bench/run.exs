# Run time for the programs in bench/programs, with and without the optimizer.
#
#     mix run bench/run.exs [PROGRAM...]
#
# When no program is specified, all programs are benchmarked.

names = with [] <- System.argv(), do: ~w(hello writes writes_nl scan loops mulrun mandelbrot)

inputs =
  for name <- names, into: %{} do
    source = File.read!("bench/programs/#{name}.bf")
    {:ok, unoptimized} = Bf.Parser.parse(source)
    {:ok, optimized} = Bf.parse(source)
    {name, %{unoptimized: unoptimized, optimized: optimized}}
  end

Benchee.run(
  %{
    "optimized" => fn %{optimized: program} -> Bf.run(program) end,
    "unoptimized" => fn %{unoptimized: program} -> Bf.run(program) end
  },
  inputs: inputs,
  warmup: 1,
  time: 5
)
