#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int d_strcount(const char *str1, const char *word, long wordlen, long start, long end) {
    int count = 0;
    for (int i = start; i < end - wordlen + 1; i++) {
        int charfail = 0;
        int wordindex = 0;
        for (int j = i; j < i + wordlen; ++j) {
            printf("show string : str1 : %c     word : %c \n", str1[j], word[wordindex]);
            if (str1[j] != word[wordindex])
                charfail = 1;
            wordindex++;
        }
        if (charfail == 0)
            count++;
        printf("cal count : %d\n", count);
        printf("----\n");

    }
    return count;
}

int main(int argc, char **argv) {
    char word[] = "welcome";
    char all[] = "to this day it welcome you the new welcome";
    printf("count : %d\n", d_strcount(all, word, strlen(word), 0, strlen(all)));
}
