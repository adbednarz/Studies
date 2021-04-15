:- consult('zadanie1.pl').

split(IN, OUT1, OUT2) :-
    freeze(IN,                                     % oczekiwanie na IN
    (   IN = [H|T] -> OUT1 = [H|T2],               % gdy IN ma co najmniej jeden element to dajemy go jako głowę OUT1
        split(T, OUT2, T2);    % rekurencja na przemian w miejsce OUT1 dajemy OUT2 i w miejsce OUT2 reszte el. z OUT1
         OUT1 = [],            % gdy IN jest puste to nie mamy, co rozdzielać
         OUT2 = []
    )).

merge_sort(IN, OUT) :-
    freeze(IN,                            % czekamy na wartość IN
    (   IN = [_|T] -> freeze(T,           % gdy X ma co najmniej jeden element to czekamy na wartość T
                     (   T = [_|_] ->     % jeśli tail jest niepusty
                         split(IN, IN2, IN3),       % rozdzielamy IN
                         merge_sort(IN2, OUT2),     % sortujemy
                         merge_sort(IN3, OUT3),     % sortujemy
                         merge(OUT2, OUT3, OUT);    % scalamy
                         OUT = IN                   % IN to tylko jeden element, kończymy rekurencję
                     ));
                  OUT = IN                          % IN jest puste, kończymy rekurencję
    )).
