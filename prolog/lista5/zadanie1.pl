key(read).
key(write).
key(if).
key(then).
key(else).
key(fi).
key(while).
key(do).
key(od).
key(and).
key(or).
key(mod).

sep("=").
sep(":=").
sep(">=").
sep("=<").
sep(">").
sep("<").
sep(")").
sep("(").
sep("/").
sep("*").
sep("-").
sep("+").
sep(";").

whitespace(' ').
whitespace('\n').
whitespace('\t').
whitespace('\r').

scanner(Stream, Tokens) :-
    reading(Stream, X),
    putting_in_order(X, [], Tokens).

reading(S, X) :-
    get_char(S, C),
    keep_reading(S, C, X).

keep_reading(_, end_of_file, []).

keep_reading(S, C, X) :-
    whitespace(C),                        %jeśli biały znak to pobiera następny znak
    get_char(S, C2),
    keep_reading(S, C2, X).

keep_reading(S, C, [H|T]) :-              %jeśli nie biały znak to jakieś wyrażenie
    read_word(S, C, C2, '', H),           %złączenie wyrazenia
    keep_reading(S, C2, T).               %czytanie dalej za wyrazeniem

read_word(_, end_of_file, end_of_file, N, N).

read_word(_, C, C, N, N) :-
    whitespace(C).                        %biały znak koniec słowa

read_word(_, C, C, N, N) :-
    char_type(C, punct),
    atom_length(N, L),
    L > 0,
    atom_chars(N, L2),
    \+ same(L2, punct).

read_word(_, C, C, N, N) :-
    char_type(C, digit),
    atom_length(N, L),
    L > 0,
    atom_chars(N, L2),
    \+ same(L2, digit).


read_word(_, C, C, N, N) :-
    char_type(C, upper),
    atom_length(N, L),
    L > 0,
    atom_chars(N, L2),
    \+ same(L2, upper).

read_word(_, C, C, N, N) :-
    char_type(C, lower),
    atom_length(N, L),
    L > 0,
    atom_chars(N, L2),
    \+ same(L2, lower).

read_word(S, C, X, Previous, N) :-
    atom_concat(Previous, C, Current),         %łączymy znak do poprzedniego wyrazu
    get_char(S, C2),
    read_word(S, C2, X, Current, N).

same([], _).

same([H|T], X) :-                              %czy każdy znak listy jest typu X
    char_type(H, X),
    same(T, X).

putting_in_order([], X, X).

putting_in_order([H|T], X1, X) :-
    key(H),
    append(X1, [key(H)], X2),
    putting_in_order(T, X2, X).

putting_in_order([H|T], X1, X) :-
    atom_string(H, H2),
    sep(H2),
    append(X1, [sep(H2)], X2),
    putting_in_order(T, X2, X).

putting_in_order([H|T], X1, X) :-
    atom_number(H, H2),
    append(X1, [int(H2)], X2),
    putting_in_order(T, X2, X).

putting_in_order([H|T], X1, X) :-
    atom_chars(H, L),
    same(L, upper),
    append(X1, [id(H)], X2),
    putting_in_order(T, X2, X).
