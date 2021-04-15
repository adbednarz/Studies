%jeśli swipl nie wyświetla całej listy nacisnąć 'w'

% gramatyka metamorficzna akceptuje a^n b^n
ab --> [].
ab --> [a], ab, [b].
% można uruchomić używając phrase(ab, X).

% gramatyka metamorficzna akceptuje a^n b^n c^n
ab(0) --> [].
ab(X) --> [a], ab(X2), [b], {X is X2 + 1}.    % wyznaczamy pasujące X

c(0) --> [].
c(X) --> {X > 0, X2 is X - 1}, [c], c(X2).

abc --> ab(X), c(X).
% można uruchomić używając phrase(abc, X).

%gramatyka metamorficzna akceptuje a^n b^fib(n)
a(0) --> [].
a(X) --> a(X2), [a], {X is X2 + 1}.             % wyznaczamy pasujące X

fib(0) --> [].
fib(1) --> [b].
fib(X) --> {X > 1, X1 is X - 1, X2 is X - 2}, fib(X1), fib(X2).

abfib --> a(X), fib(X).
%można uruchomić używając phrase(abfib, X).

%gramatyka metamorficzna
p([]) --> [].
p([X|Xs]) --> [X], p(Xs).
%phrase(p(L1), L2, L3)
% zależność między listami L1, L2, L3
%spełniające warunek phrase(p(L1), L2, L3)
%L1 jest złożona z list L2 i L3
%append(L1, L3, L2).
%?- listing(p).
%p([A|B], [A|C], D) :-
%     p(B, C, D).
