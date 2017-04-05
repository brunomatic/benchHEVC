#ifndef TRANSFORMATION_HEADER
#define TRANSFORMATION_HEADER


void fastForwardDST(const int16_t* block, int16_t* coeff, uint8_t shift);
void inverseDST(const int16_t* tmp, int16_t* block, uint8_t shift);

void butterfly4(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);
void inverseButterfly4(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);

void butterfly8(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);
void inverseButterfly8(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);

void butterfly16(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);
void inverseButterfly16(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);

void butterfly32(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);
void inverseButterfly32(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);


void transform(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result);
void inverseTransform(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result);

#endif // !TRANSFORMATION_HEADER
