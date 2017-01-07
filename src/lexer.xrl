Definitions.

COMMENT    = [^\+\-\,\.\>\<\[\]]
EMPTY_LOOP = \[[^\+\-\,\.\>\<\[\]]*\]
CHANGE     = [\+\-]+
MOVE       = [\>\<]+
READ       = \,
WRITE      = \.
LOOP_START = \[
LOOP_END   = \]

Rules.

{COMMENT}    : skip_token.
{EMPTY_LOOP} : skip_token.
{CHANGE}     : {token, {change, sum_of_instructions(TokenChars, $+, $-)}}.
{MOVE}       : {token, {move,   sum_of_instructions(TokenChars, $>, $<)}}.
{READ}       : {token, {read,   TokenChars}}.
{WRITE}      : {token, {write,  TokenChars}}.
{LOOP_START} : {token, {'[',    TokenChars}}.
{LOOP_END}   : {token, {']',    TokenChars}}.

Erlang code.

sum_of_instructions(Chars, Add, Sub) ->
    sum_of_instructions(Chars, Add, Sub, 0).

sum_of_instructions([Char|Rest], Add, Sub, Sum) when Char == Add ->
    Sum + 1 + sum_of_instructions(Rest, Add, Sub, Sum);

sum_of_instructions([Char|Rest], Add, Sub, Sum) when Char == Sub ->
    Sum - 1 + sum_of_instructions(Rest, Add, Sub, Sum);

sum_of_instructions([], _Add, _Sub, Sum) -> Sum.
