odcinek(X) :-
    X = [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P], % deklaracja elementów listy
    X ins 0..1,                                           % zero-jedynkowa lista
    sum(X, #=, 8),                                        % będzie tylko 8 jedynek
    % Mamy 16 cyfr, w cyfrach od 1-7, nie może wystąpić para (1, 0),
    % ponieważ na pewno ósemkowy ciąg jedynek jeszcze się nie zakończył
    % w cyfrach 9-16 nie może występować para (0, 1),
    % ponieważ na pewno ósemkowy ciąg jedynek nie zmieści się już w ciągu X
    % jedynie w cyfrach 8,9 mogą występować pary (0,1) lub (1,0)
    % aby móc sprawdzić, co się znajduję w danej parze korzystamy z mnożenia skalarnego
    R = [1, 2],
    scalar_product(R, [A, B], #\=, 1),
    scalar_product(R, [B, C], #\=, 1),
    scalar_product(R, [C, D], #\=, 1),
    scalar_product(R, [D, E], #\=, 1),
    scalar_product(R, [E, F], #\=, 1),
    scalar_product(R, [F, G], #\=, 1),
    scalar_product(R, [G, H], #\=, 1),
    scalar_product(R, [I, J], #\=, 2),
    scalar_product(R, [J, K], #\=, 2),
    scalar_product(R, [K, L], #\=, 2),
    scalar_product(R, [L, M], #\=, 2),
    scalar_product(R, [M, N], #\=, 2),
    scalar_product(R, [N, O], #\=, 2),
    scalar_product(R, [O, P], #\=, 2).




