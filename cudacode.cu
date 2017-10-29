#include "stdio.h"
#include "stdlib.h"

__global__ void VecAdd(float* A, float* B, float* C, int N)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    if (i < N)
        C[i] = A[i] + B[i];
}
void array_print(float* array, int size) {
    for (int i = 0; i < size; i++) {
        printf("%f ", *(array+i));
    }
    printf("\n");
}
int main()
{
    int N = 3;
    size_t size = N * sizeof(float);
    float* h_A = (float*)malloc(size);
    float* h_B = (float*)malloc(size);
    float* h_C = (float*)malloc(size);

    *(h_A) = 2;
    *(h_A+1) = 4;
    *(h_A+2) = 6;

    *(h_B) = 2;
    *(h_B+1) = 4;
    *(h_B+2) = 6;

    float* d_A;
    cudaMalloc(&d_A, size);
    float* d_B;
    cudaMalloc(&d_B, size);
    float* d_C;
    cudaMalloc(&d_C, size);

    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

    int threadPerBlock = 1024;
    int blockPerGrid = (N + threadPerBlock - 1) / threadPerBlock;
    VecAdd<<<blockPerGrid, threadPerBlock>>>(d_A,d_B,d_C, N);

    cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);
    // Free device memory
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);



    array_print(h_A,3);
    array_print(h_B,3);
    array_print(h_C,3);
}