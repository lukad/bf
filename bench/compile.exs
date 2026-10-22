# Parse and optimize time for the programs in bench/programs.
#
#     mix run bench/compile.exs [PROGRAM...]
#
# Without arguments, all programs are benchmarked.

names = with [] <- System.argv(), do: ~w(hello writes writes_nl scan loops mulrun mandelbrot)

inputs =
  for name <- names, into: %{} do
    {name, File.read!("bench/programs/#{name}.bf")}
  end

Benchee.run(
  %{
    "parse" => &Bf.Parser.parse/1,
    "optimize" => {&Bf.Optimizer.optimize/1, before_each: &elem(Bf.Parser.parse(&1), 1)},
    "parse + optimize" => &Bf.parse/1
  },
  inputs: inputs,
  warmup: 1,
  time: 3
)
