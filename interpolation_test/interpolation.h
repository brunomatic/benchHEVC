#ifndef INTERPOLATION_HEADER
#define INTERPOLATION_HEADER

#include "types.h"

void fractionalInterpolation(						\
	image * picture, uint32_t xPb, uint32_t yPb,	\
	uint8_t nPbW, uint8_t nPbH,						\
	int16_t mvLX[2], int16_t mvCLX[2],				\
	uint8_t ChromaArrayType,						\
	predictionSample * Y, predictionSample * Cb, predictionSample * Cr);

int16_t interpolateLumaSample(int32_t xInt, int32_t yInt, uint8_t xFract, uint8_t yFract, image * picture);

void interpolateChromaSample(int32_t x, int32_t y, uint8_t xFract, uint8_t yFract, image * picture, int16_t * CbSample, int16_t * CrSample);

#endif // !INTERPOLATION_HEADER
