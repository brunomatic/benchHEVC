/*
 	 Transformation benchmark implemented as per ITU-T H.265 v3(04*2015) specification
 */

#include "common.h"
#include "benchmark.h"
#include "tests.h"
#include "helper.h"

#define TESTS	1

int main() {

	if (TESTS) {
		testTransformation(4, MODE_INTER);
		testTransformation(8, MODE_INTRA);
		testTransformation(32, MODE_INTRA);
	}

	benchTransform(50000, 4, MODE_INTRA);
	benchTransform(100000, 4, MODE_INTER);
	benchTransform(5000, 8, MODE_INTER);
	//benchTransform(1000, 16, MODE_INTER);
	benchTransform(100, 32, MODE_INTER);

	return 0;
}
