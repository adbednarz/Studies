:- consult('scanner.pl').

program([H|L]) -->
    instruction(H),
    [sep(;)],
    !,
    program(L).

 program([]) -->
    [].


instruction(assign(X, Y)) -->
    [id(X)],
    [sep(:=)],
    expression(Y).

instruction(read(X)) -->
    [key(read)],
    [id(X)].

instruction(write(Y)) -->
    [key(write)],
    expression(Y).

instruction(if(X, Y)) -->
    [key(if)],
    condition(X),
    [key(then)],
    program(Y),
    [key(fi)].

instruction(if(X, Y, Z)) -->
    [key(if)],
    condition(X),
    [key(then)],
    program(Y),
    [key(else)],
    program(Z),
    [key(fi)].

instruction(while(X, Y)) -->
    [key(while)],
    condition(X),
    [key(do)],
    program(Y),
    [key(od)].


expression(X + Y) -->
    component(X),
    [sep(+)],
    expression(Y).

expression(X - Y) -->
    component(X),
    [sep(-)],
    expression(Y).

expression(X) -->
    component(X).


component(X * Y) -->
    factor(X),
    [sep(*)],
    component(Y).

component(X / Y) -->
    factor(X),
    [sep(/)],
    component(Y).

component(X mod Y) -->
    factor(X),
    [key(mod)],
    component(Y).

component(X) -->
    factor(X).


factor(id(X)) -->
    [id(X)].

factor(int(X)) -->
    [int(X)].

factor(( X )) -->
    [sep('(')],
    expression(X),
    [sep(')')].


condition((X ; Y)) -->
    conjuction(X),
    [key(or)],
    condition(Y).

condition(X) -->
    conjuction(X).


conjuction((X , Y)) -->
    simple(X),
    [key(and)],
    conjuction(Y).

conjuction(X) -->
    simple(X).


simple(X =:= Y) -->
    expression(X),
    [sep(=)],
    expression(Y).

simple(X =\= Y) -->
    expression(X),
    [sep(/=)],
    expression(Y).

simple(X < Y) -->
    expression(X),
    [sep(<)],
    expression(Y).

simple(X > Y) -->
    expression(X),
    [sep(>)],
    expression(Y).

simple(X >= Y) -->
    expression(X),
    [sep(>=)],
    expression(Y).

simple(X =< Y) -->
    expression(X),
    [sep(=<)],
    expression(Y).

simple(( X )) -->
    [sep('(')],
    condition(X),
    [sep(')')].











