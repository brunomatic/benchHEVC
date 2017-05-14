#include "matrix_mul_transform_hw.h"
#include "matrix_mul_functions_hw.h"
#include "matrix_mul_functions.h"
#include <stdlib.h>
#include "common.h"
#include "constants.h"
#include <sds_lib.h>

/*
 * Function implements forward transform using matrix multiplication
 */
void transform_matrix_mul_hw(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result) {
	uint8_t firstShift = 0, secondShift = 0;
	int16_t * temp;

	//temp = (int16_t *)sds_alloc(sizeof(int16_t)* nTbS * nTbS);

	// set shift variable based on block size and bit depth
	switch (nTbS) {
	case 4:
		if (predictionMode == MODE_INTRA) {
			transform_4_hw(&dst4, residual, result);
		} else {
			transform_4_hw(&dct4, residual, result);
		}
		break;
	case 8:
		transform_8_hw(&dct8, residual, result);
		break;
	case 16:
		firstShift = BitDepth + 4 - 9;
		secondShift = 4 + 6;
		mmul_shr(&dct16, residual, temp, nTbS, firstShift);
		mmul_shr_transpose_second(temp, &dct16, result, nTbS, secondShift);
		break;
	case 32:
		transform_32_hw(&dct32, residual, result);
		break;
	default:
		break;
	}

// debug printing
#if DEBUG
	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);

#endif // DEBUG

// cleanup

	free(temp);

}

/*
 *	Function implements inverse transformation using matrix multiplication
 */
void inverseTransform_matrix_mul_hw(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * transform, int16_t * result) {

	uint8_t firstShift, secondShift;
	int16_t * temp;

	firstShift = 7;
	secondShift = 20 - BitDepth;

	temp = (int16_t *) calloc(sizeof(int32_t), nTbS * nTbS);

	switch (nTbS) {
	case 4:
		if (predictionMode == MODE_INTRA) {
			mmul_shr_transpose_first(&dst4, transform, temp, nTbS, firstShift);
			mmul_shr(temp, &dst4, result, nTbS, secondShift);
		} else {
			mmul_shr_transpose_first(&dct4, transform, temp, nTbS, firstShift);
			mmul_shr(temp, &dct4, result, nTbS, secondShift);
		}
		break;
	case 8:
		mmul_shr_transpose_first(&dct8, transform, temp, nTbS, firstShift);
		mmul_shr(temp, &dct8, result, nTbS, secondShift);
		break;
	case 16:
		mmul_shr_transpose_first(&dct16, transform, temp, nTbS, firstShift);
		mmul_shr(temp, &dct16, result, nTbS, secondShift);
		break;
	case 32:
		mmul_shr_transpose_first(&dct32, transform, temp, nTbS, firstShift);
		mmul_shr(temp, &dct32, result, nTbS, secondShift);
		break;
	default:
		break;
	}

#if DEBUG
	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);
#endif

// cleanup
	free(temp);

}
