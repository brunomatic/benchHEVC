#include "transformation.h"
#include <stdlib.h>
#include "common.h"
#include "constants.h"

#define USE_BUTTERFLY	1
#define DEBUG 0


/*
	Butterfly algorithms - source: x265 reference source
	https://bitbucket.org/multicoreware/x265/src/
*/
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

/*
	4x4 blocks DST and 
*/
void fastForwardDST(const int16_t* block, int16_t* coeff, uint8_t shift)
{
	int i, c[4];

	for (i = 0; i < 4; i++)
	{
		// Intermediate Variables
		c[0] = block[4 * i + 0] + block[4 * i + 3];
		c[1] = block[4 * i + 1] + block[4 * i + 3];
		c[2] = block[4 * i + 0] - block[4 * i + 1];
		c[3] = 74 * block[4 * i + 2];

		coeff[i] = (int16_t)((29 * c[0] + 55 * c[1] + c[3] ) >> shift);
		coeff[4 + i] = (int16_t)((74 * (block[4 * i + 0] + block[4 * i + 1] - block[4 * i + 3]) ) >> shift);
		coeff[8 + i] = (int16_t)((29 * c[2] + 55 * c[0] - c[3] ) >> shift);
		coeff[12 + i] = (int16_t)((55 * c[2] - 29 * c[1] + c[3] ) >> shift);
	}
}
void inverseDST(const int16_t* tmp, int16_t* block, uint8_t shift)
{
	int i, c[4];

	for (i = 0; i < 4; i++)
	{
		c[0] = tmp[i] + tmp[8 + i];
		c[1] = tmp[8 + i] + tmp[12 + i];
		c[2] = tmp[i] - tmp[12 + i];
		c[3] = 74 * tmp[4 + i];

		block[4 * i + 0] = (int16_t)Clip(-32768, 32767, (29 * c[0] + 55 * c[1] + c[3]) >> shift);
		block[4 * i + 1] = (int16_t)Clip(-32768, 32767, (55 * c[2] - 29 * c[1] + c[3]) >> shift);
		block[4 * i + 2] = (int16_t)Clip(-32768, 32767, (74 * (tmp[i] - tmp[8 + i] + tmp[12 + i])) >> shift);
		block[4 * i + 3] = (int16_t)Clip(-32768, 32767, (55 * c[0] + 29 * c[2] - c[3]) >> shift);
	}
}

/*
	4x4 blocks - DCT and iDCT
*/
void butterfly4(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line)
{
	int j;
	int E[2], O[2];

	for (j = 0; j < line; j++)
	{
		E[0] = src[0] + src[3];
		O[0] = src[0] - src[3];
		E[1] = src[1] + src[2];
		O[1] = src[1] - src[2];

		dst[0] = (int16_t)((dctMatrix[0][0] * E[0] + dctMatrix[0][1] * E[1]) >> shift);
		dst[2 * line] = (int16_t)((dctMatrix[16][0] * E[0] + dctMatrix[16][1] * E[1]) >> shift);
		dst[line] = (int16_t)((dctMatrix[8][0] * O[0] + dctMatrix[8][1] * O[1]) >> shift);
		dst[3 * line] = (int16_t)((dctMatrix[24][0] * O[0] + dctMatrix[24][1] * O[1]) >> shift);

		src += 4;
		dst++;
	}
}
void inverseButterfly4(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line)
{
	int j;
	int E[2], O[2];

	for (j = 0; j < line; j++)
	{
		O[0] = dctMatrix[8][0] * src[line] + dctMatrix[24][0] * src[3 * line];
		O[1] = dctMatrix[8][1] * src[line] + dctMatrix[24][1] * src[3 * line];
		E[0] = dctMatrix[0][0] * src[0] + dctMatrix[24][0] * src[2 * line];
		E[1] = dctMatrix[0][1] * src[0] + dctMatrix[24][1] * src[2 * line];

		// Clip and store
		dst[0] = (int16_t)(Clip(-32768, 32767, (E[0] + O[0]) >> shift));
		dst[1] = (int16_t)(Clip(-32768, 32767, (E[1] + O[1]) >> shift));
		dst[2] = (int16_t)(Clip(-32768, 32767, (E[1] - O[1]) >> shift));
		dst[3] = (int16_t)(Clip(-32768, 32767, (E[0] - O[0]) >> shift));

		src++;
		dst += 4;
	}
}

