#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#define BLOCK_DIM 32
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}


__global__ void matrixAdd (int *a, int *b, int *c);

// Random
void swap_int(int* a, int* b){ int tmp = *a; *a=*b; *b=tmp; }

int rand_int_hi_lo(int upper, int lower){
    return((rand() % (upper-lower+1)) + lower);
}

int rand_int(int a,int b)
{
    if (b > a) swap_int(&a,&b);
    return rand_int_hi_lo(a,b);
}
// End of Random

int* createMatrix (int row, int column) {
    return  (int*) malloc(sizeof(int) * row * column);
}
void generateValue_Matrix(int* Matrix, int rowsize, int columnsize, char options, int predata[20][20]){
    for (int inrow = 0; inrow < rowsize; inrow++) {
        for (int incolumn = 0; incolumn < columnsize; incolumn++) {
            switch (options) {
                case 's':
                    *(Matrix+inrow+(incolumn*rowsize)) = 0;
                    break;
                case 'p':
                    *(Matrix+inrow+(incolumn*rowsize)) = predata[inrow][incolumn];
                    break;
                case 'r':
                    *(Matrix+inrow+(incolumn*rowsize)) = rand_int(1,9);
                    break;
            }
        }
    }
}
void printMatrixM(int* Matrix, int rowsize, int columnsize) {
    for (int inrow = 0; inrow < rowsize; inrow++) {
        for (int incolumn = 0; incolumn < columnsize; incolumn++) {
            printf("%d ", *(Matrix+inrow+(incolumn*rowsize)));
        }
        printf("\n");
    }
}
__global__ void multiplication_Matrix (int *matrixA, int *matrixB, int *matrixC, int matrixA_rowsize, int matrixA_columnsize, int matrixB_rowsize, int matrixB_columnsize) {
    int matrixAnswer_rowsize = matrixA_rowsize;
    int matrixAnswer_columnsize = matrixB_columnsize;

    int row = blockIdx.x * blockDim.x + threadIdx.x;
    int col = blockIdx.y * blockDim.y + threadIdx.y;

    if (row < matrixAnswer_rowsize && col < matrixAnswer_columnsize) {
        int answer = 0;
        for (int incolumn_MatrixA = 0; incolumn_MatrixA < matrixA_columnsize; incolumn_MatrixA++) {
            answer += *(matrixA+row+(incolumn_MatrixA*matrixA_rowsize)) * *(matrixB+incolumn_MatrixA+(col*matrixB_rowsize));
        }
        *(matrixC+row+(col*matrixAnswer_rowsize)) = answer;
    }
}

int main() {
    time_t timestart = time(NULL);
    int matrixA_rowsize = 10000;
    int matrixA_columnsize = 10000;
    int matrixB_rowsize = 10000;
    int matrixB_columnsize = 10000;
    int matrixC_rowsize = matrixA_rowsize;
    int matrixC_columnsize = matrixB_columnsize;

    int* MatrixA = createMatrix(matrixA_rowsize,matrixA_columnsize);
    int* MatrixB = createMatrix(matrixB_rowsize,matrixB_columnsize);
    int* MatrixC = createMatrix(matrixC_rowsize,matrixC_columnsize);


    //int mA[20][20] = {{2,1,1,1,1},{1,1,1,1,1},{1,1,1,1,1},{1,1,1,1,1},{1,1,1,1,1}};
    //int mB[20][20] = {{1,1,1,1,1},{1,1,1,1,1},{1,1,1,1,1},{1,1,1,1,1},{1,1,1,1,5}};

    int mA[20][20] = {{3,4,2}};
    int mB[20][20] = {{13,9,7,15},{8,7,4,6},{6,4,0,3}};

    generateValue_Matrix(MatrixA,matrixA_rowsize,matrixA_columnsize,'r', mA);
    generateValue_Matrix(MatrixB,matrixB_rowsize,matrixB_columnsize,'r', mB);

    //printMatrixM(MatrixA,matrixA_rowsize, matrixA_columnsize);
    //printMatrixM(MatrixB,matrixB_rowsize, matrixB_columnsize);

    printf("Generate value completed!\n");
    int *dev_MatrixA, *dev_MatrixB, *dev_MatrixC;
    int size_MatrixA = matrixA_rowsize * matrixA_columnsize * sizeof(int);
    int size_MatrixB = matrixB_rowsize * matrixB_columnsize * sizeof(int);
    int size_MatrixC = matrixC_rowsize * matrixC_columnsize * sizeof(int);

    cudaMalloc((void**)&dev_MatrixA, size_MatrixA);
    cudaMalloc((void**)&dev_MatrixB, size_MatrixB);
    cudaMalloc((void**)&dev_MatrixC, size_MatrixC);

    cudaMemcpy (dev_MatrixA, MatrixA, size_MatrixA, cudaMemcpyHostToDevice);
    cudaMemcpy (dev_MatrixB, MatrixB, size_MatrixB, cudaMemcpyHostToDevice);

    dim3 dimBlock (BLOCK_DIM, BLOCK_DIM);
    dim3 dimGrid ((int)ceil((matrixC_rowsize*1.0)/dimBlock.x),(int)ceil((matrixC_columnsize*1.0)/dimBlock.y));
    printf("thread per block is : %d\n", BLOCK_DIM*BLOCK_DIM);
    printf("block per grid is : %d , %d\n", (int)ceil((matrixC_rowsize*1.0)/dimBlock.x),(int)ceil((matrixC_columnsize*1.0)/dimBlock.y));

    multiplication_Matrix<<<dimGrid, dimBlock>>>(dev_MatrixA, dev_MatrixB, dev_MatrixC, matrixA_rowsize, matrixA_columnsize, matrixB_rowsize, matrixB_columnsize);
    cudaDeviceSynchronize();
    gpuErrchk( cudaPeekAtLastError() );
    gpuErrchk( cudaDeviceSynchronize() );

    //cudaMemcpy (MatrixA, dev_MatrixA, size, cudaMemcpyDeviceToHost);
    //cudaMemcpy (MatrixB, dev_MatrixB, size, cudaMemcpyDeviceToHost);
    //cudaMemcpy (MatrixC, dev_MatrixC, size_MatrixC, cudaMemcpyDeviceToHost);
    cudaFree(dev_MatrixA); cudaFree(dev_MatrixB); cudaFree(dev_MatrixC);

    printf("---------------------------\n");

    //printMatrixM(MatrixA,matrixA_rowsize, matrixA_columnsize);
    //printMatrixM(MatrixB,matrixB_rowsize, matrixB_columnsize);

    //printMatrixM(MatrixC,matrixC_rowsize, matrixC_columnsize);
    printf("Calulate completed\n");
    printf("\nestimate using time : %.5f\n", (double)(time(NULL) - timestart));

}

__global__ void matrixAdd (int *a, int *b, int *c) {
    //int row = blockIdx.x * blockDim.x + threadIdx.x;
    //int col = blockIdx.y * blockDim.y + threadIdx.y;

    //int index = row + col * N;

    //if (row < N && col < N) {
        //*(a+index) = 5;
        //*(b+index) = 5;
    //    c[index] = a[index] + b[index];
    //}
}