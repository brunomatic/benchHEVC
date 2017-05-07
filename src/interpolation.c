#include "interpolation.h"
#include <stdlib.h>
#include "types.h"
#include "common.h"

/*
 Luma 8 tap interpolation coefficients
 */
const int8_t interpolationCoeffLuma[3][8] = { { -1, 4, -10, 58, 17, -5, 1, 0 },
		{ -1, 4, -11, 40, 40, -11, 4, -1 }, { 0, 1, -5, 17, 58, -10, 4, -1 } };

/*
 Chroma 4 tap interpolation coefficents
 */
const int8_t interpolationCoeffChroma[7][4] = { { -2, 58, 10, -2 }, { -4, 54,
		16, -2 }, { -6, 46, 28, -4 }, { -4, 36, 36, -4 }, { -4, 28, 46, -6 }, {
		-2, 16, 54, -4 }, { -2, 10, 58, -2 } };

/*
 Compleate interpolation proces for Luma and Chroam components based on:
 picture - reference frame/picture
 (xPb, yPb) - prediction block components
 (nPbW, nPbH) - width and height of prediction block
 mvLx - motion vector for Luma component
 mvCLX - motion vector for Chroma compoents
 ChromaArrayType - 0 if no chroma interpolation will occur or it will be done with 8 tap filter
 Y, Cb, Cr - output variables for storing results of interpolation
 */
void fractionalInterpolation(image * picture, uint32_t xPb, uint32_t yPb,
		uint8_t nPbW, uint8_t nPbH, int16_t mvLX[2], int16_t mvCLX[2],
		uint8_t ChromaArrayType, predictionSample * Y, predictionSample * Cb,
		predictionSample * Cr) {

	int32_t xInt, yInt;
	uint8_t xFract, yFract;
	int8_t x, y;

	// calculate full and subpixel positions to fetch/interpolate
	xFract = mvLX[0] & 3;
	yFract = mvLX[1] & 3;
	xInt = xPb + (int32_t) (mvLX[0] >> 2);
	yInt = yPb + (int32_t) (mvLX[1] >> 2);

	// allocate memory for Luma component prediction block
	Y->data = (int16_t *) malloc(sizeof(int16_t) * nPbH * nPbW);
	Y->width = nPbW;
	Y->height = nPbH;

	// go fetch/interpolate samples
	for (y = 0; y < nPbH; y++) {
		for (x = 0; x < nPbW; x++) {

			Y->data[x + y * Y->width] = interpolateLumaSample(xInt + x,
					yInt + y, xFract, yFract, picture);

		}
	}

	/*// DEBUG - print what you fetched
	 printf("Luma interpolation debug:\n");
	 for (y = 0; y < nPbH; y++)
	 {
	 for (x = 0; x < nPbW; x++) {

	 printf("%d  ", Y->data[x + y * Y->width]);

	 }
	 printf("\n");
	 }*/

	// if needed we fetch/interpolate the chroma components too
	if (ChromaArrayType) {

		// first allocate data for Cb, Cr prediction blocks
		Cb->data = (int16_t *) malloc(
				sizeof(int16_t) * (nPbH / picture->SubHeight)
						* (nPbW / picture->SubWidth));
		Cb->width = nPbW / picture->SubWidth;
		Cb->height = nPbH / picture->SubHeight;

		Cr->data = (int16_t *) malloc(
				sizeof(int16_t) * (nPbH / picture->SubHeight)
						* (nPbW / picture->SubWidth));
		Cr->width = nPbW / picture->SubWidth;
		Cr->height = nPbH / picture->SubHeight;

		// calculate integer and fractal coordinates of samples to fetch
		xInt = (xPb / picture->SubWidth) + ((int32_t) mvCLX[0] >> 3);
		yInt = (yPb / picture->SubHeight) + ((int32_t) mvCLX[1] >> 3);
		xFract = mvCLX[0] & 7;
		yFract = mvCLX[1] & 7;

		// go fetch/interpolate
		for (y = 0; y < (nPbH / picture->SubHeight); y++) {
			for (x = 0; x < (nPbW / picture->SubWidth); x++) {

				interpolateChromaSample(xInt + x, yInt + y, xFract, yFract,
						picture, &(Cb->data[x + y * Cb->width]),
						&(Cr->data[x + y * Cr->width]));

			}
		}

		/*// DEBUG - print what you fetched
		 printf("Cb interpolation debug:\n");
		 for (y = 0; y < (nPbH / picture->SubHeight); y++)
		 {
		 for (x = 0; x < (nPbW / picture->SubWidth); x++) {

		 printf("%d  ", Cb->data[x + y * Cb->width]);

		 }
		 printf("\n");
		 }

		 // DEBUG - print what you fetched
		 printf("Cr interpolation debug:\n");
		 for (y = 0; y < (nPbH / picture->SubHeight); y++)
		 {
		 for (x = 0; x < (nPbW / picture->SubWidth); x++) {

		 printf("%d  ", Cr->data[x + y * Cr->width]);

		 }
		 printf("\n");
		 }
		 */

	}

}

