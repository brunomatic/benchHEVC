/*
Fractional sample interpolation and transformation benchmark implemented as per ITU-T H.265 v3(04*2015) specification
*/

// first get rid of those anonying MS warnings
#define _CRT_SECURE_NO_DEPRECATE

#include "common.h"
#include "benchmark.h"
#include "tests.h"


int main(int argc, char **argv)
{
	
	if(argc > 1){
		if(argv [1]){
			testInterpolation();
			testTransformation();
		}
	}
	else
	{
		benchTransform(1000000, 4, MODE_INTRA);
		benchTransform(1000000, 4, MODE_INTER );
		benchTransform(1000000, 8, MODE_INTER );
		benchTransform(1000000, 16, MODE_INTER );
		benchTransform(1000000, 32, MODE_INTER );
		

		benchInterpolation(100000, 8, 8);
		benchInterpolation(100000, 64, 64);

	}

	return 0;
}