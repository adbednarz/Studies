with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Containers.Vectors; use Ada.Containers;
with Ada.Containers.Indefinite_Vectors; use Ada.Containers;
with Ada.Numerics.Float_Random; use Ada.Numerics.Float_Random;
with Ada.Numerics.Discrete_Random;

procedure lista3 is

    package Vector_Pkg is new Vectors (Natural, Integer);
    use     Vector_Pkg;

    n : Integer;    -- liczba wierzchołkóws
    d : Integer;    -- liczba skrótów

    Del : Float := 2.0;

    type Storage is array (Natural range <>) of Vector;

    -- funkcja losująca liczby z podanego zakresu
    function randD(first, last: Integer) return Integer is
        type randRange is new Integer range first .. last;
        package Rand_Int is new ada.numerics.discrete_random(randRange);
        use Rand_Int;
        gen : Rand_Int.Generator;
        num : randRange;
        int : Integer;    
    begin
        Reset(gen);
        num := random(gen);
        int := Integer'Value (randRange'Image (num));
        return int;
    end randD;

begin
    if (Ada.Command_Line.Argument_Count /= 2) then
        Ada.Text_IO.Put_Line ("Incorrect number of arguments");
        return;
    end if;

    n := Integer'Value (Ada.Command_Line.Argument(1));
    d := Integer'Value (Ada.Command_Line.Argument(2));
    
    if n < 2 or d < 0 then
		Put_Line ("Incorrect arguments. The first argument must be greater than one, the other must be positive");
		return;
    else
        declare
           sum : Integer := 0;
        begin
            for i in  2 .. n  loop  -- sprawdzenie ile jest możliwych dodatkowych krawędzi 
                sum := sum + n - i;
            end loop;      
            if d > sum then     
                Put_Line ("The value of second paramater is too big");
                return;
            end if;       
        end;
	end if;

    declare
        graph : Storage (0 .. n - 1);
        
        Counter : Integer := 0;
        x : Integer;
        y : Integer;
        flag : Boolean := True;

        -- tablica wartości nexthop
        type vecI is array (integer range <>) of integer;
        -- tablica wartości changed
        type vecB is array (integer range <>) of Boolean;

    begin
        -- istnieją krawędzie nieskierowane {v, v+1}
        for I in 1 .. n - 1 loop
            graph (I).Append (I - 1);
            graph (I-1).Append (I);
        end loop;
        
        -- losowo przydziela d nowych połączeń między wierzchołkami
        while Counter < d loop
            x := randD(0, n - 1);
            y := randD(0, n - 1);
            if x /= y then
                for Index in graph (x).First_Index .. graph (x).Last_Index loop
                    if graph (x).Element (Index) = y then
                        flag := False;
                    end if;
                end loop;
                if flag then
                    graph (x).Append (y);
                    graph (y).Append (x);
                    Counter := Counter + 1;
                end if;
                flag := True;
            end if;
        end loop;
        Counter := 0;

        -- wypisuje graf
        for I in graph'Range loop
            Put ("Vertex" & Integer'Image (I) & " connected with [");
            for index in graph (I).First_Index .. graph (I).Last_Index loop
                Put (Integer'Image (graph (I).Element (index)) & " ");
            end loop;
            Put_line ("]");
        end loop;   

        declare
            -- wątek wypisujący informacje
            task Printing is
                entry Print (x: in String);
            end Printing;

            task body Printing is
            begin
                loop
                    select
                        accept Print (x: in String) do
                        Put_Line (x);
                        end Print;
                    or
                       delay 10.0;
                       exit;
                    end select;
                end loop;
            end Printing;  

            -- wątek routing table (i)
            protected type R(Id: Integer) is
                procedure Initialize;
                entry Sending (Packets: out Storage);
                procedure Write (Index: in Integer; NewNextHop: in Integer; NewCost: in Integer);
                function Read (Index : Integer) return Integer;
            private
                NextHop : vecI(0 .. n - 1);
                Cost : vecI(0 .. n - 1);
                Changed : vecB(0 .. n - 1) := (others => true);
                SomeTrueInChanged : Boolean := True;
                Packets : Vector;
            end R;

            -- wątek sendera
            task type Sender(Id: Integer);

            -- wątek receivera
            task type Receiver(Id: Integer) is
                entry Send (Packets: in Storage);
            end Receiver;

            -- tablica jest obiektem limited type, więc aby przypisać obiekt należy użyć access type
            -- tablica routing tables
            type RT_Array is array(0 .. n-1) of access R;
            type RTA_Access is access RT_Array;
            RTA_Ptr : RTA_Access;
            -- tablica senders
            type Senders_Array is array(0 .. n-1) of access Sender;
            type SA_Access is access Senders_Array;
            SA_Ptr : SA_Access;
            -- tablica receivers
            type Receivers_Array is array(0 .. n-1) of access Receiver;
            type RA_Access is access Receivers_Array;
            RA_Ptr : RA_Access;

            protected body R is
                -- inicjalizacja routing table
                procedure Initialize is
                begin
                    for I in 0 .. n - 1 loop
                        flag := False;
                        for Index in graph (I).First_Index .. graph (I).Last_Index loop
                            if graph (I).Element (Index) = Id then
                                flag := True;
                            end if;
                        end loop;
                        -- jest to sąsiad tego wierzchołka
                        if flag = True then
                            NextHop(I) := I;
                            Cost(I) := 1;
                        else
                            if Id < I then
                                NextHop(I) := Id + 1;
                                Cost(I) := I - Id;
                            elsif I < Id then
                                NextHop(I) := Id - 1;
                                Cost(I) := Id - I;
                            else
                                Changed(I) := false;
                            end if;                       
                        end if;
                    end loop;
                end Initialize;
                -- wysyła dostępne pakiety
                entry Sending (Packets : out Storage)
                    when SomeTrueInChanged is
                begin
                    SomeTrueInChanged := False;
                    for I in 0 .. n - 1 loop
                       if Changed(I) = True then
                            Packets (I).Append (Cost (I));
                            Packets (I).Append (Id);
                            Changed(I) := False;
                       end if;
                    end loop;   
                end Sending;
                -- czytwa wartość cost w danym indeksie routing table
                function Read (Index : Integer) return Integer is
                begin
                    return Cost (Index);
                end Read;
                -- zmienia wartości w danym indeksie routing table
                procedure Write (Index : Integer; NewNextHop : Integer; NewCost : Integer) is
                begin
                    NextHop (Index) := NewNextHop;
                    Cost (Index) := NewCost;
                    Changed (Index) := True;
                    SomeTrueInChanged := True;
                end Write;
            end R;            

            task body Sender is
                G : Generator;
            begin
                loop
                    Reset(G);
                    delay 0.1+Duration(3.0*Random(G) / Del);
                    declare
                        Packets : Storage (0 .. n - 1);  
                    begin
                        -- bierze dostępne pakiety z routing table
                        select
                            RTA_Ptr (Id).Sending(Packets);
                            Printing.Print ("Sender" & Integer'Image (Id) & " got the following packets from" & Integer'Image (Id) & " routing table:");
                            -- wypisuje pakiety
                            for I in 1 .. n-1 loop
                                if Length (Packets (I)) = 2 then
                                    Printing.Print(" [" & Integer'Image (I) & " " & Integer'Image (Packets (I).Element (0)) & " ]");
                                end if;
                            end loop;
                            -- wysyła do sąsiadów wierzchołka
                            for I in graph (Id).First_Index .. graph (Id).Last_Index loop
                                Printing.Print ("Sender" & Integer'Image (Id) & " sent packet to" & Integer'Image (graph (Id).Element (I)) & " receiver");
                                RA_Ptr (graph (Id).Element (I)).Send (Packets);
                            end loop;
                        or
                            delay 10.0;
                            exit;
                        end select;                                               
                    end;
                end loop;
            end Sender;

            task body Receiver is
                G : Generator;
            begin
                loop
                    Reset(G);
                    delay 0.1+Duration(3.0*Random(G) / Del);
                    declare
                       ReceivedPackets : Storage (0 .. n - 1);
                       OldCost : Integer;
                       Flag : Boolean := True;
                    begin
                        -- odbiera wysłane pakiety przez sendera
                        select
                            accept Send (Packets: in Storage) do
                                ReceivedPackets := Packets;         
                            end Send;
                            Flag := True;
                            for I in 0 .. n-1 loop
                                -- sprawdza, które pakiety były dostępne mają dwie wartości (j, cost(j))
                                if Length (ReceivedPackets (I)) > 0 then
                                    if Flag = True then
                                        Printing.Print ("Receiver" & Integer'Image (Id) & " received packets from sender " & Integer'Image (ReceivedPackets (I).Element (1)));
                                        Flag := False;
                                    end if;
                                    OldCost := RTA_Ptr (Id).Read (I);
                                    -- zmienia wartości w routing table jeśli nowy cost jest mniejszy
                                    if 1 + ReceivedPackets (I).Element (0) < OldCost then
                                        RTA_Ptr (Id).Write (I, ReceivedPackets (I).Element (1), 1 + ReceivedPackets (I).Element (0));
                                        Printing.Print ("Receiver" & Integer'Image (Id) & " changed values in " & Integer'Image (Id) & " routing table: Index - " &
						                Integer'Image (I) & " nexthop - " & Integer'Image (ReceivedPackets (I).Element (1)) & " cost - " & Integer'Image (1 + ReceivedPackets (I).Element (0)));
                                    end if;                                    
                                end if;
                            end loop;
                        or
                            delay 10.0;
                            exit;
                        end select;                                             
                    end;
                end loop;
            end Receiver;

        begin
            RTA_Ptr := new RT_Array;
            for I in RTA_Ptr.all'Range loop
                RTA_Ptr.all(I) := new R(I);
                RTA_Ptr (I).Initialize;
            end loop;
            SA_Ptr := new Senders_Array;
            for I in SA_Ptr.all'Range loop
                SA_Ptr.all(I) := new Sender(I);
            end loop;
            RA_Ptr := new Receivers_Array;
            for I in RA_Ptr.all'Range loop
                RA_Ptr.all(I) := new Receiver(I);
            end loop;
        end;
    end;

exception
    when Constraint_Error =>
        Put_Line("The parameters must be integer");    
end;