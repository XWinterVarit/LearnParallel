#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BLOCKDIM 1024
#include <thrust/device_vector.h>
#include <thrust/reduce.h>
#include <thrust/functional.h>
#include <thrust/inner_product.h>
using namespace thrust;
using namespace thrust::placeholders;
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

const char FileName[] = "01.nt";
const char OutputFileName[] = "b.txt";
const char QuestionFileName[] = "q.txt";
//char DefineWord[] = "http://www.w3.org/2001/XMLSchema#string";
//char DefineWord[] = "a";

const long threadchucksize = 100000000; // threadchucksize / blocksize "must" <= size of answer vector ,aka file read buffer size 200 MB each
const long blocksize = 25000;

const int sizeofQuestionArray = 2048;
const int sizeofMaximumQuestionWord = 2048;

const long sizeofAnswerVector = 4096; // number of blocks * thread per block
const int NumberOfComputeBlock = 4;
const int NumberOfThreadsPerBlock = 1024;




int WordCount;
__device__ size_t d_strlen (const char *str)
{
    return (*str) ? d_strlen(++str) + 1 : 0;
}
__device__ int d_strncmp(const char *ptr0, const char *ptr1, size_t len)
{
/*
    printf("print test.....  ");
    for (int i = 0; i < len; ++i) {
        printf("%c", *(ptr1+i));
    }
    printf("\n--");*/

    //printf("%s \n", ptr1);
/*

    int fast = len/sizeof(size_t) + 1;
    int offset = (fast-1)*sizeof(size_t);
    int current_block = 0;

    if( len <= sizeof(size_t)){ fast = 0; }


    size_t *lptr0 = (size_t*)ptr0;
    size_t *lptr1 = (size_t*)ptr1;

    while( current_block < fast ){
        if( (*(lptr0+current_block) ^ *(lptr1+current_block) )){
            int pos;

            for(pos = current_block*sizeof(size_t); pos < len ; ++pos ){
                if( (  *(ptr0+pos) ^ *(ptr1+pos)   ) || (  *(ptr0+pos) == 0) || (  *(ptr1+pos) == 0) ){
                    return  (int)((unsigned char) *(ptr0+pos) - (unsigned char) *(ptr1+pos));
                }
            }

        }

        ++current_block;
    }

    while( len > offset ){

        if( (  *(ptr0+offset) ^ *(ptr1+offset) )){
            return (int)((unsigned char) *(ptr0+offset) - (unsigned char) *(ptr1+offset));
        }
        ++offset;
    }
    return 0;
*/
/*
        for(; *ptr0 == *ptr1; ++ptr0, ++ptr1)
            if(*ptr0 == 0)
                return 0;
        return *(unsigned char *)ptr0 < *(unsigned char *)ptr1 ? -1 : 1;
*/
    while(len--)
        if(*ptr0++!=*ptr1++)
            return *(unsigned char*)(ptr0 - 1) - *(unsigned char*)(ptr1 - 1);
    return 0;


}
__device__ unsigned int string_search(long start, long end, char* target, char *buffer) {
    unsigned int i;
    unsigned int found=0;
    //printf("Receiveing : target : %s  buffer : %s\n", target, buffer);
    //printf("My Buffer: ");
    //for (i=start;i <= end; i++)
    //    printf("%c", *(buffer+i));
    //printf("\n");
    for (i=start;i <= end; i++) {
        int t = d_strncmp(&buffer[i], target, d_strlen(target));
        //printf("t dkmfdsfdfdspfdsfpodsfjkdpsof: %d \n", t);
        if (t == 0) {
            //if (i <= overflowRegion)
            found++;
        }
    }
    //printf("overflowRegion : %d\n", overflowRegion);
    //printf("Receiveing Found : %d\n", found);
    return found;
}
__device__ unsigned int string_search_rr(long start, long end, char* target, char *buffer,int overflowStringSize, char options) {

    unsigned int i;
    unsigned int found=0;

    for (i=start;i <= end  ; i++) {
        int t = d_strncmp(&buffer[i], target, d_strlen(target));
        if (t == 0 ) {
            //if (i <= overflowRegion)
            found++;

            for (int j = i; j < i + d_strlen(target); ++j) {
                //printf("change at j : %d i : %d\n", j,i);
                *(buffer+j) = '$';
            }

        }

    }

    return found;
}
__global__ void cuda_stringsearch (long bufferstart, long bufferend, char* target, char* buffer, int* allcount, int overflowStringSize, long *answerVector) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    //printf("hello from thread %d\n", index);
    //printf("Hello from threads %d  Given word %s\n", index, target);

   // long blocksize = 500/*50000*/;
    long extendblocksize = blocksize + overflowStringSize - 2;
    long startpoint = index * blocksize;
    long endpoint = startpoint + blocksize  - 1;

    if (startpoint <= bufferend) {
        if (endpoint > bufferend)
            endpoint = bufferend;

        //int count = 10;
        int count = string_search_rr(startpoint, endpoint,target, buffer, overflowStringSize, 'd');
        //printf("threads %d count %d  getting data :  startpoint %ld  endpoint %ld  overflowStringSize %d\n", index,count,startpoint, endpoint, overflowStringSize);
        *(answerVector + index) = count;
        //*allcount += count;
    }

}

