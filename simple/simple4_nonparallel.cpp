

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <math.h>
#include <iomanip>
#include <cstring>
#include <climits>
#include <chrono>

using namespace std;

#define _USE_MATH_DEFINES


#define THREADS_PER_BLOCK 32
#define N 30000


struct location_item {
	const char * name;
	float lat;
	float lon;
};

float toRad(float degree) {
    return degree / 180 * M_PI;
}

float calculateDistance(float lat1, float long1, float lat2, float long2) {

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

	printf("test NON-CUDA\n\n");
	auto start_time = print_time();

	// location_item items[N];

	const int coords_size = (N) * sizeof(float);
	const int i_M = ((N) * (N) - 1);
	const long unsigned coords_size_distance = i_M * sizeof(float);

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

	// ofstream output_file;
  	// output_file.open ("distances_nonpar", ios::trunc);
  	// ofstream csv_output;
  	// csv_output.open ("distances_nonpar.csv", ios::trunc);

	for (int i = 0; i < N; i++) {

		for (int j = 0; j < N; j++) {
			float d = calculateDistance(lat_arr[i], lon_arr[i], lat_arr[j], lon_arr[j]);
			// cout 
			// 	<< "src: " << names_arr[i] << " lat: " << lat_arr[i] << " lon: " << lon_arr[i]
			// 	<< " dest: " << names_arr[j] << " lat: " << lat_arr[j] << " lon: " << lon_arr[j]
			// 	<< " distance: " << d << endl;

			// char sep = ',';
			// csv_output
			// 	<< names_arr[i] << sep << lat_arr[i] << sep << lon_arr[i]
			// 	<< sep << names_arr[j] << sep << lat_arr[j] << sep << lon_arr[j]
			// 	<< sep << setprecision(3) << d << endl;
		}
	}

	// output_file.close();
	// csv_output.close();

	// cout << "blocks: " << i_M/THREADS_PER_BLOCK + 1<< ", threads per block: " << THREADS_PER_BLOCK << endl;

	// CUDA:
	
	// cudaMalloc((void **) &d_lat_arr, coords_size);
	// cudaMalloc((void **) &d_lon_arr, coords_size);
	// cudaMalloc((void **) &d_dist_arr, coords_size_distance);

	// cudaMemcpy(d_lat_arr, lat_arr, coords_size, cudaMemcpyHostToDevice);
	// cudaMemcpy(d_lon_arr, lon_arr, coords_size, cudaMemcpyHostToDevice);

	// calculate_distance<<<i_M/THREADS_PER_BLOCK + 1,THREADS_PER_BLOCK>>>(d_lat_arr, d_lon_arr, d_dist_arr, N - 1);

	// cudaMemcpy(dist_arr, d_dist_arr, coords_size_distance, cudaMemcpyDeviceToHost);


	// ofstream output_file;
  	// output_file.open ("distances", ios::trunc);
  	// ofstream csv_output;
  	// csv_output.open ("distances.csv", ios::trunc);

	// for (int i = 0; i <= i_M; i++) {

	// 	int i_src = i / (N);
	// 	int i_dest = i % (N);

	// 	// if (true) { // (dist_arr[i] > 500) {
	// 	// 	cout << "after CUDA:" << "i_src: " << i_src << ", i_dest: " << i_dest << endl
	// 	// 	<< "\tlat src: " <<  lat_arr[i_src] << ", lon src: " << lon_arr[i_src] << endl
	// 	// 	<< "\tlat dest: " <<  lat_arr[i_dest] << ", lon dest: " << lon_arr[i_dest] << endl
	// 	// 	<< "\tdistance (from " << names_arr[i_src] << " to " << names_arr[i_dest] << "): \t\t"
	// 	// 	<< setprecision(3) << dist_arr[i] << endl;
	// 	// }

	// 	output_file 
	// 		<< names_arr[i_src] << ";" << lat_arr[i_src] << "," << lon_arr[i_src]
	// 		<< "|"
	// 		<< names_arr[i_dest] << ";" << lat_arr[i_dest] << "," << lon_arr[i_dest]
	// 		<< "|" << dist_arr[i] << endl;
		
	// 	char sep = ',';
	// 	csv_output 
	// 		<< names_arr[i_src] << sep << lat_arr[i_src] << sep << lon_arr[i_src]
	// 		<< sep
	// 		<< names_arr[i_dest] << sep << lat_arr[i_dest] << sep << lon_arr[i_dest]
	// 		<< sep << dist_arr[i] << endl;
	// }

	// output_file.close();
	// csv_output.close();

	free(lat_arr);
	free(lon_arr);
	free(dist_arr);
	// cudaFree(d_lat_arr);
	// cudaFree(d_lon_arr);
	// cudaFree(d_dist_arr);



	auto end_time = print_time();

	cout << "time in milliseconds: " << end_time - start_time << endl;

	return 0;
}

