even_permutation([], []).
even_permutation([H|T], Ys) :-
    even_permutation(T, X),
    insert_odd(H, X, Ys).
even_permutation([H|T], Ys) :-
    odd_permutation(T, X),
    insert_even(H, X, Ys).

odd_permutation([H|T], Ys) :-
    odd_permutation(T, X),
    insert_odd(H, X, Ys).
odd_permutation([H|T], Ys) :-
    even_permutation(T, X),
    insert_even(H, X, Ys).

insert_odd(X, A, [X|A]).
insert_odd(X, [Y, Z|A], [Y, Z|B]) :-
    insert_odd(X, A, B).

insert_even(X, [Y|A], [Y, X|A]).
insert_even(X, [Y, Z|A], [Y, Z|B]) :-
    insert_even(X, A, B).


% Trochę wniosków matematycznych jest potrzebnych w tym zadaniu.
% Permutacja jest parzysta, kiedy zawiera parzystą liczbę inwersji.
% Trzeba skorzystać z faktu, że wstawienie elementu na nieparzystą
% pozycję powoduje dodanie parzystej liczby inwersji w stosunku do
% wcześniejszej permutacji. Analogicznie dodanie elementu na
% nieparzystą pozycję, daje nam parzystą liczbę inwersji
% Mamy następujące możliwości:
% Nieparzysta permutacja:
% 1) Do N elementowej parzystej permutacji dodajemy N+1 element na
% parzystą pozycję; parzysta + nieparzysta = nieparzysta
% 2) Do N elementowej nieparzystej permutacji dodajemy N+1 element na
% nieparzystą pozycję; nieparzysta + parzysta = nieparzysta
% Parzysta permutacja:
% 1) Do N elementowej parzystej permutacji dodajemy N+1 element na
% nieparzystą pozycję; parzysta + parzysta = parzysta
% 2) Do N elementowej nieparzystej permutacji dodajemy N+1 element na
% parzystą pozycję; nieparzysta + nieparzysta = parzysta
% Pusta lista jest permutacją parzystą
