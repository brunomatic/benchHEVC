#ifndef BENCHMARK_HEADER
#define BENCHMARK_HEADER

#include "types.h"

void benchTransform(uint32_t numberOfIterations, uint8_t blockSize,
		uint8_t mode);

void benchInterpolation(uint32_t numberOfIterations, uint8_t blockWidth,
		uint8_t blockHeight);

#endif // !BENCHMARK_HEADER
