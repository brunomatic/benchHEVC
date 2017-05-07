#ifndef BUTTERFLY_TRANSFORM_HEADER
#define BUTTERFLY_TRANSFORM_HEADER

#include "types.h"

void transform_butterfly(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS,
		uint8_t cIdx, int16_t * residual, int16_t * result);
void inverseTransform_butterfly(uint8_t predictionMode, uint8_t BitDepth,
		uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result);

#endif
