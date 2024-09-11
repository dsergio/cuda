

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string.h>
#include <math.h>
using namespace std;

#define _USE_MATH_DEFINES


double toRad(double degree) {
    return degree/180 * M_PI;
}

double calculateDistance(double lat1, double long1, double lat2, double long2) {
    double dist;
    dist = sin(toRad(lat1)) * sin(toRad(lat2)) + cos(toRad(lat1)) * cos(toRad(lat2)) * cos(toRad(long1 - long2));
    dist = acos(dist);
//        dist = (6371 * pi * dist) / 180;
    //got dist in radian, no need to change back to degree and convert to rad again.
    dist = 6371 * dist;
    return dist;
}



int main(void) {

	double spokane_to_yosemite = calculateDistance(47.66, -117.45, 37.73, -119.61);

	printf("distance from Spokane to Yosemite: %lf\n", spokane_to_yosemite);

	return 0;

}