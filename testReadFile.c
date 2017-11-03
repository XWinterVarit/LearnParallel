#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

int NUM_THREADS = 4;
char FileName[] = "a.txt";
char OutputFileName[] = "b.txt";
char DefineWord[] = "Cat";
long threadchucksize = 10; // Warning : Must larger than one word, if not, infinity loop begin!
char RunningThreads[8];
int WordCount;

unsigned int string_search(long start, long end, char* target, char *buffer) {
    unsigned int i;
    unsigned int found=0;
    //printf("Receiveing : target : %s  buffer : %s\n", target, buffer);
    //printf("My Buffer: ");
    //for (i=start;i <= end; i++)
    //    printf("%c", *(buffer+i));
    //printf("\n");
    for (i=start;i <= end; i++)
        if (strncmp(&buffer[i],target,strlen(target))==0) {
            //if (i <= overflowRegion)
                found++;
        }
    //printf("overflowRegion : %d\n", overflowRegion);
    //printf("Receiveing Found : %d\n", found);
    return found;
}
unsigned int string_search_rr(long start, long end, char* target, char *buffer,int overflowStringSize, char options) {
    unsigned int i;
    unsigned int found=0;
    //printf("Receiveing : target : %s  buffer : %s\n", target, buffer);
    //printf("My Buffer: ");
    //for (i=start;i <= end; i++)
    //    printf("%c", *(buffer+i));
    //printf("\n");
    for (i=start;i <= end; i++)
        if (strncmp(&buffer[i],target,strlen(target))==0) {
            //if (i <= overflowRegion)
            found++;
            //*(buffer+i) = '$';

            for (int j = i; j < i + overflowStringSize ; j++) {
                *(buffer+j) = '$';
            }
        }
    //printf("overflowRegion : %d\n", overflowRegion);
    //printf("Receiveing Found : %d\n", found);
    return found;
}
void cuda_stringsearch (long bufferstart, long bufferend, char* target, char* buffer, int* allcount, int overflowStringSize, int fakeindex) {
    long blocksize = 5;
    long extendblocksize = blocksize + overflowStringSize - 2;
    int index = fakeindex;
    long startpoint = index * blocksize;
    long endpoint = startpoint + blocksize  - 1;

    if (startpoint <= bufferend) {
        if (endpoint > bufferend)
            endpoint = bufferend;
        int count = string_search_rr(startpoint, endpoint,target, buffer, overflowStringSize, 'd');
        *allcount += count;
        printf("*******************************************************************************************************************\n");
        printf("Hello from fake threads : %d   startpoint : %ld   logical_endpoint : %ld    sending_endpoint : %ld    bufferend : %ld count : %d \n", index, startpoint, startpoint + extendblocksize, endpoint, bufferend, count);

        for (int i = startpoint; i <= startpoint + extendblocksize ; ++i) {
            printf("%c", *(buffer+i));
        }

        printf("||\n");
    }

}

int main(int argc, char **argv) {

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
    int overflowStringSize = sizeof(DefineWord)/ sizeof(char) - 1;
    printf("Overflow String size : %d\n", overflowStringSize);



    FILE * outputFile;
    long lSize2;
    outputFile = fopen(OutputFileName, "a");
    if (outputFile==NULL) {fputs ("File error",stderr); exit (1);}


    /*
     char** bufferArray = (char**)malloc(sizeof(char*)*20);
     char A[] = "aaa";
     char B[] = "bbb";
     char C[] = "ccc";
     char D[] = "ddd";
     char E[] = "eee";
     *(bufferArray+0) = A;
     *(bufferArray+1) = B;
     *(bufferArray+2) = C;
     *(bufferArray+3) = D;
     *(bufferArray+4) = E;
     for (int i = 0; i < 4; ++i) {
         printf("buff array : %s\n", *(bufferArray+i));
     }
 */
    int count = 0;
    int* countPTR = &count;
    int overflowRegion = threadchucksize - 1;
    while (1){
        char *buffer;
        startpoint = 0;
        endpoint = threadchucksize + overflowStringSize - 1;
        buffer = (char*) malloc (sizeof(char)*(threadchucksize + overflowStringSize));
        fseek (pFile , reverseoffset , SEEK_CUR);
        reverseoffset = -1 * (overflowStringSize - 1);

        fread (buffer,1,endpoint,pFile);
        if (BufferSize <= threadchucksize)
            endpoint = BufferSize;

        //int j = 0;
        //count += string_search(startpoint, endpoint, DefineWord, buffer);
        //printf("%s||| count : %d\n", buffer, count);
        //printf("-------\n");
        for (int i = 0; i < 1000; ++i) {
            cuda_stringsearch(startpoint, endpoint, DefineWord, buffer, countPTR, overflowStringSize, i);
        }
        printf("---------Buffer after changed----------------------------------------------------------------\n");
        endpoint = threadchucksize - 1;
        if (endpoint > BufferSize)
            endpoint = BufferSize;
        printf("startpoint : %ld     endpoint : %ld   BufferSize : %ld \n", startpoint, endpoint, BufferSize);
        //if (startpoint != endpoint) {
            for (int i=startpoint;i <= endpoint; i++) {
                printf("%c", *(buffer + i));
                if (*(buffer + i) != '\0')
                    fprintf(outputFile, "%c", *(buffer + i));
            }
            printf("\n");
        //}
        printf("-------------------------------------------------------------------------------------------\n");

        //fprintf(outputFile, "%s",buffer);
        BufferSize = BufferSize - threadchucksize;

        free(buffer);
        if (BufferSize <= 0)
            break;
    }
    printf("all count : %d \n", *countPTR);
    fclose (pFile);
    fclose (outputFile);
    return EXIT_SUCCESS;
}