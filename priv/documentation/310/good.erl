
a(V) when V < 0 ->
    V * -1;
a(V) when V == 0 ->
    V;
a(V) ->
    V * V.


b(V) when is_list(V) ->
    iolist_to_binary(V);

b(V) when is_binary(V) ->
    V.
