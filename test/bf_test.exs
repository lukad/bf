defmodule BfTest do
  use ExUnit.Case
  doctest Bf

  import ExUnit.CaptureIO

  describe ".parse" do
    test "skips non bf instructions" do
      assert Bf.parse("This is a valid Brainfuck program.") == {:ok, [{:write}]}
    end

    test "parses a very simple program" do
      assert Bf.parse(">+<-,.") == {:ok, [{:move, 1}, {:change, 1}, {:move, -1},
                                          {:change, -1}, {:read}, {:write}]}
    end

    test "groups consecutive occurences of + and -" do
      assert Bf.parse("++---+-----") == {:ok, [{:change, -5}]}
    end

    test "groups consecutive occurences of + and - with non code inbetween" do
      assert Bf.parse("-foo-++++\n+bar++- --") == {:ok, [{:change, 2}]}
    end

    test "groups consecutive occurences of > and <" do
      assert Bf.parse("<<<><>>>>") == {:ok, [{:move, 1}]}
    end

    test "groups consecutive occurences of < and > with non code inbetween" do
      assert Bf.parse("-foo-++++\n+bar++- --") == {:ok, [{:change, 2}]}
    end

    test "parses simple loops" do
      assert Bf.parse("-[+++]+") == {:ok, [{:change, -1},
                                           {:loop, [{:change, 3}]},
                                           {:change, 1}]}
    end

    test "parses nested loops" do
      expected = {:ok, [change: -1,
                        loop: [change: 2,
                               loop: [change: -2],
                               loop: [change: 2]],
                        change: 1]}
      assert Bf.parse("-[++[--][++]]+") == expected
    end

    test "fails when loop is not closed" do
      assert {:error, _} = Bf.parse("[")
    end

    test "fails when loop is not opened" do
      assert {:error, _} = Bf.parse("]")
    end
  end

  defmacro assert_output(program, output, input \\ "") do
    quote do
      assert capture_io(unquote(input), fn ->
        Bf.run unquote(program)
      end) == unquote(output)
    end
  end

  describe ".run" do
    test "prints all 256 characters" do
      expected = 0..255 |> Enum.to_list |> to_string()
      assert_output "-[>.+<-]>.", expected
    end

    test "wraps cell values around 256" do
      expected = [255, 1] |> to_string()
      assert_output "-.[>+<-]>++.", expected
    end

    test "stops reading after '0'" do
      assert_output ",[.,]", "abc", "abc\0def"
    end

    test "runs nested loops correctly" do
      assert_output "++++++[>++++[>++<-]<-]>>.", "0"
    end
  end
end
