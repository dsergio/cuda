

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <math.h>

using namespace std;

#define _USE_MATH_DEFINES

#define ZRO 737	

#define THREADS_PER_BLOCK 512
#define N 800


struct location_item {
	const char * name;
	double lat;
	double lon;
};

__device__ double toRad(double degree) {
    return degree / 180 * M_PI;
}

__device__ double calculateDistance(double lat1, double long1, double lat2, double long2) {
    double dist;
    dist = sin(toRad(lat1)) * sin(toRad(lat2)) + cos(toRad(lat1)) * cos(toRad(lat2)) * cos(toRad(long1 - long2));
    dist = acos(dist);

		// dist = (6371 * pi * dist) / 180;
		// got dist in radian, no need to change back to degree and convert to rad again.

    dist = 6371 * dist;

    return dist;
}

// test function, do nothing
__global__ void test_kernel(void) {
	printf("do nothing\n");
}

// add integers:
__global__ void add(int *a, int *b, int *c) {
	*c = *a + *b;
	printf("IN ADD: a = %i\n", *a);
}

// calculate_distance:
__global__ void calculate_distance(double *lat, double *lon, double *dist, int n) {

	int index = threadIdx.x + blockIdx.x * blockDim.x;
	if (index < n) {
		double d = calculateDistance(lat[index], lon[index], lat[ZRO], lon[ZRO]);
		dist[index] = d;
	}
	
}


int main(void) {

	printf("test CUDA\n\n");


	// location_item items[N];

	int coords_size = N * sizeof(double);
	cout << "coords_size: " << coords_size << " " << INT_MAX << endl;
	
	double *lat_arr, *lon_arr, *dist_arr;
	lat_arr = (double *) malloc(coords_size);
	lon_arr = (double *) malloc(coords_size);
	dist_arr = (double *) malloc(coords_size);

	double *d_lat_arr, *d_lon_arr, *d_dist_arr;


	string names_arr[N];

	// load data line by line O(n)...
	int i = 0;
	string line;
	ifstream myfile ("wa_cities");
	if (myfile.is_open()) {
		while (getline(myfile, line) && i < N) {
			
			int pos = line.find(";");
			string name = line.substr(0, pos);
			string coords = line.substr(pos + 1, strlen(line.c_str()) - pos);
			int comma = coords.find(",");
			double lat = stod(coords.substr(0, comma));
			double lon = stod(coords.substr(comma + 1, strlen(coords.c_str()) - comma));

			// items[i] = (location_item){name.c_str(), lat, lon};
			lat_arr[i] = lat;
			lon_arr[i] = lon;

			names_arr[i] = name;
			i++;
		}
		myfile.close();
	} else cout << "Unable to open file";



	for (int i = 0; i < N; i++) {
		// printf("i = %d: before CUDA: lat: %lf, name: %s\n", i, lat_arr[i], names_arr[i].c_str());
	}

	// CUDA:
	
	cudaMalloc((void **) &d_lat_arr, coords_size);
	cudaMalloc((void **) &d_lon_arr, coords_size);
	cudaMalloc((void **) &d_dist_arr, coords_size);

	cudaMemcpy(d_lat_arr, lat_arr, coords_size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_lon_arr, lon_arr, coords_size, cudaMemcpyHostToDevice);

	calculate_distance<<<N/THREADS_PER_BLOCK,THREADS_PER_BLOCK>>>(d_lat_arr, d_lon_arr, d_dist_arr, N);

	cudaMemcpy(dist_arr, d_dist_arr, coords_size, cudaMemcpyDeviceToHost);

	for (int i = 0; i < N; i++) {

		if (dist_arr[i] > 500) {
			cout << "after CUDA:";
			cout << "\tlat: " <<  lat_arr[i] << ", long: " << lon_arr[i];
			cout << "\tdistance (from " << names_arr[ZRO] << " to " << names_arr[i] << "): \t\t" << 
				dist_arr[i] << endl;
		}

	}

	free(lat_arr);
	free(lon_arr);
	free(dist_arr);
	cudaFree(d_lat_arr);
	cudaFree(d_lon_arr);
	cudaFree(d_dist_arr);


	return 0;
}

