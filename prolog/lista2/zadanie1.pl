usuń_ostatni(L, L1) :-
    append(L1, [_], L).

usuń_pierwszy([_ | L], L).
                           %usuwamy pierwszy i ostatni, aż zostanie nam jeden element
środkowy([X], X).          %i wtedy go porównujemy do podanego X
środkowy(L, X) :-          %jak jest parzyście, to porównujemy X do listy pustej []
    usuń_ostatni(L, L1),
    usuń_pierwszy(L1, L2),
    środkowy(L2, X).
