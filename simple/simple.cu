

#include <stdio.h>

// test function, do nothing
__global__ void test_kernel(void) {
	printf("do nothing\n");
}

// add integers:
__global__ void add(int *a, int *b, int *c) {
	*c = *a + *b;
	printf("IN ADD: a = %i\n", *a);
}

int main(void) {
	printf("test CUDA\n\n");

	test_kernel<<<1,1>>>();

	int a, b, c;

	int *d_a, *d_b, *d_c;

	int size = sizeof(int);

	cudaMalloc((void **) &d_a, size);
	cudaMalloc((void **) &d_b, size);
	cudaMalloc((void **) &d_c, size);

	a = 2;
	b = 2;

	cudaMemcpy(d_a, &a, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, &b, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_c, &c, size, cudaMemcpyHostToDevice);

	add<<<1,1>>>(d_a, d_b, d_c);

	cudaMemcpy(&c, d_c, size, cudaMemcpyDeviceToHost);

	printf("a = %i\nb = %i\n\na + b = c\n\nc = %i\n\n", a, b, c);
	printf("d_a = %p\n", d_a);
	printf("d_b = %p\n", d_b);
	printf("d_c = %p\n", d_c);

	printf("\n");
	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);

	return 0;
}

