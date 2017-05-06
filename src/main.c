/*
 Fractional sample interpolation and transformation benchmark implemented as per ITU-T H.265 v3(04*2015) specification
 */

// first get rid of those annoying MS warnings
#define _CRT_SECURE_NO_DEPRECATE

#include "common.h"
#include "benchmark.h"
#include "tests.h"
#include "helper.h"

#include <stdlib.h>
#include <stdio.h>
#include "asm.h"

#define TESTS	0


int main() {

	int16_t * write, * read;
	int8_t i,j ;
	if (TESTS) {
		//testInterpolation();
		testTransformation(32, MODE_INTER);
	}

	//benchTransform(5000000, 4, MODE_INTRA);
	//benchTransform(10000000, 4, MODE_INTER);
	//benchTransform(500000, 8, MODE_INTER);
	//benchTransform(100000, 16, MODE_INTER);
	//benchTransform(50000, 32, MODE_INTER);
	//benchInterpolation(10000, 8, 8);
	//benchInterpolation(5000, 64, 64);

	write = malloc(sizeof(int16_t)*32*32);
	read = malloc(sizeof(int16_t)*32*32);

	for(j = 0; j< 32; j++){
			for(i = 0; i < 32; i++){
			read[i+j*32]=-256+(i%2);
			}
		}

	dct32(read, write);

	for(j = 0; j< 32; j++){
		for(i = 0; i < 32; i++){
			printf("%d  ", write[j*32+i]);
		}
		printf("\n");
	}

	free(write);
	free(read);

	return 0;
}
