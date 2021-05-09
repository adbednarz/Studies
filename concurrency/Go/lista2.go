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

// wątek kłusownika
func poacher(trap []chan bool, pong chan int, receiver <-chan int, wg *sync.WaitGroup) {
	r := rand.Intn(DELAY)
	for {
		time.Sleep(time.Duration(r) * time.Second * 10)
		pong <- -1 // check if pong is about to close channels
		x, ok := <-receiver
		if ok == false {
			defer wg.Done()
			break
		}
		x = rand.Intn(len(trap))
		trap[x] <- true
	}
}

// wątek nadawcy
func ping(send0 chan<- int, receiver0 <-chan int, n int, printing chan<- string, wg *sync.WaitGroup) {
	r := rand.Intn(DELAY)
	var packet = 1
	for {
		time.Sleep(time.Duration(r) * time.Second / 2)
		printing <- "Packet " + strconv.Itoa(packet) + " was sent"
		send0 <- packet
		<-receiver0
		if packet == n {
			defer wg.Done()
			break
		}
		packet++
	}
}

// wątek odbiorcy
func pong(senders []chan int, receivers []chan int, n int, printing chan<- string, wg *sync.WaitGroup) {
	r := rand.Intn(DELAY)
	var counter = 0
	for {
		time.Sleep(time.Duration(r) * time.Second / 2)
		packet := <-senders[len(senders)-1]
		if packet > 0 {
			printing <- "Packet " + strconv.Itoa(packet) + " was received"
		}
		if packet == -1 && counter == n {
			for _, chain := range senders { //wątek odbiorcy po otrzymaniu wszystkich pakietów informuje inne wątki
				close(chain)
			}
			for _, chain := range receivers {
				close(chain)
			}
			close(printing)
			defer wg.Done()
			break
		} else if packet >= 0 {
			counter++
		}
		receivers[len(senders)-1] <- 1
	}
}

// wątek wierzchołka
func vertex(senders []chan int, receivers []chan int, trap []chan bool, num int, lifetime int,
	graph map[int][]int, visited_vertices map[int][]int, served_packets map[int][]int,
	transfers map[int]int, mutex *sync.Mutex, printing chan<- string, wg *sync.WaitGroup) {
	r := rand.Intn(DELAY)
	isTrap := false
	flag := false
	for {
		if flag {
			break
		}
		time.Sleep(time.Duration(r) * time.Second / 2 * 3)
		select {
		case packet, ok := <-senders[num]:
			if ok == false {
				defer wg.Done()
				flag = true
				break
			}
			printing <- "Packet " + strconv.Itoa(packet) + " is in the " +
				strconv.Itoa(num) + " vertex"
			receivers[num] <- 1
			// dopisywanie jest blokowane, bo powodowało wysyp programu przy małych opóźnieniach
			mutex.Lock()
			visited_vertices[packet-1] = append(visited_vertices[packet-1], num)
			served_packets[num] = append(served_packets[num], packet)
			mutex.Unlock()
			transfers[packet-1] += 1
			if transfers[packet-1] > lifetime {
				printing <- "Packet " + strconv.Itoa(packet) +
					" exceeded limit of transfers between vertices"
				senders[len(senders)-1] <- 0
				<-receivers[len(senders)-1]
			} else if isTrap == true {
				printing <- "Packet " + strconv.Itoa(packet) +
					" encounter a trap"
				senders[len(senders)-1] <- 0
				<-receivers[len(senders)-1]
				isTrap = false
			} else { // przekazuje pakiet do innego wierzchołka
				x := 0
				notSent := true
				for notSent {
					if num != len(senders)-2 {
						x = rand.Intn(len(graph[num]))
					} else {
						x = rand.Intn(len(graph[num]) + 1)
					}
					if x == len(graph[num]) { //ostatni wierzchołek przekazuje do kanału powiązanego z odbiorcą
						senders[len(senders)-1] <- packet
						<-receivers[len(senders)-1]
						notSent = false
					} else {
						select {
						case senders[graph[num][x]] <- packet:
							<-receivers[graph[num][x]]
							notSent = false
						case <-time.After(time.Second * 1):
						}
					}
				}
			}
		case isTrap = <-trap[num]:
		}
	}
}

