board(L) :-
    length(L, N),
    reverse(L, K),             %bo numer wiersza liczony jest od dołu planszy
    horizontal(N),
    (
        1 is N mod 2 -> black_row(N, 1, K);         %w lewym dolnym rogu zawsze musi być czarne
        white_row(N, 1, K)
    ).

horizontal(N) :-
    write("+"),
    horizontal(N, N).

horizontal(_, 0) :-
    nl.

horizontal(N,C) :-
    write("-----+"),
    C2 is C - 1,
    horizontal(N, C2).

white_row(N, N, [H|_]) :-
    line(N, H, white),
    line(N, H, white),
    horizontal(N).

white_row(N, C, [H|T]) :-
    line(N, H,  white),
    line(N, H, white),
    horizontal(N),
    C2 is C + 1,
    black_row(N , C2, T).

black_row(N, N, [H|_]) :-
	line(N, H, black),
	line(N, H, black),
	horizontal(N).

black_row(N, C, [H|T]) :-
	line(N, H, black),
	line(N, H, black),
	horizontal(N),
	C2 is C + 1,
	white_row(N, C2, T).

line(N, H, Color) :-
	write("|"),
	line(N, 1, H, Color).

line(N, N, H, white) :-
	(
		N = H -> write(" ### |") ; write("     |")
	),
	nl.

line(N, C, H, white) :-
	(
		C = H -> write(" ### |") ; write("     |")
	),
	C2 is C + 1,
	line(N, C2, H, black).

line(N, N, H, black) :-
	(
		N = H -> write(":###:|") ; write(":::::|")
	),
	nl.

line(N, C, H, black) :-
	(
		C = H -> write(":###:|") ; write(":::::|")
	),
	C2 is C + 1,
	line(N, C2, H, white).


%przykład hetmanów z wykładu
hetmany(N, P) :-
    hetmans(N, P).

hetmans(N, P) :-
	numlist(1, N, L),
	permutation(L, P),
	good(P).

good(P) :-
	\+ bad(P).

bad(P) :-
	append(_, [Wi | L1], P),
	append(L2, [Wj | _], L1),
	length(L2, K),
	abs(Wi - Wj) =:= K + 1.






