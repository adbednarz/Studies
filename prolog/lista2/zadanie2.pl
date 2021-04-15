jednokrotnie(X, L) :-          %wybieramy X z listy L
    select(X, L, A),           %po wybraniu sprawdzamy, czy X należy do lsty bez X
    \+ member(X, A).

dwukrotnie(X, L) :-
    append(B, [X | A], L),     %listę L dzielimy na listę B, gdzie nie ma żadnego X
    \+ member(X, B),             %listę drugą, która ma głowę X i w ogonie kolejny X
    jednokrotnie(X, A).          %sprawdzamy, czy ogonie jest tylo jeden X
