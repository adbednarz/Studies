INPUT
Store X
INPUT
Store Y

// Przypadek, gdy X to 1 lub 0.
Load X
Skipcond 800
Add one
Store X
Subt one
Skipcond 800
Jump DodX

// Sprawdza, czy X jest wieksze niz I.
Cond,	Load X
	    Subt I
	    Skipcond 800
	    Jump Lp
        Load X
        Store TEMP
        Jump Loop
         
// Sprawdza, czy X jest podzielne przez I.         
Loop,   Load TEMP
        Subt I
        Store TEMP
         
        Load I
        Subt TEMP
         
        Skipcond 800
        Jump Loop

// Wykonuje Jump w zaleznosci od tego, czy jest podzielna.
Decision,    Load TEMP
			 Skipcond 800
	 		 Jump DodX
		     Jump DodI
             
DodX,	Load X
		Add one
        Store X
        Clear
        Add two
        Store I
        Jump Conclusion
        
DodI,   Load I
		Add one
        Store I
        Jump Cond
	  	
Lp,     Load X
		Output
        Jump DodX
        
// Sprawdza, czy doszlismy do konca zakresu liczb.
Conclusion,	Load Y
			Subt X
			Skipcond 000
            Jump Cond
        	Halt

        
X, DEC 0
Y, DEC 0
TEMP, DEC 0
one, DEC 1
two, DEC 2
I, DEC 2

