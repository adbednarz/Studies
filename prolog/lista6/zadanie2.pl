:- consult('zadanie1.pl').
:- consult('scanner.pl').


wykonaj(NazwaPliku) :-
    execute(NazwaPliku).

execute(FileName) :-
    open(FileName, read, Stream),
    scanner(Stream, Tokens),             %zadanie 1 lista 5
    phrase(program(Program), Tokens),    %zadanie 1 lista 6
    interpreter(Program).

interpreter(PROGRAM) :-
	interpreter(PROGRAM, []).

interpreter([], _).

interpreter([read(ID) | PGM], ASSOC) :- !,
	read(N),
	integer(N),
	substitute(ASSOC, ID, N, ASSOC1),
	interpreter(PGM, ASSOC1).
interpreter([write(W) | PGM], ASSOC) :- !,
	value(W, ASSOC, VAL),
	write(VAL), nl,
	interpreter(PGM, ASSOC).
interpreter([assign(ID, W) | PGM], ASSOC) :- !,
	value(W, ASSOC, VAL),
	substitute(ASSOC, ID, VAL, ASSOC1),
	interpreter(PGM, ASSOC1).
interpreter([if(C, P) | PGM], ASSOC) :- !,
	interpreter([if(C, P, []) | PGM], ASSOC).
interpreter([if(C, P1, P2) | PGM], ASSOC) :- !,
	(   true(C, ASSOC)
	->  append(P1, PGM, NEXT)
	;   append(P2, PGM, NEXT)),
	interpreter(NEXT, ASSOC).
interpreter([while(C, P) | PGM], ASSOC) :- !,
	append(P, [while(C, P)], NEXT),
	interpreter([if(C, NEXT) | PGM], ASSOC).

substitute([], ID, N, [ID = N]).
substitute([ID = _ | ASSOC], ID, N, [ID = N | ASSOC]) :- !.
substitute([ID1 = W1 | ASSOC1], ID, N, [ID1 = W1 | ASSOC2]) :-
	substitute(ASSOC1, ID, N, ASSOC2).

take([ID = N | _], ID, N) :- !.
take([_ | ASSOC], ID, N) :-
	take(ASSOC, ID, N).

value(int(N), _, N).
value(id(ID), ASSOC, N) :-
	take(ASSOC, ID, N).
value(W1+W2, ASSOC, N) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N is N1+N2.
value(W1-W2, ASSOC, N) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N is N1-N2.
value(W1*W2, ASSOC, N) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N is N1*N2.
value(W1/W2, ASSOC, N) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N2 =\= 0,
	N is N1 div N2.
value(W1 mod W2, ASSOC, N) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N2 =\= 0,
	N is N1 mod N2.

true(W1 =:= W2, ASSOC) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N1 =:= N2.
true(W1 =\= W2, ASSOC) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N1 =\= N2.
true(W1 < W2, ASSOC) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N1 < N2.
true(W1 > W2, ASSOC) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N1 > N2.
true(W1 >= W2, ASSOC) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N1 >= N2.
true(W1 =< W2, ASSOC) :-
	value(W1, ASSOC, N1),
	value(W2, ASSOC, N2),
	N1 =< N2.
true((W1, W2), ASSOC) :-
	true(W1, ASSOC),
	true(W2, ASSOC).
true((W1; W2), ASSOC) :-
	(   true(W1, ASSOC),
	    !
	;   true(W2, ASSOC)).





