defmodule Bf.ParseError do
  @moduledoc """
  Returned by `Bf.parse/1` and raised by `Bf.parse!/1` when a program's
  brackets don't match.

  `reason` is `:unmatched_open` for a `[` without a matching `]`, and
  `:unmatched_close` for a `]` without a matching `[`. `line` and `column`
  point at that bracket. Both start at 1, and columns count graphemes.
  """

  defexception [:reason, :line, :column]

  @type t :: %__MODULE__{
          reason: :unmatched_open | :unmatched_close,
          line: pos_integer,
          column: pos_integer
        }

  @impl true
  def message(%__MODULE__{reason: reason, line: line, column: column}) do
    "unmatched #{bracket(reason)} at line #{line}, column #{column}"
  end

  defp bracket(:unmatched_open), do: "["
  defp bracket(:unmatched_close), do: "]"
end
