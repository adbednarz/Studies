package main

import (
	"container/list"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"sync"
	"time"
)

const DELAY = 2

type sendPackets struct {
	packets map[int][]int
}

type standardPacket struct {
	sender_address   [2]int
	receiver_address [2]int
	visited_routers  []int
}

type readOp struct {
	key  int
	flag bool
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
			if read.flag == false {
				read.resp <- cost[read.key]
			} else {
				read.resp <- next_hop[read.key]
			}
		case write := <-writes:
			// zapisuje nowe, otrzymane wartości dla pewnego miejsca w tabeli
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
		case get = <-getting: // odbiera otrzymane pakiety z routing table

			// jeżeli są jakieś wolne pakiety to...
			if len(get.packets) > 0 {
				// rozsyła otrzymane pakiety po sąsiadach danego wierzchołka
				for _, n := range graph[id] {
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
	r := rand.Intn(30)
	for {
		time.Sleep(time.Duration(r) * time.Second)
		select {
		case packets := <-sending: // odbiera nadesłane pakiety od senderów
			// obsługujemy każdą parę w pakiecie zbiorowym
			for _, packet := range packets.packets {
				// czyta wartość cost z routing table
				read := &readOp{
					key:  packet[0],
					flag: false,
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

func forwarder_receiving(r int, queue *list.List, forwarding chan *standardPacket, printing chan<- string, wg *sync.WaitGroup) {
	d := rand.Intn(DELAY)
	for {
		time.Sleep(time.Duration(d) * time.Second / 2)
		select {
		case packet := <-forwarding:
			// dodajemy siebie do listy odwiedzonych routerów
			packet.visited_routers = append(packet.visited_routers, r)
			queue.PushBack(packet)
		case <-time.After(10000 * time.Millisecond):
			packet := &standardPacket{
				sender_address:   [2]int{},
				receiver_address: [2]int{},
				visited_routers:  []int{}}
			queue.PushBack(packet)
			defer wg.Done()
			return
		}
	}
}

func forwarder_sending(r int, queue *list.List, reads chan *readOp, neighbours []int, forwarding []chan *standardPacket, hosts []chan *standardPacket, printing chan<- string, wg *sync.WaitGroup) {
	d := rand.Intn(DELAY)
	for {
		time.Sleep(time.Duration(d) * time.Second / 2)
		if queue.Len() > 0 {
			e := queue.Front()
			queue.Remove(e)
			packet := *(e.Value.(*standardPacket))
			if len(packet.visited_routers) == 0 {
				break
			}
			if packet.receiver_address[0] == r {
				hosts[packet.receiver_address[1]] <- &packet
			} else {
				for i := 0; i < len(neighbours); i++ {
					read := &readOp{
						key:  packet.receiver_address[0],
						flag: true,
						resp: make(chan int)}
					reads <- read
					next_hop := <-read.resp
					if next_hop == neighbours[i] {
						forwarding[neighbours[i]] <- &packet
						break
					}
				}
			}
		}
	}
}

func host(r int, h int, n int, forwarding chan *standardPacket, graph_hosts map[int][]chan *standardPacket, printing chan<- string, wg *sync.WaitGroup) {
	d := rand.Intn(DELAY)
	host_in := graph_hosts[r][h]
	rp := 0
	hp := 0
	for {
		rp = rand.Intn(n)
		if len(graph_hosts[rp]) != 0 {
			hp = rand.Intn(len(graph_hosts[rp]))
			break
		}
	}
	forward := &standardPacket{
		sender_address:   [2]int{r, h},
		receiver_address: [2]int{rp, hp},
		visited_routers:  []int{}}
	forwarding <- forward
	for {
		select {
		case packet := <-host_in:
			message := "Sender address: (" + strconv.Itoa(packet.sender_address[0]) + " " + strconv.Itoa(packet.sender_address[1]) + ")\n"
			message += "Receiver address: (" + strconv.Itoa(packet.receiver_address[0]) + " " + strconv.Itoa(packet.sender_address[1]) + ")\n"
			message += "Visited routers : ("
			for _, k := range packet.visited_routers {
				message += " " + strconv.Itoa(k)
			}
			message += " )"
			printing <- message
			time.Sleep(time.Duration(d) * time.Second / 2)
			forward = &standardPacket{
				sender_address:   [2]int{r, h},
				receiver_address: [2]int{packet.sender_address[0], packet.sender_address[1]},
				visited_routers:  []int{}}
			forwarding <- forward
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

	// połączenia między routerami
	graph := make(map[int][]int)
	// rozmieszczenie hostów między routerami
	graph_hosts := make(map[int][]chan *standardPacket)
	// kanał do nadsyłania komunikatów
	printing := make(chan string)

	if len(os.Args) != 4 {
		fmt.Println("Incorrect number of arguments")
		return
	}

	// n to liczba wierzchołków, d to liczba skrótów, h to liczba hostów
	n, err1 := strconv.Atoi(os.Args[1])
	d, err2 := strconv.Atoi(os.Args[2])
	h, err3 := strconv.Atoi(os.Args[3])

	if err1 != nil || err2 != nil || err3 != nil {
		fmt.Println("Incorrect type of arguments. Must be integers")
		return
	} else if n < 2 || d < 0 || h < 0 {
		fmt.Println("Incorrect arguments. The first argument must be greater than one, the others must be natural")
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

	// losowo przydziela hosty do danego routera
	for i := 0; i < h; i++ {
		x := rand.Intn(n)
		graph_hosts[x] = append(graph_hosts[x], make(chan *standardPacket))
	}

	// wypisuje graf
	for k, v := range graph {
		fmt.Printf("Vertex [%d] connected with %d, Hosts: %d\n", k, v, len(graph_hosts[k]))
	}

	// odbiera pakiety z routing table
	getting := make([]chan *sendPackets, n)
	// wysyła pakiety od sendera do receivera
	sending := make([]chan *sendPackets, n)
	// do przesyłania standardPacketów
	forwarding := make([]chan *standardPacket, n)
	// czyta wartości w routing table
	reads := make([]chan *readOp, n)
	// zmienia wartości nexthop oraz cost w routing table
	writes := make([]chan *writeOp, n)
	// kolejka dla pakietów standardowych
	queues := make([]*list.List, n)
	// kanałów jest tyle ile jest wierzchołków
	for i := 0; i < n; i++ {
		getting[i] = make(chan *sendPackets)
		sending[i] = make(chan *sendPackets)
		forwarding[i] = make(chan *standardPacket)
		reads[i] = make(chan *readOp)
		writes[i] = make(chan *writeOp)
		queues[i] = list.New()
	}

	// uruchamia wątki
	for i := 0; i < n; i++ {
		wg.Add(5)
		go routing_table(i, graph, getting[i], reads[i], writes[i], &wg)
		go sender(i, graph, getting[i], sending, printing, &wg)
		go receiver(i, sending[i], reads[i], writes[i], printing, &wg)
		go forwarder_receiving(i, queues[i], forwarding[i], printing, &wg)
		go forwarder_sending(i, queues[i], reads[i], graph[i], forwarding, graph_hosts[i], printing, &wg)
	}

	// uruchamia hosty
	for i := 0; i < n; i++ {
		for j := 0; j < len(graph_hosts[i]); j++ {
			go host(i, j, n, forwarding[i], graph_hosts, printing, &wg)
		}
	}
	wg.Add(1)
	go printing_server(printing, &wg)
	wg.Wait()
}
