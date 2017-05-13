defmodule BfParserTest do
  use ExUnit.Case
  doctest Bf.Parser

  import Bf.Parser

  describe "parse/1" do
    test "skips non bf instructions" do
      assert parse("This is a valid Brainfuck program.") == {:ok, [{:write}]}
    end

    test "parses an empty program" do
      assert parse("") == {:ok, []}
    end

    test "parses an empty program with non code" do
      assert parse(" foo bar baz ") == {:ok, []}
    end

    test "parses a very very simple program" do
      assert parse(" ++++ ") == {:ok, [{:change, 4}]}
    end

    test "parses a very simple program" do
      assert parse(">+<-,.") == {:ok, [{:move, 1}, {:change, 1}, {:move, -1},
                                          {:change, -1}, {:read}, {:write}]}
    end

    test "groups consecutive occurences of + and -" do
      assert parse("++---+-----") == {:ok, [{:change, -5}]}
    end

    test "groups consecutive occurences of + and - with non code inbetween" do
      assert parse("-foo-++++\n+bar++- --") == {:ok, [{:change, 2}]}
    end

    test "groups consecutive occurences of > and <" do
      assert parse("<<<><>>>>") == {:ok, [{:move, 1}]}
    end

    test "groups consecutive occurences of < and > with non code inbetween" do
      assert parse("-foo-++++\n+bar++- --") == {:ok, [{:change, 2}]}
    end

    test "parses simple loops" do
      assert parse("-[+++]+") == {:ok, [{:change, -1},
                                           {:loop, [{:change, 3}]},
                                           {:change, 1}]}
    end

    test "it skips empty loops" do
      assert parse("++[[[[][]]][]]++") == {:ok, [{:change, 4}]}
    end


    test "parses nested loops" do
      expected = {:ok, [change: -1,
                        loop: [change: 2,
                               loop: [change: -2],
                               loop: [change: 2]],
                        change: 1]}
      assert parse("-[++[--][++]]+") == expected
    end

    test "fails when loop is not closed" do
      assert {:error, _} = parse("[")
    end

    test "fails when loop is not opened" do
      assert {:error, _} = parse("]")
    end
  end
end
