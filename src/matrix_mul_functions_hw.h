#ifndef MATRIX_MUL_FUNCTIONS_HW_HEADER
#define MATRIX_MUL_FUNCTIONS_HW_HEADER

#include "types.h"

#pragma SDS data copy(src_a[0:16])
#pragma SDS data zero_copy(src_b[0:16], dst[0:16])
#pragma SDS data access_pattern(src_a:SEQUENTIAL)
void transform_4_hw(int16_t * src_a, int16_t * src_b, int16_t * dst);

#pragma SDS data copy(src_a[0:64])
#pragma SDS data zero_copy(src_b[0:64], dst[0:64])
#pragma SDS data access_pattern(src_a:SEQUENTIAL)
void transform_8_hw(int16_t * src_a, int16_t * src_b, int16_t * dst);

#pragma SDS data copy(src_a[0:256])
#pragma SDS data zero_copy(src_b[0:256], dst[0:256])
#pragma SDS data access_pattern(src_a:SEQUENTIAL)
void transform_16_hw(int16_t * src_a, int16_t * src_b, int16_t * dst);

#pragma SDS data copy(src_a[0:1024])
#pragma SDS data zero_copy(src_b[0:1024], dst[0:1024])
#pragma SDS data access_pattern(src_a:SEQUENTIAL)
void transform_32_hw(int16_t * src_a, int16_t * src_b, int16_t * dst);

#endif
