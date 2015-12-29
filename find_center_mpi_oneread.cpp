#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#include<signal.h>
#include<mpi.h>

#define INF (64 * 64 * 128 * 2)
#define N_FEATURE (128)

int signal_flag;
void handle_signal(int){
    fprintf(stderr, "get signal\n");
    signal_flag = 0;
}
struct point{
    float f[N_FEATURE];
    int c;
};
int main(int argc, char* argv[]){
    float sum;
    int n_clusters = atoi(argv[1]);
    point* points;
    point* gpoints;
    float center[n_clusters][N_FEATURE];
    int n_line = 0, i, j, k, l, p, q;
    int tab[n_clusters];
    float gcenter[n_clusters][N_FEATURE];
    int gtab[n_clusters];
    float m, n;
    char str[256];
    int b_continue = 0;
    int gn_line = 0,mn_line;
    FILE *fp_list, *fp_file;
    int mpi_size, mpi_rank;
    signal_flag = 1;
    signal(SIGINT, handle_signal);

    if(argc > 4 && strcmp(argv[4],"-c") == 0)
        b_continue = 1;
    MPI_Init(&argc,&argv);
    MPI_Comm_size(MPI_COMM_WORLD,&mpi_size);
    MPI_Comm_rank(MPI_COMM_WORLD,&mpi_rank);

    if(!mpi_rank){
        fp_list = fopen(argv[2], "r");
        fgets(str, 256, fp_list);
        while(!feof(fp_list)){
            str[strlen(str) - 1] = '\0';
            fp_file = fopen(str, "r");
            fscanf(fp_file, "%*d%d", &j);
            gn_line += j;
            fclose(fp_file);
            fgets(str, 256, fp_list);
        }
        mn_line = (gn_line + mpi_size - 1) / mpi_size * mpi_size;
        gpoints = (point*) malloc(sizeof(point) * mn_line);
        printf("total %d lines\n", gn_line);

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
                    gpoints[l + i].f[k] = sqrtf(p); // sqrt it
                }
                m = sqrtf(q);
                if(q > 0)
                    for(k = 0;k < N_FEATURE;k++){
                        gpoints[l + i].f[k] /= m;        //l2 normal
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
            for(i = 0;i < n_clusters;i++){
                k = random() % gn_line;
                for(j = 0;j < N_FEATURE;j++)
                    center[i][j] = gpoints[k].f[j];
            }
        }
    }
    MPI_Bcast(&gn_line, 1, MPI_INT, 0, MPI_COMM_WORLD);
    n_line = (gn_line + mpi_size - 1) / mpi_size;
    points = (point*) malloc(sizeof(point) * n_line);
    MPI_Scatter(gpoints, N_FEATURE * n_line, MPI_FLOAT, points, N_FEATURE * n_line, MPI_FLOAT, 0, MPI_COMM_WORLD);
    if(!mpi_rank)
        free(gpoints);
    if(mpi_size - mpi_rank == 1){
        n_line -= n_line * mpi_size - gn_line;
    }

    for(l = 0; l < 1000;l++){
        //sync center
        MPI_Bcast(&center, N_FEATURE * n_clusters, MPI_FLOAT, 0,MPI_COMM_WORLD);
        // start
        p = 0;
        sum = 0;
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
                {
                    p = 1;
                }
                points[i].c = q;
            }
        }
        //reduce sum and p
        MPI_Allreduce(&p, &q, 1, MPI_INT, MPI_MAX,  MPI_COMM_WORLD);
        p = q;
        MPI_Reduce(&sum, &m, 1, MPI_FLOAT, MPI_SUM, 0, MPI_COMM_WORLD);
        sum = m;
        if(!mpi_rank){
            printf("loop %4d: %f\n",l,sum/gn_line);
        }

        if(!signal_flag || !p)
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
        //reduce center and tab
        MPI_Reduce(center, gcenter, N_FEATURE * n_clusters, MPI_FLOAT, MPI_SUM, 0, MPI_COMM_WORLD);
        MPI_Reduce(tab, gtab, n_clusters, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
        memcpy(tab, gtab, n_clusters * sizeof(int));
        memcpy(center, gcenter, n_clusters * N_FEATURE * sizeof(float));
        if(!mpi_rank)
            for(i = 0;i < n_clusters;i++){
                if(tab[i])
                    for(j = 0; j < N_FEATURE;j++)
                        center[i][j] /= tab[i];
                else {
                    printf("empty center\n");
                    k = random() % n_line;
                    for(j = 0;j < N_FEATURE;j++)
                        center[i][j] = points[k].f[j];
                }
            }
    }
    MPI_Finalize();

    if(!mpi_rank){
        fp_list = fopen(argv[3], "w");
        for(i = 0;i < n_clusters;i++){
            for(j = 0;j < N_FEATURE;j++)
                fprintf(fp_list, "%f ",center[i][j]);
            fprintf(fp_list,"\n");
        }
        fclose(fp_list);
    }
    free(points);

    return p;
}
