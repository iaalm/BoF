#!/bin/bash

for i in 10 100 10000
do
    head -n $i ./filelist > f$i
    echo ----$i 
    echo openmp
    time ./find_center 1024 f$i c
    echo mpi
    time mpirun ./find_center_mpi 1024 f$i c > /dev/null
    echo mpi mutli machine
    time mpirun.openmpi -npernode 4 -H node25,node02,node03  ./a.out 1024 f$i c > /dev/null
    echo single
    time OMP_NUM_THREADS=1 ./find_center 1024 f$i c > /dev/null
    rm f$i
done
