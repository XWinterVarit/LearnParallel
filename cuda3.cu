#include <iostream>
#include <thrust/device_vector.h>
#include <thrust/reduce.h>
#include <thrust/functional.h>
#include <thrust/inner_product.h>
using namespace thrust;
using namespace thrust::placeholders;


unsigned int string_search(long start, long end, char* target, char *buffer) {
    unsigned int i;
    unsigned int found=0;
    for (i=start;i <= end; i++)
        if (strncmp(&buffer[i],target,strlen(target))==0)
            found++;
    return found;
}

int main(int argc, char* argv[])
{
    char FileName[256];
    char DefineWord[256];
    long threadchucksize = 100000;
    printf("Enter a file name: ");
    scanf("%s", FileName);
    printf("Word to search: ");
    scanf("%s", DefineWord);

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
        int bufferarraycount = 0;
        char* bufferArray[200];
        for (int i = 0; i < 200; ++i) {





        }
        
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
        
        
        
        if (BufferSize <= 0)
            break;
    }

    fclose (pFile);

}