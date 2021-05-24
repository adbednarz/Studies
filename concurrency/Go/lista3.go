package main

import (
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"sync"
	"time"
)

const DELAY = 2

// do przesyłania
type sendPackets struct {
	packets map[int][]int
}

type readOp struct {
	key  int
	resp chan int
}

type writeOp struct {
	key          int
	new_next_hop int
	new_cost     int
	resp         chan bool
}

func routing_table(i int, graph map[int][]int, sending chan *sendPackets, reads chan *readOp, writes chan *writeOp, wg *sync.WaitGroup) {
	var next_hop = make(map[int]int)
	var cost = make(map[int]int)
	var changed = make(map[int]bool)
	// inicjalizacja routing table
	for j, v := range graph {
		var flag = false
		for _, w := range v {
			if w == i {
				flag = true
			}
		}
		changed[j] = true
		if flag == true {
			next_hop[j] = j
			cost[j] = 1
		} else {
			if i < j {
				next_hop[j] = i + 1
				cost[j] = j - i
			} else if j < i {
				next_hop[j] = i - 1
				cost[j] = i - j
			} else {
				changed[j] = false // warunek zadania i != j
			}
		}
	}
	for {
		select {
		case <-sending:
			// odbiera zapytanie od sendera i sprawdza dostępne pakiety
			available_packets := make(map[int][]int)
			for j, c := range cost {
				if changed[j] == true {
					available_packets[j] = append(available_packets[j], j)
					available_packets[j] = append(available_packets[j], c)
					available_packets[j] = append(available_packets[j], i)
					changed[j] = false
				}
			}
			// jeżeli są jakieś dostępne pakiety to wysyła je do sendera
			if len(available_packets) > 0 {
				read := &sendPackets{
					packets: available_packets}
				sending <- read
			}
		case read := <-reads:
			// wysyła pewną wartość cost do receivera
			read.resp <- cost[read.key]
		case write := <-writes:
			// zapisuje nowe, otrzymane wartości do pewnego miejsca w tabeli
			next_hop[write.key] = write.new_next_hop
			cost[write.key] = write.new_cost
			changed[write.key] = true
			write.resp <- true
		case <-time.After(10000 * time.Millisecond):
			defer wg.Done()
			return
		}
	}
}

func sender(id int, graph map[int][]int, getting chan *sendPackets, sending []chan *sendPackets, printing chan<- string, wg *sync.WaitGroup) {
	r := rand.Intn(DELAY)
	packets := make(map[int][]int)
	for {
		time.Sleep(time.Duration(r) * time.Second / 2)
		// sprawdza, czy są dostępne pakiety w routing table
		get := &sendPackets{
			packets: packets}
		getting <- get
		select {
		case get = <-getting:
			// odbiera otrzymane pakiety z routing table
			messages := ""
			// jeżeli są jakieś wolne pakiety to...
			if len(get.packets) > 0 {
				// wypisuje otrzymane pakiety
				messages += "Sender " + strconv.Itoa(id) + " got the following packets from " + strconv.Itoa(id) + " routing table:"
				for _, packet := range get.packets {
					messages += " [" + strconv.Itoa(packet[0]) + ", " + strconv.Itoa(packet[1]) + "]"
				}
				printing <- messages
				// rozsyła otrzymane pakiety po sąsiadach danego wierzchołka
				for _, n := range graph[id] {
					printing <- "Sender " + strconv.Itoa(id) + " sent packet to " + strconv.Itoa(n) + " receiver"
					sending[n] <- get
				}
			}
		case <-time.After(10000 * time.Millisecond):
			defer wg.Done()
			return
		}
	}
}

