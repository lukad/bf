defmodule BfOptimizerTest do
  use ExUnit.Case
  doctest Bf.Optimizer

  import Bf.Optimizer

  describe "optimize/1" do
    test "keeps an empty program" do
      assert optimize([]) == []
    end

    test "merges consecutive adds" do
      assert optimize(add: 1, add: 1, add: -3) == [add: -1]
    end

    test "merges consecutive moves" do
      assert optimize(move: 1, move: 1, move: -3) == [move: -1]
    end

    test "does not merge adds and moves" do
      assert optimize(add: 1, move: 1, add: 1) == [add: 1, move: 1, add: 1]
    end

    test "drops adds and moves of 0" do
      assert optimize(add: 0, move: 0) == []
    end

    test "drops cancelling runs" do
      assert optimize(add: 1, add: -1, move: -1, move: 1) == []
    end

    test "merges across a dropped run" do
      assert optimize(move: 1, add: 1, add: -1, move: -1) == []
      assert optimize(add: 2, move: 1, move: -1, add: 3) == [add: 5]
    end

    test "does not merge across io" do
      assert optimize([{:add, 1}, :write, {:add, 1}, :read, {:add, 1}]) ==
               [{:add, 1}, :write, {:add, 1}, :read, {:add, 1}]
    end

    test "does not merge across loops" do
      assert optimize(add: 1, loop: [], add: 1) == [add: 1, loop: [], add: 1]
    end

    test "keeps empty loops" do
      assert optimize(loop: []) == [loop: []]
      assert optimize(loop: [add: 1, add: -1]) == [loop: []]
    end

    test "optimizes loop bodies" do
      assert optimize(loop: [add: -1, add: -1, move: 1, move: 1]) == [loop: [add: -2, move: 2]]
    end

    test "optimizes nested loop bodies" do
      assert optimize(loop: [move: 1, loop: [add: 1, add: 1], move: -1, move: -1]) ==
               [loop: [move: 1, loop: [add: 2], move: -2]]
    end

    test "is idempotent" do
      for source <- BfTest.Programs.all() do
        {:ok, program} = Bf.Parser.parse(source)
        optimized = optimize(program)

        assert optimize(optimized) == optimized
      end
    end
  end

  describe "optimize/1 loop rewrites" do
    test "optimizes clear loops" do
      assert optimize_source("[-]") == [set: 0]
    end

    test "combines set 0 and a following add" do
      assert optimize_source("[-]+++") == [set: 3]
    end

    test "skips add before set 0" do
      assert optimize_source("+++[-]") == [set: 0]
    end

    test "only applies the last of consecutive sets" do
      assert optimize_source("[-]++[-]+++++[-]--") == [set: -2]
    end

    test "skips a loop after set 0" do
      assert optimize_source("+++[-][.+]-") == [set: -1]
    end

    test "optimizes [>] to a scan 1" do
      assert optimize_source("[>]") == [scan: 1]
    end

    test "optimizes [<] to a scan -1" do
      assert optimize_source("[<]") == [scan: -1]
    end
  end

  describe "optimize/1 multiplication loops" do
    test "optimizes a single transfer" do
      assert optimize_source("[->+++<]") == [mul_run: [{1, 3}]]
    end

    test "optimizes multiple transfers" do
      assert optimize_source("[->++>+++<<]") == [mul_run: [{1, 2}, {2, 3}]]
    end

    test "allows the decrement anywhere in the body" do
      assert optimize_source("[>+<-]") == [mul_run: [{1, 1}]]
    end

    test "sorts transfers by offset" do
      assert optimize_source("[->>++<<<+>]") == [mul_run: [{-1, 1}, {2, 2}]]
    end

    test "sums repeated transfers to the same offset" do
      assert optimize_source("[->+>+<+<]") == [mul_run: [{1, 2}, {2, 1}]]
    end

    test "keeps negative factors" do
      assert optimize_source("[->--<]") == [mul_run: [{1, -2}]]
    end

    test "skips a multiplication loop after set 0" do
      assert optimize_source("[-][->+<]") == [set: 0]
    end

    test "optimizes multiplication loops nested in other loops" do
      assert optimize_source("+[>[->+<]<-]") ==
               [add: 1, loop: [move: 1, mul_run: [{1, 1}], move: -1, add: -1]]
    end

    test "keeps loops whose moves don't cancel out" do
      assert optimize_source("[->+]") == [loop: [add: -1, move: 1, add: 1]]
    end

    test "keeps loops that don't decrement the source by one" do
      assert optimize_source("[-->+<]") == [loop: [add: -2, move: 1, add: 1, move: -1]]
      assert optimize_source("[+>+<]") == [loop: [add: 1, move: 1, add: 1, move: -1]]
      assert optimize_source("[>+<]") == [loop: [move: 1, add: 1, move: -1]]
    end

    test "keeps loops with io" do
      assert optimize_source("[->.+<]") == [
               loop: [{:add, -1}, {:move, 1}, :write, {:add, 1}, {:move, -1}]
             ]

      assert optimize_source("[->,<]") == [loop: [{:add, -1}, {:move, 1}, :read, {:move, -1}]]
    end

    test "keeps loops with nested loops" do
      assert optimize_source("[->[-]<]") == [loop: [add: -1, move: 1, set: 0, move: -1]]
    end
  end

  defp optimize_source(source) do
    {:ok, program} = Bf.Parser.parse(source)
    optimize(program)
  end
end
