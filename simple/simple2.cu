
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <math.h>

using namespace std;

#define _USE_MATH_DEFINES

struct location_item {
	string name;
	double lat;
	double lon;
};

// calculate_distance:
__global__ void calculate_distance(location_item **items) {
	printf("items:");
}

// test function, do nothing
__global__ void test_kernel(void) {
	printf("do nothing\n");
}


double toRad(double degree) {
    return degree / 180 * M_PI;
}

double calculateDistance(double lat1, double long1, double lat2, double long2) {
    double dist;
    dist = sin(toRad(lat1)) * sin(toRad(lat2)) + cos(toRad(lat1)) * cos(toRad(lat2)) * cos(toRad(long1 - long2));
    dist = acos(dist);

		// dist = (6371 * pi * dist) / 180;
		// got dist in radian, no need to change back to degree and convert to rad again.

    dist = 6371 * dist;

    return dist;
}


int main(void) {

	printf("test CUDA\n\n");

	// load data line by line O(n)... can this be parallelized?
	
	const int SIZE = 1000;

	location_item items[SIZE];
	location_item *d_items[SIZE];

	int i = 0;
	string line;
	ifstream myfile ("wa_cities");
	if (myfile.is_open()) {
		while (getline(myfile, line)) {
			
			int pos = line.find(";");
			string name = line.substr(0, pos);
			string coords = line.substr(pos + 1, strlen(line.c_str()) - pos);
			int comma = coords.find(",");
			double lat = stod(coords.substr(0, comma));
			double lon = stod(coords.substr(comma + 1, strlen(coords.c_str()) - comma));

			items[i] = (location_item){name, lat, lon};

			i++;
		}
		myfile.close();
	} else cout << "Unable to open file";

	// CUDA:
	

	int size = sizeof(location_item);

	cudaMalloc((void **) &d_items, size);

	cudaMemcpy(d_items, &items, size, cudaMemcpyHostToDevice);

	calculate_distance<<<1,1>>>(d_items);

	test_kernel<<<1,1>>>();

	cudaMemcpy(&items, d_items, size, cudaMemcpyDeviceToHost);

	cudaFree(d_items);


	return 0;
}

