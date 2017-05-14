#include "matrix_mul_functions.h"
#include "common.h"
#include "constants.h"

/*
 * Function multiplies same dimension matrices
 */
void mmul_shr(int16_t* src_a, int16_t* src_b, int16_t* dst, uint8_t size,
		uint8_t shift) {
	uint8_t i, j, k;
	int32_t temp;
	for (i = 0; i < size; i++) {
		for (j = 0; j < size; j++) {
			temp = 0;
			for (k = 0; k < size; k++) {
				temp += src_a[i * size + k] * src_b[k * size + j];
			}
			dst[i * size + j] = (temp + (1 << (shift - 1))) >> shift;
		}

	}

}
/*
 * Function multiplies same dimension matrices, second operand is transposed
 */
void mmul_shr_transpose_second(int16_t* src_a, int16_t* src_b, int16_t* dst,
		uint8_t size, uint8_t shift) {
	uint8_t i, j, k;
	uint32_t temp;

	for (i = 0; i < size; i++) {
		for (j = 0; j < size; j++) {
			temp = 0;
			for (k = 0; k < size; k++) {
				temp += src_a[i * size + k] * src_b[j * size + k];
			}
			dst[i * size + j] = (temp + (1 << (shift - 1))) >> shift;
		}

	}

}

/*
 * Function multiplies same dimension matrices, first operand is transposed
 */
void mmul_shr_transpose_first(int16_t* src_a, int16_t* src_b, int16_t* dst,
		uint8_t size, uint8_t shift) {
	uint8_t i, j, k;
	uint32_t temp;

	for (i = 0; i < size; i++) {
		for (j = 0; j < size; j++) {
			temp = 0;
			for (k = 0; k < size; k++) {
				temp += src_a[k * size + i] * src_b[k * size + j];
			}
			dst[i * size + j] = (temp + (1 << (shift - 1))) >> shift;
		}

	}

}

