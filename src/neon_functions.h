#ifndef DCT_FUNC_HEADER
#define DCT_FUNC_HEADER

void dst_4x4_neon(int16_t * src, int16_t * dst);
void dst_4x4_1_neon(int16_t * src, int16_t * dst);
void x265_dct_4x4_neon(int16_t * src, int16_t * dst);
void x265_dct_8x8_neon(int16_t * src, int16_t * dst);
void x265_dct_16x16_neon(int16_t * src, int16_t * dst);
void dct_32x32_neon(int16_t * src, int16_t * dst);

#endif
