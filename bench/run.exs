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

{:ok, null} = File.open("/dev/null", [:write])

# Bf.run writes to the group leader. Pointing it at /dev/null keeps the
# programs' output out of the report while still paying for the writes.
run = fn program ->
  leader = Process.group_leader()
  Process.group_leader(self(), null)

  try do
    Bf.run(program)
  after
    Process.group_leader(self(), leader)
  end
end

Benchee.run(
  %{
    "optimized" => fn %{optimized: program} -> run.(program) end,
    "unoptimized" => fn %{unoptimized: program} -> run.(program) end
  },
  inputs: inputs,
  warmup: 1,
  time: 5
)
