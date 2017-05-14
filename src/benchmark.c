#include "benchmark.h"
#include <stdlib.h>
#include <stdio.h>
#include "helper.h"
#include "common.h"
#include "neon_transform.h"
#include "butterfly_transform.h"
#include "matrix_mul_transform.h"
#include "matrix_mul_transform_hw.h"
#include "interpolation.h"
#include "sds_lib.h"

void benchTransform(uint32_t numberOfIterations, uint8_t blockSize,
		uint8_t mode) {

	uint64_t start_cnt, end_cnt, total_cnt = 0, stats[4];
	volatile uint32_t i;

	int16_t * random_residual;
	int16_t * temp, *result;

	random_residual = (int16_t *) sds_alloc(
			sizeof(int16_t) * blockSize * blockSize);
	result = (int16_t *) sds_alloc(sizeof(int16_t) * blockSize * blockSize);
	temp = (int16_t *) sds_alloc(sizeof(int16_t) * blockSize * blockSize);

	printf("Running %d iterations of %dx%d transforms...\n", numberOfIterations,
			blockSize, blockSize);
	// plain matrix multiply implementation
	for (i = 0; i < numberOfIterations; i++) {

		generateResidual(blockSize, random_residual);

		start_cnt = sds_clock_counter();

		transform_matrix_mul(mode, 8, blockSize, 1, random_residual, temp);

		end_cnt = sds_clock_counter();

		total_cnt +=
				(end_cnt > start_cnt) ?
						(end_cnt - start_cnt) :
						((UINT64_MAX - start_cnt) + end_cnt);

	}
	stats[0] = total_cnt;
	total_cnt = 0;
	// partial butterfly implementation
	for (i = 0; i < numberOfIterations; i++) {

		generateResidual(blockSize, random_residual);

		start_cnt = sds_clock_counter();

		transform_butterfly(mode, 8, blockSize, 1, random_residual, temp);

		end_cnt = sds_clock_counter();

		total_cnt +=
				(end_cnt > start_cnt) ?
						(end_cnt - start_cnt) :
						((UINT64_MAX - start_cnt) + end_cnt);

	}
	stats[1] = total_cnt;
	total_cnt = 0;
	// NEON implementation
	for (i = 0; i < numberOfIterations; i++) {

		generateResidual(blockSize, random_residual);

		start_cnt = sds_clock_counter();

		transform_butterfly(mode, 8, blockSize, 1, random_residual, temp);

		end_cnt = sds_clock_counter();

		total_cnt +=
				(end_cnt > start_cnt) ?
						(end_cnt - start_cnt) :
						((UINT64_MAX - start_cnt) + end_cnt);

	}
	stats[2] = total_cnt;
	total_cnt = 0;
	// HW acceleration
	for (i = 0; i < numberOfIterations; i++) {

		generateResidual(blockSize, random_residual);

		start_cnt = sds_clock_counter();

		transform_matrix_mul_hw(mode, 8, blockSize, 1, random_residual, temp);

		end_cnt = sds_clock_counter();

		total_cnt +=
				(end_cnt > start_cnt) ?
						(end_cnt - start_cnt) :
						((UINT64_MAX - start_cnt) + end_cnt);

	}
	stats[3] = total_cnt;

	sds_free(result);
	sds_free(temp);
	sds_free(random_residual);

	printf("Average cpu cycles:\n");
	printf("\t MATRIX_MUL:%.10f\n", (float)(stats[0] / numberOfIterations));
	printf("\t BUTTERFLY:%.10f\n", (float)(stats[1] / numberOfIterations));
	printf("\t NEON:%.10f\n", (float)(stats[2] / numberOfIterations));
	printf("\t HW acc.:%.10f\n", (float)(stats[3] / numberOfIterations));

}

void benchInterpolation(uint32_t numberOfIterations, uint8_t blockWidth,
		uint8_t blockHeight) {
	/*
	uint64_t start_cnt, end_cnt, total_cnt = 0;
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

	 start_cnt = sds_clock_counter();

	 fractionalInterpolation(&picture, xPb, yPb, blockWidth, blockHeight,
	 mvLX, mvCLX, 1, &Luma, &Cb, &Cr);

	 end_cnt = sds_clock_counter();

	 (end_cnt > start_cnt) ?
	 (total_cnt += (end_cnt - start_cnt)) :
	 (total_cnt += ((UINT64_MAX - start_cnt) + end_cnt));

	 free(Luma.data);
	 free(Cb.data);
	 free(Cr.data);
	 }

	 free(picture.Y);
	 free(picture.Cb);
	 free(picture.Cr);

	printf("Average cpu cycles: %.1d\n",
			(int) (total_cnt / numberOfIterations));
*/
}
