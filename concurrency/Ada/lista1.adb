with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Containers.Vectors; use Ada.Containers;
with Ada.Numerics.Float_Random; use Ada.Numerics.Float_Random;
with Ada.Numerics.Discrete_Random;

procedure lista1 is

    package Vector_Pkg is new Vectors (Natural, Integer);
    use     Vector_Pkg;

    n : Integer;    -- liczba wierzchołków , 
    d : Integer;    -- liczba skrótów
    k : Integer;    -- liczba pakietów

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
    if (Ada.Command_Line.Argument_Count /= 3) then
        Ada.Text_IO.Put_Line ("Incorrect number of arguments");
        return;
    end if;

    n := Integer'Value (Ada.Command_Line.Argument(1));
    d := Integer'Value (Ada.Command_Line.Argument(2));
    k := Integer'Value (Ada.Command_Line.Argument(3));
    
    if n < 1 or d < 0 or k < 0 then
		Put_Line ("Incorrect arguments. The first argument must be greater than zero, the others must be positive");
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
        graph : Storage (0 .. n - 2);
        visited_vertices : Storage (1 .. k);
        served_Packets : Storage (0 .. n - 1);
        
        Counter : Integer := 0;
        x : Integer;
        y : Integer;
        flag : Boolean := True;

    begin
        -- każdy wierzchołek jest połączony z wierzchołkiem o jeden większym
        for I in 0 .. n - 2 loop
            graph (I).Append (I + 1);
        end loop;
        
        -- losowo przydziela d nowych połączeń między wierzchołkami
        while Counter < d loop
            x := randD(0, n - 3);
            y := randD(x+1, n-1);
            for Index in graph (x).First_Index .. graph (x).Last_Index loop
                if graph (x).Element (Index) = y then
                    flag := False;
                end if;
            end loop;
            if flag then
                graph (x).Append (y);
                Counter := Counter + 1;
            end if;
            flag := True;
        end loop;

        -- wypisuje graf
        for I in graph'Range loop
            Put ("Vertex" & Integer'Image (I) & " connected with [");
            for index in graph (I).First_Index .. graph (I).Last_Index loop
                Put (Integer'Image (graph (I).Element (index)) & " ");
            end loop;
            Put_line ("]");
        end loop;   

        declare
            -- wątek wierzchołka
            task type Vertex(Id: Integer) is
                entry Send (Received_Packet: in Integer);
            end Vertex;

            -- tablica wierzchołków
            -- tablica jest obiektem limited type, więc aby przypisać obiekt należy użyć access type
            type Vertices_Array is array(0 .. n-1) of access Vertex;
            type VA_Access is access Vertices_Array;
            VA_Ptr : VA_Access;

            -- wątek wypisujący informacje
            task Printing is
                entry Print (x: in String);
            end Printing;

            -- wątek nadawcy
            task Ping;

            -- wątek odbiorcy
            task Pong is
                entry Send (Received_Packet: in Integer);
            end Pong;

            task body Vertex is
                G : Generator;
                Packet : Integer;
                Rmd : Integer;
            begin
                loop
                    Reset(G);
                    delay 0.1+Duration(3.0*Random(G) / Del);
                    select
                        accept Send (Received_Packet: in Integer) do
                            Packet := Received_Packet;
                            Printing.Print ("Packet" & Integer'Image (Packet) & " is in the" & Id'Image & " vertex");
                        end Send;
                        visited_vertices (Packet).Append (Id);
                        served_Packets (Id).Append (Packet);
                        if Id /= n - 1 then -- ostatni wierzchołek jest połączony z odbiorcą
                        	Rmd := randD (0, Integer'Value(graph (Id).Length'Image)-1);
                               VA_Ptr (graph (Id).Element (Rmd)).Send (Packet);
                        else
                        	Pong.Send(Packet);
                        end if;
                    or
                        delay 0.025;
                        exit when Pong'Terminated;
                    end select;                                    
                end loop;
            end vertex;

            task body Pong is
                G : Generator;
                Packet : Integer;
                Counter : Integer := 0;
            begin
                loop
                    Reset(G);
                    delay 0.1+Duration(3.0*Random(G) / Del);
                    accept Send (Received_Packet: in Integer) do
                        Packet := Received_Packet;
                        Printing.Print ("Packet" & Integer'Image (Packet) & " was received");
                    end Send;
                    Counter := Counter + 1;
                    exit when Counter = k;
                end loop;
            end Pong;

            task body Ping is
                G : Generator;
                Packet : Integer := 1;
            begin
                loop
                    Reset(G);
                    delay 0.1+Duration(3.0*Random(G) / Del);
                    Printing.Print ("Packet" & Integer'Image (Packet) & " was sent");
                    VA_Ptr (0).Send (Packet);
                    Packet := Packet + 1;
                    exit when Packet > k;
                end loop;
            end Ping;

            task body Printing is
            begin
                loop
                    select
                        accept Print (x: in String) do
                        Put_Line (x);
                        end Print;
                    else 
                        exit when Pong'Terminated;
                    end select;
                end loop;
            end Printing;            

        begin
            VA_Ptr := new Vertices_Array;
            for I in VA_Ptr.all'Range loop
                VA_Ptr.all(I) := new vertex(I);
            end loop;
        end;

        -- wypisuje obsłużone pakiety przez dany wierzchołek
        for I in served_Packets'Range loop
            Put ("Vertex" & Integer'Image (I) & " served [");
            for index in served_Packets (I).First_Index .. served_Packets (I).Last_Index loop
                Put (Integer'Image (served_Packets (I).Element (index)) & " ");
            end loop;
            Put_line ("]");
        end loop;  

        -- wypisuje odwiedzone wierzchołki przez dany pakiet
        for I in visited_vertices'Range loop
            Put ("Packet" & Integer'Image (I) & " visited [");
            for Index in visited_vertices (I).First_Index .. visited_vertices (I).Last_Index loop
                Put (Integer'Image (visited_vertices (I).Element (Index)) & " ");
            end loop;
            Put_line ("]");
        end loop;  
    end;

exception
    when Constraint_Error =>
        Put_Line("The parameters must be integer");    
end;
