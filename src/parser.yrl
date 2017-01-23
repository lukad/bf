Nonterminals
exprs
expr
changes
moves
loop.

Terminals
change
move
read
write
'['
']'
.

Rootsymbol exprs.
Expect 2.

exprs -> expr : ['$1'].
exprs -> expr exprs : ['$1'] ++ '$2'.

expr -> changes : {change, sum('$1')}.
expr -> moves   : {move, sum('$1')}.
expr -> read    : {read}.
expr -> write   : {write}.
expr -> loop    : '$1'.

changes -> change : ['$1'].
changes -> change changes : ['$1'] ++ '$2'.

moves -> move : ['$1'].
moves -> move moves : ['$1'] ++ '$2'.

loop -> '[' ']' : {loop, []}.
loop -> '[' exprs ']' : {loop, '$2'}.

Erlang code.

value(Token) -> element(2, Token).
sum(Tokens) -> lists:foldl(fun(X, Sum) -> value(X) + Sum end, 0, Tokens).