// wątek wyswietlania komunikatów
func printing_server(printing <-chan string, wg *sync.WaitGroup) {
	for {
		message, ok := <-printing
		if ok == false {
			defer wg.Done()
			break
		}
		fmt.Println(message)
	}
}

func main() {

	var wg sync.WaitGroup // czekanie na zakończenie wszystkich wątków
	var mutex = &sync.Mutex{}

	graph := make(map[int][]int)
	visited_vertices := make(map[int][]int)
	served_packets := make(map[int][]int)
	transfers := make(map[int]int)
	// kanał do nadsyłania komunikatów
	printing := make(chan string)

	if len(os.Args) != 6 {
		fmt.Println("Incorrect number of arguments")
		return
	}

	n, err1 := strconv.Atoi(os.Args[1])
	d, err2 := strconv.Atoi(os.Args[2])
	b, err3 := strconv.Atoi(os.Args[3])
	k, err4 := strconv.Atoi(os.Args[4])
	h, err5 := strconv.Atoi(os.Args[5])

	if err1 != nil || err2 != nil || err3 != nil || err4 != nil || err5 != nil {
		fmt.Println("Incorrect type of arguments. Must be integers")
		return
	} else if n < 1 || d < 0 || b < 0 || k < 0 || h < 0 {
		fmt.Println("Incorrect arguments. The first argument must be greater than zero, the others must be positive")
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
		sum += n - 1
		if b > sum {
			fmt.Println("The value of third paramater is too big")
			return
		}
	}

	rand.Seed(time.Now().UTC().UnixNano())

	// na początku pakiety mają wyzerowane transfery pomiędzy wierzchołkami
	for i := 0; i < k; i++ {
		transfers[i] = 0
	}

	// każdy wierzchołek jest połączony z wierzchołkiem o jeden większym
	for i := 0; i < n-1; i++ {
		graph[i] = append(graph[i], i+1)
	}

	// losowo przydziela d nowych połączeń między wierzchołkami
	counter := 0
	for counter < d {
		x := rand.Intn(n - 2)
		var flag bool
		y := rand.Intn(n-x-1) + x + 1
		for _, value := range graph[x] {
			if value == y {
				flag = true
			}
		}
		if flag {
			continue
		}
		graph[x] = append(graph[x], y)
		counter++
	}

	// losowo przydziela b odwrotnie skierowanych połączeń między wierzchołkami
	counter = 0
	for counter < b {
		x := rand.Intn(n-1) + 1
		var flag bool
		y := rand.Intn(x)
		for _, value := range graph[x] {
			if value == y {
				flag = true
			}
		}
		if flag {
			continue
		}
		graph[x] = append(graph[x], y)
		counter++
	}

	// wypisuje graf
	for k, v := range graph {
		fmt.Printf("Vertex [%d] connected with %d\n", k, v)
	}

	// tworzy kanały pomiędzy wierzchołkami odpowiedzialne za komunikację
	sender := make([]chan int, n+1)
	receiver := make([]chan int, n+1)
	trap := make([]chan bool, n)
	for i := 0; i < n; i++ {
		sender[i] = make(chan int)   // służy do wysyłania pakietów
		receiver[i] = make(chan int) // służy do potwierdzania odbioru pakietów
		trap[i] = make(chan bool)    // służy do ustawiania pułapek w wierzchołkach
	}
	sender[n] = make(chan int)
	receiver[n] = make(chan int)

	// uruchamia wątki wierzchołków
	for i := 0; i < n; i++ {
		wg.Add(1)
		go vertex(sender, receiver, trap, i, h, graph, visited_vertices, served_packets, transfers, mutex, printing, &wg)
	}
	wg.Add(1)
	go ping(sender[0], receiver[0], k, printing, &wg)
	wg.Add(1)
	go pong(sender, receiver, k, printing, &wg)
	wg.Add(1)
	go printing_server(printing, &wg)
	wg.Add(1)
	go poacher(trap, sender[n], receiver[n], &wg)

	wg.Wait()

	// wyświetlanie raportu
	for k, v := range served_packets {
		fmt.Printf("Vertex[%d] served %d\n", k, v)
	}

	for k, v := range visited_vertices {
		tmp := k + 1
		fmt.Printf("Packet[%d] visited %d\n", tmp, v)
	}
}
