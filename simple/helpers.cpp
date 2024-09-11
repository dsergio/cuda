
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string.h>
using namespace std;


int main(void) {

	string str[] = {"hello", "goodbye"};
	cout << str[0];

	const int SIZE = 1000;
	char str_arr[SIZE][2048];

	int i = 0;
	string line;
	ifstream myfile ("wa_cities");
	if (myfile.is_open()) {
		while (getline(myfile, line)) {
			strcpy(str_arr[i], line.c_str());
			i++;
		}
		myfile.close();
	} else cout << "Unable to open file";


	for (int i = 0; i < SIZE; i++) {
		if (str_arr[i][0] != '\0') {
			printf("%s\n", str_arr[i]);
		}
		
	}

	return 0;
}

