#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define BLOCKDIM 1024
/*
#include <thrust/device_vector.h>
#include <thrust/reduce.h>
#include <thrust/functional.h>
#include <thrust/inner_product.h>
using namespace thrust;
using namespace thrust::placeholders;
*/
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////Important Configuration/////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

const char FileName[] = "01.nt"; // the file must have
const char OutputFileName[] = "b.txt"; // the file must have, but must be empty
const char QuestionFileName[] = "line1"; // the file must have


// Threadchucksize mean "Size" in byte of part of the file that will be sent to the gpu memory
// not worry about setting size higher than real file, because the program will auto adjust it
// Example , if your gpu memory limit at 500 MB but your file is large such as 5 GB , you should set threadchucksize to 500 * 1,000,000byte = 500,000,000
// and your part of file will be sent 5000 MB/500 MB = 10 times
// if you sent and found some memory error, it can be the os or other software use vram too, so decrease threadchucksize until no error, such as from 500,000,000 change to 200,000,000
// suggestion, you should set size as beautiful ten-end number as 100000, 20000000, 50000000
const long threadchucksize = 300000000;


// this Blocksize not mean thread per block but mean "size" of data chuck that each thread will compute from the big global data chuck (that locate in gpu)
// warning that allThreadInUse multiply with blocksize must higher than threadchucksize, if not it will incorrect result
// Example : if threadchucksize = 100,000,000 (aka 100MB. chuck of file sent to gpu) and allThreadInUse = 4096 and blocksize = 25000
// then you must check that 25000 * 4096 > 100000000 ? which is 102,400,000 > 100,000,000 so it true and can be use
// suggestion, you should set size as threadchucksize % blocksize = 0, it will be bug free.
const long blocksize = 10000;


const int NumberOfComputeBlock = 30; // aka gridsize
const int NumberOfThreadsPerBlock = 1024; //(rely on your gpu spec)

// allThreadInUse is all concurrent thread that run in the gpu,
// it can be higher than physical cuda core on gpu, because gpu can queue it and make you feel like it concurrent
// but if allThreadInUse is much higher, the answer vector that collect answer from each thread will be larger. so threadoff
const int allThreadInUse = NumberOfThreadsPerBlock * NumberOfComputeBlock;
const long sizeofAnswerVector = allThreadInUse;


const int sizeofQuestionArray = 2048; // maximum list size of question, such as = 2048 mean this program support maximum 2048 question
const int sizeofMaximumQuestionWord = 2048; // maximum string size of each question, such as = 2048 mean each question can't be larger than 2048 byte


/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////



