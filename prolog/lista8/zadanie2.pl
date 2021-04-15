oblicz([], [], 0).                         % predykat liczący iloczyny elementów dwóch list na danej pozycji
oblicz([X|TailX], [Y|TailY], Suma) :-      % zwraca ich całkowitą sumę
    oblicz(TailX, TailY, SumaTail),
    Suma #= SumaTail +  X * Y.

plecak(Wartości, Wielkości, Pojemność, Zmienne) :-
    length(Wielkości, Len),                            % długość listy elementów wynikowych musi być taka sama
    length(Zmienne, Len),                              % jak długość dostępnych elementów
    Zmienne ins 0..1,                                  % przedmiot albo bierzemy albo nie
    oblicz(Zmienne, Wielkości, Wielkość),              % liczymy wielkość danych przedmiotów
    Wielkość #=< Pojemność,                            % nie mogą przekraczać pojemności
    oblicz(Zmienne, Wartości, Wartość),                % liczymy wartość przedmiotów
    once(labeling([max(Wartość)], Zmienne)).           % wybieramy największą wartość

