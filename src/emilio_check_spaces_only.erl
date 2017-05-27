% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(emilio_check_spaces_only).

-export([
    codes/0,
    explain/1,
    format_error/2,
    run/1
]).


-include("emilio.hrl").


codes() ->
    [191, 192, 193, 194].


explain(191) ->
    "Tabs are bad, mmmkay!";
explain(192) ->
    "Form feeds are bad, mmmkay!";
explain(193) ->
    "Just Say No to Windows Line Endings.";
explain(194) ->
    "Don't use unicode white space in source files.".


format_error(191, _) ->
    "white space contains tabs";
format_error(192, _) ->
    "white space contains form feeds";
format_error(193, _) ->
    "line ending has form feed";
format_error(194, Code) ->
    io_lib:format("line contains unicode white space code: ~b", [Code]).


run(Lines) ->
    emilio_lib:foreach_token(fun check/3, Lines).


check(Loc, {white_space, _, Text}, Ctx) ->
    check_ws(Loc, Text, $\n, 191),
    NewText = check_line_ending(Text, Ctx),
    check_ws(Loc, NewText, $\r, 192),
    check_not_space(Loc, NewText);

check(_Loc, _Token, _Ctx) ->
    ok.


check_ws(_, [], _Char, _Code) ->
    ok;

check_ws({Line, Col} = Loc, [Char | Rest], Char, Code) ->
    ?EMILIO_REPORT(Loc, Code, undefined),
    check_ws({Line, Col + 1}, Rest, Char, Code);

check_ws({Line, Col}, [_ | Rest], Char, Code) ->
    check_ws({Line, Col + 1}, Rest, Char, Code).


check_line_ending(Text, Ctx) ->
    % Return a modified Text here removing
    % the trailing \r so that its not
    % reported as a 192 for line endings.
    case emilio_lib:next_token(Ctx) of
        {white_space, Anno, [$\n]} ->
            case lists:last(Text) == $\r of
                true ->
                    ?EMILIO_REPORT(Anno, 193),
                    lists:sublist(Text, length(Text) - 1);
                false ->
                    Text
            end;
        _ ->
            Text
    end.


check_not_space(_Loc, []) ->
    ok;

check_not_space({Line, Col}, [32 | Rest]) ->
    check_not_space({Line, Col + 1}, Rest);

check_not_space({Line, Col} = Loc, [NotSpace | Rest]) ->
    ?EMILIO_REPORT(Loc, 194, NotSpace),
    check_not_space({Line, Col + 1}, Rest).