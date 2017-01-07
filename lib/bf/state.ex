defmodule Bf.State do
  @enforce_keys [:program, :mem]
  defstruct     [:program, :mem, ptr: 0]

  @mem_size 30_000

  def new(program, mem \\ List.duplicate(0, @mem_size)) do
    %Bf.State{
      program: program,
      mem: mem
    }
  end
end
