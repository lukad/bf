defmodule BfParserTest do
  use ExUnit.Case
  doctest Bf.Parser

  import Bf.Parser

  alias Bf.ParseError

  describe "parse/1" do
    test "parses an empty program" do
      assert parse("") == {:ok, []}
    end

    test "parses an empty program with non code" do
      assert parse(" foo bar baz ") == {:ok, []}
    end

    test "skips non bf instructions" do
      assert parse("This is a valid Brainfuck program.") == {:ok, [:write]}
    end

    test "parses every instruction" do
      assert parse("+-><,.") ==
               {:ok, [add: 1, add: -1, move: 1, move: -1] ++ [:read, :write]}
    end

    test "does not merge instructions" do
      assert parse("++<<") == {:ok, [add: 1, add: 1, move: -1, move: -1]}
    end

    test "parses empty loops" do
      assert parse("[]") == {:ok, [loop: []]}
    end

    test "parses empty loops with comments" do
      assert parse("[ foobar ]") == {:ok, [loop: []]}
    end

    test "parses simple loops" do
      assert parse("-[+]+") == {:ok, [add: -1, loop: [add: 1], add: 1]}
    end

    test "parses consecutive loops" do
      assert parse("[-][+]") == {:ok, [loop: [add: -1], loop: [add: 1]]}
    end

    test "parses nested loops" do
      assert parse("+[-[>]<]") ==
               {:ok, [add: 1, loop: [add: -1, loop: [move: 1], move: -1]]}
    end

    test "parses deeply nested loops" do
      assert parse("[[[.]]]") == {:ok, [loop: [loop: [loop: [:write]]]]}
    end

    test "fails when loop is not closed" do
      assert parse("[") == {:error, %ParseError{reason: :unmatched_open, line: 1, column: 1}}
    end

    test "fails when loop is not opened" do
      assert parse("]") == {:error, %ParseError{reason: :unmatched_close, line: 1, column: 1}}
      assert parse("[]]") == {:error, %ParseError{reason: :unmatched_close, line: 1, column: 3}}
    end

    test "points at the innermost unclosed [" do
      assert parse("[[]") == {:error, %ParseError{reason: :unmatched_open, line: 1, column: 1}}
      assert parse("[[") == {:error, %ParseError{reason: :unmatched_open, line: 1, column: 2}}
      assert parse("+[[-]+") == {:error, %ParseError{reason: :unmatched_open, line: 1, column: 2}}
    end

    test "counts lines" do
      assert parse("+\n+\n  ]") ==
               {:error, %ParseError{reason: :unmatched_close, line: 3, column: 3}}
    end

    test "counts \\r\\n as one line break" do
      assert parse("+\r\n+\r\n  ]") ==
               {:error, %ParseError{reason: :unmatched_close, line: 3, column: 3}}
    end

    test "raises parse errors with a message" do
      assert_raise ParseError, "unmatched ] at line 3, column 7", fn ->
        raise ParseError, reason: :unmatched_close, line: 3, column: 7
      end
    end

    test "counts columns in graphemes" do
      assert parse("ä é ]") == {:error, %ParseError{reason: :unmatched_close, line: 1, column: 5}}
    end
  end
end
