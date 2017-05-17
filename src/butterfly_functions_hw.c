#include "butterfly_functions_hw.h"

/*
 4x4 blocks DST
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

			src_buf[0][i] =(int16_t) ((29 * c[0] + 55 * c[1] + c[3] + (1 << 7)) >> 8);
			src_buf[1][i] = (int16_t)((74 * (temp[i][0] + temp[i][1] - temp[i][3]) + (1 << 7)) >> 8);
			src_buf[2][i] =(int16_t) ((29 * c[2] + 55 * c[0] - c[3] + (1 << 7)) >> 8);
			src_buf[3][i] =(int16_t) ((55 * c[2] - 29 * c[1] + c[3] + (1 << 7)) >> 8);
		}

	// write back
		for (i = 0; i < 4; i++) {
			for (j = 0; j < 4; j++) {
	#pragma HLS PIPELINE
				dst[i * 4 + j] = src_buf[i][j];
			}
		}
}

/*
 4x4 blocks DCT
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

		src_buf[0][i] = (int16_t) ((64 * E[0] + 64 * E[1] + (1 << 7)) >> 8);
		src_buf[1][i] = (int16_t) ((64 * E[0] + -64 * E[1] + (1 << 7)) >> 8);
		src_buf[2][i] = (int16_t) ((83 * O[0] + 36 * O[1] + (1 << 7)) >> 8);
		src_buf[3][i] = (int16_t) ((36 * O[0] + -83 * O[1] + (1 << 7)) >> 8);
	}

	// write back
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
#pragma HLS PIPELINE
			dst[i * 4 + j] = src_buf[i][j];
		}
	}

}

/*
 8x8 blocks DCT
 */
void dct_butterfly_8_hw(int16_t* src, int16_t* dst) {
	int i,j;
	int E[4], O[4];
#pragma HLS array_partition variable=E complete
#pragma HLS array_partition variable=O complete
	int EE[2], EO[2];
#pragma HLS array_partition variable=EE complete
#pragma HLS array_partition variable=EO complete
	int16_t src_buf[8][8], temp[8][8];
#pragma HLS array_partition variable=src_buf complete
#pragma HLS array_partition variable=temp complete

// copy to internal buffers
	for (i = 0; i < 8; i++) {
		for (j = 0; j < 8; j++) {
#pragma HLS PIPELINE
			src_buf[i][j] = src[i * 8 + j];
		}
	}


	for (i = 0; i < 8; i++) {
#pragma HLS PIPELINE
		E[0] = src_buf[i][0] + src_buf[i][7];
		E[1] = src_buf[i][1] + src_buf[i][6];
		E[2] = src_buf[i][2] + src_buf[i][5];
		E[3] = src_buf[i][3] + src_buf[i][4];

		O[0] = src_buf[i][0] - src_buf[i][7];
		O[1] = src_buf[i][1] - src_buf[i][6];
		O[2] = src_buf[i][2] - src_buf[i][5];
		O[3] = src_buf[i][3] - src_buf[i][4];

		/* EE and EO */
		EE[0] = E[0] + E[3];
		EE[1] = E[1] + E[2];
		EO[0] = E[0] - E[3];
		EO[1] = E[1] - E[2];

		temp[0][i] = (int16_t) ((64 * EE[0] + 64 * EE[1] + 0 * EO[0] + 0 * EO[1]+ (1<<1)) >> 2);
		temp[4][i] = (int16_t) ((64 * EE[0] + -64 * EE[1] + 0 * EO[0] + 0 * EO[1]+ (1<<1)) >> 2);
		temp[2][i] = (int16_t) ((0 * EE[0] + 0 * EE[1] + 83 * EO[0] + 36 * EO[1]+ (1<<1)) >> 2);
		temp[6][i] = (int16_t) ((0 * EE[0] + 0 * EE[1] + 36 * EO[0] + -83 * EO[1]+ (1<<1)) >> 2);

		temp[1][i] = (int16_t) ((89 * O[0] + 75 * O[1] + 50 * O[2] + 18 * O[3]+ (1<<1)) >> 2);
		temp[3][i] = (int16_t) ((75 * O[0] + -18 * O[1] + -89 * O[2] + -50 * O[3]+ (1<<1)) >> 2);
		temp[5][i] = (int16_t) ((50 * O[0] + -89 * O[1] + 18 * O[2] + 75 * O[3]+ (1<<1)) >> 2);
		temp[7][i] = (int16_t) ((18 * O[0] + -50 * O[1] + 75 * O[2] + -89 * O[3]+ (1<<1)) >> 2);
	}

	for (i = 0; i < 8; i++) {
#pragma HLS PIPELINE
		E[0] = temp[i][0] + temp[i][7];
		E[1] = temp[i][1] + temp[i][6];
		E[2] = temp[i][2] + temp[i][5];
		E[3] = temp[i][3] + temp[i][4];

		O[0] = temp[i][0] - temp[i][7];
		O[1] = temp[i][1] - temp[i][6];
		O[2] = temp[i][2] - temp[i][5];
		O[3] = temp[i][3] - temp[i][4];

		/* EE and EO */
		EE[0] = E[0] + E[3];
		EE[1] = E[1] + E[2];
		EO[0] = E[0] - E[3];
		EO[1] = E[1] - E[2];

		src_buf[0][i]  = (int16_t) ((64 * EE[0] + 64 * EE[1] + 0 * EO[0] + 0 * EO[1]+ (1<<8)) >> 9);
		src_buf[4][i] = (int16_t) ((64 * EE[0] + -64 * EE[1] + 0 * EO[0] + 0 * EO[1]+ (1<<8)) >> 9);
		src_buf[2][i] = (int16_t) ((0 * EE[0] + 0 * EE[1] + 83 * EO[0] + 36 * EO[1]+ (1<<8)) >> 9);
		src_buf[6][i] = (int16_t) ((0 * EE[0] + 0 * EE[1] + 36 * EO[0] + -83 * EO[1]+ (1<<8)) >> 9);

		src_buf[1][i] = (int16_t) ((89 * O[0] + 75 * O[1] + 50 * O[2] + 18 * O[3]+ (1<<8)) >> 9);
		src_buf[3][i] = (int16_t) ((75 * O[0] + -18 * O[1] + -89 * O[2] + -50 * O[3]+ (1<<8)) >> 9);
		src_buf[5][i] = (int16_t) ((50 * O[0] + -89 * O[1] + 18 * O[2] + 75 * O[3]+ (1<<8)) >> 9);
		src_buf[7][i] = (int16_t) ((18 * O[0] + -50 * O[1] + 75 * O[2] + -89 * O[3]+ (1<<8)) >> 9);
	}

	// write back
	for (i = 0; i < 8; i++) {
		for (j = 0; j < 8; j++) {
#pragma HLS PIPELINE
			dst[i * 8 + j] = src_buf[i][j];
		}
	}

}


