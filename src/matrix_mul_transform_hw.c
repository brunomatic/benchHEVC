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

	// set shift variable based on block size and bit depth
	switch (nTbS) {
	case 4:
		if (predictionMode == MODE_INTRA) {
			transform_4_hw((int16_t *)&dst4, residual, result);
		} else {
			transform_4_hw((int16_t *)&dct4, residual, result);
		}
		break;
	case 8:
		transform_8_hw((int16_t *)&dct8, residual, result);
		break;
	case 16:
		transform_16_hw((int16_t *)&dct16, residual, result);
		break;
	case 32:
		transform_32_hw((int16_t *)&dct32, residual, result);
		break;
	default:
		break;
	}

// debug printing
#if DEBUG
	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);

#endif // DEBUG

}
