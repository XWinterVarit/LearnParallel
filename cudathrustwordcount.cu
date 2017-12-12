//
// Created by Cheevarit Rodnuson on 11/21/17.
//

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <string.h>
#include <iostream>
#include <stdlib.h>
#include <stdio.h>


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
int main(void)
{
   /*
    const char raw_input[] = "  But the raven, sitting lonely on the placid bust, spoke only,\n"
            "  That one word, as if his soul in that one word he did outpour.\n"
            "  Nothing further then he uttered - not a feather then he fluttered -\n"
            "  Till I scarcely more than muttered `Other friends have flown before -\n"
            "  On the morrow he will leave me, as my hopes have flown before.'\n"
            "  Then the bird said, `Nevermore.'\n";
    thrust::device_vector<char> input(raw_input, raw_input + sizeof(raw_input));
*/
    long* test= createVector(10,2);
    readVector(test,10);
    thrust::device_vector<long> d_test(10,0);
    for (int i = 0; i < 10; i++) {
        d_test[i] = *(test + i);
    }
    long sum = thrust::reduce(d_test.begin(), d_test.end(),(int) 0, thrust::plus<int>());
    printf("sum : %lu\n", sum);

    //printf("%s\n",a);
    return 0;
}

