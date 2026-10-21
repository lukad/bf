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
end
