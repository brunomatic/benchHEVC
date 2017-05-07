#include "matrix_mul_transform.h"
#include <stdlib.h>
#include "common.h"
#include "constants.h"

/*
 * Function implements forward transform using matrix multiplication
 */
void transform_matrix_mul(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result) {
	uint8_t firstShift = 0, secondShift = 0;
	int32_t * temp;
	int32_t sum = 0;
	uint8_t i, j, k, stepSize;

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

	temp = (int32_t *) calloc(sizeof(int32_t), nTbS * nTbS);

	// check if it is alternate transform - DST
	if (predictionMode == MODE_INTRA && nTbS == 4) {
		for (i = 0; i < nTbS; i++) {
			for (j = 0; j < nTbS; j++) {
				for (k = 0; k < nTbS; k++) {
					temp[i * nTbS + j] += dstMatrix[i][k]
							* residual[k * nTbS + j];
				}
				temp[i * nTbS + j] = (temp[i * nTbS + j] + (1 << (firstShift-1)))>> firstShift;
			}

		}

		for (i = 0; i < nTbS; i++) {
			for (j = 0; j < nTbS; j++) {
				for (k = 0; k < nTbS; k++) {
					sum += temp[i * nTbS + k] * dstMatrix[j][k];
				}
				result[i * nTbS + j] = (sum + (1 << (secondShift-1)))>> secondShift;
				sum = 0;
			}

		}

	}
	// if not use regular DCT matrix and calculate the step size based on block size
	else {
		stepSize = 32 / nTbS;

		// fist multiply with transformation matrix and shift
		for (i = 0; i < nTbS; i++) {
			for (j = 0; j < nTbS; j++) {
				for (k = 0; k < nTbS; k++) {
					temp[i * nTbS + j] += dctMatrix[i * stepSize][k]
							* residual[k * nTbS + j];
				}
				temp[i * nTbS + j] = (temp[i * nTbS + j]+ (1 << (firstShift-1))) >> firstShift;
			}

		}

		for (i = 0; i < nTbS; i++) {
			for (j = 0; j < nTbS; j++) {
				for (k = 0; k < nTbS; k++) {
					sum += temp[i * nTbS + k] * dctMatrix[j * stepSize][k];
				}
				result[i * nTbS + j] = (sum + (1 << (secondShift-1))) >> secondShift;
				sum = 0;
			}

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
 *	Function implements inverse transformation using matrix multiplication
 */
void inverseTransform_matrix_mul(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * transform, int16_t * result) {

	uint8_t firstShift, secondShift;
	int32_t * temp;
	int32_t sum = 0;
	uint8_t i, j, k, stepSize;

	firstShift = 7;
	secondShift = 20 - BitDepth;

	temp = (int32_t *) calloc(sizeof(int32_t), nTbS * nTbS);

	// check if it is alternate tranform - DST
	if (predictionMode == MODE_INTRA && nTbS == 4) {
		for (i = 0; i < nTbS; i++) {
			for (j = 0; j < nTbS; j++) {
				for (k = 0; k < nTbS; k++) {
					temp[i * nTbS + j] += dstMatrix[k][i]
							* transform[k * nTbS + j];
				}
				temp[i * nTbS + j] = (temp[i * nTbS + j] + (1 << (firstShift-1)))>> firstShift;
			}

		}

		for (i = 0; i < nTbS; i++) {
			for (j = 0; j < nTbS; j++) {
				for (k = 0; k < nTbS; k++) {
					sum += temp[i * nTbS + k] * dstMatrix[k][j];
				}
				result[i * nTbS + j] = (sum + (1 << (secondShift-1)))  >> secondShift;
				sum = 0;
			}

		}

	}
	// if not use regular DCT matrix and calculate the step size based on block size
	else {
		stepSize = 32 / nTbS;

		// fist multiply with transformation matrix and shift
		for (i = 0; i < nTbS; i++) {
			for (j = 0; j < nTbS; j++) {
				for (k = 0; k < nTbS; k++) {
					temp[i * nTbS + j] += dctMatrix[k][i * stepSize]
							* transform[k * nTbS + j];
				}
				temp[i * nTbS + j] = (temp[i * nTbS + j] + (1 << (firstShift-1))) >> firstShift;
			}

		}

		for (i = 0; i < nTbS; i++) {
			for (j = 0; j < nTbS; j++) {
				for (k = 0; k < nTbS; k++) {
					sum += temp[i * nTbS + k] * dctMatrix[k][j];
				}
				result[i * nTbS + j] = (sum + (1 << (secondShift - 1)))
						>> secondShift;
				sum = 0;
			}

		}

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