/*
 16x16 blocks DCT and iDCT
 */
void dct_butterfly_16_hw(int16_t* src, int16_t* dst) {
	int j, k;
	int E[8], O[8];
#pragma HLS array_partition variable=E complete
#pragma HLS array_partition variable=O complete
	int EE[4], EO[4];
#pragma HLS array_partition variable=E complete
#pragma HLS array_partition variable=O complete
	int EEE[2], EEO[2];
#pragma HLS array_partition variable=E complete
#pragma HLS array_partition variable=O complete
	int16_t src_buf[16][16], temp[16][16];
#pragma HLS array_partition variable=src_buf complete
#pragma HLS array_partition variable=temp complete

	const int16_t dct16[16][16] =
	{
		{ 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64 },
		{ 90, 87, 80, 70, 57, 43, 25,  9, -9, -25, -43, -57, -70, -80, -87, -90 },
		{ 89, 75, 50, 18, -18, -50, -75, -89, -89, -75, -50, -18, 18, 50, 75, 89 },
		{ 87, 57,  9, -43, -80, -90, -70, -25, 25, 70, 90, 80, 43, -9, -57, -87 },
		{ 83, 36, -36, -83, -83, -36, 36, 83, 83, 36, -36, -83, -83, -36, 36, 83 },
		{ 80,  9, -70, -87, -25, 57, 90, 43, -43, -90, -57, 25, 87, 70, -9, -80 },
		{ 75, -18, -89, -50, 50, 89, 18, -75, -75, 18, 89, 50, -50, -89, -18, 75 },
		{ 70, -43, -87,  9, 90, 25, -80, -57, 57, 80, -25, -90, -9, 87, 43, -70 },
		{ 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64 },
		{ 57, -80, -25, 90, -9, -87, 43, 70, -70, -43, 87,  9, -90, 25, 80, -57 },
		{ 50, -89, 18, 75, -75, -18, 89, -50, -50, 89, -18, -75, 75, 18, -89, 50 },
		{ 43, -90, 57, 25, -87, 70,  9, -80, 80, -9, -70, 87, -25, -57, 90, -43 },
		{ 36, -83, 83, -36, -36, 83, -83, 36, 36, -83, 83, -36, -36, 83, -83, 36 },
		{ 25, -70, 90, -80, 43,  9, -57, 87, -87, 57, -9, -43, 80, -90, 70, -25 },
		{ 18, -50, 75, -89, 89, -75, 50, -18, -18, 50, -75, 89, -89, 75, -50, 18 },
		{ 9, -25, 43, -57, 70, -80, 87, -90, 90, -87, 80, -70, 57, -43, 25, -9 }
	};

	// copy to internal buffers
	for (k = 0; k < 16; k++) {
		for (j = 0; j < 16; j++) {
#pragma HLS PIPELINE
			src_buf[k][j] = src[k * 16 + j];
		}
	}
	for (j = 0; j < 16; j++) {
//#pragma HLS PIPELINE
		/* E and O */
		for (k = 0; k < 8; k++) {
#pragma HLS PIPELINE
			E[k] = src_buf[j][k] + src_buf[j][15 - k];
			O[k] = src_buf[j][k] - src_buf[j][15 - k];
		}

		/* EE and EO */
		for (k = 0; k < 4; k++) {
#pragma HLS PIPELINE
			EE[k] = E[k] + E[7 - k];
			EO[k] = E[k] - E[7 - k];
		}

		/* EEE and EEO */
		EEE[0] = EE[0] + EE[3];
		EEO[0] = EE[0] - EE[3];
		EEE[1] = EE[1] + EE[2];
		EEO[1] = EE[1] - EE[2];

		temp[0][j] = (int16_t) ((dct16[0][0] * EEE[0] + dct16[0][1] * EEE[1]+ (1<<2)) >> 3);
		temp[8][j] = (int16_t) ((dct16[8][0] * EEE[0] + dct16[8][1] * EEE[1] + (1<<2)) >> 3);
		temp[4][j] = (int16_t) ((dct16[4][0] * EEO[0] + dct16[4][1] * EEO[1] + (1<<2)) >> 3);
		temp[12][j] = (int16_t) ((dct16[12][0] * EEO[0] + dct16[12][1] * EEO[1] + (1<<2)) >> 3);

		for (k = 2; k < 16; k += 4) {
#pragma HLS PIPELINE
			temp[k][j] = (int16_t) ((dct16[k][0] * EO[0] + dct16[k][1] * EO[1]
						+ dct16[k][2] * EO[2] + dct16[k][3] * EO[3]
						+ (1<<2)) >> 3);
		}

		for (k = 1; k < 16; k += 2) {
#pragma HLS PIPELINE
			temp[k][j] = (int16_t) ((dct16[k][0] * O[0] + dct16[k][1] * O[1]
						+ dct16[k][2] * O[2] + dct16[k][3] * O[3]
						+ dct16[k][4] * O[4] + dct16[k][5] * O[5]
						+ dct16[k][6] * O[6] + dct16[k][7] * O[7]
						+ (1<<2)) >> 3);
		}
	}

		for (j = 0; j < 16; j++) {
//#pragma HLS PIPELINE
		/* E and O */
		for (k = 0; k < 8; k++) {
#pragma HLS PIPELINE
			E[k] = temp[j][k] + temp[j][15 - k];
			O[k] = temp[j][k] - temp[j][15 - k];
		}

		/* EE and EO */
		for (k = 0; k < 4; k++) {
#pragma HLS PIPELINE
			EE[k] = E[k] + E[7 - k];
			EO[k] = E[k] - E[7 - k];
		}

		/* EEE and EEO */
		EEE[0] = EE[0] + EE[3];
		EEO[0] = EE[0] - EE[3];
		EEE[1] = EE[1] + EE[2];
		EEO[1] = EE[1] - EE[2];

		src_buf[0][j] = (int16_t) ((dct16[0][0] * EEE[0] + dct16[0][1] * EEE[1]+ (1<<9)) >> 10);
		src_buf[8][j] = (int16_t) ((dct16[8][0] * EEE[0] + dct16[8][1] * EEE[1] + (1<<9)) >> 10);
		src_buf[4][j] = (int16_t) ((dct16[4][0] * EEO[0] + dct16[4][1] * EEO[1] + (1<<9)) >> 10);
		src_buf[12][j] = (int16_t) ((dct16[12][0] * EEO[0] + dct16[12][1] * EEO[1] + (1<<9)) >> 10);

		for (k = 2; k < 16; k += 4) {
#pragma HLS PIPELINE
			src_buf[k][j] = (int16_t) ((dct16[k][0] * EO[0] + dct16[k][1] * EO[1]
						+ dct16[k][2] * EO[2] + dct16[k][3] * EO[3]
						+ (1<<9)) >> 10);
		}

		for (k = 1; k < 16; k += 2) {
#pragma HLS PIPELINE
			src_buf[k][j] = (int16_t) ((dct16[k][0] * O[0] + dct16[k][1] * O[1]
						+ dct16[k][2] * O[2] + dct16[k][3] * O[3]
						+ dct16[k][4] * O[4] + dct16[k][5] * O[5]
						+ dct16[k][6] * O[6] + dct16[k][7] * O[7]
						+ (1<<9)) >> 10);
		}
	}

	// write back
	for (k = 0; k < 16; k++) {
		for (j = 0; j < 16; j++) {
#pragma HLS PIPELINE
			dst[k * 16 + j] = src_buf[k][j];
		}
	}
}


