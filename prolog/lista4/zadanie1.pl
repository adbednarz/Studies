putting_signs([X], X).
putting_signs(List, X + Y) :-
    append([Hl|Tl], [Hr|Tr], List),
    putting_signs([Hl|Tl], X),
    putting_signs([Hr|Tr], Y).

putting_signs(List, X - Y) :-
    append([Hl|Tl], [Hr|Tr], List),
    putting_signs([Hl|Tl], X),
    putting_signs([Hr|Tr], Y).

putting_signs(List, X * Y) :-
    append([Hl|Tl], [Hr|Tr], List),
    putting_signs([Hl|Tl], X),
    putting_signs([Hr|Tr], Y).

putting_signs(List, X / Y) :-
    append([Hl|Tl], [Hr|Tr], List),
    putting_signs([Hl|Tl], X),
    putting_signs([Hr|Tr], Y).

%predykaty liczące wyrażenia arytmetyczne
count(X, R) :-
    number(X),
    R is X.

count(X+Y, R) :-
    count(X, A),
    count(Y, B),
    R is A+B.

count(X-Y, R) :-
    count(X, A),
    count(Y, B),
    R is A-B.

count(X*Y, R) :-
    count(X, A),
    count(Y, B),
    R is A*B.

count(X/Y, R) :-
    count(X, A),
    count(Y, B),
    B =\= 0,
    R is A/B.

% putting_signs będzię nam generowało wszystkie możliwości wstawienia
% znaków, count będzie obliczało wynik jakie dane wyrażenie da,
% natomiast na końcu wyselekcjonujemy tylko te, których wynik spełni
% wartość oczekiwaną przez użytkownika
expression(List, Value, Expression) :-
    putting_signs(List, Expression),
    count(Expression, Result),
    Value =:= Result.

%wrapper
wyrażenie(Lista, Wartość, Wyrażenie) :-
    expression(Lista, Wartość, Wyrażenie).
