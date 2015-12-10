#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>

#define INF (64 * 64 * 128 * 2)
#define N_FEATURE (128)

struct point{
    float f[N_FEATURE];
    int c;
};
int main(int argc, char* argv[]){
    float sum;
    int n_clusters = atoi(argv[1]);
    point* points;
    float center[n_clusters][N_FEATURE];
    int n_line = 0, i, j, k, l, p, q;
    int tab[n_clusters];
    float m, n;
    char str[256];
    int b_continue = 0;

    if(argc > 4 && strcmp(argv[4],"-c") == 0)
        b_continue = 1;

    FILE *fp_list = fopen(argv[2], "r"), *fp_file;
    fgets(str, 256, fp_list);
    while(!feof(fp_list)){
        str[strlen(str) - 1] = '\0';
        fp_file = fopen(str, "r");
        fscanf(fp_file, "%*d%d", &j);
        n_line += j;
        fclose(fp_file);
        fgets(str, 256, fp_list);
    }
    points = (point*) malloc(sizeof(point) * n_line);
    printf("total %d lines\n",n_line);

    l = 0;
    rewind(fp_list);
    fgets(str, 256, fp_list);
    while(!feof(fp_list)){
        str[strlen(str) - 1] = '\0';
        q = 0;
        fp_file = fopen(str, "r");
        fscanf(fp_file, "%*d%d", &j);
        for(i = 0;i < j;i++){
            fscanf(fp_file, "%*f%*f%*f%*f%*f");
            for(k = 0;k < N_FEATURE;k++){
                fscanf(fp_file, "%d", &p);
                q += p;
                points[l + i].f[k] = sqrtf(p); // sqrt it
            }
            m = sqrtf(q);
            for(k = 0;k < N_FEATURE;k++){
                points[l + i].f[k] /= m;        //l2 normal
            }
        }
        l += j;
        fclose(fp_file);
        fgets(str, 256, fp_list);
    }
    fclose(fp_list);

    //kmeans
    if(b_continue){
        fp_list = fopen(argv[3], "r");
        for(i = 0;i < n_clusters;i++){
            for(j = 0;j < N_FEATURE;j++)
                fscanf(fp_list, "%f",&center[i][j]);
        }
        fclose(fp_list);
    }
    else{
        for(i = 0;i < n_clusters;i++)
            for(j = 0;j < N_FEATURE;j++)
                center[i][j] = random() / (float) RAND_MAX;
    }

    for(l = 0; l < 1000;l++){
        // start
        p = 0;
        sum = 0;
        #pragma omp parallel for private(i,j,k,m,n,q)
        for(i = 0;i < n_line;i++){
            n = INF;   
            for(j = 0; j < n_clusters;j++){
                m = 0;
                for(k = 0;k < N_FEATURE;k++)
                    m += (points[i].f[k] - center[j][k]) * (points[i].f[k] - center[j][k]);
                if(m < n){
                    q = j;
                    n = m;
                }
            }
            sum += n;
            if(q != points[i].c){
                #pragma omp crititcal
                {
                    p = 1;
                }
                points[i].c = q;
            }
        }
        printf("loop %6d: %f\n",l,sum/n_line);

        if(!p)
            break;
        //calc center
        for(i = 0;i < n_clusters;i++){
            tab[i] = 0;
            for(j = 0; j < N_FEATURE;j++)
                center[i][j] = 0;
        }
        for(i = 0;i < n_line;i++){
            tab[points[i].c]++;
            for(j = 0; j < N_FEATURE;j++){
                center[points[i].c][j] += points[i].f[j];
            }
        }
        for(i = 0;i < n_clusters;i++){
            for(j = 0; j < N_FEATURE;j++)
                if(tab[i])
                    center[i][j] /= tab[i];
        }
    }

    fp_list = fopen(argv[3], "w");
    for(i = 0;i < n_clusters;i++){
        for(j = 0;j < N_FEATURE;j++)
            fprintf(fp_list, "%f ",center[i][j]);
        fprintf(fp_list,"\n");
    }
    fclose(fp_list);
    delete points;

    return p;
}
