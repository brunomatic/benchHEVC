#ifndef MATRIX_MUL_TRANSFORM_HEADER
#define MATRIX_MUL_TRANSFORM_HEADER

#include "types.h"

void transform_matrix_mul(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result);

void inverseTransform_matrix_mul(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * transform, int16_t * result);

#endif
