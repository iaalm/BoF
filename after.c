#include<stdio.h>
#include<math.h>
#define n_cluster (1024)

int main(int argc, char *argv[]){
    FILE* fp = fopen(argv[1],"r");
    if(fp == NULL)
        return 1;
    int i, j;
    float sum;
    char str[512];
    int tab[n_cluster];
    fscanf(fp, "%s", str);
    while(!feof(fp)){
        printf("%s",str);
        j = 0;
        for(i = 0;i < n_cluster;i++){
            fscanf(fp,"%d",tab+i);
            j += tab[i] * tab[i];
        }
        sum = sqrtf(j);
        for(i = 0;i < n_cluster;i++){
            if(tab[i])
                printf(" %d:%f", i+1, tab[i]/sum);
        }
        putchar(10);
        fscanf(fp, "%s", str);
    }
    fclose(fp);
    return 0;
}
