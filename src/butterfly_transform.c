#include "butterfly_transform.h"
#include "butterfly_functions.h"
#include <stdlib.h>
#include "common.h"

#if DEBUG

#include <stdio.h>
#include "helper.h"

#endif

/*
 * Function implements forward transform using partial butterfly algorithms in C
 */
void transform_butterfly(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS,
		uint8_t cIdx, int16_t * residual, int16_t * result) {

	uint8_t firstShift = 0, secondShift = 0;
	int16_t * temp;

	// set shift variable based on block size and bit depth
	switch (nTbS) {
	case 4:
		firstShift = BitDepth + 2 - 9;
		secondShift = 2 + 6;
		break;
	case 8:
		firstShift = BitDepth + 3 - 9;
		secondShift = 3 + 6;
		break;
	case 16:
		firstShift = BitDepth + 4 - 9;
		secondShift = 4 + 6;
		break;
	case 32:
		firstShift = BitDepth + 5 - 9;
		secondShift = 5 + 6;
		break;
	default:
		break;
	}

	// allocate and zero int space
	temp = (int16_t *) malloc(sizeof(int16_t) * nTbS * nTbS);

	// handle alternate DST transform of 4x4 blocks
	if (predictionMode == MODE_INTRA && nTbS == 4) {
		fastForwardDST(residual, temp, firstShift);
		fastForwardDST(temp, result, secondShift);
	}
	// handle everything else using butterfly algorithms from x265
	else {
		switch (nTbS) {
		case 4:
			butterfly4(residual, temp, firstShift);
			butterfly4(temp, result, secondShift);
			break;
		case 8:
			butterfly8(residual, temp, firstShift);
			butterfly8(temp, result, secondShift);
			break;
		case 16:
			butterfly16(residual, temp, firstShift);
			butterfly16(temp, result, secondShift);
			break;
		case 32:
			butterfly32(residual, temp, firstShift);
			butterfly32(temp, result, secondShift);
			break;
		default:
			break;
		}
	}

	// debug printing
#if DEBUG
	printf("Temp(1DCT) matrix:\n");
	printMatrix(temp, nTbS);
	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);

#endif // DEBUG

	// cleanup

	free(temp);
}

/*
 * Function implements inverse transform using butterfly algorithms in C
 */
void inverseTransform_butterfly(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * transform, int16_t * result) {

	uint8_t firstShift, secondShift;
	int16_t * temp;

	temp = (int16_t *) malloc(sizeof(int16_t) * nTbS * nTbS);

	firstShift = 7;
	secondShift = 20 - BitDepth;

	// handle alternate DST transform of 4x4 blocks
	if (predictionMode == MODE_INTRA && nTbS == 4) {
		inverseDST(transform, temp, firstShift);
		inverseDST(temp, result, secondShift);
	}
	// handle everything else using butterfly algorithms from x265
	else {
		switch (nTbS) {
		case 4:
			inverseButterfly4(transform, temp, firstShift);
			inverseButterfly4(temp, result, secondShift);
			break;
		case 8:
			inverseButterfly8(transform, temp, firstShift);
			inverseButterfly8(temp, result, secondShift);
			break;
		case 16:
			inverseButterfly16(transform, temp, firstShift);
			inverseButterfly16(temp, result, secondShift);
			break;
		case 32:
			inverseButterfly32(transform, temp, firstShift);
			inverseButterfly32(temp, result, secondShift);
			break;
		default:
			break;
		}
	}

#if DEBUG
	printf("Temp(1DCT) matrix:\n");
	printMatrix(temp, nTbS);
	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);

#endif

	free(temp);

}