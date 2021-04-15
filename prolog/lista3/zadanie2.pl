max_sum(L, X) :-
    find_max_sum(L, 0, 0, X).

find_max_sum([], _, Sum, Sum).
find_max_sum([H|T], Value1, Value2, Sum) :-       %Value1 pomocnicza, Value2 końcowa
    New_value1 is max(H, Value1+H),               %jeśli sam element jest większy od sumy poprzednich zamienamy
    New_value2 is max(Value2, New_value1),        %jeśli suma bieżąca jest większa od poprzedniej to zamieniamy
    find_max_sum(T, New_value1, New_value2, Sum).
