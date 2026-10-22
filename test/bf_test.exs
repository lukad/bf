defmodule BfTest do
  use ExUnit.Case
  doctest Bf

  import ExUnit.CaptureIO

  defmacro assert_output(program, output, input \\ "") do
    quote do
      assert capture_io(unquote(input), fn ->
               Bf.run(unquote(program))
             end) == unquote(output)
    end
  end

  describe "Bf.run/1" do
    test "prints all 256 characters" do
      expected = 0..255 |> Enum.to_list() |> to_string()

      [
        {:add, -1},
        {:loop, [{:move, 1}, :write, {:add, 1}, {:move, -1}, {:add, -1}]},
        {:move, 1},
        :write
      ]
      |> assert_output(expected)
    end

    test "wraps cell values around 256" do
      expected = [255, 1] |> to_string()

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
      |> assert_output(to_string([246]))
    end

    test "wraps multiplied cell values around 256" do
      [{:add, 200}, {:mul_run, [{1, 2}]}, {:move, 1}, :write]
      |> assert_output(to_string([144]))
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

  describe "Bf.parse/1 |> Bf.run/1" do
    test "runs hello world" do
      {:ok, program} = Bf.parse(BfTest.Programs.hello_world())
      assert_output(program, "Hello World!\n")
    end

    test "echoes input" do
      {:ok, program} = Bf.parse(",[.,]")
      assert_output(program, "abc", "abc\0")
    end

    test "returns :ok" do
      {:ok, program} = Bf.parse("+.")
      capture_io(fn -> assert Bf.run(program) == :ok end)
    end

    test "returns parse errors" do
      assert {:error, _} = Bf.parse("[")
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

  defp output_of(program) do
    capture_io("abc\0", fn -> Bf.run(program) end)
  end
end
