#include "butterfly_functions_hw.h"

/*
 4x4 blocks DST and
 */
void dst_butterfly_4_hw(int16_t* src, int16_t* dst) {

	uint8_t i, j;
	int16_t src_buf[4][4], temp[4][4];
#pragma HLS array_partition variable=src_buf complete
#pragma HLS array_partition variable=temp complete
	int32_t c[4];
#pragma HLS array_partition variable=c complete

	// copy to internal buffers
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
#pragma HLS PIPELINE
			src_buf[i][j] = src[i * 4 + j];
		}
	}

	for (i = 0; i < 4; i++) {
#pragma HLS PIPELINE
		c[0] = src_buf[i][0] + src_buf[i][3];
		c[1] = src_buf[i][1] + src_buf[i][3];
		c[2] = src_buf[i][0] - src_buf[i][1];
		c[3] = 74 * src_buf[i][2];

		temp[0][i] =(int16_t) ((29 * c[0] + 55 * c[1] + c[3] + (1 << (1 - 1))) >> 1);
		temp[1][i] = (int16_t)((74 * (src_buf[i][0] + src_buf[i][1] - src_buf[i][3]) + (1 << (1 - 1))) >> 1);
		temp[2][i] =(int16_t) ((29 * c[2] + 55 * c[0] - c[3] + (1 << (1 - 1))) >> 1);
		temp[3][i] =(int16_t) ((55 * c[2] - 29 * c[1] + c[3] + (1 << (1 - 1))) >> 1);
	}

	for (i = 0; i < 4; i++) {
#pragma HLS PIPELINE
			c[0] = temp[i][0] + temp[i][3];
			c[1] = temp[i][1] + temp[i][3];
			c[2] = temp[i][0] - temp[i][1];
			c[3] = 74 * temp[i][2];

			dst[i] =(int16_t) ((29 * c[0] + 55 * c[1] + c[3] + (1 << 7)) >> 8);
			dst[4 + i] = (int16_t)((74 * (temp[i][0] + temp[i][1] - temp[i][3]) + (1 << 7)) >> 8);
			dst[8 + i] =(int16_t) ((29 * c[2] + 55 * c[0] - c[3] + (1 << 7)) >> 8);
			dst[12 + i] =(int16_t) ((55 * c[2] - 29 * c[1] + c[3] + (1 << 7)) >> 8);
		}
}

/*
 4x4 blocks - DCT and iDCT
 */
void dct_butterfly_4_hw(int16_t* src, int16_t* dst) {
	uint8_t i, j;
	int32_t E[2], O[2];
#pragma HLS array_partition variable=E complete
#pragma HLS array_partition variable=O complete
	int16_t src_buf[4][4], temp[4][4];
#pragma HLS array_partition variable=src_buf complete
#pragma HLS array_partition variable=temp complete

	// copy to internal buffers
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
#pragma HLS PIPELINE
			src_buf[i][j] = src[i * 4 + j];
		}
	}

	for (i = 0; i < 4; i++) {
#pragma HLS PIPELINE
		E[0] = src_buf[i][0] + src_buf[i][3];
		E[1] = src_buf[i][1] + src_buf[i][2];
		O[0] = src_buf[i][0] - src_buf[i][3];
		O[1] = src_buf[i][1] - src_buf[i][2];

		temp[0][i] = (int16_t) ((64 * E[0] + 64 * E[1] + (1 << (1 - 1))) >> 1);
		temp[1][i] = (int16_t) ((64 * E[0] + -64 * E[1] + (1 << (1 - 1))) >> 1);
		temp[2][i] = (int16_t) ((83 * O[0] + 36 * O[1] + (1 << (1 - 1))) >> 1);
		temp[3][i] = (int16_t) ((36 * O[0] + -83 * O[1] + (1 << (1 - 1))) >> 1);
	}

	for (i = 0; i < 4; i++) {
#pragma HLS PIPELINE
		E[0] = temp[i][0] + temp[i][3];
		E[1] = temp[i][1] + temp[i][2];
		O[0] = temp[i][0] - temp[i][3];
		O[1] = temp[i][1] - temp[i][2];

		dst[i] = (int16_t) ((64 * E[0] + 64 * E[1] + (1 << 7)) >> 8);
		dst[4 + i] = (int16_t) ((64 * E[0] + -64 * E[1] + (1 << 7)) >> 8);
		dst[8 + i] = (int16_t) ((83 * O[0] + 36 * O[1] + (1 << 7)) >> 8);
		dst[12 + i] = (int16_t) ((36 * O[0] + -83 * O[1] + (1 << 7)) >> 8);
	}

}
