#include <iostream>
using namespace std;
int main() {
    std::cout << "Hello, World!" << std::endl;
    int a[] = {1,2,3,4,5};
    printf("%d\n", &a[0]);
    printf("%d\n", &a[1]);
    printf("%d\n", &a[2]);
    return 0;
}