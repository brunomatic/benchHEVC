#include "benchmark.h"
#include <stdlib.h>
#include <stdio.h>
#include "timing.h"
#include "helper.h"
#include "common.h"
#include "transformation.h"
#include "interpolation.h"

void benchTransform(uint32_t numberOfIterations, uint8_t blockSize,
		uint8_t mode) {
	double start_time, end_time, total_time = 0;
	volatile uint32_t i;

	int16_t * random_residual;
	int16_t * temp, *result;

	random_residual = (int16_t *) malloc(
			sizeof(int16_t) * blockSize * blockSize);
	result = (int16_t *) malloc(sizeof(int16_t) * blockSize * blockSize);
	temp = (int16_t *) malloc(sizeof(int16_t) * blockSize * blockSize);

	printf("Running %d iterations of %dx%d transforms and inverse transforms...\n",
			numberOfIterations, blockSize, blockSize);
	for (i = 0; i < numberOfIterations; i++) {

		generateResidual(blockSize, random_residual);

		start_time = get_time();

		transform(mode, 8, blockSize, 1, random_residual, temp);

		end_time = get_time();

		total_time += (end_time - start_time);

	}

	free(result);
	free(temp);
	free(random_residual);

	printf("Total execution time: %.10f\n", total_time);

}

void benchInterpolation(uint32_t numberOfIterations, uint8_t blockWidth,
		uint8_t blockHeight) {
	double start_time, end_time, total_time = 0;
	volatile uint32_t i;
	image picture;
	int16_t mvLX[2], mvCLX[2];
	uint32_t xPb, yPb;
	predictionSample Luma, Cb, Cr;

	generatePicture(&picture, 1920, 1080, YUV_422);

	printf("Running %d iteratons of %dx%d interpolations...\n",
			numberOfIterations, blockWidth, blockHeight);
	for (i = 0; i < numberOfIterations; i++) {

		generateRandomMV(&xPb, &yPb, (int16_t *) &mvLX, (int16_t *) &mvCLX,
				1920, 1080, blockWidth, blockHeight);

		start_time = get_time();

		fractionalInterpolation(&picture, xPb, yPb, blockWidth, blockHeight,
				mvLX, mvCLX, 1, &Luma, &Cb, &Cr);

		end_time = get_time();

		free(Luma.data);
		free(Cb.data);
		free(Cr.data);

		total_time += (end_time - start_time);
	}

	free(picture.Y);
	free(picture.Cb);
	free(picture.Cr);

	printf("Total execution time: %.10f\n", total_time);

}
