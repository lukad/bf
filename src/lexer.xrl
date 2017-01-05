Definitions.

COMMENT    = [^\+\-\,\.\>\<\[\]]
OPERATOR   = [\+\-\,\.\>\<]
LOOP_START = \[
LOOP_END   = \]

Rules.

{COMMENT}    : skip_token.
{OPERATOR}   : {token, {operator, TokenLine, TokenChars}}.
{LOOP_START} : {token, {'[', TokenLine, TokenChars}}.
{LOOP_END}   : {token, {']', TokenLine, TokenChars}}.

Erlang code.
