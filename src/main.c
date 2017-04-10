/*
 Fractional sample interpolation and transformation benchmark implemented as per ITU-T H.265 v3(04*2015) specification
 */

// first get rid of those annoying MS warnings
#define _CRT_SECURE_NO_DEPRECATE

#include "common.h"
#include "benchmark.h"
#include "tests.h"

#define TESTS	0

int main() {

	if (TESTS) {
		//testInterpolation();
		testTransformation(4, MODE_INTRA);
	}

	benchTransform(5000000, 4, MODE_INTRA);
	benchTransform(10000000, 4, MODE_INTER);
	/*
	benchTransform(500000, 8, MODE_INTER);
	benchTransform(100000, 16, MODE_INTER);
	*/
	//benchTransform(50000, 32, MODE_INTER);

/*
	benchInterpolation(10000, 8, 8);
	benchInterpolation(5000, 64, 64);
*/
	return 0;
}