long* createVector (long size, long inivalue) {
    long* vector = (long*) malloc(sizeof(long)*size);
    for (long i = 0; i < size; ++i) {
        vector[i] = inivalue;
    }
    return vector;
}
void readVector (long* vector, long size) {
    for (long i = 0; i < size; ++i) {
        printf("%ld ",vector[i]);
    }
    printf("\n");
}
long sumVector (long* vector, long size) {
    long sum = 0;
    for (long i = 0; i < size; ++i) {
        sum+= vector[i];
    }
    return sum;
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
    char** questionArray = (char**) malloc(sizeof(char*)*sizeofQuestionArray);
    long* questionAnswer = (long*) malloc(sizeof(long)*sizeofQuestionArray);

    int questionCount = 0;
    for (int j = 0; j <= strlen(Question_Buffer); ++j) {
        end++;
        if (*(Question_Buffer+j) == '\n' || *(Question_Buffer+j) == '\0') {
            questionCount++;
            //piece = (char*) malloc(sizeof(char)*2048);
            //memcpy(piece, (Question_Buffer+start), end - start - 1);
            *(questionArray+questionCount) = (char*) malloc(sizeof(char)*sizeofAnswerVector);
            memcpy(*(questionArray+questionCount), (Question_Buffer+start), end - start - 1);
            *(questionAnswer+questionCount) = 0/*(long) strlen(*(questionArray+questionCount))*/;
            if (strlen(*(questionArray+questionCount)) > Question_maxLength)
                Question_maxLength = strlen(*(questionArray+questionCount));
            //printf("print piece %s|||\n", *(questionArray+questionCount));
            //printf("piece length : %lu \n", strlen(*(questionArray+questionCount)));
            start = end;

        }
    }

    for (int k = 1; k <= questionCount; ++k) {
        printf("element at : %d is : %s value is : %lu\n",  k, *(questionArray+k), *(questionAnswer+k));
    }

    printf("Question max length : %d\n", Question_maxLength);
    printf("Question elements count : %d\n", questionCount);
    free(Question_Buffer);
    printf("This is question file --------\n");

    int overflowStringSize = Question_maxLength /*- 1*/;
    printf("Overflow String size : %d\n", overflowStringSize);



    FILE * outputFile;
    long lSize2;
    outputFile = fopen(OutputFileName, "a");
    if (outputFile==NULL) {fputs ("File error",stderr); exit (1);}


    int count = 0;
    int* countPTR = &count;
    int overflowRegion = threadchucksize - 1;
    while (1){
        //printf("precount  all count %d\n", count);

        char *buffer;
        startpoint = 0;
        endpoint = threadchucksize + overflowStringSize - 1;
        buffer = (char*) malloc (sizeof(char)*(threadchucksize + overflowStringSize));
        fseek (pFile , reverseoffset , SEEK_CUR);
        reverseoffset = -1 * (overflowStringSize - 1);

        fread (buffer,1,endpoint,pFile);
        if (BufferSize <= threadchucksize)
            endpoint = BufferSize;
        printf("This will send buffer start at %ld to %ld of all %ld\n", startpoint, endpoint, BufferSize);

        //int j = 0;
        //count += string_search(startpoint, endpoint, DefineWord, buffer);
        //printf("%s||| count : %d\n", buffer, count);
        //printf("-------\n");




        char *dev_buffer;
        int *dev_countPTR;
        char *dev_defineword;
        long *dev_answerVector;

        cudaMalloc((void**)&dev_buffer, sizeof(char)*(threadchucksize + overflowStringSize));
        cudaMalloc((void**)&dev_countPTR, sizeof(int));

        cudaMemcpy(dev_buffer, buffer, sizeof(char)*(threadchucksize + overflowStringSize), cudaMemcpyHostToDevice);
        cudaMemcpy(dev_countPTR, countPTR, sizeof(int),cudaMemcpyHostToDevice);

        for (int question = 1; question <= questionCount; ++question) {
        //int question = 1;
            long size_answerVector = sizeofAnswerVector;
            long* answerVector = createVector(size_answerVector,0);
            cudaMalloc((void**)&dev_answerVector, sizeof(long)*size_answerVector);
            cudaMalloc((void**)&dev_defineword, sizeof(*(questionArray+question)));

            cudaMemcpy(dev_answerVector, answerVector, sizeof(long)*size_answerVector, cudaMemcpyHostToDevice);
            cudaMemcpy(dev_defineword, *(questionArray+question), sizeof(*(questionArray+question)), cudaMemcpyHostToDevice);
            //printf("iteration at question : %s\n", *(questionArray+question));

            cuda_stringsearch<<<NumberOfComputeBlock,NumberOfThreadsPerBlock>>>(startpoint, endpoint, dev_defineword, dev_buffer, dev_countPTR, overflowStringSize, dev_answerVector);
            cudaDeviceSynchronize();
            cudaMemcpy (answerVector, dev_answerVector, sizeof(long)*size_answerVector, cudaMemcpyDeviceToHost);

            cudaFree(dev_answerVector);
            cudaFree(dev_defineword);

            //readVector(answerVector, size_answerVector);
            long iterationsum =  sumVector(answerVector, size_answerVector);

            *(questionAnswer+question) += iterationsum;

            //printf("iteration at question : %s   founded %ld\n", *(questionArray+question),  iterationsum);
            free(answerVector);
        }


        gpuErrchk( cudaPeekAtLastError() );
        gpuErrchk( cudaDeviceSynchronize() );

        cudaMemcpy (buffer, dev_buffer,sizeof(char)*(threadchucksize + overflowStringSize),cudaMemcpyDeviceToHost);
        //cudaMemcpy (countPTR, dev_countPTR, sizeof(int), cudaMemcpyDeviceToHost);
        cudaFree(dev_buffer); cudaFree(dev_countPTR);

        printf("---------saveing change buffered----------------------------------------------------------------\n");
        endpoint = threadchucksize - 1;
        if (endpoint > BufferSize)
            endpoint = BufferSize;
        //printf("startpoint : %ld     endpoint : %ld   BufferSize : %ld \n", startpoint, endpoint, BufferSize);
        for (int i=startpoint;i <= endpoint; i++) {
            if (*(buffer + i) != '\0' && *(buffer + i) != '$' )
                fprintf(outputFile, "%c", *(buffer + i));
            //printf("%c", *(buffer + i));
        }
        printf("\n");

        printf("-------------------------------------------------------------------------------------------\n");

        //fprintf(outputFile, "%s",buffer);

        BufferSize = BufferSize - threadchucksize;

        free(buffer);
        if (BufferSize <= 0)
            break;
    }
    for (int k = 1; k <= questionCount; ++k) {
        printf("element at : %d is : %s value is : %lu\n",  k, *(questionArray+k), *(questionAnswer+k));
    }
    fclose (pFile);
    fclose (outputFile);
    return EXIT_SUCCESS;
}