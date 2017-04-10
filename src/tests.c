
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
void testInterpolation()
{
	image picture;
	uint8_t nPbW = 4, nPbH = 4;
	int16_t mvLX[2] = { 3 , 3 }, mvCLX[2] = { 4, 4 };
	uint32_t xPb = 1, yPb = 1;
	predictionSample Luma, Cb, Cr;

	generatePicture(&picture, 512, 512, YUV_444);

	//writeImage(&picture, "img.ppm");

	printPlaneSegment(&picture, 8, 8, 1, 1, Y_PLANE);

	//printPlaneSegment(&picture, 8, 8, 1, 1, CB_PLANE);

	//printPlaneSegment(&picture, 8, 8, 1, 1, CR_PLANE);

	fractionalInterpolation(&picture, xPb, yPb, nPbW, nPbH, mvLX, mvCLX, 1, &Luma, &Cb, &Cr);

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
void testTransformation() {
	
	int16_t residual[4][4] = {
		{ -256, -256, -256, -256 },
		{ -256, -256, -256, -256 },
		{ -256, -256, -256, -256 },
		{ -256, -256, -256, -256 }
	};
	int16_t * temp, *result;

	result = (int16_t *)malloc(sizeof(int16_t) * 4 * 4);
	temp = (int16_t *)malloc(sizeof(int16_t) * 4 * 4);

	printf("Residual block:\n");
	printMatrix((int16_t *)&residual, 4);
	transform(MODE_INTER, 8, 4, 1, (int16_t *)&residual, temp);

	printf("2D DCT block:\n");
	printMatrix(temp, 4);

	inverseTransform(MODE_INTER, 8, 4, 1, temp, result);

	printf("Reconstructed block:\n");
	printMatrix(result, 4);

	free(result);
	free(temp);


	return;

}
