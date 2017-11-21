#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

int NUM_THREADS = 4;
char FileName[] = "a.txt";
char QuestionFileName[] = "q.txt";
char OutputFileName[] = "b.txt";
char DefineWord[] = "Cat";
long threadchucksize = 50; // Warning : Must larger than one word, if not, infinity loop begin!
char RunningThreads[8];
int WordCount;

char* d_strcat( char* dest, char* src )
{
    while (*dest) dest++;
    while (*dest++ == *src++);
    return --dest;
}


int d_strncmp(const char *ptr0, const char *ptr1, size_t len)
{
    int fast = len/sizeof(size_t) + 1;
    int offset = (fast-1)*sizeof(size_t);
    int current_block = 0;

    if( len <= sizeof(size_t)){ fast = 0; }


    size_t *lptr0 = (size_t*)ptr0;
    size_t *lptr1 = (size_t*)ptr1;

    while( current_block < fast ){
        if( (lptr0[current_block] ^ lptr1[current_block] )){
            int pos;
            for(pos = current_block*sizeof(size_t); pos < len ; ++pos ){
                if( (ptr0[pos] ^ ptr1[pos]) || (ptr0[pos] == 0) || (ptr1[pos] == 0) ){
                    return  (int)((unsigned char)ptr0[pos] - (unsigned char)ptr1[pos]);
                }
            }
        }

        ++current_block;
    }

    while( len > offset ){
        if( (ptr0[offset] ^ ptr1[offset] )){
            return (int)((unsigned char)ptr0[offset] - (unsigned char)ptr1[offset]);
        }
        ++offset;
    }


    return 0;
}

unsigned int string_search(long start, long end, char* target, char *buffer) {
    unsigned int i;
    unsigned int found=0;
    //printf("Receiveing : target : %s  buffer : %s\n", target, buffer);
    //printf("My Buffer: ");
    //for (i=start;i <= end; i++)
    //    printf("%c", *(buffer+i));
    //printf("\n");
    for (i=start;i <= end; i++)
        if (d_strncmp(&buffer[i],target,strlen(target))==0) {
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
        if (d_strncmp(&buffer[i],target,strlen(target))==0) {
            //if (i <= overflowRegion)
            found++;
            //printf("found at i : %d\n", i);
            for (int j = i; j < i + strlen(target); ++j) {
                //printf("change at j : %d i : %d\n", j,i);
                *(buffer+j) = '$';
            }
        }
    //printf("overflowRegion : %d\n", overflowRegion);
    //printf("Receiveing Found : %d\n", found);
    return found;




/*
    int found = 0;
    for (long i = start; i < end +1 ; i++) {
        int charfail = 0;
        int wordindex = 0;
        //printf("show string : str1 : %c     word :  \n", *(buffer+i));


        for (int j = i; j < i + overflowStringSize && j < end + 1; ++j) {
            //printf("show string : str1 : %c     word : %c \n", *(buffer+j), *(target+wordindex));

            if (*(buffer+j) != *(target+wordindex))
                charfail = 1;

            wordindex++;
        }

        if (charfail == 0)
            found++;
        //printf("cal found : %d\n", found);
        //printf("----\n");

    }
    //printf("overflowRegion : %d\n", overflowRegion);
    //printf("Receiveing Found : %d\n", found);
    return found;
    */
}
void cuda_stringsearch (long bufferstart, long bufferend, char* target, char* buffer, int* allcount, int overflowStringSize, int fakeindex /*,char* questionBuffer*/) {
    long blocksize = 10;
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
/*
        for (int i = startpoint; i <= startpoint + extendblocksize ; ++i) {
            printf("%c", *(buffer+i));
        }

        printf("||\n");
        */
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

    FILE * questionFile;
    long lSizeQ;
    questionFile = fopen(QuestionFileName, "r");
    if (questionFile == NULL) {fputs ("File error", stderr); exit(1);}
    fseek(questionFile, 0, SEEK_END);
    lSizeQ = ftell(questionFile);
    rewind(questionFile);
    long QuestionBufferSize = sizeof(char)*lSizeQ;
    printf("Question Buffer index size %lu \n", QuestionBufferSize);
    char *Question_Buffer = (char*) malloc (lSizeQ);
    fread(Question_Buffer, 1, QuestionBufferSize, questionFile);
    printf("This is question file --------\n");

    //printf("%s\n", Question_Buffer);


    long start = 0, end = 0;
    int Question_maxLength = 0;
    char** questionArray = (char**) malloc(sizeof(char*)*2048);
    long* questionAnswer = (long*) malloc(sizeof(long)*2048);

    int questionCount = 0;
    for (int j = 0; j <= strlen(Question_Buffer); ++j) {
        end++;
        if (*(Question_Buffer+j) == '\n' || *(Question_Buffer+j) == '\0') {
            questionCount++;
            //piece = (char*) malloc(sizeof(char)*2048);
            //memcpy(piece, (Question_Buffer+start), end - start - 1);
            *(questionArray+questionCount) = (char*) malloc(sizeof(char)*2048);
            memcpy(*(questionArray+questionCount), (Question_Buffer+start), end - start - 1);
            *(questionAnswer+questionCount) = 0;
            if (strlen(*(questionArray+questionCount)) > Question_maxLength)
                Question_maxLength = strlen(*(questionArray+questionCount));
            //printf("print piece %s|||\n", *(questionArray+questionCount));
            //printf("piece length : %lu \n", strlen(*(questionArray+questionCount)));
            start = end;

        }
    }

    for (int k = 1; k <= questionCount; ++k) {
        printf("element at : %d is : %s value is : \n",  k, *(questionArray+k));
    }

    printf("Question max length : %d\n", Question_maxLength);
    printf("Question elements count : %d\n", questionCount);
    free(Question_Buffer);
    printf("This is question file --------\n");


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
/*
        //printf("---------Buffer after changed----------------------------------------------------------------\n");
        endpoint = threadchucksize - 1;
        if (endpoint > BufferSize)
            endpoint = BufferSize;
        //printf("startpoint : %ld     endpoint : %ld   BufferSize : %ld \n", startpoint, endpoint, BufferSize);
        //if (startpoint != endpoint) {
            for (int i=startpoint;i <= endpoint; i++) {
                printf("%c", *(buffer + i));
                if (*(buffer + i) != '\0')
                    fprintf(outputFile, "%c", *(buffer + i));
            }
            printf("\n");
        //}
        printf("-------------------------------------------------------------------------------------------\n");
*/
        //fprintf(outputFile, "%s",buffer);
        BufferSize = BufferSize - threadchucksize;

        free(buffer);
        if (BufferSize <= 0)
            break;
    }
    printf("all count : %d \n", *countPTR);
    fclose (pFile);
    fclose (outputFile);
    return 0;
}