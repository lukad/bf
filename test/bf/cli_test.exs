defmodule BfCLITest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Bf.CLI

  @moduletag :tmp_dir

  describe "main/1" do
    test "runs a program", %{tmp_dir: tmp_dir} do
      path = write_program(tmp_dir, ",[.,]")

      assert capture_bytes("hello", fn -> CLI.main([path]) end) == "hello"
    end
  end

  describe "run/1" do
    test "passes bytes through unchanged", %{tmp_dir: tmp_dir} do
      path = write_program(tmp_dir, ",[.,]")
      bytes = <<0x61, 0xFF, 0xC3, 0xA4>>

      assert capture_bytes(bytes, fn -> assert CLI.run(parsed(path)) == 0 end) == bytes
    end

    test "exits with 141 when stdout is closed", %{tmp_dir: tmp_dir} do
      path = write_program(tmp_dir, "+.")
      {:ok, closed} = StringIO.open("")
      StringIO.close(closed)
      group_leader = Process.group_leader()
      Process.group_leader(self(), closed)

      try do
        assert CLI.run(parsed(path)) == 141
      after
        Process.group_leader(self(), group_leader)
      end
    end

    test "prints the ast", %{tmp_dir: tmp_dir} do
      path = write_program(tmp_dir, "++[>+<-]")

      assert capture_io(fn -> assert CLI.run({[:ast], parsed(path)}) == 0 end) ==
               "[add: 2, mul_run: [{1, 1}]]\n"
    end

    test "fails when the program can't be read", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "missing.bf")

      assert capture_io(:stderr, fn -> assert CLI.run(parsed(path)) == 1 end) ==
               "Could not read program: no such file or directory\n"
    end

    test "fails when the program can't be parsed", %{tmp_dir: tmp_dir} do
      path = write_program(tmp_dir, "+[")

      assert capture_io(:stderr, fn -> assert CLI.run(parsed(path)) == 1 end) ==
               "Could not parse program: unmatched [ at line 1, column 2\n"

      assert capture_io(:stderr, fn -> assert CLI.run({[:ast], parsed(path)}) == 1 end) ==
               "Could not parse program: unmatched [ at line 1, column 2\n"
    end
  end

  defp parsed(path), do: %Optimus.ParseResult{args: %{program_file: path}}

  defp write_program(tmp_dir, source) do
    path = Path.join(tmp_dir, "program.bf")
    File.write!(path, source)
    path
  end

  defp capture_bytes(input, fun) do
    capture_io([input: input, encoding: :latin1, capture_prompt: false], fun)
  end
end
