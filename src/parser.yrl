Nonterminals
exprs
expr
loop.

Terminals
inc
dec
left
right
read
write
'['
']'
.

exprs -> expr : ['$1'].
exprs -> expr exprs : ['$1'] ++ '$2'.

expr -> inc   : {inc,    value_of('$1')}.
expr -> dec   : {dec,    value_of('$1')}.
expr -> left  : {left,   value_of('$1')}.
expr -> right : {right,  value_of('$1')}.
expr -> read  : {read}.
expr -> write : {write}.
expr -> loop  : '$1'.

loop -> '[' ']' : {loop, []}.
loop -> '[' exprs ']' : {loop, '$2'}.

Rootsymbol exprs.

Erlang code.

value_of({_, V}) -> V.
