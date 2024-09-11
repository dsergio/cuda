
CC=nvcc
CFLAGS=-gencode arch=compute_61,code=sm_61

all:
	$(CC) construct_distance_matrix.cu $(CFLAGS) -o a.out

clean:
	rm ./a.out