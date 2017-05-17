#ifndef BUTTERFLY_FUNCTIONS_HW_HEADER
#define BUTTERFLY_FUNCTIONS_HW_HEADER

#include "types.h"

#pragma SDS data zero_copy(src[0:16], dst[0:16])
#pragma SDS data access_pattern(src:SEQUENTIAL, dst:SEQUENTIAL)
void dst_butterfly_4_hw(int16_t* src, int16_t* dst);

#pragma SDS data zero_copy(src[0:16], dst[0:16])
#pragma SDS data access_pattern(src:SEQUENTIAL, dst:SEQUENTIAL)
void dct_butterfly_4_hw(int16_t* src, int16_t* dst);

#pragma SDS data zero_copy(src[0:64], dst[0:64])
#pragma SDS data access_pattern(src:SEQUENTIAL, dst:SEQUENTIAL)
void dct_butterfly_8_hw(int16_t* src, int16_t* dst);

#pragma SDS data zero_copy(src[0:256], dst[0:256])
#pragma SDS data access_pattern(src:SEQUENTIAL, dst:SEQUENTIAL)
void dct_butterfly_16_hw(int16_t* src, int16_t* dst);

#pragma SDS data zero_copy(src[0:1024], dst[0:1024])
#pragma SDS data access_pattern(src:SEQUENTIAL, dst:SEQUENTIAL)
void dct_butterfly_32_hw(int16_t* src, int16_t* dst);


#endif
