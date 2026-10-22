defmodule Bf.Program do
  @moduledoc false

  @type instruction ::
          {:add, integer}
          | {:move, integer}
          | {:set, integer}
          | {:scan, integer}
          | {:mul_run, [{integer, integer}]}
          | :read
          | :write
          | {:loop, t}

  @type t :: [instruction]
end
