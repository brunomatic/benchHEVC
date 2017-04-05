#ifndef HELPER_HEADER
#define HELPER_HEADER

#include "types.h"

void generatePicture(image * picture, uint32_t w, uint32_t h, uint8_t format);

void printPlane(image * img, uint8_t component);

void printPlaneSegment(image * img, uint8_t sizeX, uint8_t sizeY, uint32_t x, uint32_t y, uint8_t component);

void writeImage(image * img, uint8_t * filename);

void printMatrix(int16_t * matrix, uint8_t size);

void generateResidual(uint8_t blockSize, int16_t * residual);

void generateRandomMV(uint32_t * xPb, uint32_t * yPb, int16_t * mvLX, int16_t * mvCLX, uint32_t width, uint32_t height, uint8_t blockWidth, uint8_t blockHeight);

#endif // !HELPER_HEADER
