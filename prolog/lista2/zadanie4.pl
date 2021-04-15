reguła(X, *, 1, X).
reguła(1, *, X, X).
reguła(X, +, 0, X).
reguła(0, +, X, X).
reguła(X, +, Y, X + Y).
reguła(_, *, 0, 0).
reguła(0, *, _, 0).
reguła(1, *, X, X).
reguła(X, *, 1, X).
reguła(X, *, Y, X*Y).
reguła(X, -, 0, X).
reguła(0, -, X, -X).
reguła(X, -, X, 0).
reguła(X, -, Y, X-Y).
reguła(0, /, _, 0).
reguła(X, /, 1, X).
reguła(X, /, X, 1).
reguła(X*Y, /, Y, X).
reguła(X, /, Y, X/Y).

uprość(X, X) :-     %Prolog "drzewo" backtrackowania; ! sprawia, że prolog wie, że nie warto się już wracać
    atomic(X), !.                      %atomic sprawdza, czy to liczba lub atom (stałe)

uprość(Wyrażenie, Wynik) :-
    Wyrażenie =.. [Operator, L, P],    %rozkładanie struktur, przykład  a + b = +(a, b) =.. X => X = [+, a, b]
    uprość(L, X),
    uprość(P, Y),
    reguła(X, Operator, Y, Wynik).
