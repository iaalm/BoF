CXXFLAGS=-fopenmp -O3
OBJ=find_center find_center_c gen_feature
all: $(OBJ)

clean:
	rm -f $(OBJ)
