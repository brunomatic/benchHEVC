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

/*
void transposeIntr(const int16_t* src, int16_t * dst){
	int16x4x2_t block[4];
	int16x8_t blockQ[4];
	int32x4x2_t temp[2];

	/*	|	block[0][0]	|	block[1][0]	|
	 * 	|	block[0][1]	|	block[1][1]	|
	 * 	---------------------------------
	 * 	|	block[2][0]	|	block[3][0]	|
	 * 	|	block[2][1]	|	block[3][1]	|
	 */
/*
	block[0].val[0] = vld1_s16(src);
	block[1].val[0] = vld1_s16(src+4);
	block[0].val[1] = vld1_s16(src+8);
	block[1].val[1] = vld1_s16(src+12);
	block[2].val[0] = vld1_s16(src+16);
	block[3].val[0] = vld1_s16(src+20);
	block[2].val[1] = vld1_s16(src+24);
	block[3].val[1] = vld1_s16(src+28);

	block[0] = vtrn_s16(block[0].val[0],block[0].val[1]);
	block[1] = vtrn_s16(block[1].val[0],block[1].val[1]);
	block[2] = vtrn_s16(block[2].val[0],block[2].val[1]);
	block[3] = vtrn_s16(block[3].val[0],block[3].val[1]);

	blockQ[0] =  vcombine_s16(block[0].val[0],block[0].val[1]);
	blockQ[1] =  vcombine_s16(block[1].val[0],block[1].val[1]);
	blockQ[2] =  vcombine_s16(block[2].val[0],block[2].val[1]);
	blockQ[3] =  vcombine_s16(block[3].val[0],block[3].val[1]);

	temp[0] =  vtrnq_s32((int32x4_t)blockQ[0],(int32x4_t)blockQ[2]);
	temp[1] = vtrnq_s32((int32x4_t)blockQ[1],(int32x4_t)blockQ[3]);

	block[0].val[0] = vget_low_s16((int16x8_t)temp[0].val[0]);
	block[0].val[1] = vget_high_s16((int16x8_t)temp[0].val[0]);

	block[2].val[0] = vget_low_s16((int16x8_t)temp[0].val[1]);
	block[2].val[1] = vget_high_s16((int16x8_t)temp[0].val[1]);

	block[1].val[0] = vget_low_s16((int16x8_t)temp[1].val[0]);
	block[1].val[1] = vget_high_s16((int16x8_t)temp[1].val[0]);

	block[3].val[0] = vget_low_s16((int16x8_t)temp[1].val[1]);
	block[3].val[1] = vget_high_s16((int16x8_t)temp[1].val[1]);

	vst1_s16(dst, block[0].val[0]);
	vst1_s16(dst+4, block[0].val[1]);
	vst1_s16(dst+8, block[1].val[0]);
	vst1_s16(dst+12, block[1].val[1]);
	vst1_s16(dst+16, block[2].val[0]);
	vst1_s16(dst+20, block[2].val[1]);
	vst1_s16(dst+24, block[3].val[0]);
	vst1_s16(dst+28, block[3].val[1]);

	return;

}

*/

int main() {

	/*int16_t testMatrix[8][8] = {
			{0, 1, 2, 3, 4, 5, 6, 7},
			{8, 9, 10, 11, 12, 13, 14, 15},
			{16, 17, 18, 19, 20, 21, 22, 23},
			{24, 25, 26, 27, 28, 29, 30, 31},
			{0, 1, 2, 3, 4, 5, 6, 7},
			{8, 9, 10, 11, 12, 13, 14, 15},
			{16, 17, 18, 19, 20, 21, 22, 23},
			{24, 25, 26, 27, 28, 29, 30, 31}
	};
	int16_t * write;
	int8_t i,j ;
*/
	if (TESTS) {
		//testInterpolation();
		//testTransformation(8, MODE_INTER);
	}

	testTransformation(16, MODE_INTER);

	//benchTransform(5000000, 4, MODE_INTRA);
	//benchTransform(10000000, 4, MODE_INTER);
	//benchTransform(500000, 8, MODE_INTER);
	//benchTransform(100000, 16, MODE_INTER);
	//benchTransform(50000, 32, MODE_INTER);
	//benchInterpolation(10000, 8, 8);
	//benchInterpolation(5000, 64, 64);
/*
	write = malloc(sizeof(int16_t)*8*8);

	transpose(&testMatrix, write);

	for(j = 0; j< 4; j++){
		for(i = 0; i < 8; i++){
			printf("%d  ", write[j*8+i]);
		}
		printf("\n");
	}

	free(write);
*/
	return 0;
}
