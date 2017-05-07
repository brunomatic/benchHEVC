#include "tests.h"
#include <stdlib.h>
#include <stdio.h>
#include "types.h"
#include "common.h"
#include "helper.h"
#include "interpolation.h"
#include "transformation.h"

/*
 Function for testing interpolation algorithm on a known pattern
 */
void testInterpolation() {
	image picture;
	uint8_t nPbW = 4, nPbH = 4;
	int16_t mvLX[2] = { 3, 3 }, mvCLX[2] = { 4, 4 };
	uint32_t xPb = 1, yPb = 1;
	predictionSample Luma, Cb, Cr;

	generatePicture(&picture, 512, 512, YUV_444);

	//writeImage(&picture, "img.ppm");

	printPlaneSegment(&picture, 8, 8, 1, 1, Y_PLANE);

	//printPlaneSegment(&picture, 8, 8, 1, 1, CB_PLANE);

	//printPlaneSegment(&picture, 8, 8, 1, 1, CR_PLANE);

	fractionalInterpolation(&picture, xPb, yPb, nPbW, nPbH, mvLX, mvCLX, 1,
			&Luma, &Cb, &Cr);

	printMatrix(Luma.data, 4);

	//printMatrix(Cb.data, 4);

	//printMatrix(Cr.data, 4);

	free(Luma.data);
	free(Cb.data);
	free(Cr.data);

	free(picture.Y);
	free(picture.Cb);
	free(picture.Cr);

	return;
}

/*
 Function for testing transformation algorithm on a known pattern
 */
void testTransformation(uint8_t size, uint8_t mode) {

	int16_t *residual, *temp, *result;
	uint8_t i, j;

	residual = (int16_t *) malloc(sizeof(int16_t) * size * size);
	result = (int16_t *) malloc(sizeof(int16_t) * size * size);
	temp = (int16_t *) malloc(sizeof(int16_t) * size * size);

	for (i = 0; i < size; i++) {
		for (j = 0; j < size; j++) {
			residual[i * size + j] = -256 + (j % 2);
		}
	}

	printf("Residual block:\n");
	printMatrix(residual, size);
	transform(mode, 8, size, 1, residual, temp);

	printf("2D DCT block:\n");
	printMatrix(temp, size);

	inverseTransform(mode, 8, size, 1, temp, result);

	printf("Reconstructed block:\n");
	printMatrix(result, size);

	free(result);
	free(temp);
	free(residual);

	return;

}
