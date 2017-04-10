#ifndef TRANSFORMATION_HEADER
#define TRANSFORMATION_HEADER

#include "types.h"

void transform(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result);
void inverseTransform(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result);

#endif // !TRANSFORMATION_HEADER
