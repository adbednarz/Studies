merge(X, Y, Z) :-
   freeze(X,                              % czekamy na wartość X
   (   X = [H|T] -> freeze(Y,             % gdy X ma co namniej jeden element to czekamy na Y
          (   Y = [H2|T2] -> ( H =< H2 -> % gdy Y ma co najmniej jeden element to porównujemy head obu list
                                Z = [H|T3], merge(T, Y, T3);  % head X mniejsze to wstawiamy jako head Z i rekurencja
                                Z = [H2|T3], merge(X, T2, T3), merge(X, T2, T3) %analogiczny przypadek przeciwny
                             );
          Z = X));                        % jeżeli Y nie ma elementów, to wszystkie elementy X to Z
   Z = Y)).                               % jeżeli X nie ma elementów, to wszystkie elementy Y to Z
