Nonterminals
program
exprs
expr
loop.

Terminals
operator
'['
']'
.

program -> exprs : '$1'.

exprs -> expr : ['$1'].
exprs -> expr exprs : ['$1'] ++ '$2'.

expr -> operator : {operator, value_of('$1')}.
expr -> loop : '$1'.

loop -> '[' ']' : {loop, []}.
loop -> '[' exprs ']' : {loop, '$2'}.

Rootsymbol program.

Erlang code.

value_of({_, _, V}) -> V.
