Definitions.

COMMENT    = [^\+\-\,\.\>\<\[\]]
EMPTY_LOOP = \[[^\+\-\,\.\>\<\[\]]*\]
INC        = \++
DEC        = \-+
LEFT       = \<+
RIGHT      = \>+
READ       = \,
WRITE      = \.
LOOP_START = \[
LOOP_END   = \]

Rules.

{COMMENT}    : skip_token.
{EMPTY_LOOP} : skip_token.
{INC}        : {token, {inc,   length(TokenChars)}}.
{DEC}        : {token, {dec,   length(TokenChars)}}.
{LEFT}       : {token, {left,  length(TokenChars)}}.
{RIGHT}      : {token, {right, length(TokenChars)}}.
{READ}       : {token, {read,  TokenChars}}.
{WRITE}      : {token, {write, TokenChars}}.
{LOOP_START} : {token, {'[',   TokenChars}}.
{LOOP_END}   : {token, {']',   TokenChars}}.

Erlang code.
