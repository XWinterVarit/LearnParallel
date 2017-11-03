
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

int NUM_THREADS = 4;
char FileName[] = "01all.nt";
char DefineWord[] = "<http://www.w3.org/2001/XMLSchema#string>";
long threadchucksize = 100000; // Warning : Must larger than one word, if not, infinity loop begin!
char RunningThreads[8];
int WordCount;
pthread_mutex_t lock_WordCount;

typedef struct _thread_data_t {
    int tid;
    long startindex;
    long endindex;
    char* SearchWord;
    char *buffer;
} thread_data_t;

unsigned int string_search(long start, long end, char* target, char *buffer) {
    unsigned int i;
    unsigned int found=0;
    for (i=start;i <= end; i++)
        if (strncmp(&buffer[i],target,strlen(target))==0)
            found++;
    return found;
}
void *thr_func(void *arg) {
    thread_data_t *data = (thread_data_t *)arg;
    int found = string_search(data->startindex, data->endindex, data->SearchWord, data->buffer);
    pthread_mutex_lock(&lock_WordCount);
    WordCount = WordCount + found;
    pthread_mutex_unlock(&lock_WordCount);
    free(data->buffer);
    RunningThreads[data->tid] = 0;
    pthread_exit(NULL);
}

int main(int argc, char **argv) {

    clock_t start = clock();

    pthread_t thr[NUM_THREADS];
    int i, rc;
    thread_data_t thr_data[NUM_THREADS];
    int k = 0;
    for (k = 0; k < NUM_THREADS; ++k)
        RunningThreads[k] = 0;

    pthread_mutex_init(&lock_WordCount, NULL);

    FILE * pFile;
    long lSize;
    pFile = fopen ( FileName , "r" );
    if (pFile==NULL) {fputs ("File error",stderr); exit (1);}
    fseek (pFile , 0 , SEEK_END);
    lSize = ftell (pFile);
    rewind (pFile);
    long BufferSize = sizeof(char)*lSize;
    printf("Buffer index size %lu \n",BufferSize);

    int reverseoffset = 0;
    /* create threads */
    long endpoint = 0,startpoint = 0;
    while (1){
        char *buffer;
        startpoint = 0;
        endpoint = threadchucksize;
        buffer = (char*) malloc (sizeof(char)*threadchucksize);
        fseek (pFile , reverseoffset , SEEK_CUR);
        reverseoffset = 0;

        fread (buffer,1,threadchucksize,pFile);
        if (BufferSize <= threadchucksize)
            endpoint = BufferSize;
        else
            while (buffer[endpoint] != ' ' && buffer[endpoint] != '\n') {
                endpoint--;
                reverseoffset--;
            }
        BufferSize -= endpoint;
        int j = 0;
        while(1) {
            if (RunningThreads[j] == 0){
                thr_data[j].tid = j;
                thr_data[j].startindex = startpoint;
                thr_data[j].endindex = endpoint;
                thr_data[j].SearchWord = DefineWord;
                thr_data[j].buffer = buffer;
                RunningThreads[j] = 1;
                printf("GiveWorkToThread %d , startpoint %lu, endpoint %lu FromBufferSize %lu WordCount %d\n", j, startpoint, endpoint, BufferSize, WordCount);
                //getchar();

                if ((rc = pthread_create(&thr[j], NULL, thr_func, &thr_data[j]))) {
                    fprintf(stderr, "error: pthread_create, rc: %d\n", rc);
                    return EXIT_FAILURE;
                }
                break;
            }
            if (j == NUM_THREADS-1)
                j = 0;
            else
                j++;
        }
        if (BufferSize <= 0)
            break;
    }
    for (i = 0; i < NUM_THREADS; ++i) {
        pthread_join(thr[i], NULL);
    }
    fclose (pFile);
    clock_t end = clock();
    float seconds = (float)(end - start) / CLOCKS_PER_SEC;
    printf("Total Word Count : %d\n", WordCount);
    printf("Execution Time : %f second.\n", seconds);
    return EXIT_SUCCESS;
}