func receiver(id int, sending chan *sendPackets, reads chan *readOp,
	writes chan *writeOp, printing chan<- string, wg *sync.WaitGroup) {
	r := rand.Intn(DELAY)
	for {
		time.Sleep(time.Duration(r) * time.Second / 2)
		select {
		case packets := <-sending: // odbiera nadesłane pakiety od senderów
			flag := true
			// obsługujemy każdą parę w pakiecie zbiorowym
			for _, packet := range packets.packets {
				// na samym początku wyświetla od kogo dostał ten pakiet
				if flag {
					printing <- "Receiver " + strconv.Itoa(id) + " received packets from sender " + strconv.Itoa(packet[2])
					flag = false
				}
				// czyta wartość cost z routing table
				read := &readOp{
					key:  packet[0],
					resp: make(chan int)}
				reads <- read
				old_cost := <-read.resp
				// jeżeli nowa wartość cost jest mniejsza to, zmienia wartości w routing table
				if old_cost > packet[1]+1 {
					write := &writeOp{
						key:          packet[0],
						new_next_hop: packet[2],
						new_cost:     packet[1] + 1,
						resp:         make(chan bool)}
					writes <- write
					<-write.resp
					printing <- "Receiver " + strconv.Itoa(id) + " changed values in " + strconv.Itoa(id) + " routing table: Index - " +
						strconv.Itoa(packet[0]) + " nexthop - " + strconv.Itoa(packet[2]) +
						" cost - " + strconv.Itoa(packet[1]+1)
				}
			}
		case <-time.After(10000 * time.Millisecond):
			defer wg.Done()
			return
		}
	}
}

// wątek wyswietlania komunikatów
func printing_server(printing <-chan string, wg *sync.WaitGroup) {
	for {
		select {
		case message := <-printing:
			fmt.Println(message)
		case <-time.After(10000 * time.Millisecond):
			defer wg.Done()
			return
		}
	}
}

func main() {

	var wg sync.WaitGroup // czekanie na zakończenie wszystkich wątków

	graph := make(map[int][]int)
	// kanał do nadsyłania komunikatów
	printing := make(chan string)

	if len(os.Args) != 3 {
		fmt.Println("Incorrect number of arguments")
		return
	}

	// n to liczba wierzchołków, a d to liczba skrótów
	n, err1 := strconv.Atoi(os.Args[1])
	d, err2 := strconv.Atoi(os.Args[2])

	if err1 != nil || err2 != nil {
		fmt.Println("Incorrect type of arguments. Must be integers")
		return
	} else if n < 2 || d < 0 {
		fmt.Println("Incorrect arguments. The first argument must be greater than one, the second must be natural")
		return
	} else {
		var sum = 0
		for i := 2; i < n; i++ {
			sum += n - i
		}
		if d > sum {
			fmt.Println("The value of second paramater is too big")
			return
		}
	}

	rand.Seed(time.Now().UTC().UnixNano())

	// istnieją krawędzie nieskierowane {v, v+1}
	for i := 1; i < n; i++ {
		graph[i] = append(graph[i], i-1)
		graph[i-1] = append(graph[i-1], i)
	}

	// losowo przydziela d nowych połączeń między wierzchołkami
	counter := 0
	for counter < d {
		var flag bool
		x := rand.Intn(n)
		y := rand.Intn(n)
		if x == y {
			continue
		}
		for _, value := range graph[x] {
			if value == y {
				flag = true
			}
		}
		if flag {
			continue
		}
		graph[x] = append(graph[x], y)
		graph[y] = append(graph[y], x)
		counter++
	}

	// wypisuje graf
	for k, v := range graph {
		fmt.Printf("Vertex [%d] connected with %d\n", k, v)
	}

	// odbiera pakiety z routing table
	getting := make([]chan *sendPackets, n)
	// wysyła pakiety od sendera do receivera
	sending := make([]chan *sendPackets, n)
	// czyta wartość cost w routing table
	reads := make([]chan *readOp, n)
	// zmienia wartości nexthop oraz cost w routing table
	writes := make([]chan *writeOp, n)
	// kanałów jest tyle ile jest wierzchołków
	for i := 0; i < n; i++ {
		getting[i] = make(chan *sendPackets)
		sending[i] = make(chan *sendPackets)
		reads[i] = make(chan *readOp)
		writes[i] = make(chan *writeOp)
	}

	// uruchamia wątki
	for i := 0; i < n; i++ {
		wg.Add(3)
		go routing_table(i, graph, getting[i], reads[i], writes[i], &wg)
		go sender(i, graph, getting[i], sending, printing, &wg)
		go receiver(i, sending[i], reads[i], writes[i], printing, &wg)
	}
	wg.Add(1)
	go printing_server(printing, &wg)
	wg.Wait()
}
