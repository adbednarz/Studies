whitespace(' ').
whitespace('\t').
whitespace('\n').
whitespace('\r').

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

sep(";").
sep("+"). 
sep("-"). 
sep("*"). 
sep("/"). 
sep("("). 
sep(")"). 
sep("<"). 
sep(">").  
sep("=<"). 
sep(">="). 
sep(":="). 
sep("="). 

scanner(X,Y) :-
    reading(X,A),
    putting_in_order(A, [], Y).

reading(S,X) :-
	get_char(S, C),                              
	keep_reading(S, C, X).                

keep_reading(_, end_of_file, []) :-                  
	!.
    
keep_reading(S, C1, X) :-
	whitespace(C1),                                        
	!,
	get_char(S, C2),                                    
	keep_reading(S, C2, X).                             
    
keep_reading(S, C1, [H | T]) :-                         
	read_word(S, C1, C2, '', H),                   
	keep_reading(S, C2, T).                             


read_word(_, end_of_file, end_of_file, N, N) :-     
	!.
    
read_word(_, C, C, N, N) :-                          
	whitespace(C),                                           
	!. 

read_word(_,C, C, N, N) :-                           
    char_type(C, punct),                               
    atom_length(N,L), 
    L > 0,                                             
    atom_chars(N, L2),                               
    \+ same(L2, punct),                          
    !.

read_word(_,C, C, N, N) :-
    char_type(C, upper),                                
    atom_length(N,L),
    L > 0,
    atom_chars(N, L2),
    \+ same(L2, upper),
    !.

read_word(_,C, C, N, N) :-
    char_type(C, lower),                                 
    atom_length(N,L),
    L > 0,
    atom_chars(N, L2),
    \+ same(L2, lower),
    !.   

read_word(_,C, C, N, N) :-
    char_type(C, digit),                                 
    atom_length(N,L),
    L > 0,
    atom_chars(N, L2),
    \+ same(L2, digit),
    !.    
    
read_word(S, C1, C3, N1, N) :-                       
	atom_concat(N1, C1, N2),                            
	get_char(S, C2),                                    
	read_word(S, C2, C3, N2, N).
    
same([], _) :-
    !.
    
same([H|L],Y) :-
    char_type(H,Y),                                     
    same(L,Y).
    
 
putting_in_order([], Y, Y) :-      
    !.
    
putting_in_order([H1 | X], Y1, Y) :-    
    key(H1),
    !,
    append(Y1, [key(H1)], Y2),
    putting_in_order(X, Y2, Y).
    
putting_in_order([H1 | X], Y1, Y) :-     
    atom_string(H1,H),
    sep(H),
    !,
    append(Y1, [sep(H1)], Y2),
    putting_in_order(X, Y2, Y).
    
putting_in_order([H1 | X], Y1, Y) :-          
    atom_number(H1, H),
    !,
    append(Y1, [int(H)], Y2), 
    putting_in_order(X, Y2, Y).
    
putting_in_order([H1 | X], Y1, Y) :-          
    atom_chars(H1, L),                    
    same(L, upper),                              
    !, 
    append(Y1, [id(H1)], Y2),
    putting_in_order(X, Y2, Y). 
    













