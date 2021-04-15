:- use_module(library(clpfd)).

list_max([L|Ls], Max) :-
    list_max_(Ls, L, Max).

list_max_([], Max, Max).
list_max_([L|Ls], Max0, Max) :-
    Max1 #= max(Max0,L),
    list_max_(Ls, Max1, Max).

tasks([[2, 1, 3],
      [3, 2, 1],
      [4, 2, 2],
      [3, 3, 2],
      [3, 1, 1],
      [3, 4, 2],
      [5, 2, 1]]).

% A_ to czas startu zadania, B_ to długość trwania zadania, C_ to
% potrzebne zasoby, trzeci element to czas zakończenia zadania, a
% ostatni to identyfikator zadania
create_tasks(Tasks, [A1, A2, A3, A4, A5, A6, A7], [B1, B2, B3, B4, B5, B6, B7], [C1, C2, C3, C4, C5, C6, C7]) :-
    Tasks = [task(A1,B1,_,C1,_),
             task(A2,B2,_,C2,_),
             task(A3,B3,_,C3,_),
             task(A4,B4,_,C4,_),
             task(A5,B5,_,C5,_),
             task(A6,B6,_,C6,_),
             task(A7,B7,_,C7,_)].

resources(5, 5).

get_t([], []).

get_t([A|B], [X|Y]) :-
    get_time(A, X),
    get_t(B, Y).

get_time([R, _, _], R).

get_r1([], []).

get_r1([A|B], [X|Y]) :-
    get_res1(A, X),
    get_r1(B, Y).

get_res1([_, R, _], R).

get_r2([], []).

get_r2([A|B], [X|Y]) :-
    get_res2(A, X),
    get_r2(B, Y).

get_res2([_, _, R], R).

end_time([], [], []).

end_time([A|B], [X|Y], [P|Q]) :-
    P = A + X,
    end_time(B, Y, Q).


schedule(Horizon, Starts, MakeSpan) :-
    Starts = [_, _, _, _, _, _, _],                 % deklaracja listy elementów początkowego startu zadań
    Starts ins 0..Horizon,                          % dziedzina tych elementów
    resources(R1, R2),                              % wzięcie z predykatu dostępnych jednostek zasobu
    tasks(Data),                                    % wzięcie zdeklarowanych zadań
    get_t(Data, Time),                              % z zadań wzięcie jedynie czasu ich trwania
    get_r1(Data, Resources1),                       % z zadań wzięcie jedynie pierszego limitu zasobów
    get_r2(Data, Resources2),                       % z zadań wzięcie jedynie drugiego limitu zasobów
    create_tasks(Tasks, Starts, Time, Resources1),  % do zadań z 1 limitem przydzielenie im czas startu
    cumulative(Tasks, [limit(R1)]),                 % użycie predykatu z clpfd
    create_tasks(Tasks2, Starts, Time, Resources2), % do zadań z 2 limitem przydzielnie im czasu startu
    cumulative(Tasks2, [limit(R2)]),                % użycie predykatu z clpfd
    end_time(Starts, Time, Result),                 % obliczenie czasu zakończenia dla każdego zadania
    list_max(Result, MakeSpan),                     % wzięcie najpóźniejszego czasu
    once(labeling([min(MakeSpan)], Starts)).        % wyświetlenie jednej odpowiedzi z najwcześniejszym czasem

% Zamieściłem tylko jedno zadanie, ponieważ w tym czasie nazbierało się
% dużo obowiązków na uczelni i chcąc jakoś temu podołać, muszę pewne
% rzeczy ograniczyć (wrócę do tych zadań już po zaliczeniach).
% Niemniej jednak chciałbym podziękować tak ogólnie za ten cały semestr
% i może do zobaczenia na innych kursach ;) Miłych wakacji!