/*
 32x32 blocks DCT and iDCT
 */
void dct_butterfly_32_hw(int16_t* src, int16_t* dst) {
	int j, k;
	int E[16], O[16];
#pragma HLS array_partition variable=E complete
#pragma HLS array_partition variable=O complete
	int EE[8], EO[8];
#pragma HLS array_partition variable=EE complete
#pragma HLS array_partition variable=EO complete
	int EEE[4], EEO[4];
#pragma HLS array_partition variable=EEE complete
#pragma HLS array_partition variable=EEO complete
	int EEEE[2], EEEO[2];
#pragma HLS array_partition variable=EEEE complete
#pragma HLS array_partition variable=EEEO complete
	int16_t src_buf[32][32], temp[32][32];
#pragma HLS array_partition variable=src_buf complete
#pragma HLS array_partition variable=temp complete

	const int16_t dct32[32][32] =
	{
		{ 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64 },
		{ 90, 90, 88, 85, 82, 78, 73, 67, 61, 54, 46, 38, 31, 22, 13,  4, -4, -13, -22, -31, -38, -46, -54, -61, -67, -73, -78, -82, -85, -88, -90, -90 },
		{ 90, 87, 80, 70, 57, 43, 25,  9, -9, -25, -43, -57, -70, -80, -87, -90, -90, -87, -80, -70, -57, -43, -25, -9,  9, 25, 43, 57, 70, 80, 87, 90 },
		{ 90, 82, 67, 46, 22, -4, -31, -54, -73, -85, -90, -88, -78, -61, -38, -13, 13, 38, 61, 78, 88, 90, 85, 73, 54, 31,  4, -22, -46, -67, -82, -90 },
		{ 89, 75, 50, 18, -18, -50, -75, -89, -89, -75, -50, -18, 18, 50, 75, 89, 89, 75, 50, 18, -18, -50, -75, -89, -89, -75, -50, -18, 18, 50, 75, 89 },
		{ 88, 67, 31, -13, -54, -82, -90, -78, -46, -4, 38, 73, 90, 85, 61, 22, -22, -61, -85, -90, -73, -38,  4, 46, 78, 90, 82, 54, 13, -31, -67, -88 },
		{ 87, 57,  9, -43, -80, -90, -70, -25, 25, 70, 90, 80, 43, -9, -57, -87, -87, -57, -9, 43, 80, 90, 70, 25, -25, -70, -90, -80, -43,  9, 57, 87 },
		{ 85, 46, -13, -67, -90, -73, -22, 38, 82, 88, 54, -4, -61, -90, -78, -31, 31, 78, 90, 61,  4, -54, -88, -82, -38, 22, 73, 90, 67, 13, -46, -85 },
		{ 83, 36, -36, -83, -83, -36, 36, 83, 83, 36, -36, -83, -83, -36, 36, 83, 83, 36, -36, -83, -83, -36, 36, 83, 83, 36, -36, -83, -83, -36, 36, 83 },
		{ 82, 22, -54, -90, -61, 13, 78, 85, 31, -46, -90, -67,  4, 73, 88, 38, -38, -88, -73, -4, 67, 90, 46, -31, -85, -78, -13, 61, 90, 54, -22, -82 },
		{ 80,  9, -70, -87, -25, 57, 90, 43, -43, -90, -57, 25, 87, 70, -9, -80, -80, -9, 70, 87, 25, -57, -90, -43, 43, 90, 57, -25, -87, -70,  9, 80 },
		{ 78, -4, -82, -73, 13, 85, 67, -22, -88, -61, 31, 90, 54, -38, -90, -46, 46, 90, 38, -54, -90, -31, 61, 88, 22, -67, -85, -13, 73, 82,  4, -78 },
		{ 75, -18, -89, -50, 50, 89, 18, -75, -75, 18, 89, 50, -50, -89, -18, 75, 75, -18, -89, -50, 50, 89, 18, -75, -75, 18, 89, 50, -50, -89, -18, 75 },
		{ 73, -31, -90, -22, 78, 67, -38, -90, -13, 82, 61, -46, -88, -4, 85, 54, -54, -85,  4, 88, 46, -61, -82, 13, 90, 38, -67, -78, 22, 90, 31, -73 },
		{ 70, -43, -87,  9, 90, 25, -80, -57, 57, 80, -25, -90, -9, 87, 43, -70, -70, 43, 87, -9, -90, -25, 80, 57, -57, -80, 25, 90,  9, -87, -43, 70 },
		{ 67, -54, -78, 38, 85, -22, -90,  4, 90, 13, -88, -31, 82, 46, -73, -61, 61, 73, -46, -82, 31, 88, -13, -90, -4, 90, 22, -85, -38, 78, 54, -67 },
		{ 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64, 64, -64, -64, 64 },
		{ 61, -73, -46, 82, 31, -88, -13, 90, -4, -90, 22, 85, -38, -78, 54, 67, -67, -54, 78, 38, -85, -22, 90,  4, -90, 13, 88, -31, -82, 46, 73, -61 },
		{ 57, -80, -25, 90, -9, -87, 43, 70, -70, -43, 87,  9, -90, 25, 80, -57, -57, 80, 25, -90,  9, 87, -43, -70, 70, 43, -87, -9, 90, -25, -80, 57 },
		{ 54, -85, -4, 88, -46, -61, 82, 13, -90, 38, 67, -78, -22, 90, -31, -73, 73, 31, -90, 22, 78, -67, -38, 90, -13, -82, 61, 46, -88,  4, 85, -54 },
		{ 50, -89, 18, 75, -75, -18, 89, -50, -50, 89, -18, -75, 75, 18, -89, 50, 50, -89, 18, 75, -75, -18, 89, -50, -50, 89, -18, -75, 75, 18, -89, 50 },
		{ 46, -90, 38, 54, -90, 31, 61, -88, 22, 67, -85, 13, 73, -82,  4, 78, -78, -4, 82, -73, -13, 85, -67, -22, 88, -61, -31, 90, -54, -38, 90, -46 },
		{ 43, -90, 57, 25, -87, 70,  9, -80, 80, -9, -70, 87, -25, -57, 90, -43, -43, 90, -57, -25, 87, -70, -9, 80, -80,  9, 70, -87, 25, 57, -90, 43 },
		{ 38, -88, 73, -4, -67, 90, -46, -31, 85, -78, 13, 61, -90, 54, 22, -82, 82, -22, -54, 90, -61, -13, 78, -85, 31, 46, -90, 67,  4, -73, 88, -38 },
		{ 36, -83, 83, -36, -36, 83, -83, 36, 36, -83, 83, -36, -36, 83, -83, 36, 36, -83, 83, -36, -36, 83, -83, 36, 36, -83, 83, -36, -36, 83, -83, 36 },
		{ 31, -78, 90, -61,  4, 54, -88, 82, -38, -22, 73, -90, 67, -13, -46, 85, -85, 46, 13, -67, 90, -73, 22, 38, -82, 88, -54, -4, 61, -90, 78, -31 },
		{ 25, -70, 90, -80, 43,  9, -57, 87, -87, 57, -9, -43, 80, -90, 70, -25, -25, 70, -90, 80, -43, -9, 57, -87, 87, -57,  9, 43, -80, 90, -70, 25 },
		{ 22, -61, 85, -90, 73, -38, -4, 46, -78, 90, -82, 54, -13, -31, 67, -88, 88, -67, 31, 13, -54, 82, -90, 78, -46,  4, 38, -73, 90, -85, 61, -22 },
		{ 18, -50, 75, -89, 89, -75, 50, -18, -18, 50, -75, 89, -89, 75, -50, 18, 18, -50, 75, -89, 89, -75, 50, -18, -18, 50, -75, 89, -89, 75, -50, 18 },
		{ 13, -38, 61, -78, 88, -90, 85, -73, 54, -31,  4, 22, -46, 67, -82, 90, -90, 82, -67, 46, -22, -4, 31, -54, 73, -85, 90, -88, 78, -61, 38, -13 },
		{ 9, -25, 43, -57, 70, -80, 87, -90, 90, -87, 80, -70, 57, -43, 25, -9, -9, 25, -43, 57, -70, 80, -87, 90, -90, 87, -80, 70, -57, 43, -25,  9 },
		{ 4, -13, 22, -31, 38, -46, 54, -61, 67, -73, 78, -82, 85, -88, 90, -90, 90, -90, 88, -85, 82, -78, 73, -67, 61, -54, 46, -38, 31, -22, 13, -4 }
	};

	// copy to internal buffers
	for (k = 0; k < 32; k++) {
		for (j = 0; j < 32; j++) {
#pragma HLS PIPELINE
			src_buf[k][j] = src[k * 32 + j];
		}
	}

	for (j = 0; j < 32; j++) {
//#pragma HLS PIPELINE
		for (k = 0; k < 16; k++) {
#pragma HLS PIPELINE
			E[k] = src_buf[j][k] + src_buf[j][31 - k];
			O[k] = src_buf[j][k] - src_buf[j][31 - k];
		}

		/* EE and EO */
		for (k = 0; k < 8; k++) {
#pragma HLS PIPELINE
			EE[k] = E[k] + E[15 - k];
			EO[k] = E[k] - E[15 - k];
		}

		/* EEE and EEO */
		for (k = 0; k < 4; k++) {
#pragma HLS PIPELINE
			EEE[k] = EE[k] + EE[7 - k];
			EEO[k] = EE[k] - EE[7 - k];
		}

		/* EEEE and EEEO */
		EEEE[0] = EEE[0] + EEE[3];
		EEEO[0] = EEE[0] - EEE[3];
		EEEE[1] = EEE[1] + EEE[2];
		EEEO[1] = EEE[1] - EEE[2];

		temp[0][j] = (int16_t) ((dct32[0][0] * EEEE[0]
				+ dct32[0][1] * EEEE[1] + (1<<3)) >> 4);
		temp[16][j] = (int16_t) ((dct32[16][0] * EEEE[0]
				+ dct32[16][1] * EEEE[1] + (1<<3)) >> 4);
		temp[8][j] = (int16_t) ((dct32[8][0] * EEEO[0]
				+ dct32[8][1] * EEEO[1] + (1<<3)) >> 4);
		temp[24][j] = (int16_t) ((dct32[24][0] * EEEO[0]
				+ dct32[24][1] * EEEO[1] + (1<<3)) >> 4);

		for (k = 4; k < 32; k += 8) {
#pragma HLS PIPELINE
			temp[k][j] = (int16_t) ((dct32[k][0] * EEO[0]
					+ dct32[k][1] * EEO[1] + dct32[k][2] * EEO[2]
					+ dct32[k][3] * EEO[3] + (1<<3)) >> 4);
		}

		for (k = 2; k < 32; k += 4) {
#pragma HLS PIPELINE
			temp[k][j] = (int16_t) ((dct32[k][0] * EO[0]
					+ dct32[k][1] * EO[1] + dct32[k][2] * EO[2]
					+ dct32[k][3] * EO[3] + dct32[k][4] * EO[4]
					+ dct32[k][5] * EO[5] + dct32[k][6] * EO[6]
					+ dct32[k][7] * EO[7] + (1<<3)) >> 4);
		}

		for (k = 1; k < 32; k += 2) {
#pragma HLS PIPELINE
			temp[k][j] = (int16_t) ((dct32[k][0] * O[0]
					+ dct32[k][1] * O[1] + dct32[k][2] * O[2]
					+ dct32[k][3] * O[3] + dct32[k][4] * O[4]
					+ dct32[k][5] * O[5] + dct32[k][6] * O[6]
					+ dct32[k][7] * O[7] + dct32[k][8] * O[8]
					+ dct32[k][9] * O[9] + dct32[k][10] * O[10]
					+ dct32[k][11] * O[11] + dct32[k][12] * O[12]
					+ dct32[k][13] * O[13] + dct32[k][14] * O[14]
					+ dct32[k][15] * O[15] + (1<<3)) >> 4);
		}
	}

	for (j = 0; j < 32; j++) {
//#pragma HLS PIPELINE
		for (k = 0; k < 16; k++) {
#pragma HLS PIPELINE
			E[k] = temp[j][k] + temp[j][31 - k];
			O[k] = temp[j][k] - temp[j][31 - k];
		}

		/* EE and EO */
		for (k = 0; k < 8; k++) {
#pragma HLS PIPELINE
			EE[k] = E[k] + E[15 - k];
			EO[k] = E[k] - E[15 - k];
		}

		/* EEE and EEO */
		for (k = 0; k < 4; k++) {
#pragma HLS PIPELINE
			EEE[k] = EE[k] + EE[7 - k];
			EEO[k] = EE[k] - EE[7 - k];
		}

		/* EEEE and EEEO */
		EEEE[0] = EEE[0] + EEE[3];
		EEEO[0] = EEE[0] - EEE[3];
		EEEE[1] = EEE[1] + EEE[2];
		EEEO[1] = EEE[1] - EEE[2];

		src_buf[0][j] = (int16_t) ((dct32[0][0] * EEEE[0]
				+ dct32[0][1] * EEEE[1] + (1<<10)) >> 11);
		src_buf[16][j] = (int16_t) ((dct32[16][0] * EEEE[0]
				+ dct32[16][1] * EEEE[1] + (1<<10)) >> 11);
		src_buf[8][j] = (int16_t) ((dct32[8][0] * EEEO[0]
				+ dct32[8][1] * EEEO[1] + (1<<10)) >> 11);
		src_buf[24][j] = (int16_t) ((dct32[24][0] * EEEO[0]
				+ dct32[24][1] * EEEO[1] + (1<<10)) >> 11);

		for (k = 4; k < 32; k += 8) {
#pragma HLS PIPELINE
			src_buf[k][j] = (int16_t) ((dct32[k][0] * EEO[0]
					+ dct32[k][1] * EEO[1] + dct32[k][2] * EEO[2]
					+ dct32[k][3] * EEO[3] + (1<<10)) >> 11);
		}

		for (k = 2; k < 32; k += 4) {
#pragma HLS PIPELINE
			src_buf[k][j] = (int16_t) ((dct32[k][0] * EO[0]
					+ dct32[k][1] * EO[1] + dct32[k][2] * EO[2]
					+ dct32[k][3] * EO[3] + dct32[k][4] * EO[4]
					+ dct32[k][5] * EO[5] + dct32[k][6] * EO[6]
					+ dct32[k][7] * EO[7] + (1<<10)) >> 11);
		}

		for (k = 1; k < 32; k += 2) {
#pragma HLS PIPELINE
			src_buf[k][j] = (int16_t) ((dct32[k][0] * O[0]
					+ dct32[k][1] * O[1] + dct32[k][2] * O[2]
					+ dct32[k][3] * O[3] + dct32[k][4] * O[4]
					+ dct32[k][5] * O[5] + dct32[k][6] * O[6]
					+ dct32[k][7] * O[7] + dct32[k][8] * O[8]
					+ dct32[k][9] * O[9] + dct32[k][10] * O[10]
					+ dct32[k][11] * O[11] + dct32[k][12] * O[12]
					+ dct32[k][13] * O[13] + dct32[k][14] * O[14]
					+ dct32[k][15] * O[15] + (1<<10)) >> 11);
		}

	}

	// write back
	for (k = 0; k < 32; k++) {
		for (j = 0; j < 32; j++) {
#pragma HLS PIPELINE
			dst[k * 32 + j] = src_buf[k][j];
		}
	}

}
