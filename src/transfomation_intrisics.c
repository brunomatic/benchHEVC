#if USE_INTRISICS

#include "transformation.h"
#include <stdlib.h>
#include "common.h"
#include "constants.h"
#include "arm_neon.h"


void fastForwardDST(const int16_t* block, int16_t* coeff, uint8_t shift);
void inverseDST(const int16_t* tmp, int16_t* block, uint8_t shift);

void butterfly4(const int16_t* src, int16_t* dst, uint8_t shift);
void inverseButterfly4(const int16_t* src, int16_t* dst, uint8_t shift);


/*
	4x4 blocks DST and
*/
void fastForwardDST(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{
	int16x4x4_t data;
	int32x4_t C[4];
	int32x4_t temp[5];
	int32x4_t round = vdupq_n_s32((1 << (shift - 1)));
	int32x4_t shift_v = vdupq_n_s32(-shift);

	data = vld4_s16(src);

	C[0] = vaddl_s16(data.val[0], data.val[3]);		// c[0] = src[0] + src[3];
	C[1] = vaddl_s16(data.val[1], data.val[3]);		// c[1] = src[1] + src[3];
	C[2] = vsubl_s16(data.val[0], data.val[1]);		// c[2] = src[0] - src[1];
	C[3] = vmull_n_s16(data.val[2], 74);			// c[3] = 74 * src[2];

	temp[0] = vmulq_n_s32(C[0], 29);				// 29 * c[0]
	temp[1] = vmulq_n_s32(C[1], 55);				// 55 * c[1]
	temp[0] = vaddq_s32(temp[0], temp[1]);			// 29 * c[0] + 55 * c[1]
	temp[0] = vaddq_s32(temp[0], C[3]);				// 29 * c[0] + 55 * c[1] + c[3]

	temp[1] = vaddl_s16(data.val[0], data.val[1]);	// src[0] + src[1]
	temp[1] = vsubw_s16(temp[1], data.val[3]);		// src[0] + src[1] - src[3]
	temp[1] = vmulq_n_s32(temp[1], 74);				// 74 * (src[0] + src[1] - src[3])

	temp[2] = vmulq_n_s32(C[2], 29);				// 29 * c[2]
	temp[3] = vmulq_n_s32(C[0], 55);				// 55 * c[0]
	temp[2] = vaddq_s32(temp[2], temp[3]);			// 29 * c[2] + 55 * c[0]
	temp[2] = vsubq_s32(temp[2], C[3]);				// 29 * c[2] + 55 * c[0] - c[3]

	temp[3] = vmulq_n_s32(C[2], 55);				// 55 * c[2]
	temp[4] = vmulq_n_s32(C[1], 29);				// 29 * c[1]
	temp[3] = vsubq_s32(temp[3], temp[4]);			// 55 * c[2] - 29 * c[1]
	temp[3] = vaddq_s32(temp[3], C[3]);				// 55 * c[2] - 29 * c[1] + c[3]

	temp[0] = vaddq_s32(temp[0], round);			// 29 * c[0] + 55 * c[1] + c[3] + round
	temp[1] = vaddq_s32(temp[1], round);			// 74 * (src[0] + src[1] - src[3])  + round
	temp[2] = vaddq_s32(temp[2], round);			// 29 * c[2] + 55 * c[0] - c[3]  + round
	temp[3] = vaddq_s32(temp[3], round);  			// 55 * c[2] - 29 * c[1] + c[3]  + round

	temp[0] = vqshlq_s32(temp[0], shift_v);			// (29 * c[0] + 55 * c[1] + c[3] + round)>>shift
	temp[1] = vqshlq_s32(temp[1], shift_v);			// (74 * (src[0] + src[1] - src[3])  + round)>>shift
	temp[2] = vqshlq_s32(temp[2], shift_v);			// (29 * c[2] + 55 * c[0] - c[3]  + round)>>shift
	temp[3] = vqshlq_s32(temp[3], shift_v);  		// (55 * c[2] - 29 * c[1] + c[3]  + round)>>shift

	data.val[0] = vqmovn_s32(temp[0]);
	data.val[1] = vqmovn_s32(temp[1]);
	data.val[2] = vqmovn_s32(temp[2]);
	data.val[3] = vqmovn_s32(temp[3]);

	vst1_s16(dst, data.val[0]);
	vst1_s16(dst+4, data.val[1]);
	vst1_s16(dst+8, data.val[2]);
	vst1_s16(dst+12, data.val[3]);

	return;
}
void inverseDST(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{
	int16x4x4_t data;
	int32x4_t C[4];
	int32x4_t temp[5];
	int32x4_t round = vdupq_n_s32((1 << (shift - 1)));
	int32x4_t shift_v = vdupq_n_s32(-shift);


	data.val[0] = vld1_s16(src);
	data.val[1] = vld1_s16(src+4);
	data.val[2] = vld1_s16(src+8);
	data.val[3] = vld1_s16(src+12);

	C[0] = vaddl_s16(data.val[0], data.val[2]);		// c[0] = src[0] + src[2];
	C[1] = vaddl_s16(data.val[2], data.val[3]);		// c[1] = src[2] + src[3];
	C[2] = vsubl_s16(data.val[0], data.val[3]);		// c[2] = src[0] - src[3];
	C[3] = vmull_n_s16(data.val[1], 74);			// c[3] = 74 * src[1];

	temp[0] = vmulq_n_s32(C[0], 29);				// 29 * c[0]
	temp[1] = vmulq_n_s32(C[1], 55);				// 55 * c[1]
	temp[0] = vaddq_s32(temp[0], temp[1]);			// 29 * c[0] + 55 * c[1]
	temp[0] = vaddq_s32(temp[0], C[3]);				// 29 * c[0] + 55 * c[1] + c[3]

	temp[1] = vmulq_n_s32(C[2], 55);				// 55 * c[2]
	temp[2] = vmulq_n_s32(C[1], 29);				// 29 * c[1]
	temp[1] = vsubq_s32(temp[1], temp[2]);			// 55 * c[2] - 29 * c[1]
	temp[1] = vaddq_s32(temp[1], C[3]);				// 55 * c[2] - 29 * c[1] + c[3]

	temp[2] = vsubl_s16(data.val[0], data.val[2]);	// src[0] - src[2]
	temp[2] = vaddw_s16(temp[2], data.val[3]);		// src[0] - src[1] + src[3]
	temp[2] = vmulq_n_s32(temp[2], 74);				// 74 * (src[0] - src[1] + src[3])

	temp[3] = vmulq_n_s32(C[0], 55);				// 55 * c[0]
	temp[4] = vmulq_n_s32(C[2], 29);				// 29 * c[2]
	temp[3] = vaddq_s32(temp[3], temp[4]);			// 55 * c[0] + 29 * c[2]
	temp[3] = vsubq_s32(temp[3], C[3]);				// 55 * c[2] + 29 * c[1] - c[3]

	temp[0] = vaddq_s32(temp[0], round);			// 29 * c[0] + 55 * c[1] + c[3] + round
	temp[1] = vaddq_s32(temp[1], round);			// 55 * c[2] - 29 * c[1] + c[3]  + round
	temp[2] = vaddq_s32(temp[2], round);			// 74 * (src[0] - src[1] + src[3])  + round
	temp[3] = vaddq_s32(temp[3], round);  			// 55 * c[2] + 29 * c[1] - c[3]  + round

	temp[0] = vqshlq_s32(temp[0], shift_v);			// (29 * c[0] + 55 * c[1] + c[3] + round)>>shift
	temp[1] = vqshlq_s32(temp[1], shift_v);			// (55 * c[2] - 29 * c[1] + c[3]  + round) + round)>>shift
	temp[2] = vqshlq_s32(temp[2], shift_v);			// (74 * (src[0] - src[1] + src[3]) + round)>>shift
	temp[3] = vqshlq_s32(temp[3], shift_v);  		// (55 * c[2] + 29 * c[1] - c[3]  + round)>>shift

	data.val[0] = vqmovn_s32(temp[0]);
	data.val[1] = vqmovn_s32(temp[1]);
	data.val[2] = vqmovn_s32(temp[2]);
	data.val[3] = vqmovn_s32(temp[3]);

	vst4_s16(dst, data);

	return;
}

/*
	4x4 blocks - DCT and iDCT
*/
void butterfly4(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{

	int16x4x4_t data;
	int32x4x2_t E, O;
	int32x4_t temp[10];
	int32x4_t round = vdupq_n_s32((1 << (shift - 1)));
	int32x4_t shift_v = vdupq_n_s32(-shift);

	data = vld4_s16(src);

	E.val[0] = vaddl_s16(data.val[0], data.val[1]);
	E.val[1] = vaddl_s16(data.val[2], data.val[3]);

	O.val[0] = vsubl_s16(data.val[0], data.val[1]);
	O.val[1] = vsubl_s16(data.val[2], data.val[3]);

	temp[0] = vmulq_n_s32(E.val[0], 64);	// E[0]*64
	temp[1] = vmulq_n_s32(E.val[1], 64);	// E[1]*64

	temp[2] = vmulq_n_s32(E.val[1], -64);	// E[1]*-64

	temp[3] = vmulq_n_s32(O.val[0], 83);	// O[0]*83
	temp[4] = vmulq_n_s32(O.val[1], 36);	// O[1]*36

	temp[5] = vmulq_n_s32(O.val[0], 36);	// O[0]*36
	temp[6] = vmulq_n_s32(O.val[1], -83);	// O[1]*-83


	temp[7] = vaddq_s32(temp[0], temp[1]);	// E[0]*64 + E[1]*64
	temp[8] = vaddq_s32(temp[0], temp[2]);	// E[0]*64 + E[1]*-64

	temp[9] = vaddq_s32(temp[3], temp[4]);  // O[0]*83 + O[1]*36
	temp[10] = vaddq_s32(temp[5], temp[6]);	// O[0]*83 + O[1]*36

	temp[7] = vaddq_s32(temp[7], round);	// E[0]*64 + E[1]*64 + round
	temp[8] = vaddq_s32(temp[8], round);	// E[0]*64 + E[1]*-64 + round
	temp[9] = vaddq_s32(temp[9], round);	// O[0]*83 + O[1]*36 + round
	temp[10] = vaddq_s32(temp[10], round);  // O[0]*83 + O[1]*36 + round


	temp[7] = vqshlq_s32(temp[7], shift_v);		// (E[0]*64 + E[1]*64 + round)>>shift
	temp[8] = vqshlq_s32(temp[8], shift_v); 	// (E[0]*64 + E[1]*-64 + round)>>shift
	temp[9] = vqshlq_s32(temp[9], shift_v); 	// (O[0]*83 + O[1]*36 + round)>>shift
	temp[10] = vqshlq_s32(temp[10], shift_v);	// (O[0]*83 + O[1]*36 + round)>>shift

	data.val[0] = vqmovn_s32(temp[7]);
	data.val[1] = vqmovn_s32(temp[8]);
	data.val[2] = vqmovn_s32(temp[9]);
	data.val[3] = vqmovn_s32(temp[10]);

	vst1_s16(dst, data.val[0]);
	vst1_s16(dst+4, data.val[1]);
	vst1_s16(dst+8, data.val[2]);
	vst1_s16(dst+12, data.val[3]);

	return;

}
void inverseButterfly4(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{
	int16x4x4_t data;
	int32x4x2_t E, O;
	int32x4_t temp[7];
	int32x4_t round = vdupq_n_s32((1 << (shift - 1)));
	int32x4_t shift_v = vdupq_n_s32(-shift);

	data = vld4_s16(src);

	temp[0] = vmull_n_s16(data.val[0], 64);	// src[0]*64
	temp[1] = vmull_n_s16(data.val[2], 64);	// src[2]*64

	temp[2] = vmull_n_s16(data.val[1], 83);	// src[1]*83
	temp[3] = vmull_n_s16(data.val[3], 36);	// src[3]*36

	temp[4] = vmull_n_s16(data.val[1], 36);		// src[1]*36
	temp[5] = vmull_n_s16(data.val[3], -83);	// src[3]*-83

	temp[6] = vmull_n_s16(data.val[1], -64);	// src[2]*-64

	E.val[0] = vaddq_s32(temp[0], temp[1]);  // E[0] = 64 * src[0] + 64 * src[2];
	O.val[0] = vaddq_s32(temp[2], temp[3]);	 // O[0] = 83 * src[1] + 36 * src[3];
	O.val[1] = vaddq_s32(temp[4], temp[5]);	 // O[1] = 36 * src[1] + -83 * src[3];
	E.val[1] = vaddq_s32(temp[0], temp[6]);	 // E[1] = 64 * src[0] + -64 * src[2];

	temp[0] = vaddq_s32(E.val[0], O.val[0]);	// E[0] + O[0]
	temp[1] = vsubq_s32(E.val[0], O.val[0]);	// E[0] - O[0]
	temp[2] = vaddq_s32(E.val[1], O.val[1]);	// E[1] + O[1]
	temp[3] = vsubq_s32(E.val[1], O.val[1]);	// E[1] - O[1]

	temp[0] = vaddq_s32(temp[0], round);	// E[0] + O[0] + round
	temp[1] = vaddq_s32(temp[1], round);	// E[0] - O[0] + round
	temp[2] = vaddq_s32(temp[2], round);	// E[1] + O[1] + round
	temp[3] = vaddq_s32(temp[3], round);	// E[1] - O[1] + round

	temp[0] = vqshlq_s32(temp[0], shift_v);	// clip((E[0] + O[0] + round)>>shift)
	temp[1] = vqshlq_s32(temp[1], shift_v);	// clip((E[0] - O[0] + round)>>shift)
	temp[2] = vqshlq_s32(temp[2], shift_v);	// clip((E[1] + O[1] + round)>>shift)
	temp[3] = vqshlq_s32(temp[3], shift_v);	// clip((E[1] - O[1] + round)>>shift)

	data.val[0] = vqmovn_s32(temp[0]);	// clip(E[0] + O[0] + round)
	data.val[1] = vqmovn_s32(temp[1]);	// clip(E[0] - O[0] + round)
	data.val[2] = vqmovn_s32(temp[2]);	// clip(E[1] + O[1] + round)
	data.val[3] = vqmovn_s32(temp[3]);	// clip(E[1] - O[1] + round)


	vst1_s16(dst, data.val[0]);
	vst1_s16(dst+4, data.val[2]);
	vst1_s16(dst+8, data.val[3]);
	vst1_s16(dst+12, data.val[1]);

	return;
}

#endif
