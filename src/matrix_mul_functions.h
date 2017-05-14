#ifndef MATRIX_MUL_FUNCTIONS_HEADER
#define MATRIX_MUL_FUNCTIONS_HEADER

#include "types.h"

void mmul_shr(int16_t* coeff, int16_t* src, int16_t* dst, uint8_t size,
		uint8_t shift);
void mmul_shr_transpose_second(int16_t* src_a, int16_t* src_b, int16_t* dst,
		uint8_t size, uint8_t shift);
void mmul_shr_transpose_first(int16_t* src_a, int16_t* src_b, int16_t* dst,
		uint8_t size, uint8_t shift);

#endif
