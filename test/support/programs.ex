defmodule BfTest.Programs do
  @moduledoc false

  @hello_world "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."

  def hello_world, do: @hello_world

  def all do
    [
      "",
      "+-><",
      "++--+-.>+<-.",
      ">+-<.",
      "-[>.+<-]",
      "+++[>+++[>++<-]<-]>>.",
      "[-]+++[.-]",
      "+++[-][.+]-.",
      "++[>]<.",
      ",[.,]",
      "comments + are - ignored .",
      @hello_world
    ]
  end
end
