#ifndef NEON_TRANSFORM_HEADER
#define NEON_TRANSFORM_HEADER

#include "types.h"

void transform_neon(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS,
		uint8_t cIdx, int16_t * residual, int16_t * result);

#endif
