filozofowie :-
    mutex_create(Widelec1),                                      %mutex ma dostęp do kodu with_mutex
    mutex_create(Widelec2),
    mutex_create(Widelec3),
    mutex_create(Widelec4),
    mutex_create(Widelec5),
    thread_create(filozof(1, Widelec1, Widelec2), ID1, []),      % tworzenie wątku danego filozofa
    thread_create(filozof(2, Widelec2, Widelec3), ID2, []),      % przydzielanie mu dwóch widelców
    thread_create(filozof(3, Widelec3, Widelec4), ID3, []),
    thread_create(filozof(4, Widelec4, Widelec5), ID4, []),
    thread_create(filozof(5, Widelec5, Widelec1), ID5, []),
    thread_join(ID1,_),
    thread_join(ID2,_),
    thread_join(ID3,_),                                     %czekanie aż się skończą, nigdy nie skończą
    thread_join(ID4,_),
    thread_join(ID5,_).

filozof(C, Lewy, Prawy) :-                           % każdy podniesie prawy widelec i się zakleszczą
    format('Filozof ~w mysli~n', [C]),             % format, żeby wyświetliło wszystko jak wątek zostanie przerwany
    format('Filozof ~w chce prawy widelec~n', [C]),
    with_mutex(Prawy,
    (
        format('Filozof ~w podniosl prawy widelec~n', [C]),
        format('Filozof ~w chce lewy widelec~n', [C]),
        with_mutex(Lewy,
        (
            format('Filozof ~w podniosl lewy widelec~n', [C]),
            format('Filozof ~w je~n', [C]),
            format('Filozof ~w odklada lewy widelec~n', [C])
        )),
        format('Filozof ~w odklada prawy widelec~n', [C])
    )),
    filozof(C, Lewy, Prawy).
