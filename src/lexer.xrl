Definitions.

COMMENT = [^\+\-\,\.\>\<\[\]#]

Rules.

{COMMENT} : skip_token.
\+        : {token, {change, 1}}.
\-        : {token, {change, -1}}.
\>        : {token, {move, +1}}.
\<        : {token, {move, -1}}.
\,        : {token, {read, TokenChars}}.
\.        : {token, {write, TokenChars}}.
\[        : {token, {'[', TokenChars}}.
\]        : {token, {']', TokenChars}}.
\#        : debug(os:getenv("BF_DEBUG", "")).

Erlang code.

debug("TRUE") ->
    {token, {break}};

debug(_) ->
    skip_token.
