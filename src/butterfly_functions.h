#ifndef BUTTERFLY_FUNCTIONS_HEADER
#define BUTTERFLY_FUNCTIONS_HEADER

#include "types.h"

/*
 Butterfly algorithms - source: x265 reference source
 https://bitbucket.org/multicoreware/x265/src/
 */
void fastForwardDST(const int16_t* block, int16_t* coeff, uint8_t shift);
void inverseDST(const int16_t* tmp, int16_t* block, uint8_t shift);

void butterfly4(const int16_t* src, int16_t* dst, uint8_t shift);
void inverseButterfly4(const int16_t* src, int16_t* dst, uint8_t shift);

void butterfly8(const int16_t* src, int16_t* dst, uint8_t shift);
void inverseButterfly8(const int16_t* src, int16_t* dst, uint8_t shift);

void butterfly16(const int16_t* src, int16_t* dst, uint8_t shift);
void inverseButterfly16(const int16_t* src, int16_t* dst, uint8_t shift);

void butterfly32(const int16_t* src, int16_t* dst, uint8_t shift);
void inverseButterfly32(const int16_t* src, int16_t* dst, uint8_t shift);

#endif
