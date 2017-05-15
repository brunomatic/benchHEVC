#include "matrix_mul_transform.h"
#include "matrix_mul_functions.h"
#include <stdlib.h>
#include "common.h"
#include "constants.h"

/*
 * Function implements forward transform using matrix multiplication
 */
void transform_matrix_mul(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result) {
	uint8_t firstShift = 0, secondShift = 0;
	int16_t * temp;

	temp = (int16_t *) calloc(sizeof(int16_t), nTbS * nTbS);

	// set shift variable based on block size and bit depth
	switch (nTbS) {
	case 4:
		firstShift = BitDepth + 2 - 9;
		secondShift = 2 + 6;
		if (predictionMode == MODE_INTRA) {
			mmul_shr((int16_t *)&dst4, residual, temp, nTbS, firstShift);
			mmul_shr_transpose_second(temp, (int16_t *)&dst4, result, nTbS, secondShift);
		} else {
			mmul_shr((int16_t *)&dct4, residual, temp, nTbS, firstShift);
			mmul_shr_transpose_second(temp, (int16_t *)&dct4, result, nTbS, secondShift);
		}
		break;
	case 8:
		firstShift = BitDepth + 3 - 9;
		secondShift = 3 + 6;
		mmul_shr((int16_t *)&dct8, residual, temp, nTbS, firstShift);
		mmul_shr_transpose_second(temp, (int16_t *)&dct8, result, nTbS, secondShift);
		break;
	case 16:
		firstShift = BitDepth + 4 - 9;
		secondShift = 4 + 6;
		mmul_shr((int16_t *)&dct16, residual, temp, nTbS, firstShift);
		mmul_shr_transpose_second(temp, (int16_t *)&dct16, result, nTbS, secondShift);
		break;
	case 32:
		firstShift = BitDepth + 5 - 9;
		secondShift = 5 + 6;
		mmul_shr((int16_t *)&dct32, residual, temp, nTbS, firstShift);
		mmul_shr_transpose_second(temp, (int16_t *)&dct32, result, nTbS, secondShift);
		break;
	default:
		break;
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
 *	Function implements inverse transformation using matrix multiplication
 */
void inverseTransform_matrix_mul(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * transform, int16_t * result) {

	uint8_t firstShift, secondShift;
	int16_t * temp;

	firstShift = 7;
	secondShift = 20 - BitDepth;

	temp = (int16_t *) calloc(sizeof(int32_t), nTbS * nTbS);

	switch (nTbS) {
	case 4:
		if (predictionMode == MODE_INTRA) {
			mmul_shr_transpose_first((int16_t *)&dst4, transform, temp, nTbS, firstShift);
			mmul_shr(temp, (int16_t *)&dst4, result, nTbS, secondShift);
		} else {
			mmul_shr_transpose_first((int16_t *)&dct4, transform, temp, nTbS, firstShift);
			mmul_shr(temp, (int16_t *)&dct4, result, nTbS, secondShift);
		}
		break;
	case 8:
		mmul_shr_transpose_first((int16_t *)&dct8, transform, temp, nTbS, firstShift);
		mmul_shr(temp, (int16_t *)&dct8, result, nTbS, secondShift);
		break;
	case 16:
		mmul_shr_transpose_first((int16_t *)&dct16, transform, temp, nTbS, firstShift);
		mmul_shr(temp, (int16_t *)&dct16, result, nTbS, secondShift);
		break;
	case 32:
		mmul_shr_transpose_first((int16_t *)&dct32, transform, temp, nTbS, firstShift);
		mmul_shr(temp, (int16_t *)&dct32, result, nTbS, secondShift);
		break;
	default:
		break;
	}

#if DEBUG
	printf("Temp(1DCT) matrix:\n");
	printMatrix(temp, nTbS);
	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);
#endif

// cleanup
	free(temp);

}
