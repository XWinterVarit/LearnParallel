#include <stdio.h>
#include <stdlib.h>
#include <time.h>

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
                    *(Matrix+inrow+(incolumn*rowsize)) = rand_int(10,99);
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
int* multiplication_Matrix (int* matrixA,int matrixA_rowsize, int matrixA_columnsize, int* matrixB, int matrixB_rowsize, int matrixB_columnsize) {
    int matrixAnswer_rowsize = matrixA_rowsize;
    int matrixAnswer_columnsize = matrixB_columnsize;
    int* MatrixAnswer = createMatrix(matrixAnswer_rowsize,matrixAnswer_columnsize);
    for (int inrow = 0; inrow < matrixAnswer_rowsize; inrow++) {
        printf("iteration : %d of %d\n", inrow, matrixA_rowsize);
        for (int incolumn = 0; incolumn < matrixAnswer_columnsize; incolumn++) {
            int answer = 0;
            /*
            char s;
            printf("Wait to press \n");
            fgets(&s, 1, stdin);
            */
            //printf("%d ", AnswerMatrix[inrow][incolumn]);

            for (int incolumn_MatrixA = 0; incolumn_MatrixA < matrixA_columnsize; incolumn_MatrixA++) {
                answer += *(matrixA+inrow+(incolumn_MatrixA*matrixA_rowsize)) * *(matrixB+incolumn_MatrixA+(incolumn*matrixB_rowsize));
            }
            *(MatrixAnswer+inrow+(incolumn*matrixAnswer_rowsize)) = answer;
        }
        //printf("\n");
    }
    return MatrixAnswer;
}
int main(int argc, char *argv[]) {
    time_t start = time(NULL);
    int matrixA_rowsize = 2000;
    int matrixA_columnsize = 2000;
    int matrixB_rowsize = 2000;
    int matrixB_columnsize = 2000;
    int matrixAnswer_rowsize = matrixA_rowsize;
    int matrixAnswer_columnsize = matrixB_columnsize;

    int* MatrixA = createMatrix(matrixA_rowsize,matrixA_columnsize);
    int* MatrixB = createMatrix(matrixB_rowsize,matrixB_columnsize);


    int mA[20][20] = {{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10},{1,2,3,4,5,6,7,8,9,10}};
    int mB[20][20] = {{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0},{11,22,33,44,55,66,77,88,99,0}};

    generateValue_Matrix(MatrixA,matrixA_rowsize,matrixA_columnsize,'r', mA);
    generateValue_Matrix(MatrixB,matrixB_rowsize,matrixB_columnsize,'r', mB);
    //printMatrixM(MatrixA,matrixA_rowsize,matrixA_columnsize);
    //printMatrixM(MatrixB,matrixB_rowsize,matrixB_columnsize);

    int* AnswerMatrix = multiplication_Matrix(MatrixA, matrixA_rowsize, matrixA_columnsize, MatrixB, matrixB_rowsize, matrixB_columnsize);
    //printMatrixM(AnswerMatrix, matrixAnswer_rowsize, matrixAnswer_columnsize);
    printf("\nestimate using time : %.2f\n", (double)(time(NULL) - start));
}