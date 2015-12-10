#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#include<cuda_runtime.h>

#define INF (64 * 64 * 128 * 2)
#define N_FEATURE (128)

static void HandleError( cudaError_t err,
                         const char *file,
                         int line ) {
    if (err != cudaSuccess) {
        printf( "%s in %s at line %d\n", cudaGetErrorString( err ),
                file, line );
        exit( EXIT_FAILURE );
    }
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))

struct point{
    float f[N_FEATURE];
    int c;
};

__global__ static void kmeans_cluster(point* points,float (*center)[N_FEATURE], int n_line, int n_clusters, int* p){
    int i,j,k,q;
    float m,n;
        for(i = blockIdx.x;i < n_line;i+=gridDim.x){
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
            //sum += n;
            if(q != points[i].c && *p == 0){
                #pragma omp crititcal
                {
                    *p = 1;
                }
                points[i].c = q;
            }
        }
}
__global__ static void kmeans_center(point* points,float (*center)[N_FEATURE], int n_line, int n_clusters){
    int i,j,k,n;
        for(i = blockIdx.x;i < n_clusters;i+=gridDim.x){
            for(j = 0; j < N_FEATURE;j++)
                center[i][j] = 0;
            n = 0;

            for (j = 0; j < n_line;j++)
                if(points[j].c == i){
                    n++;
                    for(k = 0;k < N_FEATURE;k++)
                        center[i][k] += points[i].f[k];
                }
            for(j = 0; j < N_FEATURE;j++)
                center[i][j] /= n;
        }
}

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
        fp_file = fopen(str, "r");
        fscanf(fp_file, "%*d%d", &j);
        for(i = 0;i < j;i++){
            fscanf(fp_file, "%*f%*f%*f%*f%*f");
            q = 0;
            for(k = 0;k < N_FEATURE;k++){
                fscanf(fp_file, "%d", &p);
                q += p;
                points[l + i].f[k] = sqrtf(p); // sqrt it
            }
            m = sqrtf(q);
            if(q > 0)
                for(k = 0;k < N_FEATURE;k++){
                    points[l + i].f[k] /= m;        //l2 normal
                }
        }
        l += j;
        fclose(fp_file);
        fgets(str, 256, fp_list);
    }
    fclose(fp_list);

    //init center
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

    //kmeans
    point* dev_points;
    float (*dev_center)[N_FEATURE];
    int *dev_p;
    HANDLE_ERROR( cudaMalloc( (void**)&dev_center, n_clusters * N_FEATURE * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_points, n_line * sizeof(point) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_p, sizeof(int) ) );
    HANDLE_ERROR( cudaMemcpy( dev_points, points, n_line * sizeof(point), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( dev_center, center, n_clusters * N_FEATURE * sizeof(float), cudaMemcpyHostToDevice ) );
    for(l = 0; l < 1000;l++){
        // start
        // sum = 0
        p = 0;
    HANDLE_ERROR( cudaMemcpy( dev_p, &p, sizeof(int), cudaMemcpyHostToDevice ) );
    kmeans_cluster<<<128,1>>>(dev_points,dev_center,n_line,n_clusters,dev_p);
    HANDLE_ERROR( cudaMemcpy( &p, dev_p, sizeof(int), cudaMemcpyDeviceToHost ) );
        //printf("loop %6d: %f\n",l,sum/n_line);

        if(!p)
            break;
        //calc center
    kmeans_center<<<128,1>>>(dev_points,dev_center,n_line,n_clusters);
    printf("loop %4d: %f\n",l,sum/n_line);
    }
    HANDLE_ERROR( cudaMemcpy( center, dev_center, n_clusters * N_FEATURE * sizeof(float), cudaMemcpyDeviceToHost ) );
    HANDLE_ERROR( cudaFree( dev_points ) );
    HANDLE_ERROR( cudaFree( dev_center ) );
    HANDLE_ERROR( cudaFree( dev_p ) );

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

