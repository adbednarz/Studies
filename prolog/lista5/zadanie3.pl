browse(X) :-
    go(X, [], []).

go(Where, Left, Right) :-
    writeln(Where),
    write("command: "),        % mam problem bo drukuje dopiero jak przejdzie do nowej lini, chyba, że będzie writeln
    read(Answer),

    (out(Answer) ->
        B1 is 1
    ;   B1 is 0
    ),

    (in(Answer) ->
    (Where =.. [_, Where2 | Right2] ->            %rozbijamy term i bierzemy pierwszy z lewej argument do Where2
            go(Where2, [], Right2)
        ;   true
        )
    ;   true
    ),


    (next(Answer) ->
        (Right = [Head|Tail] ->                    %jeżeli Right możemy jeszcze rodzielić na niepuste Head, to możemy iść w bok
            (
                append([Where], Left, Left2),         %teraz po prawej stronie będzie też where
                go(Head, Left2, Tail),
                B2 is B1+1
            )
        ;   B2 is B1
        )
    ;   B2 is B1
    ),

    (prev(Answer) ->
        (Left = [H|T] ->                          %analogicznie jak next, tylko teraz sprawdzamy lewą stronę
            (
                append([Where], Right, Right2),     %aktualniamy prawą stronę
                go(H, T, Right2),
                B3 is B2+1
            )
        ;    B3 is B2
        )
    ;   B3 is B2
    ),

    (B3 > 0 ->
        true
    ;   go(Where, Left, Right)
    ).

in(i).
out(o).
next(n).
prev(p).







