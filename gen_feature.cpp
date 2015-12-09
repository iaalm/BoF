#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>

#define INF (64 * 64 * 128 * 2)
#define N_FEATURE (128)

int main(int argc, char* argv[]){
    float tf[N_FEATURE];
    int n_clusters = atoi(argv[1]);
    int feature[n_clusters];
    float center[n_clusters][N_FEATURE];
    int n_line = 0, i, j, k, l, p, q;
    int tab[n_clusters];
    float m, n;
    char str[256];

    FILE *fp_list = fopen(argv[3], "r"), *fp_file;
    for(i = 0;i < n_clusters;i++){
        for(j = 0;j < N_FEATURE;j++)
            fscanf(fp_list, "%f",&center[i][j]);
    }
    fclose(fp_list);
    fp_list = fopen(argv[2], "r");
    fgets(str, 256, fp_list);
    while(!feof(fp_list)){
        str[strlen(str) - 1] = '\0';
        fp_file = fopen(str, "r");
        fscanf(fp_file, "%*d%d", &l);
        bzero(feature,n_clusters * sizeof(int));
        for(i = 0;i < l;i++){
            fscanf(fp_file, "%*f%*f%*f%*f%*f");
            for(k = 0;k < N_FEATURE;k++){
                fscanf(fp_file, "%d", &p);
                tf[k] = sqrtf(p); // sqrt it
            }
            n = INF;   
            for(j = 0; j < n_clusters;j++){
                m = 0;
                for(k = 0;k < N_FEATURE;k++)
                    m += (tf[k] - center[j][k]) * (tf[k] - center[j][k]);
                if(m < n){
                    q = j;
                    n = m;
                }
            }
            feature[q]++;
        }
        fclose(fp_file);
        //output
        printf("%s:",str);
        for(i =0;i < n_clusters;i++)
            printf(" %d",feature[i]);
        putchar(10);
        fgets(str, 256, fp_list);
    }
    fclose(fp_list);

    return p;
}
