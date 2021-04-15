#include <stdio.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdatomic.h>
  
// maximum size of matrix 
#define MAX 100
  
// maximum number of threads 
#define MAX_THREAD 10 

//arrays
int matA[MAX][MAX]; 
int matB[MAX][MAX]; 
int matC[MAX][MAX];
pthread_t threads[MAX_THREAD]; 

//variables
atomic_int step_i = 0;
int thre;
int size;

void* multi(void* arg) 
{
    int i = -1;
    while((i = step_i++) < size)
    {
        for (int j = 0; j < size; j++)  {
            for (int k = 0; k < size; k++) { 
                matC[i][j] = matA[i][k] * matB[k][j];
				if(matC[i][j] == 1) {
					break;
				}
			}

		}
    }
} 

int main(int argc, char *argv[]) 
{

	srand (time(NULL));	

    //arguments
    if(argc != 3)
    {
        printf("Illegal number of arguments!\n");
        return EXIT_FAILURE;
    }

    //size, threads
    if((size = atoi(argv[1])) > MAX)
    {
         printf("Too big size!\n");
         return EXIT_FAILURE;
    }

    //threads
    if((thre = atoi(argv[2])) > MAX_THREAD)
    {
         printf("Too big size!\n");
         return EXIT_FAILURE;
    }

    // Generating random values in matA and matB 
    for (int i = 0; i < size; i++) { 
        for (int j = 0; j < MAX; j++) {
            matB[i][j] = random() % 2; 
            matA[i][j] = random() % 2; 
        } 
    } 
  
    // printing matrix A
    printf("\nA\n");
    for (int i = 0; i < size; i++) { 
        for (int j = 0; j < size; j++)
            printf("%d  ", matA[i][j]);
        printf("\n");
    } 
  
    // printing matrix B
    printf("\nB\n");
    for (int i = 0; i < size; i++) { 
        for (int j = 0; j < size; j++)
            printf("%d  ", matB[i][j]);
        printf("\n");
    } 

    // Creating threads, each evaluating its own part 
    for (int i = 0; i < thre; i++) { 
        int* p; 
        pthread_create(&threads[i], NULL, multi, NULL); 
    } 
  
    // joining and waiting for all threads to complete 
    for (int i = 0; i < thre; i++)  
        pthread_join(threads[i], NULL);     
  
    // printing matrix A x B
    printf("\nA x B\n");
    for (int i = 0; i < size; i++) { 
        for (int j = 0; j < size; j++)
            printf("%d  ", matC[i][j]);
        printf("\n");
    } 

    return EXIT_SUCCESS; 
} 
