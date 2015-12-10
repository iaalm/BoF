CXXFLAGS=-fopenmp -O3
OBJ=find_center find_center_cuda gen_feature
all: $(OBJ)

find_center_cuda:find_center_cuda.cu
	nvcc -arch=sm_12 $^ -o $@ 

clean:
	rm -f $(OBJ)
