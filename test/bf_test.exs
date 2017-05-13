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
      expected = 0..255 |> Enum.to_list |> to_string()
      {:ok, [{:add, -1},
             {:loop, [{:move, 1}, {:write}, {:add, 1},
                      {:move, -1}, {:add, -1}]},
             {:move, 1}, {:write}]}
      |> assert_output(expected)
    end

    test "wraps cell values around 256" do
      expected = [255, 1] |> to_string()
      {:ok, [{:add, -1}, {:write},
             {:loop, [{:move, 1}, {:add, 1},
                      {:move, -1}, {:add, -1}]},
             {:move, 1}, {:add, 2}, {:write}]}
      |> assert_output(expected)
    end

    test "stops reading after '0'" do
      program = {:ok, [{:read},
                      {:loop, [{:write}, {:read}]}]}
      assert_output program, "abc", "abc\0def"
    end

    test "runs nested loops correctly" do
      {:ok, [{:add, 6},
             {:loop, [{:move, 1}, {:add, 4},
                      {:loop, [{:move, 1}, {:add, 2},
                               {:move, -1}, {:add, -1}]},
                      {:move, -1}, {:add, -1}]},
             {:move, 2},
             {:write}]}
      |> assert_output("0")
    end

    test "runs resets cells ([-])" do
      {:ok, [{:add, 10},
             {:move, -1},
             {:add, 1},
             {:move, 1},
             {:set, 6},
             {:loop, [{:move, 1}, {:add, 4},
                      {:loop, [{:move, 1}, {:add, 2},
                               {:move, -1}, {:add, -1}]},
                      {:move, -1}, {:add, -1}]},
             {:move, 2},
             {:write}]}
      |> assert_output("0")
    end
  end
end
