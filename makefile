CXXFLAGS=-fopenmp -O3
OBJ=find_center gen_feature
all: $(OBJ)

clean:
	rm -f $(OBJ)