int WordCount;
__device__ size_t d_strlen (const char *str)
{
    return (*str) ? d_strlen(++str) + 1 : 0;
}
__device__ int d_strncmp(const char *ptr0, const char *ptr1, size_t len)
{
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
__device__ unsigned int string_search_rr(long start, long end, char* target, char *buffer,int overflowStringSize, char options, char *changebuffer) {

    unsigned int i;
    unsigned int found=0;

    for (i=start;i <= end  ; i++) {
        int t = d_strncmp(&buffer[i], target, d_strlen(target));
        if (t == 0 ) {
            //if (i <= overflowRegion)
            found++;

            for (int j = i; j < i + d_strlen(target); ++j) {
                //printf("change at j : %d i : %d\n", j,i);
                *(changebuffer+j) = '$';
            }

        }

    }

    return found;
}
__global__ void cuda_stringsearch (long bufferstart, long bufferend, char* target, char* buffer, int* allcount, int overflowStringSize, long *answerVector, char* changebuffer) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    //printf("hello from thread %d\n", index);
/*  
  if (index == 1) {
        printf("GPU KERNEL :: Hello from threads %d  Given word %s  size %d \n", index, target, d_strlen(target));
    }
*/
    //printf("Hello from threads %d  Given word %s\n", index, target);

   // long blocksize = 500/*50000*/;
    long extendblocksize = blocksize + overflowStringSize - 2;
    long startpoint = index * blocksize;
    long endpoint = startpoint + blocksize  - 1;

    if (startpoint <= bufferend) {
        if (endpoint > bufferend)
            endpoint = bufferend;

        //int count = 10;
        int count = string_search_rr(startpoint, endpoint,target, buffer, overflowStringSize, 'd', changebuffer);
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

    time_t timestart = time(NULL);

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
    long* questionAnswer = (long*) malloc(sizeof(long)*sizeofQuestionArray); // found word list

    int questionCount = 0;
    for (int j = 0; j <= strlen(Question_Buffer); ++j) {
        end++;
        if (*(Question_Buffer+j) == '\n' || *(Question_Buffer+j) == '\0') {
            questionCount++;
            //piece = (char*) malloc(sizeof(char)*2048);
            //memcpy(piece, (Question_Buffer+start), end - start - 1);
            *(questionArray+questionCount) = (char*) malloc(sizeof(char)*sizeofAnswerVector);
            memcpy(*(questionArray+questionCount), (Question_Buffer+start), end - start - 1);
            *(questionAnswer+questionCount) = 0; /* each question start founded = zero */               /*(long) strlen(*(questionArray+questionCount)) this commented code use to check if for loop work!*/
            if (strlen(*(questionArray+questionCount)) > Question_maxLength)
                Question_maxLength = strlen(*(questionArray+questionCount));
            //printf("print piece %s|||\n", *(questionArray+questionCount));
            //printf("piece length : %lu \n", strlen(*(questionArray+questionCount)));
            start = end;

        }
    }
/*
    for (int k = 1; k <= questionCount; ++k) {
        printf("element at : %d is : %s value is : %lu  length is %zu\n",  k, *(questionArray+k), *(questionAnswer+k), strlen(*(questionArray+k)));
    }
*/
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
        char *dev_changebuffer;
        int *dev_countPTR;
        //char *dev_defineword;
        //long *dev_answerVector;

        cudaMalloc((void**)&dev_buffer, sizeof(char)*(threadchucksize + overflowStringSize));
        cudaMalloc((void**)&dev_changebuffer, sizeof(char)*(threadchucksize + overflowStringSize));
        cudaMalloc((void**)&dev_countPTR, sizeof(int));

        cudaMemcpy(dev_buffer, buffer, sizeof(char)*(threadchucksize + overflowStringSize), cudaMemcpyHostToDevice);
        cudaMemcpy(dev_changebuffer, buffer, sizeof(char)*(threadchucksize + overflowStringSize), cudaMemcpyHostToDevice);

        cudaMemcpy(dev_countPTR, countPTR, sizeof(int),cudaMemcpyHostToDevice);

        for (int question = 1; question <= questionCount; ++question) {
        //int question = 1;
            long size_answerVector = sizeofAnswerVector;
            long* answerVector = createVector(size_answerVector,0);
	    char *dev_defineword;
	    long *dev_answerVector;

//	    printf("HOST :: starting iteration %d at question : %s  string length : %zu\n",question, *(questionArray+question),  strlen(*(questionArray+question)));
/*		for (int d = 0; d < strlen(*(questionArray+question)); d++) {
			printf("%c",*(*(questionArray+question)+d));
		}
		printf("\nend test \n");*/
            cudaMalloc((void**)&dev_answerVector, sizeof(long)*size_answerVector);
            cudaMalloc((void**)&dev_defineword, /*sizeof(char)**/ sizeofMaximumQuestionWord/*strlen(*(questionArray+question))*/);

            cudaMemcpy(dev_answerVector, answerVector, sizeof(long)*size_answerVector, cudaMemcpyHostToDevice);
            cudaMemcpy(dev_defineword, *(questionArray+question), /*sizeof(char)**/ sizeofMaximumQuestionWord /*strlen(*(questionArray+question))*/, cudaMemcpyHostToDevice);
            //printf("iteration at question : %s\n", *(questionArray+question));

            cuda_stringsearch<<<NumberOfComputeBlock,NumberOfThreadsPerBlock>>>(startpoint, endpoint, dev_defineword, dev_buffer, dev_countPTR, overflowStringSize, dev_answerVector, dev_changebuffer);
            cudaDeviceSynchronize();
            cudaMemcpy (answerVector, dev_answerVector, sizeof(long)*size_answerVector, cudaMemcpyDeviceToHost);

            cudaFree(dev_answerVector);
            cudaFree(dev_defineword);
	    
            //readVector(answerVector, size_answerVector); //uncomment this to diagnostic answer vector matrix
            long iterationsum =  sumVector(answerVector, size_answerVector);

            *(questionAnswer+question) += iterationsum;

            printf("HOST :: Finish iteration %d at question : %s  temporary founded %ld\n\n",question, *(questionArray+question),  iterationsum);
            free(answerVector);
        }


        gpuErrchk( cudaPeekAtLastError() );
        gpuErrchk( cudaDeviceSynchronize() );

        cudaMemcpy (buffer, dev_changebuffer,sizeof(char)*(threadchucksize + overflowStringSize),cudaMemcpyDeviceToHost);
        //cudaMemcpy (countPTR, dev_countPTR, sizeof(int), cudaMemcpyDeviceToHost);
        cudaFree(dev_buffer); cudaFree(dev_countPTR); cudaFree(dev_changebuffer);

        printf("---------saving change buffered----------------------------------------------------------------\n");
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
        printf("element at : %d is : %s finally founded : %lu\n",  k, *(questionArray+k), *(questionAnswer+k));
    }
    fclose (pFile);
    fclose (outputFile);

    printf("\nestimate using time : %.2f\n", (double)(time(NULL) - timestart));

    return EXIT_SUCCESS;
}
