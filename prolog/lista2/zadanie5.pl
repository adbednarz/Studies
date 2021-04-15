lista(N, L) :-
    numlist(1, N, A),
    permutation(A, B),
    indeks_nieparzysty(L, B),
    permutation(A, C),
    indeks_parzysty(L, C),
    \+ (between(2, N, X), \+ warunek(X, L)).

warunek(X, [A|B]) :-                      %za każdym razem bierzemy pierwszy element i go porównujemy
    X =:= A + 1;                          %prawda, jeśli znajdziemy element o 1 mniejszy od X przed nim
    (   X =\= A, warunek(X, B)).          %fałsz, jeśli nie znajdziemy takiego elementu, a już jesteśmy na X

indeks_nieparzysty([], []).               %indeksy numerujemy od 1; spełniamy warunki co drugi stąd ten podział
indeks_nieparzysty([X, _|L], [X|R]) :-    %w pierwszy element wstawiamy pierwszy z permutacji, drugi niewiadomy
    indeks_nieparzysty(L, R).

indeks_parzysty([], []).
indeks_parzysty([_, X|L], [X|R]) :-       %pierwszy niewiadomy, w drugi wstawiamy pierwszy z permutacji
    indeks_parzysty(L, R).


/*
Używając polecenia time((lista(N,_),fail))

    N    N!       inf        avg
    1    1        38         38
    2    2        103        51,5
    3    6        891        297
    4    24       16 191     4 047,75
    5    120      463 959    92 791,8
    6    720      18 862 261 3 143 710,17

Niestety wyniki nie są zadowalające :(
Sposób ten okazał się nieefektywny lub dało się lepiej go napisać
*/
