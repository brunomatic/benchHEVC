#include "neon_transform.h"
#include "neon_functions.h"
#include "common.h"

#if DEBUG

#include <stdio.h>
#include "helper.h"

#endif

/*
 *	Function implements forward transfrom using NEON ASM functions
 */
void transform_neon(uint8_t predictionMode, uint8_t BitDepth, uint8_t nTbS,
		uint8_t cIdx, int16_t * residual, int16_t * result) {

	// handle alternate DST transform of 4x4 blocks
	if (predictionMode == MODE_INTRA && nTbS == 4) {
		dst_4x4_neon(residual, result);
	}
	// handle everything else using butterfly algorithms from x265
	else {
		switch (nTbS) {
		case 4:
			x265_dct_4x4_neon(residual, result);
			break;
		case 8:
			x265_dct_8x8_neon(residual, result);
			break;
		case 16:
			x265_dct_16x16_neon(residual, result);
			break;
		case 32:
			dct_32x32_neon(residual, result);
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
