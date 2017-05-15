#include "matrix_mul_functions_hw.h"

/*
 * Transform for 4x4 matrix
 */
void transform_4_hw(int16_t * src_a, int16_t * src_b, int16_t * dst) {
	uint8_t i, j, k;
	int32_t temp32;
	int16_t a_buf[4][4], b_buf[4][4], temp[4][4];
#pragma HLS array_partition variable=a_buf block factor=4 dim=2
#pragma HLS array_partition variable=b_buf block factor=4 dim=1
#pragma HLS array_partition variable=temp block factor=4 dim=2

// copy to internal buffers
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
#pragma HLS PIPELINE
			a_buf[i][j] = src_a[i * 4 + j];
			b_buf[i][j] = src_b[i * 4 + j];
		}
	}

// multiply transform matrix with residual to temporary buffer
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
#pragma HLS PIPELINE
			temp32 = 0;
			for (k = 0; k < 4; k++) {
				temp32 += a_buf[i][k] * b_buf[k][j];
			}
			temp[i][j] = temp32 >> 1;
		}
	}

// multiply temporary buffer with transposed transform matrix and send it out
	for (i = 0; i < 4; i++) {
			for (j = 0; j < 4; j++) {
#pragma HLS PIPELINE
				temp32 = 0;
				for (k = 0; k < 4; k++) {
					temp32 += temp[i][k] * a_buf[j][k];
				}
				dst[i*4+j] = (temp32 + (1 << 7)) >> 8;
			}
	}

}
/*
 * Transform for 8x8 matrix
 */
void transform_8_hw(int16_t * src_a, int16_t * src_b, int16_t * dst) {
	uint8_t i, j, k;
	int32_t temp32;
	int16_t a_buf[8][8], b_buf[8][8], temp[8][8];
#pragma HLS array_partition variable=a_buf block factor=8 dim=2
#pragma HLS array_partition variable=b_buf block factor=8 dim=1
#pragma HLS array_partition variable=temp block factor=8 dim=2

// copy to internal buffers
	for (i = 0; i < 8; i++) {
		for (j = 0; j < 8; j++) {
#pragma HLS PIPELINE
			a_buf[i][j] = src_a[i * 8 + j];
			b_buf[i][j] = src_b[i * 8 + j];
		}
	}

// multiply transform matrix with residual to temporary buffer
	for (i = 0; i < 8; i++) {
		for (j = 0; j < 8; j++) {
#pragma HLS PIPELINE
			temp32 = 0;
			for (k = 0; k < 8; k++) {
				temp32 += a_buf[i][k] * b_buf[k][j];
			}
			temp[i][j] = (temp32 + (1 << 1)) >> 2;
		}
	}

// multiply temporary buffer with transposed transform matrix and send it out
	for (i = 0; i < 8; i++) {
			for (j = 0; j < 8; j++) {
#pragma HLS PIPELINE
				temp32 = 0;
				for (k = 0; k < 8; k++) {
					temp32 += temp[i][k] * a_buf[j][k];
				}
				dst[i * 8 + j] = (temp32 + (1 << 8)) >> 9;
			}
	}

}

/*
 * Transform for 16x16 matrix
 */
void transform_16_hw(int16_t * src_a, int16_t * src_b, int16_t * dst) {
	uint8_t i, j, k;
	int32_t temp32;
	int16_t a_buf[16][16], b_buf[16][16], temp[16][16];
#pragma HLS array_partition variable=a_buf block factor=16 dim=2
#pragma HLS array_partition variable=b_buf block factor=16 dim=1
#pragma HLS array_partition variable=temp block factor=16 dim=2

// copy to internal buffers
	for (i = 0; i < 16; i++) {
		for (j = 0; j < 16; j++) {
#pragma HLS PIPELINE
			a_buf[i][j] = src_a[i * 16 + j];
			b_buf[i][j] = src_b[i * 16 + j];
		}
	}

// multiply transform matrix with residual to temporary buffer
	for (i = 0; i < 16; i++) {
		for (j = 0; j < 16; j++) {
#pragma HLS PIPELINE
			temp32 = 0;
			for (k = 0; k < 16; k++) {
				temp32 += a_buf[i][k] * b_buf[k][j];
			}
			temp[i][j] = (temp32 + (1 << 2)) >> 3;
		}
	}

// multiply temporary buffer with transposed transform matrix and send it out
	for (i = 0; i < 16; i++) {
			for (j = 0; j < 16; j++) {
#pragma HLS PIPELINE
				temp32 = 0;
				for (k = 0; k < 16; k++) {
					temp32 += temp[i][k] * a_buf[j][k];
				}
				dst[i * 16 + j] = (temp32 + (1 << 9)) >> 10;
			}
	}

}

/*
 * Transform for 32x32 matrix
 */
void transform_32_hw(int16_t * src_a, int16_t * src_b, int16_t * dst) {
	uint8_t i, j, k;
	int32_t temp32;
	int16_t a_buf[32][32], b_buf[32][32], temp[32][32];
#pragma HLS array_partition variable=a_buf block factor=32 dim=2
#pragma HLS array_partition variable=b_buf block factor=32 dim=1
#pragma HLS array_partition variable=temp block factor=32 dim=2

// copy to internal buffers
	for (i = 0; i < 32; i++) {
		for (j = 0; j < 32; j++) {
#pragma HLS PIPELINE
			a_buf[i][j] = src_a[i * 32 + j];
			b_buf[i][j] = src_b[i * 32 + j];
		}
	}

// multiply transform matrix with residual to temporary buffer
	for (i = 0; i < 32; i++) {
		for (j = 0; j < 32; j++) {
#pragma HLS PIPELINE
			temp32 = 0;
			for (k = 0; k < 32; k++) {
				temp32 += a_buf[i][k] * b_buf[k][j];
			}
			temp[i][j] = (temp32 + (1 << 3)) >> 4;
		}
	}

// multiply temporary buffer with transposed transform matrix and send it out
	for (i = 0; i < 32; i++) {
			for (j = 0; j < 32; j++) {
#pragma HLS PIPELINE
				temp32 = 0;
				for (k = 0; k < 32; k++) {
					temp32 += temp[i][k] * a_buf[j][k];
				}
				dst[i * 32 + j] = (temp32 + (1 << 10)) >> 11;
			}
	}

}
