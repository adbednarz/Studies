with Ada.Containers.Synchronized_Queue_Interfaces;
with Ada.Containers.Unbounded_Synchronized_Queues;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Containers.Vectors; use Ada.Containers;
with Ada.Containers.Indefinite_Vectors; use Ada.Containers;
with Ada.Numerics.Float_Random; use Ada.Numerics.Float_Random;
with Ada.Numerics.Discrete_Random;

procedure lista4 is

    package Vector_Pkg is new Vectors (Natural, Integer);
    use     Vector_Pkg;

    n : Integer;    -- liczba wierzchołkóws
    d : Integer;    -- liczba skrótów
    h : Integer;    -- liczba hostów

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
    h := Integer'Value (Ada.Command_Line.Argument(3));
    
    if n < 2 or d < 0 or h < 0 then
		Put_Line ("Incorrect arguments. The first argument must be greater than one, the others must be natural");
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
        graph_hosts : Storage (0 .. n - 1);
        
        Counter : Integer := 0;
        x : Integer;
        y : Integer;
        flag : Boolean := True;

        -- tablica wartości nexthop
        type vecI is array (integer range <>) of integer;
        -- tablica wartości changed
        type vecB is array (integer range <>) of Boolean;
        -- dwuelementowa tablica
        type twoIndexedArray is array (0 .. 1) of Integer;

        -- rekord przechowujący dane standard packet
        type Standard_Packet is
            record
          	    sender_address : twoIndexedArray;
	            receiver_address : twoIndexedArray;
	            visited_routers : Vector; 
            end record; 

        -- definowanie queue w Ada
        package Standard_Packet_Queue_Interfaces is
            new Ada.Containers.Synchronized_Queue_Interfaces
            (Element_Type => Standard_Packet);

        package Standard_Packet_Queues is
            new Ada.Containers.Unbounded_Synchronized_Queues
            (Queue_Interfaces => Standard_Packet_Queue_Interfaces);

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

        -- losowo przydziela hosty do routerów
        for I in 0 .. h - 1 loop
            x := randD(0, n - 1);
            graph_hosts (x).Append (I);
        end loop;

        -- wypisuje graf
        for I in graph'Range loop
            Put ("Vertex" & Integer'Image (I) & " connected with [");
            for index in graph (I).First_Index .. graph (I).Last_Index loop
                Put (Integer'Image (graph (I).Element (index)) & " ");
            end loop;
            Put_line ("] Hosts:" & Integer'Image (Standard.Integer (Length (graph_hosts (I)))));
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
                function Read (Index : Integer; Flag : Boolean) return Integer;
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

            -- wątek forward receiving
            task type Forwarder_Receiving(Id: Integer) is
                entry Send (Packet: in Standard_Packet);
            end Forwarder_Receiving;

            -- wątek forward sending
            task type Forwarder_Sending(Id: Integer);

            -- wątek hosta
            task type Host(R: Integer; H: Integer) is
                entry Send (Packet: in Standard_Packet);
            end Host;

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
            -- tablica forwarders_sending
            type Forwarder_Receiving_Array is array(0 .. n-1) of access Forwarder_Receiving;
            type FRA_Access is access Forwarder_Receiving_Array;
            FRA_Ptr : FRA_Access;
            -- tablica forwarders_receiving
            type Forwarder_Sending_Array is array(0 .. n-1) of access Forwarder_Sending;
            type FSA_Access is access Forwarder_Sending_Array;
            FSA_Ptr : FSA_Access;
            -- tablica hosts
            type Hosts_Array is array(0 .. h-1) of access Host;
            type HA_Access is access Hosts_Array;
            HA_Ptr : HA_Access;
            -- tablica queues
            Queues : array(0 .. n-1) of Standard_Packet_Queues.Queue;    

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
                function Read (Index : Integer; Flag : Boolean) return Integer is
                begin
                    if (Flag) then
                        return NextHop (Index);
                    else 
                        return Cost (Index);
                    end if;
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
                            -- wysyła do sąsiadów wierzchołka
                            for I in graph (Id).First_Index .. graph (Id).Last_Index loop
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
                    delay 0.1+Duration(10.0*(Random(G)+0.5));
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
                            for I in 0 .. n-1 loop
                                -- sprawdza, które pakiety były dostępne mają dwie wartości (j, cost(j))
                                if Length (ReceivedPackets (I)) > 0 then
                                    OldCost := RTA_Ptr (Id).Read (I, False);
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

            task body Forwarder_Receiving is
                G : Generator;
                standardPacket : Standard_Packet;
            begin
                loop
                    Reset(G);
                    delay 0.1+Duration(3.0*Random(G) / Del);
                    accept Send (Packet: in Standard_Packet) do
                        standardPacket := Packet;        
                    end Send;
                    standardPacket.visited_routers.Append (Id);
                    Queues (Id).Enqueue (New_Item => standardPacket);
                end loop;
            end Forwarder_Receiving;

            task body Forwarder_Sending is
                G : Generator;
                standardPacket : Standard_Packet;
                nextHop : Integer;
            begin
                loop
                    Reset(G);
                    delay 0.1+Duration(3.0*Random(G) / Del);
                    declare
                        flag : Boolean := True;    
                    begin
                        Queues (Id).Dequeue (Element => standardPacket);                   
                        if standardPacket.receiver_address (0) = Id then
                            HA_Ptr (graph_hosts (Id).Element (standardPacket.receiver_address (1))).Send (standardPacket);
                        else
                            for I in graph (Id).First_Index .. graph (Id).Last_Index loop
                               nextHop := RTA_Ptr (Id).Read (standardPacket.receiver_address (0), True);
                               if graph (Id).Element (I) = nextHop and Flag then
                                    FRA_Ptr (graph (Id).Element (I)).Send (standardPacket);
                                    Flag := False;
                               end if;
                            end loop; 
                        end if;           
                    end;
                end loop;
            end Forwarder_Sending;

            task body Host is
                G : Generator;
                standardPacket : Standard_Packet;
                RP : Integer;
                HP : Integer;
                Flag : Boolean := True;
            begin
                while Flag loop
                    RP := randD(0, n-1);
                    if (Length(graph_hosts (RP)) > 0) then
                        HP := randD(0, Standard.Integer (Length(graph_hosts (RP))) - 1);
                        standardPacket.sender_address (0) := R;
                        standardPacket.sender_address (1) := H;
                        standardPacket.receiver_address (0) := RP;
                        standardPacket.receiver_address (1) := HP;
                        FRA_Ptr (R).Send (standardPacket);
                        Flag := False;
                    end if;
                end loop;
                loop
                    accept Send (Packet: in Standard_Packet) do
                        standardPacket := Packet;         
                    end Send;
                    Reset(G);
                    Printing.Print ("Sender address: (" & Integer'Image (standardPacket.sender_address (0)) & " " & Integer'Image (standardPacket.sender_address (1)) & " )");
                    Printing.Print ("Receiver address: (" & Integer'Image (standardPacket.receiver_address (0)) & " " & Integer'Image (standardPacket.receiver_address (1)) & " )");
                    Printing.Print ("Visited routers : ");
                    for E in standardPacket.visited_routers.First_Index .. standardPacket.visited_routers.Last_Index loop
                        Printing.Print (Integer'Image(standardPacket.visited_routers (E)));
                    end loop;
                    Reset(G);
                    delay 0.1+Duration(3.0*Random(G) / Del);
                    declare
                        packet : Standard_Packet;
                    begin                        
                        packet.sender_address (0) := R;
                        packet.sender_address (1) := H;
                        packet.receiver_address (0) := standardPacket.sender_address (0);
                        packet.receiver_address (1) := standardPacket.sender_address (1);
                        FRA_Ptr (R).Send (packet);                    
                    end;                
                end loop;
            end Host;

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
            FRA_Ptr := new Forwarder_Receiving_Array;
            for I in RTA_Ptr.all'Range loop
                FRA_Ptr.all(I) := new Forwarder_Receiving(I);
            end loop;
            FSA_Ptr := new Forwarder_Sending_Array;
            for I in SA_Ptr.all'Range loop
                FSA_Ptr.all(I) := new Forwarder_Sending(I);
            end loop;
            HA_Ptr := new Hosts_Array;
            for I in graph_hosts'Range loop
                for Y in graph_hosts (I).First_Index .. graph_hosts (I).Last_Index loop
                    HA_Ptr.all(graph_hosts (I).Element (Y)) := new Host(I, Y);
                end loop;
            end loop;
        end;
    end;

exception
    when Constraint_Error =>
        Put_Line("The parameters must be integer");    
end;