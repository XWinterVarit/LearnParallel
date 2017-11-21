//
// Created by Cheevarit Rodnuson on 11/21/17.
//

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <string.h>
#include <iostream>
struct changer{
    const int a;

    changer(int _a) : a(_a) {}
    __host__ __device__
    int operator() (const float& x) const {
        return a*x;
    }
};
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
    int a[] = {1,2,3,4,5,6,7,8,9};
    thrust::device_vector<int> dev_a(a, a+9);
    thrust::transform(dev_a.begin(), dev_a.end(), dev_a.begin(), changer(5));
    thrust::host_vector<int> hos_a = dev_a;
    for (int i = 0; i < hos_a.size(); ++i) {
        printf("%d ", hos_a[i]);
    }
    printf("\n");
    //printf("%s\n",a);
    return 0;
}