/*
 Function retrives one sample(pixel/subpixel) by either interpolation or just fetching it for Luma component:
 1. Check what we need for calculation - load those samples based on fractional vector
 2. Set bitshift value
 3. Set row index to know which values to use for calculation
 4. Crunch the numbers
 */
int16_t interpolateLumaSample(int32_t x, int32_t y, uint8_t xFract,
		uint8_t yFract, image * picture) {

	int32_t samples[8], result = 0, rowIndex;
	uint8_t shift;
	int8_t i;

	// first handle integer pixel( if fractal = 0,0 )
	if (xFract == 0 && yFract == 0) {
		shift = max(2, 14 - picture->bitDepthY);
		return pixelY(picture, x, y)<< shift;

	}

	// if we are calculating sth in first row load only horizontal integer pixels
	// these are interpolated horizonataly so set the rowIndex depending on xFract
	if (yFract == 0) {
		for (i = 0; i < 8; i++) {
			samples[i] = pixelY(picture, x - 3 + i, y);
		}
		shift = min(4, picture->bitDepthY - 8);
		rowIndex = xFract - 1;
	}
	// everything else is interpolated verticaly so the rowIndex is depending on yFract
	else {
		rowIndex = yFract - 1;

		// handle first row, those subpixels are calculated based on integer pixels
		if (xFract == 0) {
			for (i = 0; i < 8; i++) {
				samples[i] = pixelY(picture, x, y - 3 + i);
			}
			shift = min(4, picture->bitDepthY - 8);
		}
		// handle the rest, those need subpixel positions above and below the reference block
		// those subpixels are retreived by recursive call with different coordinates
		else {
			for (i = 0; i < 8; i++) {
				samples[i] = interpolateLumaSample(x, y - 3 + i, xFract, 0,
						picture);
			}
			shift = 6;
		}
	}

	// crunch the numbers
	for (i = 0; i < 8; i++) {
		result += samples[i] * interpolationCoeffLuma[rowIndex][i];
	}

	return result >> shift;
}

/*
 Function retrives one sample(pixel/subpixel) by either interpolation or just fetching it for both Chroma components:
 1. Check what we need for calculation - load those samples based on fractional vector
 2. Set bitshift value
 3. Set row index to know which values to use for calculation
 4. Crunch the numbers
 */
void interpolateChromaSample(int32_t x, int32_t y, uint8_t xFract,
		uint8_t yFract, image * picture, int16_t * CbSample, int16_t * CrSample) {
	int16_t samples[2][4], rowIndex;
	int32_t tempCb = 0, tempCr = 0;
	uint8_t shift;
	int8_t i;

	*CbSample = 0;
	*CrSample = 0;

	// first handle integer pixel, just fetch it
	if (xFract == 0 && yFract == 0) {
		shift = max(2, 14 - picture->bitDepthC);
		*CbSample = pixelCb(picture, x, y)<< shift;
		*CrSample = pixelCr(picture, x, y)<< shift;
		return;
	}

	// check what to load
	// handling the first column - we need vertical integer pixels
	if (xFract == 0) {
		for (i = 0; i < 4; i++) {
			samples[0][i] = pixelCb(picture, x, y - 1 + i);
			samples[1][i] = pixelCr(picture, x, y - 1 + i);
		}
		shift = min(4, picture->bitDepthC - 8);
		rowIndex = yFract - 1;
	} else {
		// handle the first row, these are calculated base on integer pixels horizontaly
		if (yFract == 0) {
			for (i = 0; i < 4; i++) {
				samples[0][i] = pixelCb(picture, x - 1 + i, y);
				samples[1][i] = pixelCr(picture, x - 1 + i, y);
			}
			shift = min(4, picture->bitDepthC - 8);
			rowIndex = xFract - 1;
		}

		// all other rows needs subpixels calculated by recursion
		else {
			for (i = 0; i < 4; i++) {
				interpolateChromaSample(x, y - 1 + i, yFract, 0, picture,
						&samples[0][i], &samples[1][i]);
			}
			shift = 6;
			rowIndex = yFract - 1;
		}
	}

	// possible overflow, use temp 32 bit vars for number crunching
	for (i = 0; i < 4; i++) {
		tempCb += samples[0][i] * interpolationCoeffChroma[rowIndex][i];
		tempCr += samples[1][i] * interpolationCoeffChroma[rowIndex][i];
	}

	*CbSample = tempCb >> shift;
	*CrSample = tempCr >> shift;

	return;
}
