# bf

`bf` is a simple [Brainfuck](https://esolangs.org/wiki/brainfuck) interpreter written in Elixir.
It uses [`leex`](http://erlang.org/doc/man/leex.html) and [`yecc`](http://erlang.org/doc/man/yecc.html) for lexing and parsing.

## Installation

Automatic installation with mix >= 1.4.0

```bash
mix escript.install github lukad/bf
```
Manual installation

```
git clone https://github.com/lukad/bf.git
cd bf
MIX_ENV=prod mix do escript.build, escript.install
```


## Usage

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
