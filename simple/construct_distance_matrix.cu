

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <math.h>
#include <iomanip>
#include <chrono>

using namespace std;



#define _USE_MATH_DEFINES


#define THREADS_PER_BLOCK 32
#define N 4


struct location_item {
	const char * name;
	float lat;
	float lon;
};

__device__ float toRad(float degree) {
    return degree / 180 * M_PI;
}

__device__ float calculateDistance(float lat1, float long1, float lat2, float long2) {

	if (lat1 == lat2 && long1 == long2) {
		return 0;
	}
    float dist;
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
__global__ void calculate_distance(float *lat, float *lon, float *dist, int n) {

	int i = threadIdx.x + blockIdx.x * blockDim.x;

	int i_m = ((n + 1) * (n + 1) - 1);

	// printf("i: %d, n: %d, i_m: %d\n", i, n, i_m);
	if (i <= i_m) {

		int i_src = i / (n + 1);
		int i_dest = i % (n + 1);

		float d = calculateDistance(lat[i_src], lon[i_src], lat[i_dest], lon[i_dest]);
		d = round(d);

		// printf("i: %d, n: %d, i_m: %d, i_src: %d, i_dest: %d " 
		// 	"lat src: %lf, lon src: %lf, lat dest: %lf, lon dest: %lf, d=%lf\n", 
		// 	i, n, i_m, i_src, i_dest, lat[i_src], lon[i_src], lat[i_dest], lon[i_dest], d);

		

		dist[i] = d;
	}
	
}

auto print_time() {
	auto now = chrono::system_clock::now();

    // Convert the current time to time since epoch
    auto duration = now.time_since_epoch();

    // Convert duration to milliseconds
    auto milliseconds
        = chrono::duration_cast<chrono::milliseconds>(
              duration)
              .count();

    // Print the result
    cout << "Current time in milliseconds is: "
         << milliseconds << endl;
    return milliseconds;
}


int main(void) {

	printf("test CUDA\n\n");
	
	
	auto start_time = print_time();

	// location_item items[N];

	const long long unsigned coords_size = (N) * sizeof(float);
	const long long unsigned i_M = ((N) * (N) - 1);
	const long long unsigned coords_size_distance = i_M * sizeof(float);

	cout << "N : " << N << ", i_M: " << i_M << endl;

	cout << "coords_size: " << coords_size << 
		", coords_size_distance: " << coords_size_distance << ", INT_MAX: " << INT_MAX << endl;
	
	float *lat_arr, *lon_arr, *dist_arr;
	lat_arr = (float *) malloc(coords_size);
	lon_arr = (float *) malloc(coords_size);
	dist_arr = (float *) malloc(coords_size_distance);

	float *d_lat_arr, *d_lon_arr, *d_dist_arr;


	string names_arr[N + 1];

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
			float lat = stod(coords.substr(0, comma));
			float lon = stod(coords.substr(comma + 1, strlen(coords.c_str()) - comma));

			// items[i] = (location_item){name.c_str(), lat, lon};
			lat_arr[i] = lat;
			lon_arr[i] = lon;

			names_arr[i] = name;
			i++;
		}
		myfile.close();
	} else cout << "Unable to open file";



	// for (int i = 0; i < N; i++) {
	// 	printf("i = %d: before CUDA: lat: %lf, name: %s\n", i, lat_arr[i], names_arr[i].c_str());
	// }

	cout << "blocks: " << i_M/THREADS_PER_BLOCK + 1<< ", threads per block: " << THREADS_PER_BLOCK << endl;

	// CUDA:
	
	cudaMalloc((void **) &d_lat_arr, coords_size);
	cudaMalloc((void **) &d_lon_arr, coords_size);
	cudaMalloc((void **) &d_dist_arr, coords_size_distance);

	cudaMemcpy(d_lat_arr, lat_arr, coords_size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_lon_arr, lon_arr, coords_size, cudaMemcpyHostToDevice);

	calculate_distance<<<i_M/THREADS_PER_BLOCK + 1,THREADS_PER_BLOCK>>>(d_lat_arr, d_lon_arr, d_dist_arr, N - 1);


	cudaError_t error = cudaGetLastError();
	if(error != cudaSuccess)
	{
		// print the CUDA error message and exit
		printf("CUDA error: %s\n", cudaGetErrorString(error));
		exit(-1);
	}

	cudaMemcpy(dist_arr, d_dist_arr, coords_size_distance, cudaMemcpyDeviceToHost);


	ofstream output_file;
  	output_file.open ("distances_matrix", ios::trunc);


	for (int i = 0; i <= i_M; i++) {

		int i_src = i / (N);
		int i_dest = i % (N);

		// if (true) { // (dist_arr[i] > 500) {
		// 	cout << "after CUDA:" << "i_src: " << i_src << ", i_dest: " << i_dest << endl
		// 	<< "\tlat src: " <<  lat_arr[i_src] << ", lon src: " << lon_arr[i_src] << endl
		// 	<< "\tlat dest: " <<  lat_arr[i_dest] << ", lon dest: " << lon_arr[i_dest] << endl
		// 	<< "\tdistance (from " << names_arr[i_src] << " to " << names_arr[i_dest] << "): \t\t"
		// 	<< setprecision(3) << dist_arr[i] << endl;
		// }
		

		if (i > 0 && i % N == 0) {
			output_file << endl;
			output_file << dist_arr[i];
		} else {
			if (i > 0) {
				output_file << " ";
			}
			output_file << dist_arr[i];
		}
	}

	output_file.close();

	free(lat_arr);
	free(lon_arr);
	free(dist_arr);
	cudaFree(d_lat_arr);
	cudaFree(d_lon_arr);
	cudaFree(d_dist_arr);

	auto end_time = print_time();
	cout << "time in milliseconds: " << end_time - start_time << endl;

	return 0;
}

