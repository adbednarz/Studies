%Wszystkie zapałki zapisane w ppostaci listy
base([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]).
%Reprezentacja kwadratów w zależności od rozmiaru
big_square([1, 2, 3, 4, 7, 11, 14, 18, 21, 22, 23, 24]).
medium_square([[1, 2, 4, 6, 11, 13, 15, 16], [2, 3, 5, 7, 12, 14, 16, 17], [8, 9, 11, 13, 18, 20, 22, 23], [9, 10, 12, 14, 19, 21, 23, 24]]).
small_square([[1, 4, 5, 8], [2, 5, 6, 9], [3, 6, 7, 10], [8, 11, 12, 15], [9, 12, 13, 16], [10, 13, 14, 17], [15, 18, 19, 22], [16, 19, 20, 23], [17, 20, 21, 24]]).

%implementacja generowania podzbiorów w Prologu
subset([], _).
subset([H | T1], [H | T2]) :-
	subset(T1, T2).
subset([H | T1], [_ | T2]) :-
	subset([H | T1], T2).

%generowanie podzbiorów i sprawdzenie ich długości zarazem
subset(X, Y, N) :-
	subset(X, Y),
	length(X, N).

create_big(X, List, Result) :-
	X = 1,
	big_square(Big_square),
	union(Big_square, List, Result).

create_big(X, List, Result) :-
	X = 0,
	Result = List.

create_medium(Y, List, Result) :-
	medium_square(Medium_square),
	subset(Squares, Medium_square, Y),
	create_medium(Y, List, Squares, Result).

create_medium(0, List, _, Result) :-
	Result = List.
create_medium(Y, List, [Head|Tail], Result) :-
	union(Head, List, L2),
	Y2 is Y - 1,
	create_small(Y2, L2, Tail, Result).

create_small(Z, List, Result) :-
	small_square(Small_square),
	subset(Square, Small_square, Z),
	create_small(Z, List, Square, Result).

create_small(0, List, _, Result) :-
	Result = List.
create_small(Z, List, [Head|Tail], Result) :-
	union(Head, List, L2),
	Z2 is Z - 1,
	create_small(Z2, L2, Tail, Result).

draw(L) :-
	base(Base),
	draw(Base, L).

draw([], _) :- !.

draw([Head|Tail], List) :-
	member(Head, [2, 3, 9, 10, 16, 17, 23, 24]),
	(
		member(Head, List) -> write('---*') ; write('   *')
	),
	draw(Tail, List).

draw([Head|Tail], List) :-
	member(Head, [1, 8, 15, 22]),
	(
		member(Head, List) -> nl, write('*---*') ; nl, write('*   *')
	),
	draw(Tail, List).

draw([Head|Tail], List) :-
	member(Head, [5, 6, 7, 12, 13, 14, 19, 20, 21]),
	(
		member(Head, List) -> write('|   ') ; write('    ')
	),
	draw(Tail, List).

draw([Head|Tail], List) :-
	member(Head, [4, 11, 18]),
	(
		member(Head, List) -> nl, write('|   ') ; nl, write('    ')
	),
	draw(Tail, List).


big(1, List) :-
	intersection(List, [1, 2, 3, 4, 7, 11, 14, 18, 21, 22, 23, 24], X),
	length(X, N),
	N =:= 12.

big(0, List) :-
	intersection(List, [1, 2, 3, 4, 7, 11, 14, 18, 21, 22, 23, 24], X),
	length(X, N),
	N =\= 12.

medium(_, _, X, [], Result) :-
	Result is X.
medium(Number, L, A, [Head|Tail], Result) :-
	(
		(
			intersection(L, Head, X),
			length(X, N),
			N =:= 8
		) ->
		(
			A2 is A + 1,
			A2 =< Number,
			medium(Number, L, A2, Tail, Result)
		)
		;
		(
			A =< Number,
			medium(Number, L, A, Tail, Result)
		)
	).

medium(N, L) :-
	medium(N, L, 0, [[1, 2, 4, 6, 11, 13, 15, 16], [2, 3, 5, 7, 12, 14, 16, 17], [8, 9, 11, 13, 18, 20, 22, 23], [9, 10, 12, 14, 19, 21, 23, 24]], C),
	N is C.

small(_, _, C, [], Result) :-
	Result is C.
small(Result, L, C, [Head|Tail], Result) :-
	(
		(
			intersection(L, Head, X),
			length(X, N),
			N =:= 4
		) ->
		(
			C2 is C + 1,
			C2 =< Ilosc,
			male(Ilosc, L, C2, Tail, Result)
		)
		;
		(
			C =< Ilosc,
			male(Ilosc, L, C, Tail, Result)
		)
	).

small(N, L) :-
	small(N, L, 0, [[1, 4, 5, 8], [2, 5, 6, 9], [3, 6, 7, 10], [8, 11, 12, 15], [9, 12, 13, 16], [10, 13, 14, 17], [15, 18, 19, 22], [16, 19, 20, 23], [17, 20, 21, 24]], C),
	N is C.

matches(N, Squares) :-
	Squares = (duże(X), średnie(Y), małe(Z)),
	!,
	create_big(X, [], L1),
	create_medium(Y, L1, L2),
	create_small(Z, L2, L3),
	length(L3, Number_of_matches),
	N is 24 - Number_of_matches,
	big(X, L3),
	medium(Y, L3),
	small(Z, L3),
	draw(L3).

%wrapper
zapałki(N, Kwadraty) :-
	matches(N, Kwadraty).
