CXXFLAGS=-fopenmp -O3
LDFLAGS=-lm
OBJ=find_center find_center_mpi find_center_mpi_oneread find_center_cuda gen_feature after
all: $(OBJ)

find_center_cuda:find_center_cuda.cu
	nvcc -arch=sm_50 $^ -o $@ 

find_center_mpi:find_center_mpi.cpp
	mpic++ -O3 $^ -o $@ 

find_center_mpi_oneread:find_center_mpi_oneread.cpp
	mpic++ -O3 $^ -o $@ 

clean:
	rm -f $(OBJ)
