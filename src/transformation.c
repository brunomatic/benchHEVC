#include "transformation.h"
#include <stdlib.h>
#include "common.h"
#include "constants.h"

#define USE_NEON_ASM 	1
#define USE_BUTTERFLY	1
#define DEBUG 0

#if DEBUG

#include <stdio.h>
#include "helper.h"

#endif


#if USE_NEON_ASM

#include "dct_functions.h"

#endif

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

void butterfly16(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);
void inverseButterfly16(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);

void butterfly32(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);
void inverseButterfly32(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line);

/*
	4x4 blocks DST and 
*/
void fastForwardDST(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{

	int32_t c[4];
	uint8_t i;
	int16_t round = 1 << (shift - 1);

	for (i = 0; i < 4; i++)
	{
		// Intermediate Variables
		c[0] = src[4 * i + 0] + src[4 * i + 3];
		c[1] = src[4 * i + 1] + src[4 * i + 3];
		c[2] = src[4 * i + 0] - src[4 * i + 1];
		c[3] = 74 * src[4 * i + 2];

		dst[i] = (int16_t)		((29 * c[0] + 55 * c[1] + c[3] + round) >> shift);
		dst[4 + i] = (int16_t)	((74 * (src[4 * i + 0] + src[4 * i + 1] - src[4 * i + 3]) + round) >> shift);
		dst[8 + i] = (int16_t)	((29 * c[2] + 55 * c[0] - c[3] + round) >> shift);
		dst[12 + i] = (int16_t)	((55 * c[2] - 29 * c[1] + c[3] + round) >> shift);
	}
}
void inverseDST(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{

	int32_t c[4];
	uint8_t i;
	int16_t round = 1 << (shift - 1);

	for (i = 0; i < 4; i++)
	{
		c[0] = src[i] + src[8 + i];
		c[1] = src[8 + i] + src[12 + i];
		c[2] = src[i] - src[12 + i];
		c[3] = 74 * src[4 + i];

		dst[4 * i + 0] = (int16_t)Clip(-32768, 32767, (29 * c[0] + 55 * c[1] + c[3] + round) >> shift);
		dst[4 * i + 1] = (int16_t)Clip(-32768, 32767, (55 * c[2] - 29 * c[1] + c[3] + round) >> shift);
		dst[4 * i + 2] = (int16_t)Clip(-32768, 32767, (74 * (src[i] - src[8 + i] + src[12 + i]) + round) >> shift);
		dst[4 * i + 3] = (int16_t)Clip(-32768, 32767, (55 * c[0] + 29 * c[2] - c[3] + round) >> shift);

	}

}

/*
	4x4 blocks - DCT and iDCT
*/
void butterfly4(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{
	uint8_t j;
	int32_t E[2], O[2];
	uint8_t round = 1 << (shift - 1);

	for (j = 0; j < 4; j++)
	{
		E[0] = src[0] + src[3];
		O[0] = src[0] - src[3];
		E[1] = src[1] + src[2];
		O[1] = src[1] - src[2];

		dst[0] = (int16_t)((	 64 * E[0] + 	 64 * E[1] + round) >> shift);
		dst[8] = (int16_t)((	 64 * E[0] + 	-64 * E[1] + round) >> shift);
		dst[4] = (int16_t)((	 83 * O[0] + 	 36 * O[1] + round) >> shift);
		dst[12] = (int16_t)((	 36 * O[0] +	-83 * O[1] + round) >> shift);

		src += 4;
		dst++;
	}
}
void inverseButterfly4(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{
	uint8_t j;
	int32_t E[2], O[2];
	uint8_t round = 1 << (shift - 1);

	for (j = 0; j < 4; j++)
	{
		E[0] = 64 * src[0] + 64 * src[2];
		O[0] = 83 * src[1] + 36 * src[3];
		O[1] = 36 * src[1] + -83 * src[3];
		E[1] = 64 * src[0] + -64 * src[2];

		// Clip and store
		dst[0] = (int16_t)(Clip(-32768, 32767, (E[0] + O[0] + round) >> shift));
		dst[12] = (int16_t)(Clip(-32768, 32767, (E[0] - O[0] + round) >> shift));
		dst[4] = (int16_t)(Clip(-32768, 32767, (E[1] + O[1] + round) >> shift));
		dst[8] = (int16_t)(Clip(-32768, 32767, (E[1] - O[1] + round) >> shift));

		src+=4;
		dst++;
	}
}

/*
	8x8 blocks DCT and iDCT
*/
void butterfly8(const int16_t* restrict src, int16_t* restrict dst, uint8_t shift)
{
	int j, k;
	int E[4], O[4];
	int EE[2], EO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < 8; j++)
		{


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


			dst[0] = (int16_t)((	64 * EE[0] + 	64 * EE[1] +	0 * EO[0] + 	0 * EO[1] + round) >> shift);
			dst[32] = (int16_t)((	64 * EE[0] + 	-64 * EE[1] +	0 * EO[0] + 	0 * EO[1] + round) >> shift);
			dst[16] = (int16_t)((	0  * EE[0] + 	 0 * EE[1]	+	83 * EO[0] + 	36 * EO[1] + round) >> shift);
			dst[48] = (int16_t)((	0  * EE[0] + 	 0 * EE[1]	+	36 * EO[0] + 	-83 * EO[1] + round) >> shift);

			dst[8] = (int16_t)((	89 * O[0] + 	75 * O[1] + 	50 * O[2] + 	18 * O[3] + round) >> shift);
			dst[24] = (int16_t)((	75 * O[0] + 	-18 * O[1] + 	-89 * O[2] + 	-50 * O[3] + round) >> shift);
			dst[40] = (int16_t)((	50 * O[0] +		-89 * O[1] + 	18 * O[2] + 	75 * O[3] + round) >> shift);
			dst[56] = (int16_t)((	18 * O[0] + 	-50 * O[1] + 	75 * O[2] + 	-89 * O[3] + round) >> shift);

			src += 8;
			dst++;
		}
}
void inverseButterfly8(const int16_t* src, int16_t* dst, uint8_t shift)
{
	int j, k;
	int E[4], O[4];
	int EE[2], EO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < 8; j++)
	{
		/* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
		for (k = 0; k < 4; k++)
		{
			O[k] = dctMatrix[4][k] * src[8] + dctMatrix[12][k] * src[24] + dctMatrix[20][k] * src[40] + dctMatrix[28][k] * src[56];
		}

		EO[0] = dctMatrix[8][0] * src[16] + dctMatrix[24][0] * src[48];
		EO[1] = dctMatrix[8][1] * src[16] + dctMatrix[24][1] * src[48];
		EE[0] = dctMatrix[0][0] * src[0] + dctMatrix[16][0] * src[32];
		EE[1] = dctMatrix[0][1] * src[0] + dctMatrix[16][1] * src[32];

		/* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
		E[0] = EE[0] + EO[0];
		E[3] = EE[0] - EO[0];
		E[1] = EE[1] + EO[1];
		E[2] = EE[1] - EO[1];
		for (k = 0; k < 4; k++)
		{
			dst[k] = (int16_t)Clip(-32768, 32767, (E[k] + O[k] + round) >> shift);
			dst[k + 4] = (int16_t)Clip(-32768, 32767, (E[3 - k] - O[3 - k] + round) >> shift);
		}

		src++;
		dst += 8;
	}
}

/*
	16x16 blocks DCT and iDCT
*/
void butterfly16(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line)
{
	int j, k;
	int E[8], O[8];
	int EE[4], EO[4];
	int EEE[2], EEO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < line; j++)
	{
		/* E and O */
		for (k = 0; k < 8; k++)
		{
			E[k] = src[k] + src[15 - k];
			O[k] = src[k] - src[15 - k];
		}

		/* EE and EO */
		for (k = 0; k < 4; k++)
		{
			EE[k] = E[k] + E[7 - k];
			EO[k] = E[k] - E[7 - k];
		}

		/* EEE and EEO */
		EEE[0] = EE[0] + EE[3];
		EEO[0] = EE[0] - EE[3];
		EEE[1] = EE[1] + EE[2];
		EEO[1] = EE[1] - EE[2];

		dst[0] = (int16_t)((dctMatrix[0][0] * EEE[0] + dctMatrix[0][1] * EEE[1] + round) >> shift);
		dst[8 * line] = (int16_t)((dctMatrix[16][0] * EEE[0] + dctMatrix[16][1] * EEE[1] + round) >> shift);
		dst[4 * line] = (int16_t)((dctMatrix[8][0] * EEO[0] + dctMatrix[8][1] * EEO[1] + round) >> shift);
		dst[12 * line] = (int16_t)((dctMatrix[24][0] * EEO[0] + dctMatrix[24][1] * EEO[1] + round) >> shift);

		for (k = 2; k < 16; k += 4)
		{
			dst[k * line] = (int16_t)((dctMatrix[k * 2][0] * EO[0] + dctMatrix[k * 2][1] * EO[1] + dctMatrix[k * 2][2] * EO[2] +
				dctMatrix[k * 2][3] * EO[3] + round) >> shift);
		}

		for (k = 1; k < 16; k += 2)
		{
			dst[k * line] = (int16_t)((dctMatrix[k * 2][0] * O[0] + dctMatrix[k * 2][1] * O[1] + dctMatrix[k * 2][2] * O[2] + dctMatrix[k * 2][3] * O[3] +
				dctMatrix[k * 2][4] * O[4] + dctMatrix[k * 2][5] * O[5] + dctMatrix[k * 2][6] * O[6] + dctMatrix[k * 2][7] * O[7] + round) >> shift);
		}

		src += 16;
		dst++;
	}
}
void inverseButterfly16(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line)
{
	int j, k;
	int E[8], O[8];
	int EE[4], EO[4];
	int EEE[2], EEO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < line; j++)
	{
		/* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
		for (k = 0; k < 8; k++)
		{
			O[k] = dctMatrix[2][k] * src[line] + dctMatrix[6][k] * src[3 * line] + dctMatrix[10][k] * src[5 * line] + dctMatrix[14][k] * src[7 * line] +
				dctMatrix[18][k] * src[9 * line] + dctMatrix[22][k] * src[11 * line] + dctMatrix[26][k] * src[13 * line] + dctMatrix[30][k] * src[15 * line];
		}

		for (k = 0; k < 4; k++)
		{
			EO[k] = dctMatrix[4][k] * src[2 * line] + dctMatrix[12][k] * src[6 * line] + dctMatrix[20][k] * src[10 * line] + dctMatrix[28][k] * src[14 * line];
		}

		EEO[0] = dctMatrix[8][0] * src[4 * line] + dctMatrix[24][0] * src[12 * line];
		EEE[0] = dctMatrix[0][0] * src[0] + dctMatrix[16][0] * src[8 * line];
		EEO[1] = dctMatrix[8][1] * src[4 * line] + dctMatrix[24][1] * src[12 * line];
		EEE[1] = dctMatrix[0][1] * src[0] + dctMatrix[16][1] * src[8 * line];

		/* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
		for (k = 0; k < 2; k++)
		{
			EE[k] = EEE[k] + EEO[k];
			EE[k + 2] = EEE[1 - k] - EEO[1 - k];
		}

		for (k = 0; k < 4; k++)
		{
			E[k] = EE[k] + EO[k];
			E[k + 4] = EE[3 - k] - EO[3 - k];
		}

		for (k = 0; k < 8; k++)
		{
			dst[k] = (int16_t)Clip(-32768, 32767, (E[k] + O[k] + round) >> shift);
			dst[k + 8] = (int16_t)Clip(-32768, 32767, (E[7 - k] - O[7 - k] + round) >> shift);
		}

		src++;
		dst += 16;
	}
}

/*
	32x32 blocks DCT and iDCT
*/
void butterfly32(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line)
{
	int j, k;
	int E[16], O[16];
	int EE[8], EO[8];
	int EEE[4], EEO[4];
	int EEEE[2], EEEO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < line; j++)
	{
		/* E and O*/
		for (k = 0; k < 16; k++)
		{
			E[k] = src[k] + src[31 - k];
			O[k] = src[k] - src[31 - k];
		}

		/* EE and EO */
		for (k = 0; k < 8; k++)
		{
			EE[k] = E[k] + E[15 - k];
			EO[k] = E[k] - E[15 - k];
		}

		/* EEE and EEO */
		for (k = 0; k < 4; k++)
		{
			EEE[k] = EE[k] + EE[7 - k];
			EEO[k] = EE[k] - EE[7 - k];
		}

		/* EEEE and EEEO */
		EEEE[0] = EEE[0] + EEE[3];
		EEEO[0] = EEE[0] - EEE[3];
		EEEE[1] = EEE[1] + EEE[2];
		EEEO[1] = EEE[1] - EEE[2];

		dst[0] = (int16_t)((dctMatrix[0][0] * EEEE[0] + dctMatrix[0][1] * EEEE[1] + round) >> shift);
		dst[16 * line] = (int16_t)((dctMatrix[16][0] * EEEE[0] + dctMatrix[16][1] * EEEE[1] + round) >> shift);
		dst[8 * line] = (int16_t)((dctMatrix[8][0] * EEEO[0] + dctMatrix[8][1] * EEEO[1] + round) >> shift);
		dst[24 * line] = (int16_t)((dctMatrix[24][0] * EEEO[0] + dctMatrix[24][1] * EEEO[1] + round) >> shift);
		for (k = 4; k < 32; k += 8)
		{
			dst[k * line] = (int16_t)((dctMatrix[k][0] * EEO[0] + dctMatrix[k][1] * EEO[1] + dctMatrix[k][2] * EEO[2] +
				dctMatrix[k][3] * EEO[3] + round) >> shift);
		}

		for (k = 2; k < 32; k += 4)
		{
			dst[k * line] = (int16_t)((dctMatrix[k][0] * EO[0] + dctMatrix[k][1] * EO[1] + dctMatrix[k][2] * EO[2] +
				dctMatrix[k][3] * EO[3] + dctMatrix[k][4] * EO[4] + dctMatrix[k][5] * EO[5] +
				dctMatrix[k][6] * EO[6] + dctMatrix[k][7] * EO[7] + round) >> shift);
		}

		for (k = 1; k < 32; k += 2)
		{
			dst[k * line] = (int16_t)((dctMatrix[k][0] * O[0] + dctMatrix[k][1] * O[1] + dctMatrix[k][2] * O[2] + dctMatrix[k][3] * O[3] +
				dctMatrix[k][4] * O[4] + dctMatrix[k][5] * O[5] + dctMatrix[k][6] * O[6] + dctMatrix[k][7] * O[7] +
				dctMatrix[k][8] * O[8] + dctMatrix[k][9] * O[9] + dctMatrix[k][10] * O[10] + dctMatrix[k][11] *
				O[11] + dctMatrix[k][12] * O[12] + dctMatrix[k][13] * O[13] + dctMatrix[k][14] * O[14] +
				dctMatrix[k][15] * O[15] + round) >> shift);
		}

		src += 32;
		dst++;
	}
}
void inverseButterfly32(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line)
{
	int j, k;
	int E[16], O[16];
	int EE[8], EO[8];
	int EEE[4], EEO[4];
	int EEEE[2], EEEO[2];
	int round = 1 << (shift - 1);

	for (j = 0; j < line; j++)
	{
		/* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
		for (k = 0; k < 16; k++)
		{
			O[k] = dctMatrix[1][k] * src[line] + dctMatrix[3][k] * src[3 * line] + dctMatrix[5][k] * src[5 * line] + dctMatrix[7][k] * src[7 * line] +
				dctMatrix[9][k] * src[9 * line] + dctMatrix[11][k] * src[11 * line] + dctMatrix[13][k] * src[13 * line] + dctMatrix[15][k] * src[15 * line] +
				dctMatrix[17][k] * src[17 * line] + dctMatrix[19][k] * src[19 * line] + dctMatrix[21][k] * src[21 * line] + dctMatrix[23][k] * src[23 * line] +
				dctMatrix[25][k] * src[25 * line] + dctMatrix[27][k] * src[27 * line] + dctMatrix[29][k] * src[29 * line] + dctMatrix[31][k] * src[31 * line];
		}

		for (k = 0; k < 8; k++)
		{
			EO[k] = dctMatrix[2][k] * src[2 * line] + dctMatrix[6][k] * src[6 * line] + dctMatrix[10][k] * src[10 * line] + dctMatrix[14][k] * src[14 * line] +
				dctMatrix[18][k] * src[18 * line] + dctMatrix[22][k] * src[22 * line] + dctMatrix[26][k] * src[26 * line] + dctMatrix[30][k] * src[30 * line];
		}

		for (k = 0; k < 4; k++)
		{
			EEO[k] = dctMatrix[4][k] * src[4 * line] + dctMatrix[12][k] * src[12 * line] + dctMatrix[20][k] * src[20 * line] + dctMatrix[28][k] * src[28 * line];
		}

		EEEO[0] = dctMatrix[8][0] * src[8 * line] + dctMatrix[24][0] * src[24 * line];
		EEEO[1] = dctMatrix[8][1] * src[8 * line] + dctMatrix[24][1] * src[24 * line];
		EEEE[0] = dctMatrix[0][0] * src[0] + dctMatrix[16][0] * src[16 * line];
		EEEE[1] = dctMatrix[0][1] * src[0] + dctMatrix[16][1] * src[16 * line];

		/* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
		EEE[0] = EEEE[0] + EEEO[0];
		EEE[3] = EEEE[0] - EEEO[0];
		EEE[1] = EEEE[1] + EEEO[1];
		EEE[2] = EEEE[1] - EEEO[1];
		for (k = 0; k < 4; k++)
		{
			EE[k] = EEE[k] + EEO[k];
			EE[k + 4] = EEE[3 - k] - EEO[3 - k];
		}

		for (k = 0; k < 8; k++)
		{
			E[k] = EE[k] + EO[k];
			E[k + 8] = EE[7 - k] - EO[7 - k];
		}

		for (k = 0; k < 16; k++)
		{
			dst[k] = (int16_t)Clip(-32768, 32767, (E[k] + O[k] + round) >> shift);
			dst[k + 16] = (int16_t)Clip(-32768, 32767, (E[15 - k] - O[15 - k] + round) >> shift);
		}

		src++;
		dst += 32;
	}
}


/*
	Function preforms basic 2DCT transformation on residual signal.
	Instead coordinatesy x,y of the block wee just use prediction mode since the data is fabricated
	We also need BitDepth to calculate coeffs for clip3 operation
*/
void transform(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS, uint8_t cIdx, int16_t * residual, int16_t * result) {
	
	uint8_t firstShift = 0, secondShift = 0;
#if USE_BUTTERFLY
	int16_t * temp;
#else
	int32_t * temp;
	int32_t sum = 0;
	uint8_t i, j, k, stepSize;
#endif

	// set shift variable based on block size and bit depth
	switch (nTbS)
	{
	case 4:
		firstShift = BitDepth + 2 - 9;
		secondShift = 2 + 6;
		break;
	case 8:
		firstShift = BitDepth + 3 - 9;
		secondShift = 3 + 6;
		break;
	case 16:
		firstShift = BitDepth + 4 - 9;
		secondShift = 4 + 6;
		break;
	case 32:
		firstShift = BitDepth + 5 - 9;
		secondShift = 5 + 6;
		break;
	default:
		break;
	}

#if USE_BUTTERFLY

	// allocate and zero int space
	temp = (int16_t *)malloc(sizeof(int16_t)*nTbS*nTbS);

	// handle alternate DST transform of 4x4 blocks
	if (predictionMode == MODE_INTRA && nTbS == 4) 
	{
		fastForwardDST(residual, temp, firstShift);
		fastForwardDST(temp, result, secondShift);
	}
	// handle everything else using butterfly algorithms from x265
	else
	{
		switch (nTbS)
		{
		case 4:
#if USE_NEON_ASM
			x265_dct_4x4_neon(residual, result);
#else
			butterfly4(residual, temp, firstShift);
			butterfly4(temp, result, secondShift);
#endif
			break;
		case 8:
#if USE_NEON_ASM
			x265_dct_8x8_neon(residual, result);
#else
			butterfly8(residual, temp, firstShift);
			butterfly8(temp, result, secondShift);
#endif
			break;
		case 16:
#if USE_NEON_ASM
			x265_dct_16x16_neon(residual, result);
#else
			butterfly16(residual, temp, firstShift, 16);
			butterfly16(temp, result, secondShift, 16);
#endif
			break;
		case 32:
			butterfly32(residual, temp, firstShift, 32);
			butterfly32(temp, result, secondShift, 32);
			break;
		default:
			break;
		}
	}


#else

	temp = (int32_t *)calloc(sizeof(int32_t), nTbS*nTbS);

	// check if it is alternate transform - DST
	if (predictionMode == MODE_INTRA && nTbS == 4) {
		for (i = 0; i < nTbS; i++)
		{
			for (j = 0; j < nTbS; j++)
			{
				for (k = 0; k < nTbS; k++)
				{
					temp[i*nTbS + j] += dstMatrix[i][k] * residual[k * nTbS + j];
				}
				temp[i*nTbS + j] = temp[i*nTbS + j] >> firstShift;
			}

		}

		for (i = 0; i < nTbS; i++)
		{
			for (j = 0; j < nTbS; j++)
			{
				for (k = 0; k < nTbS; k++)
				{
					sum += temp[i*nTbS + k] * dstMatrix[j][k];
				}
				result[i*nTbS + j] = sum >> secondShift;
				sum = 0;
			}

		}


	}
	// if not use regular DCT matrix and calculate the step size based on block size
	else {
		stepSize = 32 / nTbS;

		// fist multiply with transformation matrix and shift
		for (i = 0; i < nTbS; i++)
		{
			for (j = 0; j < nTbS; j++)
			{
				for (k = 0; k < nTbS; k++)
				{
					temp[i*nTbS + j] += dctMatrix[i*stepSize][k] * residual[k*nTbS + j];
				}
				temp[i*nTbS + j] = temp[i*nTbS + j] >> firstShift;
			}

		}

		for (i = 0; i < nTbS; i++)
		{
			for (j = 0; j < nTbS; j++)
			{
				for (k = 0; k < nTbS; k++)
				{
					sum  += temp[i*nTbS + k] * dctMatrix[j*stepSize][k];
				}
				result[i*nTbS + j] = sum >> secondShift;
				sum = 0;
			}

		}

	}
#endif

// debug printing
#if DEBUG
	printf("Temp(1DCT) matrix:\n");
	printMatrix(temp, nTbS);

	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);

#endif // DEBUG


	// cleanup
	free(temp);

}


/*
	Inverse 2D DCT
*/
void inverseTransform(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS, uint8_t cIdx, int16_t * transform, int16_t * result) {

	uint8_t firstShift, secondShift;
#if USE_BUTTERFLY
	int16_t * temp;
#else
	int32_t * temp;
	int32_t sum = 0;
	uint8_t i, j, k, stepSize;
#endif



	firstShift = 7;
	secondShift = 20 - BitDepth;


#if USE_BUTTERFLY

	temp = (int16_t *)malloc(sizeof(int16_t)*nTbS*nTbS);

	// handle alternate DST transform of 4x4 blocks
	if (predictionMode == MODE_INTRA && nTbS == 4)
	{
		inverseDST(transform, temp, firstShift);
		inverseDST(temp, result, secondShift);
	}
	// handle everything else using butterfly algorithms from x265
	else
	{
		switch (nTbS)
		{
		case 4:
			inverseButterfly4(transform, temp, firstShift);
			inverseButterfly4(temp, result, secondShift);
			break;
		case 8:
			inverseButterfly8(transform, temp, firstShift);
			inverseButterfly8(temp, result, secondShift);
			break;
		case 16:
			inverseButterfly16(transform, temp, firstShift, 16);
			inverseButterfly16(temp, result, secondShift, 16);
			break;
		case 32:
			inverseButterfly32(transform, temp, firstShift, 32);
			inverseButterfly32(temp, result, secondShift, 32);
			break;
		default:
			break;
		}
	}


#else

	temp = (int32_t *)calloc(sizeof(int32_t), nTbS*nTbS);

	// check if it is alternate tranform - DST
	if (predictionMode == MODE_INTRA && nTbS == 4) {
		for (i = 0; i < nTbS; i++)
		{
			for (j = 0; j < nTbS; j++)
			{
				for (k = 0; k < nTbS; k++)
				{
					temp[i*nTbS + j] += dstMatrix[k][i] * transform[k * nTbS + j];
				}
				temp[i*nTbS + j] = temp[i*nTbS + j] >> firstShift;
			}

		}

		for (i = 0; i < nTbS; i++)
		{
			for (j = 0; j < nTbS; j++)
			{
				for (k = 0; k < nTbS; k++)
				{
					sum += temp[i*nTbS + k] * dstMatrix[k][j];
				}
				result[i*nTbS + j] = sum >> secondShift;
				sum = 0;
			}

		}


	}
	// if not use regular DCT matrix and calculate the step size based on block size
	else {
		stepSize = 32 / nTbS;

		// fist multiply with transformation matrix and shift
		for (i = 0; i < nTbS; i++)
		{
			for (j = 0; j < nTbS; j++)
			{
				for (k = 0; k < nTbS; k++)
				{
					temp[i*nTbS + j] += dctMatrix[k][i*stepSize] * transform[k*nTbS + j];
				}
				temp[i*nTbS + j] = temp[i*nTbS + j] >> firstShift;
			}

		}

		for (i = 0; i < nTbS; i++)
		{
			for (j = 0; j < nTbS; j++)
			{
				for (k = 0; k < nTbS; k++)
				{
					sum += temp[i*nTbS + k] * dctMatrix[k][j];
				}
				result[i*nTbS + j] = sum >> secondShift;
				sum = 0;
			}

		}

	}
#endif

#if DEBUG
	printf("Temp(1DCT) matrix:\n");
	printMatrix(temp, nTbS);


	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);

#endif

	// cleanup
	free(temp);

}
