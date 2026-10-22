defmodule BfTest do
  use ExUnit.Case
  doctest Bf

  defp assert_output(program, output, input \\ "") do
    assert Bf.run(program, input) == output
  end

  describe "Bf.run/2" do
    test "prints all 256 characters" do
      expected = 0..255 |> Enum.to_list() |> :binary.list_to_bin()

      [
        {:add, -1},
        {:loop, [{:move, 1}, :write, {:add, 1}, {:move, -1}, {:add, -1}]},
        {:move, 1},
        :write
      ]
      |> assert_output(expected)
    end

    test "wraps cell values around 256" do
      expected = <<255, 1>>

      [
        {:add, -1},
        :write,
        {:loop, [{:move, 1}, {:add, 1}, {:move, -1}, {:add, -1}]},
        {:move, 1},
        {:add, 2},
        :write
      ]
      |> assert_output(expected)
    end

    test "reads 0 at the end of the input" do
      [{:add, 5}, :read, :write, {:add, 7}, :read, :write]
      |> assert_output(<<0, 0>>)
    end

    test "reads multi-byte characters as separate bytes" do
      [
        :read,
        {:move, 1},
        :read,
        {:move, 1},
        :read,
        :write,
        {:move, -1},
        :write,
        {:move, -1},
        :write
      ]
      |> assert_output(<<0, 164, 195>>, "ä")
    end

    test "writes bytes unchanged" do
      [{:add, 0xC3}, :write, {:add, -0xC3 + 0xA4}, :write]
      |> assert_output("ä")
    end

    test "stops reading after '0'" do
      program = [:read, {:loop, [:write, :read]}]
      assert_output(program, "abc", "abc\0def")
    end

    test "runs nested loops correctly" do
      [
        {:add, 6},
        {:loop,
         [
           {:move, 1},
           {:add, 4},
           {:loop, [{:move, 1}, {:add, 2}, {:move, -1}, {:add, -1}]},
           {:move, -1},
           {:add, -1}
         ]},
        {:move, 2},
        :write
      ]
      |> assert_output("0")
    end

    test "runs resets cells ([-])" do
      [
        {:add, 10},
        {:move, -1},
        {:add, 1},
        {:move, 1},
        {:set, 6},
        {:loop,
         [
           {:move, 1},
           {:add, 4},
           {:loop, [{:move, 1}, {:add, 2}, {:move, -1}, {:add, -1}]},
           {:move, -1},
           {:add, -1}
         ]},
        {:move, 2},
        :write
      ]
      |> assert_output("0")
    end

    test "scans forwards for closest 0 cell in steps of 1" do
      [
        {:add, 1},
        {:move, 9},
        {:add, 1},
        {:move, 1},
        {:add, 64},
        {:move, -10},
        {:loop, [move: 1, add: -1]},
        {:move, -9},
        {:scan, 1},
        {:move, 1},
        :write
      ]
      |> assert_output("@")
    end

    test "scans backwards for closest 0 cell in steps of n" do
      [{:move, -1}, {:add, 64}, {:move, 4}, {:add, 1}, {:scan, -3}, {:move, -1}, :write]
      |> assert_output("@")
    end

    test "multiplies the current cell into other cells and clears it" do
      [
        {:add, 3},
        {:move, 1},
        {:add, 1},
        {:move, -1},
        {:mul_run, [{1, 2}, {2, 3}]},
        :write,
        {:move, 1},
        :write,
        {:move, 1},
        :write
      ]
      |> assert_output(<<0, 7, 9>>)
    end

    test "multiplies with negative factors and offsets" do
      [{:move, 1}, {:add, 5}, {:mul_run, [{-1, -2}]}, {:move, -1}, :write]
      |> assert_output(<<246>>)
    end

    test "wraps moves of more than the tape size around the tape" do
      [{:move, -30_001}, {:add, 1}, {:move, 30_001}, {:move, -1}, :write]
      |> assert_output(<<1>>)
    end

    test "wraps multiplied cell values around 256" do
      [{:add, 200}, {:mul_run, [{1, 2}]}, {:move, 1}, :write]
      |> assert_output(<<144>>)
    end

    test "wraps multiplication offsets around the tape" do
      [{:add, 7}, {:mul_run, [{-1, 1}]}, {:move, -1}, :write]
      |> assert_output(<<7>>)
    end

    test "does nothing when multiplying 0" do
      [{:move, 1}, {:add, 4}, {:move, -1}, {:mul_run, [{1, 3}]}, {:move, 1}, :write]
      |> assert_output(<<4>>)
    end
  end

  describe "Bf.parse/1 |> Bf.run/2" do
    test "runs hello world" do
      {:ok, program} = Bf.parse(BfTest.Programs.hello_world())
      assert_output(program, "Hello World!\n")
    end

    test "echoes input" do
      {:ok, program} = Bf.parse(",[.,]")
      assert_output(program, "abc", "abc")
    end

    test "returns parse errors" do
      assert {:error, %Bf.ParseError{} = error} = Bf.parse("+\n[")
      assert Exception.message(error) == "unmatched [ at line 2, column 1"

      assert {:error, %Bf.ParseError{} = error} = Bf.parse("]")
      assert Exception.message(error) == "unmatched ] at line 1, column 1"
    end
  end

  describe "Bf.run/3" do
    setup do
      {:ok, program} = Bf.parse(",[.,]")
      %{echo: program}
    end

    test "reads input chunks of any size", %{echo: program} do
      assert Bf.run(program, ["", "ab", "", "cde", "f"], "") == "abcdef"
    end

    test "reads 0 at the end of the input", %{echo: program} do
      assert Bf.run(program, [], "") == ""
    end

    test "only reads as much input as the program does" do
      {:ok, program} = Bf.parse(",.,.")
      assert Bf.run(program, Stream.repeatedly(fn -> "a" end), "") == "aa"
    end

    test "halts the input when the program is done reading" do
      {:ok, program} = Bf.parse(",.")
      assert Bf.run(program, notifying_stream(["ab", "cd"]), "") == "a"
      assert_received :started
      assert_received :halted
    end

    test "doesn't start the input when the program doesn't read" do
      {:ok, program} = Bf.parse("+.")
      assert Bf.run(program, notifying_stream(["ab"]), "") == <<1>>
      refute_received :started
    end

    test "puts each byte into the output", %{echo: program} do
      assert Bf.run(program, ["abc"], []) == ["a", "b", "c"]
    end
  end

  describe "optimizations" do
    test "don't change a program's behaviour" do
      for source <- BfTest.Programs.all() do
        {:ok, program} = Bf.Parser.parse(source)
        {:ok, optimized} = Bf.parse(source)

        assert output_of(program) == output_of(optimized),
               "optimized program behaves differently: #{inspect(source)}"
      end
    end
  end

  defp notifying_stream(chunks) do
    test = self()

    Stream.resource(
      fn ->
        send(test, :started)
        chunks
      end,
      fn
        [] -> {:halt, []}
        [chunk | rest] -> {[chunk], rest}
      end,
      fn _ -> send(test, :halted) end
    )
  end

  defp output_of(program) do
    Bf.run(program, "abc\0")
  end
end
