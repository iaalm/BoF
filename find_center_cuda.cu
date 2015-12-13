#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#include<cuda_runtime.h>

#define INF (64 * 64 * 128 * 2)
#define N_FEATURE (128)
typedef float fv[N_FEATURE];

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

__global__ static void kmeans_cluster(int max_iter, fv *points,fv *center, int n_line, int n_clusters){
    int i,j,k,l,q;
    __shared__ unsigned int p;
    extern __shared__ unsigned int cluster[];
    float m,n;
    fv tfeature;
    for(l = 0; l < max_iter;l++){
        if(blockDim.x == 0 && threadIdx.x == 0)
            p = 0;
        __syncthreads();
        for(i = blockIdx.x * gridDim.x + threadIdx.x;i < n_line;i+=blockDim.x * gridDim.x){
            //memcpy(tfeature,points[i],sizeof(float)*N_FEATURE);
	    for(j = 0; j < N_FEATURE;j++)
		tfeature[j] = points[i][j];
            n = INF;   
            for(j = 0; j < n_clusters;j++){
                m = 0;
                for(k = 0;k < N_FEATURE;k++)
                    m += (tfeature[k] - center[j][k]) * (tfeature[k] - center[j][k]);
                if(m < n){
                    q = j;
                    n = m;
                }
            }
            //sum += n;
            if(q != cluster[i] && p == 0){
                atomicAdd(&p, 1);
                cluster[i] = q;
            }
        }
        __syncthreads();
        if(p == 0)
            return ;
        for(i = blockIdx.x * gridDim.x + threadIdx.x;i < n_clusters;i+=blockDim.x * gridDim.x){
            for(j = 0; j < N_FEATURE;j++)
                tfeature[j] = 0;
            n = 0;

            for (j = 0; j < n_line;j++)
                if(cluster[j] == i){
                    n++;
                    for(k = 0;k < N_FEATURE;k++)
                        tfeature[k] += points[j][k];
                }
            if(n > 0)
                for(j = 0; j < N_FEATURE;j++)
                    tfeature[j] /= n;
            //memcpy(center[i],tfeature,sizeof(float)*N_FEATURE);
	    for(j = 0; j < N_FEATURE;j++)
		center[i][j] = tfeature[j];
        }
    }
}

int main(int argc, char* argv[]){
    float sum;
    int n_clusters = atoi(argv[1]);
    fv* points;
    fv center[n_clusters];
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
    points =  (fv*)malloc(sizeof(float) * N_FEATURE * n_line);
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
                points[l + i][k] = sqrtf(p); // sqrt it
            }
            m = sqrtf(q);
            if(q > 0)
                for(k = 0;k < N_FEATURE;k++){
                    points[l + i][k] /= m;        //l2 normal
                }
        }
        l += j;
        fclose(fp_file);
        fgets(str, 256, fp_list);
    }
    fclose(fp_list);

    puts("data load done!");
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
    fv* dev_points;
    fv* dev_center;
    HANDLE_ERROR( cudaMalloc( (void**)&dev_center, n_clusters * N_FEATURE * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_points, n_line * N_FEATURE * sizeof(float) ) );
    HANDLE_ERROR( cudaMemcpy( dev_center, center, n_clusters * N_FEATURE * sizeof(float), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( dev_points, points, n_line * N_FEATURE * sizeof(float), cudaMemcpyHostToDevice ) );
    kmeans_cluster<<<1,128,n_line * sizeof(float)>>>(100,dev_points,dev_center,n_line,n_clusters);
    HANDLE_ERROR( cudaMemcpy( center, dev_center, n_clusters * N_FEATURE * sizeof(float), cudaMemcpyDeviceToHost ) );

    fp_list = fopen(argv[3], "w");
    for(i = 0;i < n_clusters;i++){
        for(j = 0;j < N_FEATURE;j++)
            fprintf(fp_list, "%f ",center[i][j]);
        fprintf(fp_list,"\n");
    }
    fclose(fp_list);
    delete points;
    HANDLE_ERROR( cudaFree( dev_points ) );
    HANDLE_ERROR( cudaFree( dev_center ) );

    return p;
}

