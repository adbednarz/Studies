arc(a, b).
arc(b, a).
arc(b, c).
arc(c, d).

ścieżka(X, Y, S) :-
    arc(X, A),           % możliwe drogi z wierzchołka X
    \+ (member(A, S)),   % A nie jest już w ścieżce
    (
        Y = A;                     % dana możliwość okazuje się odpowiedzią, kończymy
        ścieżka(A, Y, [A | S])     % szukamy dalej ścieżki z nowego węzła
    ).

osiągalny(X, Y) :-       % przypadek trywialny, gdy to ten sam wierzchołek
    X = Y.

osiągalny(X, Y) :-
    ścieżka(X, Y, [X]).  % szukanie ścieżki, X to jej pierwszy element
