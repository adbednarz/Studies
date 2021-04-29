package main

import (
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"sync"
	"time"
)

const DELAY = 5

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
		printing <- "Packet " + strconv.Itoa(packet) + " was received"
		receivers[len(senders)-1] <- 1
		counter++
		if counter == n { // wątek odbiorcy po otrzymaniu wszystkich pakietów zamyka wszystkie kanały
			for _, chain := range senders {
				close(chain)
			}
			close(printing)
			defer wg.Done()
			break
		}
	}
}

// wątek wierzchołka
func vertex(senders []chan int, receivers []chan int, num int,
	graph map[int][]int, visited_vertices map[int][]int, served_packets map[int][]int,
	mutex *sync.Mutex, printing chan<- string, wg *sync.WaitGroup) {
	r := rand.Intn(DELAY)
	for {
		time.Sleep(time.Duration(r) * time.Second / 2 * 3)
		packet, ok := <-senders[num]
		if ok == false {
			defer wg.Done()
			break
		}
		printing <- "Packet " + strconv.Itoa(packet) + " is in the " +
			strconv.Itoa(num) + " vertex"
		receivers[num] <- 1
		// nadpisywanie jest blokowane, bo powodowało wysyp programu przy małych opóźnieniach
		mutex.Lock()
		visited_vertices[packet-1] = append(visited_vertices[packet-1], num)
		served_packets[num] = append(served_packets[num], packet)
		mutex.Unlock()
		if num != len(senders)-2 { // przekazuje pakiet do innego wierzchołka
			x := rand.Intn(len(graph[num]))
			senders[graph[num][x]] <- packet
			<-receivers[graph[num][x]]
		} else { // ostatni wierzchołek przekazuje do kanału powiązanego z odbiorcą
			senders[len(senders)-1] <- packet
			<-receivers[len(senders)-1]
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
	// kanał do nadsyłania komunikatów
	printing := make(chan string)

	if len(os.Args) != 4 {
		fmt.Println("Incorrect number of arguments")
		return
	}

	n, err1 := strconv.Atoi(os.Args[1])
	d, err2 := strconv.Atoi(os.Args[2])
	k, err3 := strconv.Atoi(os.Args[3])

	if err1 != nil || err2 != nil || err3 != nil {
		fmt.Println("Incorrect type of arguments. Must be integers")
		return
	} else if n < 1 || d < 0 || k < 0 {
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
	}

	rand.Seed(time.Now().UTC().UnixNano())

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

	// wypisuje graf
	for k, v := range graph {
		fmt.Printf("Vertex [%d] connected with %d\n", k, v)
	}

	// tworzy kanały pomiędzy wierzchołkami odpowiedzialne za komunikację
	sender := make([]chan int, n+1)
	receiver := make([]chan int, n+1)
	for i := 0; i <= n; i++ {
		sender[i] = make(chan int, 1) // służy do wysyłania pakietów
		receiver[i] = make(chan int)  // służy do potwierdzania odbioru pakietów
	}

	// uruchamia wątki wierzchołków
	for i := 0; i < n; i++ {
		wg.Add(1)
		go vertex(sender, receiver, i, graph, visited_vertices, served_packets, mutex, printing, &wg)
	}
	wg.Add(1)
	go ping(sender[0], receiver[0], k, printing, &wg)
	wg.Add(1)
	go pong(sender, receiver, k, printing, &wg)
	wg.Add(1)
	go printing_server(printing, &wg)

	wg.Wait()

	// wyświetlanie raportu
	for k, v := range served_packets {
		fmt.Printf("Vertex[%d] served %d\n", k, v)
	}

	for k, v := range visited_vertices {
		fmt.Printf("Packet[%d] visited %d\n", k, v)
	}
}
