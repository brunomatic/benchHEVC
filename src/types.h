#ifndef TYPES_HEADER
#define TYPES_HEADER

#include <stdint.h>

typedef struct {
	uint8_t * Y;
	uint8_t * Cb;
	uint8_t * Cr;
	uint32_t height;
	uint32_t width;
	uint8_t bitDepthY;
	uint8_t bitDepthC;
	uint8_t SubHeight;
	uint8_t SubWidth;
	uint8_t format;
} image;

typedef struct {
	int16_t * data;
	uint32_t width;
	uint32_t height;
} predictionSample;

#endif // !TYPES_HEADER
