#ifndef TRANSFORMATION_HEADER
#define TRANSFORMATION_HEADER

#include "types.h"

#define NEON_ASM 1
#define BUTTERFLY 0

#if NEON_ASM
#include "neon_transform.h"
#include "butterfly_transform.h"
#define transform(predictionMode, BitDepth, nTbS, cIdx, residual, result)	transform_neon(predictionMode, BitDepth, nTbS, cIdx, residual, result);
#define inverseTransform(predictionMode, BitDepth, nTbS, cIdx, residual, result)		inverseTransform_butterfly(predictionMode, BitDepth, nTbS, cIdx, residual, result);
#elif BUTTERFLY
#include "butterfly_transform.h"
#define transform(predictionMode, BitDepth, nTbS, cIdx, residual, result)	transform_butterfly(predictionMode, BitDepth, nTbS, cIdx, residual, result);
#define inverseTransform(predictionMode, BitDepth, nTbS, cIdx, residual, result)		inverseTransform_butterfly(predictionMode, BitDepth, nTbS, cIdx, residual, result);
#else
#include "matrix_mul_transform.h"
#define transform(predictionMode, BitDepth, nTbS, cIdx, residual, result)	transform_matrix_mul(predictionMode, BitDepth, nTbS, cIdx, residual, result);
#define inverseTransform(predictionMode, BitDepth, nTbS, cIdx, residual, result)		inverseTransform_matrix_mul(predictionMode, BitDepth, nTbS, cIdx, residual, result);
#endif

#endif // !TRANSFORMATION_HEADER