/*
	8x8 blocks DCT and iDCT
*/
void butterfly8(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line)
{
	int j, k;
	int E[4], O[4];
	int EE[2], EO[2];

	for (j = 0; j < line; j++)
	{
		/* E and O*/
		for (k = 0; k < 4; k++)
		{
			E[k] = src[k] + src[7 - k];
			O[k] = src[k] - src[7 - k];
		}

		/* EE and EO */
		EE[0] = E[0] + E[3];
		EO[0] = E[0] - E[3];
		EE[1] = E[1] + E[2];
		EO[1] = E[1] - E[2];

		dst[0] = (int16_t)((dctMatrix[0][0] * EE[0] + dctMatrix[0][1] * EE[1]) >> shift);
		dst[4 * line] = (int16_t)((dctMatrix[16][0] * EE[0] + dctMatrix[16][1] * EE[1]) >> shift);
		dst[2 * line] = (int16_t)((dctMatrix[8][0] * EO[0] + dctMatrix[8][1] * EO[1]) >> shift);
		dst[6 * line] = (int16_t)((dctMatrix[24][0] * EO[0] + dctMatrix[24][1] * EO[1]) >> shift);

		dst[line] = (int16_t)((dctMatrix[4][0] * O[0] + dctMatrix[4][1] * O[1] + dctMatrix[4][2] * O[2] + dctMatrix[4][3] * O[3]) >> shift);
		dst[3 * line] = (int16_t)((dctMatrix[12][0] * O[0] + dctMatrix[12][1] * O[1] + dctMatrix[12][2] * O[2] + dctMatrix[12][3] * O[3]) >> shift);
		dst[5 * line] = (int16_t)((dctMatrix[20][0] * O[0] + dctMatrix[20][1] * O[1] + dctMatrix[20][2] * O[2] + dctMatrix[20][3] * O[3]) >> shift);
		dst[7 * line] = (int16_t)((dctMatrix[28][0] * O[0] + dctMatrix[28][1] * O[1] + dctMatrix[28][2] * O[2] + dctMatrix[28][3] * O[3]) >> shift);

		src += 8;
		dst++;
	}
}
void inverseButterfly8(const int16_t* src, int16_t* dst, uint8_t shift, uint8_t line)
{
	int j, k;
	int E[4], O[4];
	int EE[2], EO[2];

	for (j = 0; j < line; j++)
	{
		/* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
		for (k = 0; k < 4; k++)
		{
			O[k] = dctMatrix[4][k] * src[line] + dctMatrix[12][k] * src[3 * line] + dctMatrix[20][k] * src[5 * line] + dctMatrix[28][k] * src[7 * line];
		}

		EO[0] = dctMatrix[8][0] * src[2 * line] + dctMatrix[24][0] * src[6 * line];
		EO[1] = dctMatrix[8][1] * src[2 * line] + dctMatrix[24][1] * src[6 * line];
		EE[0] = dctMatrix[0][0] * src[0] + dctMatrix[16][0] * src[4 * line];
		EE[1] = dctMatrix[0][1] * src[0] + dctMatrix[16][1] * src[4 * line];

		/* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
		E[0] = EE[0] + EO[0];
		E[3] = EE[0] - EO[0];
		E[1] = EE[1] + EO[1];
		E[2] = EE[1] - EO[1];
		for (k = 0; k < 4; k++)
		{
			dst[k] = (int16_t)Clip(-32768, 32767, (E[k] + O[k]) >> shift);
			dst[k + 4] = (int16_t)Clip(-32768, 32767, (E[3 - k] - O[3 - k]) >> shift);
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

		dst[0] = (int16_t)((dctMatrix[0][0] * EEE[0] + dctMatrix[0][1] * EEE[1]) >> shift);
		dst[8 * line] = (int16_t)((dctMatrix[16][0] * EEE[0] + dctMatrix[16][1] * EEE[1]) >> shift);
		dst[4 * line] = (int16_t)((dctMatrix[8][0] * EEO[0] + dctMatrix[8][1] * EEO[1]) >> shift);
		dst[12 * line] = (int16_t)((dctMatrix[24][0] * EEO[0] + dctMatrix[24][1] * EEO[1]) >> shift);

		for (k = 2; k < 16; k += 4)
		{
			dst[k * line] = (int16_t)((dctMatrix[k * 2][0] * EO[0] + dctMatrix[k * 2][1] * EO[1] + dctMatrix[k * 2][2] * EO[2] +
				dctMatrix[k * 2][3] * EO[3]) >> shift);
		}

		for (k = 1; k < 16; k += 2)
		{
			dst[k * line] = (int16_t)((dctMatrix[k * 2][0] * O[0] + dctMatrix[k * 2][1] * O[1] + dctMatrix[k * 2][2] * O[2] + dctMatrix[k * 2][3] * O[3] +
				dctMatrix[k * 2][4] * O[4] + dctMatrix[k * 2][5] * O[5] + dctMatrix[k * 2][6] * O[6] + dctMatrix[k * 2][7] * O[7] ) >> shift);
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
			dst[k] = (int16_t)Clip(-32768, 32767, (E[k] + O[k]) >> shift);
			dst[k + 8] = (int16_t)Clip(-32768, 32767, (E[7 - k] - O[7 - k]) >> shift);
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

		dst[0] = (int16_t)((dctMatrix[0][0] * EEEE[0] + dctMatrix[0][1] * EEEE[1]) >> shift);
		dst[16 * line] = (int16_t)((dctMatrix[16][0] * EEEE[0] + dctMatrix[16][1] * EEEE[1]) >> shift);
		dst[8 * line] = (int16_t)((dctMatrix[8][0] * EEEO[0] + dctMatrix[8][1] * EEEO[1]) >> shift);
		dst[24 * line] = (int16_t)((dctMatrix[24][0] * EEEO[0] + dctMatrix[24][1] * EEEO[1]) >> shift);
		for (k = 4; k < 32; k += 8)
		{
			dst[k * line] = (int16_t)((dctMatrix[k][0] * EEO[0] + dctMatrix[k][1] * EEO[1] + dctMatrix[k][2] * EEO[2] +
				dctMatrix[k][3] * EEO[3]) >> shift);
		}

		for (k = 2; k < 32; k += 4)
		{
			dst[k * line] = (int16_t)((dctMatrix[k][0] * EO[0] + dctMatrix[k][1] * EO[1] + dctMatrix[k][2] * EO[2] +
				dctMatrix[k][3] * EO[3] + dctMatrix[k][4] * EO[4] + dctMatrix[k][5] * EO[5] +
				dctMatrix[k][6] * EO[6] + dctMatrix[k][7] * EO[7]) >> shift);
		}

		for (k = 1; k < 32; k += 2)
		{
			dst[k * line] = (int16_t)((dctMatrix[k][0] * O[0] + dctMatrix[k][1] * O[1] + dctMatrix[k][2] * O[2] + dctMatrix[k][3] * O[3] +
				dctMatrix[k][4] * O[4] + dctMatrix[k][5] * O[5] + dctMatrix[k][6] * O[6] + dctMatrix[k][7] * O[7] +
				dctMatrix[k][8] * O[8] + dctMatrix[k][9] * O[9] + dctMatrix[k][10] * O[10] + dctMatrix[k][11] *
				O[11] + dctMatrix[k][12] * O[12] + dctMatrix[k][13] * O[13] + dctMatrix[k][14] * O[14] +
				dctMatrix[k][15] * O[15]) >> shift);
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
			dst[k] = (int16_t)Clip(-32768, 32767, (E[k] + O[k]) >> shift);
			dst[k + 16] = (int16_t)Clip(-32768, 32767, (E[15 - k] - O[15 - k]) >> shift);
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
	
	uint8_t firstShift, secondShift;
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
	temp = (int16_t *)calloc(sizeof(int16_t), nTbS*nTbS);

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
			butterfly4(residual, temp, firstShift, 4);
			butterfly4(temp, result, secondShift, 4);
			break;
		case 8:
			butterfly8(residual, temp, firstShift, 8);
			butterfly8(temp, result, secondShift, 8);
			break;
		case 16:
			butterfly16(residual, temp, firstShift, 16);
			butterfly16(temp, result, secondShift, 16);
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

	// check if it is alternate tranform - DST
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
	for (i = 0; i < nTbS; i++)
	{
		for (j = 0; j < nTbS; j++)
		{
			printf("%d	", temp[i*nTbS + j]);
		}
		printf("\n");
	}

	printf("Result(2DCT) matrix:\n");
	for (i = 0; i < nTbS; i++)
	{
		for (j = 0; j < nTbS; j++)
		{
			printf("%d	", result[i*nTbS + j]);
		}
		printf("\n");
	}
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

	temp = (int16_t *)calloc(sizeof(int16_t), nTbS*nTbS);

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
			inverseButterfly4(transform, temp, firstShift, 4);
			inverseButterfly4(temp, result, secondShift, 4);
			break;
		case 8:
			inverseButterfly8(transform, temp, firstShift, 8);
			inverseButterfly8(temp, result, secondShift, 8);
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
	for (i = 0; i < nTbS; i++)
	{
		for (j = 0; j < nTbS; j++)
		{
			printf("%d	", temp[i*nTbS + j]);
		}
		printf("\n");
	}

	printf("Result(2DCT) matrix:\n");
	for (i = 0; i < nTbS; i++)
	{
		for (j = 0; j < nTbS; j++)
		{
			printf("%d	", result[i*nTbS + j]);
		}
		printf("\n");
	}
#endif

	// cleanup
	free(temp);

}
