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
      assert parse(" ++++ ") == {:ok, [{:add, 4}]}
    end

    test "parses a very simple program" do
      assert parse(">+<-,.") ==
               {:ok, [{:move, 1}, {:add, 1}, {:move, -1}, {:add, -1}, {:read}, {:write}]}
    end

    test "groups consecutive occurences of + and -" do
      assert parse("++---<>+-----") == {:ok, [{:add, -5}]}
    end

    test "groups consecutive occurences of + and - with non code inbetween" do
      assert parse("-foo-++++\n+bar++- --") == {:ok, [{:add, 2}]}
    end

    test "groups consecutive occurences of > and <" do
      assert parse("<<<>+-<>>>>") == {:ok, [{:move, 1}]}
    end

    test "groups consecutive occurences of < and > with non code inbetween" do
      assert parse("-foo-++++\n+bar++- --") == {:ok, [{:add, 2}]}
    end

    test "parses simple loops" do
      assert parse("-[+++]+") == {:ok, [{:add, -1}, {:loop, [{:add, 3}]}, {:add, 1}]}
    end

    test "parses empty loops with comments" do
      assert parse("[ foobar ]") == {:ok, [{:loop, []}]}
    end

    test "it skips a loop after a loop" do
      assert parse("++[--][+++]++") == {:ok, [{:add, 2}, {:loop, [{:add, -2}]}, add: 2]}
    end

    test "parses nested loops" do
      expected = {:ok, [add: -1, loop: [add: 2, loop: [add: -2]], add: 1]}
      assert parse("-[++[--][++]]+") == expected
    end

    test "fails when loop is not closed" do
      assert {:error, _} = parse("[")
    end

    test "fails when loop is not opened" do
      assert {:error, _} = parse("]")
    end

    test "optimizes clear loops" do
      assert parse("[-]") == {:ok, [{:set, 0}]}
    end

    test "it combines set 0 and a following add" do
      assert parse("[-]+++") == {:ok, [{:set, 3}]}
    end

    test "it skips add before set 0" do
      assert parse("+++[-]") == {:ok, [{:set, 0}]}
    end

    test "it skips add before set" do
      assert parse("-[-]+++") == {:ok, [{:set, 3}]}
    end

    test "it combines consecutive sets" do
      assert parse("[-]+++++[-]--") == {:ok, [{:set, 3}]}
    end

    test "skips set 0 and a loop" do
      assert parse("+++[-][.+]-") == {:ok, [{:set, -1}]}
    end

    test "optimizes [>] to a scan 1" do
      assert parse("[>]") == {:ok, [{:scan, 1}]}
    end

    test "optimizes [<] to a scan -1" do
      assert parse("[<]") == {:ok, [{:scan, -1}]}
    end
  end
end
