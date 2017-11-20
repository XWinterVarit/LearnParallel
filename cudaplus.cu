#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#define BLOCK_DIM 1024





__global__ void matrixAdd (int *a, int N) {
    //int row = blockIdx.x * blockDim.x + threadIdx.x;
    //int col = blockIdx.y * blockDim.y + threadIdx.y;


    int index = blockIdx.x * blockDim.x + threadIdx.x;

    if (index < N) {
        a[index] = index;
        //printf("Hello from blockidx %d  threadidx %d  index %d  a[index] %d \n", blockIdx.x, threadIdx.x, index, a[index]);

    }
    //if (row < N && col < N) {
    //*(a+index) = 5;
    //*(b+index) = 5;
    //    c[index] = a[index] + b[index];
    //}
}
int* createVector (int size, int inivalue) {
    int* vector = (int*) malloc(sizeof(int)*size);
    for (int i = 0; i < size; ++i) {
        vector[i] = inivalue;
    }
    return vector;
}
void readVector (int* vector, int size) {
    for (int i = 0; i < size; ++i) {
        printf("%d ",vector[i]);
    }
    printf("\n");
}
int main() {
    int dev = 0, driverVersion = 0, runtimeVersion = 0;

    cudaSetDevice(dev);
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp, dev);

    printf("\nDevice %d: \"%s\"\n", dev, deviceProp.name);

    // Console log
    cudaDriverGetVersion(&driverVersion);
    cudaRuntimeGetVersion(&runtimeVersion);
    printf("  CUDA Driver Version / Runtime Version          %d.%d / %d.%d\n", driverVersion/1000, (driverVersion%100)/10, runtimeVersion/1000, (runtimeVersion%100)/10);
    printf("  CUDA Capability Major/Minor version number:    %d.%d\n", deviceProp.major, deviceProp.minor);
    printf("  Total amount of constant memory:               %lu bytes\n", deviceProp.totalConstMem);
    printf("  Total amount of shared memory per block:       %lu bytes\n", deviceProp.sharedMemPerBlock);
    printf("  Total number of registers available per block: %d\n", deviceProp.regsPerBlock);
    printf("  Warp size:                                     %d\n", deviceProp.warpSize);
    printf("  Maximum number of threads per multiprocessor:  %d\n", deviceProp.maxThreadsPerMultiProcessor);
    printf("  Maximum number of threads per block:           %d\n", deviceProp.maxThreadsPerBlock);
    printf("  Max dimension size of a thread block (x,y,z): (%d, %d, %d)\n",
           deviceProp.maxThreadsDim[0],
           deviceProp.maxThreadsDim[1],
           deviceProp.maxThreadsDim[2]);
    printf("  Max dimension size of a grid size    (x,y,z): (%d, %d, %d)\n",
           deviceProp.maxGridSize[0],
           deviceProp.maxGridSize[1],
           deviceProp.maxGridSize[2]);








    //int* test = (int*) malloc(sizeof(int)*4);
    int sizeVector = 1024;
    int memsizeVector = sizeof(int) * sizeVector;
    int* Vector = createVector(sizeVector,2);
    readVector(Vector,sizeVector);
/*
    *(test) = 0;
    *(test+1) = 0;    *(test+2) = 0;

    for (int i = 0; i < 3; ++i) {
        printf("%d ", test[i]);
    }
    printf("\n");
*/

    int *dev_Vector;


    cudaMalloc((void**)&dev_Vector, memsizeVector);


    cudaMemcpy (dev_Vector, Vector, memsizeVector, cudaMemcpyHostToDevice);



    matrixAdd<<<1, BLOCK_DIM>>>(dev_Vector,sizeVector);
    cudaDeviceSynchronize();

    cudaMemcpy (Vector, dev_Vector, memsizeVector, cudaMemcpyDeviceToHost);
    cudaFree(dev_Vector);

    printf("---------------------------\n");


    readVector(Vector, sizeVector);

    printf("Calulate completed");
}

