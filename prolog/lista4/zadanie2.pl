%sprawdza czy dwa kolejne argumenty są takie same, zaczynając od lewej
% strony i rekurencyjnie pójście wzdłuż
left(L, R, [L, R|_]).
left(L, R, [_|T]) :-
    left(L, R, T).

% sprawdza, czy elementy są takie same wykorzystując predykat left i
% kolejność X,Y w dwoch wariantach
next_to(X, Y, Houses) :-
    left(X, Y, Houses).
next_to(X, Y, Houses) :-
    left(Y, X, Houses).

% zawiera listę, której każdy element opisuje dom i jest bieżąco
% wypełniania danymi informacjami, a gdy spełni wszystkie warunki,
% wskaże nam kto hoduje rybki
fish(Who) :-
    Houses = [[1, _, _, _, _, _], [2, _, _, _, _, _], [3, _, _, _, _, _], [4, _, _, _, _, _], [5, _, _, _, _, _]],
    member([1, _, norwegian, _, _, _], Houses),
    member([_, red, englishman, _, _, _], Houses),
    left([_, green, _, _, _, _],[_, white, _, _, _, _], Houses),
    member([_, _, danish, _, tea, _], Houses),
    next_to([_, _, _, _, _, light], [_, _, _, cats, _, _], Houses),
    member([_, yellow, _, _, _, cigar], Houses),
    member([_, _, german, _, _, pipe], Houses),
    member([3, _, _, _, milk, _], Houses),
    next_to([_, _, _, _, _,light], [_, _, _, _, water, _], Houses),
    member([_, _, _, birds, _, without_filtr], Houses),
    member([_, _, swede, dogs, _, _], Houses),
    next_to([_, _, norwegian, _, _, _], [_, blue, _, _, _, _], Houses),
    next_to([_, _, _, horses, _, _], [_, yellow, _, _, _, _], Houses),
    member([_, _, _, _, beer, menthol], Houses),
    member([_, green, _, _, coffee, _], Houses),
    member([_, _, Who, fishs, _, _], Houses).

%wrapper
rybki(Kto) :-
    fish(Kto).
