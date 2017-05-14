#include "butterfly_functions.h"
#include "common.h"
#include "constants.h"

/*
 4x4 blocks DST and
 */
void fastForwardDST(const int16_t* restrict src, int16_t* restrict dst,
		uint8_t shift) {

	int32_t c[4];
	uint8_t i;
	int16_t round = 1 << (shift - 1);

	for (i = 0; i < 4; i++) {
		// Intermediate Variables
		c[0] = src[4 * i + 0] + src[4 * i + 3];
		c[1] = src[4 * i + 1] + src[4 * i + 3];
		c[2] = src[4 * i + 0] - src[4 * i + 1];
		c[3] = 74 * src[4 * i + 2];

		dst[i] = (int16_t) ((29 * c[0] + 55 * c[1] + c[3] + round) >> shift);
		dst[4 + i] = (int16_t) ((74
				* (src[4 * i + 0] + src[4 * i + 1] - src[4 * i + 3]) + round)
				>> shift);
		dst[8 + i] =
				(int16_t) ((29 * c[2] + 55 * c[0] - c[3] + round) >> shift);
		dst[12 + i] =
				(int16_t) ((55 * c[2] - 29 * c[1] + c[3] + round) >> shift);
	}
}
void inverseDST(const int16_t* restrict src, int16_t* restrict dst,
		uint8_t shift) {

	int32_t c[4];
	uint8_t i;
	int32_t round = 1 << (shift - 1);

	for (i = 0; i < 4; i++) {
		c[0] = src[i] + src[8 + i];
		c[1] = src[8 + i] + src[12 + i];
		c[2] = src[i] - src[12 + i];
		c[3] = 74 * src[4 + i];

		dst[4 * i + 0] = (int16_t) Clip(-32768, 32767,
				(29 * c[0] + 55 * c[1] + c[3] + round) >> shift);
		dst[4 * i + 1] = (int16_t) Clip(-32768, 32767,
				(55 * c[2] - 29 * c[1] + c[3] + round) >> shift);
		dst[4 * i + 2] = (int16_t) Clip(-32768, 32767,
				(74 * (src[i] - src[8 + i] + src[12 + i]) + round) >> shift);
		dst[4 * i + 3] = (int16_t) Clip(-32768, 32767,
				(55 * c[0] + 29 * c[2] - c[3] + round) >> shift);

	}

}

/*
 4x4 blocks - DCT and iDCT
 */
void butterfly4(const int16_t* restrict src, int16_t* restrict dst,
		uint8_t shift) {
	uint8_t j;
	int32_t E[2], O[2];
	uint8_t round = 1 << (shift - 1);

	for (j = 0; j < 4; j++) {
		E[0] = src[0] + src[3];
		O[0] = src[0] - src[3];
		E[1] = src[1] + src[2];
		O[1] = src[1] - src[2];

		dst[0] = (int16_t) ((64 * E[0] + 64 * E[1] + round) >> shift);
		dst[8] = (int16_t) ((64 * E[0] + -64 * E[1] + round) >> shift);
		dst[4] = (int16_t) ((83 * O[0] + 36 * O[1] + round) >> shift);
		dst[12] = (int16_t) ((36 * O[0] + -83 * O[1] + round) >> shift);

		src += 4;
		dst++;
	}
}
void inverseButterfly4(const int16_t* restrict src, int16_t* restrict dst,
		uint8_t shift) {
	uint8_t j;
	int32_t E[2], O[2];
	uint8_t round = 1 << (shift - 1);

	for (j = 0; j < 4; j++) {
		E[0] = 64 * src[0] + 64 * src[2];
		O[0] = 83 * src[1] + 36 * src[3];
		O[1] = 36 * src[1] + -83 * src[3];
		E[1] = 64 * src[0] + -64 * src[2];

		// Clip and store
		dst[0] =
				(int16_t) (Clip(-32768, 32767, (E[0] + O[0] + round) >> shift));
		dst[12] =
				(int16_t) (Clip(-32768, 32767, (E[0] - O[0] + round) >> shift));
		dst[4] =
				(int16_t) (Clip(-32768, 32767, (E[1] + O[1] + round) >> shift));
		dst[8] =
				(int16_t) (Clip(-32768, 32767, (E[1] - O[1] + round) >> shift));

		src += 4;
		dst++;
	}
}

/*
 8x8 blocks DCT and iDCT
 */
