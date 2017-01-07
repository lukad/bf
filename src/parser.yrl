Nonterminals
exprs
expr
loop.

Terminals
change
move
read
write
'['
']'
.

exprs -> expr : ['$1'].
exprs -> expr exprs : ['$1'] ++ '$2'.

expr -> change : '$1'.
expr -> move   : '$1'.
expr -> read   : {read}.
expr -> write  : {write}.
expr -> loop   : '$1'.

loop -> '[' ']' : {loop, []}.
loop -> '[' exprs ']' : {loop, '$2'}.

Rootsymbol exprs.
