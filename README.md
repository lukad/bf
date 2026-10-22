[![Hex.pm Version](https://img.shields.io/hexpm/v/bf)](https://hex.pm/packages/bf)
[![Hex.pm Docs](https://img.shields.io/badge/hex-docs-orange.svg)](https://bf.hexdocs.pm)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/bf)](https://hex.pm/packages/bf)
[![Hex.pm License](https://img.shields.io/hexpm/l/bf)](https://hex.pm/packages/bf)

# bf

`bf` is an optimizing [Brainfuck](https://esolangs.org/wiki/brainfuck) interpreter written in Elixir. Use it as a library or from the command line.

## Documentation

Documentation for the latest release is available at [hexdocs.pm](https://hexdocs.pm/bf).

## Library usage

Add `bf` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bf, "~> 1.4.0"}
  ]
end
```

Parse a program with `Bf.parse/1`, then run it with `Bf.run/2`, which takes the input as a string and returns the output:

```elixir
iex> {:ok, program} = Bf.parse(",[.,]")
iex> Bf.run(program, "hello")
"hello"
```

`Bf.run/3` streams instead. It reads from any enumerable of binaries, only as far as the program needs, and puts each byte the program writes into any collectable right away:

```elixir
iex> Bf.run(program, File.stream!("input.txt", 1), File.stream!("output.txt"))
```

Parse errors tell you which bracket doesn't match:

```elixir
iex> Bf.parse("+[")
{:error, %Bf.ParseError{reason: :unmatched_open, line: 1, column: 2}}
```

## Command line

Install the `bf` escript with mix:

```bash
mix escript.install hex bf
```

Or build it from source:

```bash
git clone https://github.com/lukad/bf.git
cd bf
MIX_ENV=prod mix do escript.build, escript.install
```

Run a program, with stdin and stdout as its input and output:

```bash
$ cat <<EOF> hello.bf
+++++ +++++             initialize counter (cell #0) to 10
[                       use loop to set the next four cells to 70/100/30/10
    > +++++ ++              add  7 to cell #1
    > +++++ +++++           add 10 to cell #2
    > +++                   add  3 to cell #3
    > +                     add  1 to cell #4
    <<<< -                  decrement counter (cell #0)
]
> ++ .                  print 'H'
> + .                   print 'e'
+++++ ++ .              print 'l'
.                       print 'l'
+++ .                   print 'o'
> ++ .                  print ' '
<< +++++ +++++ +++++ .  print 'W'
> .                     print 'o'
+++ .                   print 'r'
----- - .               print 'l'
----- --- .             print 'd'
> + .                   print '!'
> .                     print '\n'
EOF

$ bf hello.bf
Hello World!
```

`bf ast hello.bf` prints the optimized program instead of running it.

## Interpreter Info

- Cells are 8 bits wide
- Cells wrap around 256
  - `255 + 1 = 0`
  - `0 - 1 = 255`
- The tape is 30000 cells large
- The tape pointer wraps around 30000
- Input and output are bytes
- Reading at the end of the input sets the cell to 0
