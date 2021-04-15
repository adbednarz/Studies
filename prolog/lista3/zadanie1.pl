sum([], 0).           %rekurencyjnie dodajemy elementy do siebie
sum([H|T], Sum) :-     %rodzielamy listę na głowę i ogon
    sum(T, X),
    Sum is H + X.

average(L, Average) :-  %obliczamy sumę, sprawdzamy długość listy i dzielimy
    sum(L, Sum),
    length(L, N),
    Average is Sum / N.

wariancja(L, X) :-       %polski wrappper
    variance(L, X).      %fancyenglishpredicate

variance(L, X) :-
    average(L, Average),
    length(L, N),
    numerator(L, Average, Numerator),
    X is Numerator/N.

numerator([], _, 0).
numerator([H|T], Average, Numerator) :- %korzystamy ze wzoru na wariancje i obliczamy licznik
    numerator(T, Average, X),
    Numerator is (H - Average)^2 + X.
