#include "butterfly_transform_hw.h"
#include "butterfly_functions_hw.h"
#include <stdlib.h>
#include "sds_lib.h"
#include "common.h"

#if DEBUG

#include <stdio.h>
#include "helper.h"

#endif

/*
 * Function implements forward transform using partial butterfly algorithms in C
 */
void transform_butterfly_hw(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS,
		uint8_t cIdx, int16_t * residual, int16_t * result) {

	// handle alternate DST transform of 4x4 blocks
	if (predictionMode == MODE_INTRA && nTbS == 4) {
		dst_butterfly_4_hw(residual, result);
	}
	// handle everything else using butterfly algorithms from x265
	else {
		switch (nTbS) {
		case 4:
			dct_butterfly_4_hw(residual, result);
			break;
		case 8:
			dct_butterfly_8_hw(residual, result);
			break;
		case 16:
			dct_butterfly_16_hw(residual, result);
			break;
		case 32:
			dct_butterfly_32_hw(residual, result);
			break;
		default:
			break;
		}
	}

	// debug printing
#if DEBUG
	printf("Result(2DCT) matrix:\n");
	printMatrix(result, nTbS);

#endif // DEBUG

}