void butterfly8(const int16_t* restrict src, int16_t* restrict dst,
		uint8_t shift) {
	int j;
	int E[4], O[4];
	int EE[2], EO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < 8; j++) {

		E[0] = src[0] + src[7];
		E[1] = src[1] + src[6];
		E[2] = src[2] + src[5];
		E[3] = src[3] + src[4];

		O[0] = src[0] - src[7];
		O[1] = src[1] - src[6];
		O[2] = src[2] - src[5];
		O[3] = src[3] - src[4];

		/* EE and EO */
		EE[0] = E[0] + E[3];
		EE[1] = E[1] + E[2];
		EO[0] = E[0] - E[3];
		EO[1] = E[1] - E[2];

		dst[0] = (int16_t) ((64 * EE[0] + 64 * EE[1] + 0 * EO[0] + 0 * EO[1]
				+ round) >> shift);
		dst[32] = (int16_t) ((64 * EE[0] + -64 * EE[1] + 0 * EO[0] + 0 * EO[1]
				+ round) >> shift);
		dst[16] = (int16_t) ((0 * EE[0] + 0 * EE[1] + 83 * EO[0] + 36 * EO[1]
				+ round) >> shift);
		dst[48] = (int16_t) ((0 * EE[0] + 0 * EE[1] + 36 * EO[0] + -83 * EO[1]
				+ round) >> shift);

		dst[8] = (int16_t) ((89 * O[0] + 75 * O[1] + 50 * O[2] + 18 * O[3]
				+ round) >> shift);
		dst[24] = (int16_t) ((75 * O[0] + -18 * O[1] + -89 * O[2] + -50 * O[3]
				+ round) >> shift);
		dst[40] = (int16_t) ((50 * O[0] + -89 * O[1] + 18 * O[2] + 75 * O[3]
				+ round) >> shift);
		dst[56] = (int16_t) ((18 * O[0] + -50 * O[1] + 75 * O[2] + -89 * O[3]
				+ round) >> shift);

		src += 8;
		dst++;
	}
}
void inverseButterfly8(const int16_t* src, int16_t* dst, uint8_t shift) {
	int j, k;
	int E[4], O[4];
	int EE[2], EO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < 8; j++) {
		/* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
		for (k = 0; k < 4; k++) {
			O[k] = dct8[1][k] * src[8] + dct8[3][k] * src[24]
					+ dct8[5][k] * src[40] + dct8[7][k] * src[56];
		}

		EO[0] = dct8[2][0] * src[16] + dct8[6][0] * src[48];
		EO[1] = dct8[2][1] * src[16] + dct8[6][1] * src[48];
		EE[0] = dct8[0][0] * src[0] + dct8[4][0] * src[32];
		EE[1] = dct8[0][1] * src[0] + dct8[4][1] * src[32];

		/* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
		E[0] = EE[0] + EO[0];
		E[3] = EE[0] - EO[0];
		E[1] = EE[1] + EO[1];
		E[2] = EE[1] - EO[1];
		for (k = 0; k < 4; k++) {
			dst[k] = (int16_t) Clip(-32768, 32767,
					(E[k] + O[k] + round) >> shift);
			dst[k + 4] = (int16_t) Clip(-32768, 32767,
					(E[3 - k] - O[3 - k] + round) >> shift);
		}

		src++;
		dst += 8;
	}
}

/*
 16x16 blocks DCT and iDCT
 */
void butterfly16(const int16_t* src, int16_t* dst, uint8_t shift) {
	int j, k;
	int E[8], O[8];
	int EE[4], EO[4];
	int EEE[2], EEO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < 16; j++) {
		/* E and O */
		for (k = 0; k < 8; k++) {
			E[k] = src[k] + src[15 - k];
			O[k] = src[k] - src[15 - k];
		}

		/* EE and EO */
		for (k = 0; k < 4; k++) {
			EE[k] = E[k] + E[7 - k];
			EO[k] = E[k] - E[7 - k];
		}

		/* EEE and EEO */
		EEE[0] = EE[0] + EE[3];
		EEO[0] = EE[0] - EE[3];
		EEE[1] = EE[1] + EE[2];
		EEO[1] = EE[1] - EE[2];

		dst[0] = (int16_t) ((dct16[0][0] * EEE[0] + dct16[0][1] * EEE[1]
				+ round) >> shift);
		dst[128] = (int16_t) ((dct16[8][0] * EEE[0]
				+ dct16[8][1] * EEE[1] + round) >> shift);
		dst[64] = (int16_t) ((dct16[4][0] * EEO[0]
				+ dct16[4][1] * EEO[1] + round) >> shift);
		dst[192] = (int16_t) ((dct16[12][0] * EEO[0]
				+ dct16[12][1] * EEO[1] + round) >> shift);

		for (k = 2; k < 16; k += 4) {
			dst[k * 16] = (int16_t) ((dct16[k][0] * EO[0]
					+ dct16[k][1] * EO[1] + dct16[k][2] * EO[2]
					+ dct16[k][3] * EO[3] + round) >> shift);
		}

		for (k = 1; k < 16; k += 2) {
			dst[k * 16] = (int16_t) ((dct16[k][0] * O[0]
					+ dct16[k][1] * O[1] + dct16[k][2] * O[2]
					+ dct16[k][3] * O[3] + dct16[k][4] * O[4]
					+ dct16[k][5] * O[5] + dct16[k][6] * O[6]
					+ dct16[k][7] * O[7] + round) >> shift);
		}

		src += 16;
		dst++;
	}
}
void inverseButterfly16(const int16_t* src, int16_t* dst, uint8_t shift) {
	int j, k;
	int E[8], O[8];
	int EE[4], EO[4];
	int EEE[2], EEO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < 16; j++) {
		/* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
		for (k = 0; k < 8; k++) {
			O[k] = dct16[1][k] * src[16] + dct16[3][k] * src[48]
					+ dct16[5][k] * src[80]
					+ dct16[7][k] * src[112]
					+ dct16[9][k] * src[144]
					+ dct16[11][k] * src[176]
					+ dct16[13][k] * src[208]
					+ dct16[15][k] * src[240];
		}

		for (k = 0; k < 4; k++) {
			EO[k] = dct16[2][k] * src[32]
					+ dct16[6][k] * src[96]
					+ dct16[10][k] * src[160]
					+ dct16[14][k] * src[224];
		}

		EEO[0] = dct16[4][0] * src[64]
				+ dct16[12][0] * src[192];
		EEE[0] = dct16[0][0] * src[0] + dct16[8][0] * src[128];
		EEO[1] = dct16[4][1] * src[64]
				+ dct16[12][1] * src[192];
		EEE[1] = dct16[0][1] * src[0] + dct16[8][1] * src[128];

		/* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
		for (k = 0; k < 2; k++) {
			EE[k] = EEE[k] + EEO[k];
			EE[k + 2] = EEE[1 - k] - EEO[1 - k];
		}

		for (k = 0; k < 4; k++) {
			E[k] = EE[k] + EO[k];
			E[k + 4] = EE[3 - k] - EO[3 - k];
		}

		for (k = 0; k < 8; k++) {
			dst[k] = (int16_t) Clip(-32768, 32767,
					(E[k] + O[k] + round) >> shift);
			dst[k + 8] = (int16_t) Clip(-32768, 32767,
					(E[7 - k] - O[7 - k] + round) >> shift);
		}

		src++;
		dst += 16;
	}
}

/*
 32x32 blocks DCT and iDCT
 */
void butterfly32(const int16_t* src, int16_t* dst, uint8_t shift) {
	int j, k;
	int E[16], O[16];
	int EE[8], EO[8];
	int EEE[4], EEO[4];
	int EEEE[2], EEEO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < 32; j++) {
		/* E and O*/
		for (k = 0; k < 16; k++) {
			E[k] = src[k] + src[31 - k];
			O[k] = src[k] - src[31 - k];
		}

		/* EE and EO */
		for (k = 0; k < 8; k++) {
			EE[k] = E[k] + E[15 - k];
			EO[k] = E[k] - E[15 - k];
		}

		/* EEE and EEO */
		for (k = 0; k < 4; k++) {
			EEE[k] = EE[k] + EE[7 - k];
			EEO[k] = EE[k] - EE[7 - k];
		}

		/* EEEE and EEEO */
		EEEE[0] = EEE[0] + EEE[3];
		EEEO[0] = EEE[0] - EEE[3];
		EEEE[1] = EEE[1] + EEE[2];
		EEEO[1] = EEE[1] - EEE[2];

		dst[0] = (int16_t) ((dct32[0][0] * EEEE[0]
				+ dct32[0][1] * EEEE[1] + round) >> shift);
		dst[512] = (int16_t) ((dct32[16][0] * EEEE[0]
				+ dct32[16][1] * EEEE[1] + round) >> shift);
		dst[256] = (int16_t) ((dct32[8][0] * EEEO[0]
				+ dct32[8][1] * EEEO[1] + round) >> shift);
		dst[768] = (int16_t) ((dct32[24][0] * EEEO[0]
				+ dct32[24][1] * EEEO[1] + round) >> shift);
		for (k = 4; k < 32; k += 8) {
			dst[k * 32] = (int16_t) ((dct32[k][0] * EEO[0]
					+ dct32[k][1] * EEO[1] + dct32[k][2] * EEO[2]
					+ dct32[k][3] * EEO[3] + round) >> shift);
		}

		for (k = 2; k < 32; k += 4) {
			dst[k * 32] = (int16_t) ((dct32[k][0] * EO[0]
					+ dct32[k][1] * EO[1] + dct32[k][2] * EO[2]
					+ dct32[k][3] * EO[3] + dct32[k][4] * EO[4]
					+ dct32[k][5] * EO[5] + dct32[k][6] * EO[6]
					+ dct32[k][7] * EO[7] + round) >> shift);
		}

		for (k = 1; k < 32; k += 2) {
			dst[k * 32] = (int16_t) ((dct32[k][0] * O[0]
					+ dct32[k][1] * O[1] + dct32[k][2] * O[2]
					+ dct32[k][3] * O[3] + dct32[k][4] * O[4]
					+ dct32[k][5] * O[5] + dct32[k][6] * O[6]
					+ dct32[k][7] * O[7] + dct32[k][8] * O[8]
					+ dct32[k][9] * O[9] + dct32[k][10] * O[10]
					+ dct32[k][11] * O[11] + dct32[k][12] * O[12]
					+ dct32[k][13] * O[13] + dct32[k][14] * O[14]
					+ dct32[k][15] * O[15] + round) >> shift);
		}

		src += 32;
		dst++;
	}
}
void inverseButterfly32(const int16_t* src, int16_t* dst, uint8_t shift) {
	int j, k;
	int E[16], O[16];
	int EE[8], EO[8];
	int EEE[4], EEO[4];
	int EEEE[2], EEEO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < 32; j++) {
		/* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
		for (k = 0; k < 16; k++) {
			O[k] = dct32[1][k] * src[32] + dct32[3][k] * src[96]
					+ dct32[5][k] * src[160]
					+ dct32[7][k] * src[224]
					+ dct32[9][k] * src[288]
					+ dct32[11][k] * src[352]
					+ dct32[13][k] * src[416]
					+ dct32[15][k] * src[480]
					+ dct32[17][k] * src[544]
					+ dct32[19][k] * src[608]
					+ dct32[21][k] * src[672]
					+ dct32[23][k] * src[736]
					+ dct32[25][k] * src[800]
					+ dct32[27][k] * src[864]
					+ dct32[29][k] * src[928]
					+ dct32[31][k] * src[992];
		}

		for (k = 0; k < 8; k++) {
			EO[k] = dct32[2][k] * src[64]
					+ dct32[6][k] * src[192]
					+ dct32[10][k] * src[320]
					+ dct32[14][k] * src[448]
					+ dct32[18][k] * src[576]
					+ dct32[22][k] * src[704]
					+ dct32[26][k] * src[832]
					+ dct32[30][k] * src[960];
		}

		for (k = 0; k < 4; k++) {
			EEO[k] = dct32[4][k] * src[128]
					+ dct32[12][k] * src[384]
					+ dct32[20][k] * src[640]
					+ dct32[28][k] * src[896];
		}

		EEEO[0] = dct32[8][0] * src[256]
				+ dct32[24][0] * src[768];
		EEEO[1] = dct32[8][1] * src[256]
				+ dct32[24][1] * src[768];
		EEEE[0] = dct32[0][0] * src[0] + dct32[16][0] * src[512];
		EEEE[1] = dct32[0][1] * src[0] + dct32[16][1] * src[512];

		/* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
		EEE[0] = EEEE[0] + EEEO[0];
		EEE[3] = EEEE[0] - EEEO[0];
		EEE[1] = EEEE[1] + EEEO[1];
		EEE[2] = EEEE[1] - EEEO[1];
		for (k = 0; k < 4; k++) {
			EE[k] = EEE[k] + EEO[k];
			EE[k + 4] = EEE[3 - k] - EEO[3 - k];
		}

		for (k = 0; k < 8; k++) {
			E[k] = EE[k] + EO[k];
			E[k + 8] = EE[7 - k] - EO[7 - k];
		}

		for (k = 0; k < 16; k++) {
			dst[k] = (int16_t) Clip(-32768, 32767,
					(E[k] + O[k] + round) >> shift);
			dst[k + 16] = (int16_t) Clip(-32768, 32767,
					(E[15 - k] - O[15 - k] + round) >> shift);
		}

		src++;
		dst += 32;
	}
}
