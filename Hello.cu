#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
__global__ void hello (int receive) {
    int index = threadIdx.x;
    printf("Hello from thread : %d with receive value : %d\n", index, receive);
}
int main(int argc, char **argv) {
    printf("well\n");
    hello<<<1,2>>>(5);
    cudaDeviceSynchronize();
    return 0;
}