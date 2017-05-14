/*****************************************************************************
 * Copyright (C) 2013-2017 MulticoreWare, Inc
 *
 * Authors: Min Chen <chenm003@163.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at license @ x265.com.
 *****************************************************************************/

// Taken from x265 and adopted a bit


/*****************************************************************************
 * Copyright (C) Bruno Matic
 *
 * Author od dst_4x4_neon and dct_32x32_ neon functions: Bruno Matic <bruno.matic.zg@gmail.com>
 * Use these functions is not allowed unless the author grants rights to do so.
 *****************************************************************************
*/
	.align 8

	.globl  x265_dct_4x4_neon
	.type    x265_dct_4x4_neon,%function

x265_dct_4x4_neon:
	.fnstart
    vld1.16         {d0}, [r0]!                     // d0  = [03 02 01 00]
    vld1.16         {d1}, [r0]!                     // d1  = [13 12 11 10]
    vld1.16         {d2}, [r0]!                     // d2  = [23 22 21 20]
    vld1.16         {d3}, [r0]                      // d3  = [33 32 31 30]

    vtrn.32         q0, q1                                  // q0  = [31 30 11 10 21 20 01 00], q1 = [33 32 13 12 23 22 03 02]
    vrev32.16       q1, q1                                  // q1  = [32 33 12 13 22 23 02 03]

    ldr	r0, =0x00240053
    ldr	r2, =0xFFAD0024

    // DCT-1D
    vadd.s16        q2, q0, q1                              // q2  = [E31 E30 E11 E10 E21 E20 E01 E00]
    vsub.s16        q3, q0, q1                              // q3  = [O31 O30 O11 O10 O21 O20 O01 O00]
    vdup.32         d16, r0                                 // d16 = [ 36  83]
    vdup.32         d17, r2                                 // d17 = [-83  36]
    vtrn.16         d4, d5                                  // d4  = [E30 E20 E10 E00], d5 = [E31 E21 E11 E01]
    vtrn.32         d6, d7                                  // q3  = [O31 O30 O21 O20 O11 O10 O01 O00]

    vmull.s16       q9, d6, d16
    vmull.s16       q10, d7, d16                            // [q9, q10] = [ 36*O1 83*O0] -> [1]
    vmull.s16       q11, d6, d17
    vmull.s16       q12, d7, d17                            // [q11,q12] = [-83*O1 36*O0] -> [3]

    vadd.s16        d0, d4, d5                              // d0 = [E0 + E1]
    vsub.s16        d1, d4, d5                              // d1 = [E0 - E1]

    vpadd.s32       d18, d18, d19                           // q9  = [1]
    vpadd.s32       d19, d20, d21
    vpadd.s32       d20, d22, d23                           // q10 = [3]
    vpadd.s32       d21, d24, d25

    vshll.s16       q1, d0, #6                              // q1  = 64 * [0]
    vshll.s16       q2, d1, #6                              // q2  = 64 * [2]

    // TODO: Dynamic Range is 11+6-1 bits
    vqrshrn.s32     d25, q9, #1                              // d25 = R[13 12 11 10]
    vqrshrn.s32     d24, q1, #1                              // d24 = R[03 02 01 00]
    vqrshrn.s32     d26, q2, #1                              // q26 = R[23 22 21 20]
    vqrshrn.s32     d27, q10, #1                             // d27 = R[33 32 31 30]


    // DCT-2D
    vmovl.s16       q0, d16                                // q14 = [ 36  83]

    vtrn.32         q12, q13                                // q12 = [31 30 11 10 21 20 01 00], q13 = [33 32 13 12 23 22 03 02]
    vrev32.16       q13, q13                                // q13 = [32 33 12 13 22 23 02 03]

    vaddl.s16       q1, d24, d26                            // q0  = [E21 E20 E01 E00]
    vaddl.s16       q2, d25, d27                            // q1  = [E31 E30 E11 E10]
    vsubl.s16       q3, d24, d26                            // q2  = [O21 O20 O01 O00]
    vsubl.s16       q8, d25, d27                            // q3  = [O31 O30 O11 O10]

    vtrn.32         q1, q2                                  // q1  = [E30 E20 E10 E00], q2  = [E31 E21 E11 E01]
    vtrn.32         q3, q8                                  // q3  = [O30 O20 O10 O00], q8  = [O31 O21 O11 O01]

    vmul.s32        q9, q3, d0[0]                           // q9  = [83*O30 83*O20 83*O10 83*O00]
    vmul.s32        q10, q8, d0[1]                          // q10 = [36*O31 36*O21 36*O11 36*O01]
    vmul.s32        q11, q3, d0[1]                          // q11 = [36*O30 36*O20 36*O10 36*O00]
    vmul.s32        q12, q8, d0[0]                          // q12 = [83*O31 83*O21 83*O11 83*O01]

    vadd.s32        q0, q1, q2                              // d0 = [E0 + E1]
    vsub.s32        q1, q1, q2                              // d1 = [E0 - E1]

    vadd.s32        q9, q9, q10
    vsub.s32        q10, q11, q12

    vshl.s32        q0, q0, #6                              // q1  = 64 * [0]
    vshl.s32        q1, q1, #6                              // q2  = 64 * [2]

    vqrshrn.s32     d25, q9, #8                              // d25 = R[13 12 11 10]
    vqrshrn.s32     d27, q10, #8                             // d27 = R[33 32 31 30]

    vqrshrn.s32     d24, q0, #8                              // d24 = R[03 02 01 00]
    vqrshrn.s32     d26, q1, #8                              // q26 = R[23 22 21 20]

    vst1.16         {d24-d27}, [r1]
    bx              lr
.fnend

.ltorg

.align 8

	.globl  dst_4x4_1_neon
	.type    dst_4x4_1_neon,%function

dst_4x4_1_neon:
	.fnstart
    vld4.16	{d2-d5}, [r0]

    // d2=> [0 4 8 12]
    // d3=> [1 5 9 13]
    // d4=> [2 6 10 14]
    // d5=> [3 7 11 15]
	vmov.s16 d31, #74

	vaddl.s16 q4, d2, d5	// q4 => C1
	vaddl.s16 q5, d3, d5	// q5 => C2
	vsubl.s16 q6, d3, d2	// q6 => C3
	vmull.s16 q7, d4, d31	// q7 => C4
	vaddl.s16 q3, d2, d3
	vsubw.s16 q3, q3, d5	// q3 => C0

	vmov.s32 q8, #29		// q8  => 29
	vmov.s32 q9, #74		// q9  => 74
	vmov.s32 q10, #55		// q10 => 55
	vmov.s32 q11, #84		// q11 => 84

	vmul.s32 q12, q4, q8	// dst[0]	= 29*C1
	vmul.s32 q13, q3, q9	// dst[4]	= 74*C0
	vmul.s32 q14, q5, q10	// dst[8]	= 55*C2
	vmov.s32 q15, q7		// dst[12]	= C4

	vmla.s32 q12, q5, q10	// dst[0]	+= 55*C2
	vmls.s32 q14, q6, q11	// dst[8]	-= 84*C3
	vmls.s32 q15, q6, q11	// dst[12]	-= 84*C3

	vadd.s32 q12, q12, q7	// dst[0]	+= C4
	vsub.s32 q14, q14, q7	// dst[8]	+= C4
	vmls.s32 q15, q4, q8	// dst[12]	-= 29*C1

	vqrshrn.s32	d2, q12, #1			// d2 => dst[0]
	vqrshrn.s32 d3, q13, #1			// d3 => dst[4]
    vqrshrn.s32	d4, q14, #1			// d4 => dst[8]
    vqrshrn.s32	d5, q15, #1			// d5 => dst[12]

   // transpose for next pass
    vtrn.16 d2, d3
    vtrn.16	d4, d5
    vtrn.32	d2, d4
    vtrn.32 d3, d5

    // d2=> [0 4 8 12]
    // d3=> [1 5 9 13]
    // d4=> [2 6 10 14]
    // d5=> [3 7 11 15]
	vmov.s16 d31, #74

	vaddl.s16 q4, d2, d5	// q4 => C1
	vaddl.s16 q5, d3, d5	// q5 => C2
	vsubl.s16 q6, d3, d2	// q6 => C3
	vmull.s16 q7, d4, d31	// q7 => C4
	vaddl.s16 q3, d2, d3
	vsubw.s16 q3, q3, d5	// q3 => C0

	vmov.s32 q8, #29		// q8  => 29
	vmov.s32 q9, #74		// q9  => 74
	vmov.s32 q10, #55		// q10 => 55
	vmov.s32 q11, #84		// q11 => 84

	vmul.s32 q12, q4, q8	// dst[0]	= 29*C1
	vmul.s32 q13, q3, q9	// dst[4]	= 74*C0
	vmul.s32 q14, q5, q10	// dst[8]	= 55*C2
	vmov.s32 q15, q7		// dst[12]	= C4

	vmla.s32 q12, q5, q10	// dst[0]	+= 55*C2
	vmls.s32 q14, q6, q11	// dst[8]	-= 84*C3
	vmls.s32 q15, q6, q11	// dst[12]	-= 84*C3

	vadd.s32 q12, q12, q7	// dst[0]	+= C4
	vsub.s32 q14, q14, q7	// dst[8]	+= C4
	vmls.s32 q15, q4, q8	// dst[12]	-= 29*C1

	vqrshrn.s32	d2, q12, #8			// d2 => dst[0]
	vqrshrn.s32 d3, q13, #8			// d3 => dst[4]
    vqrshrn.s32	d4, q14, #8			// d4 => dst[8]
    vqrshrn.s32	d5, q15, #8			// d5 => dst[12]

	vst1.16 {d2-d5}, [r1]
	bx lr
.fnend

.ltorg


.align 8

	.globl  dst_4x4_neon
	.type    dst_4x4_neon,%function

dst_4x4_neon:
	.fnstart
    vld4.16	{d2-d5}, [r0]

    // d2=> [0 4 8 12]
    // d3=> [1 5 9 13]
    // d4=> [2 6 10 14]
    // d5=> [3 7 11 15]

	vmov.s16 d15, #74

	vaddl.s16 q3, d2, d5	// q3 => C0
	vaddl.s16 q4, d3, d5	// q4 => C1
	vsubl.s16 q5, d2, d3	// q5 => C2
	vaddl.s16 q6, d2, d3	// 		q6 => src[0] + src[1]
	vsubw.s16 q6, q6, d5	// q6 => C4
	vmull.s16 q7, d4, d15	// q7 => 74 * src[2]

	vmov.s32 q8, #29		// q8 => 29
	vmov.s32 q9, #74		// q9 => 74
	vmov.s32 q10, #55		// q10=> 55

	vmul.s32 q11, q3, q8	// dst[0]	= 29*C0
	vmul.s32 q12, q6, q9	// dst[4]	= 74*C4
	vmul.s32 q13, q5, q8	// dst[8]	= 29*C2
	vmul.s32 q14, q5, q10	// dst[12	= 55*C2

	vmla.s32 q11, q4, q10	// dst[0]	+= 55*C1
	vmla.s32 q13, q3, q10	// dst[8]	+= 55*C0
	vmls.s32 q14, q4, q8	// dst[12]	-= 29*C1

	vadd.s32 q11, q11, q7	// dst[0]	+= C3
	vsub.s32 q13, q13, q7	// dst[8]	-= C3
	vadd.s32 q14, q14, q7	// dst[12]	+= C3

	vqrshrn.s32	d2, q11, #1			// d2 => dst[0]
	vqrshrn.s32 d3, q12, #1			// d3 => dst[4]
    vqrshrn.s32	d4, q13, #1			// d4 => dst[8]
    vqrshrn.s32	d5, q14, #1			// d5 => dst[12]

   // transpose for next pass
    vtrn.16 d2, d3
    vtrn.16	d4, d5
    vtrn.32	d2, d4
    vtrn.32 d3, d5

    // d2=> [0 4 8 12]
    // d3=> [1 5 9 13]
    // d4=> [2 6 10 14]
    // d5=> [3 7 11 15]

	vmov.s16 d15, #74

	vaddl.s16 q3, d2, d5	// q3 => C0
	vaddl.s16 q4, d3, d5	// q4 => C1
	vsubl.s16 q5, d2, d3	// q5 => C2
	vaddl.s16 q6, d2, d3	// 		q6 => src[0] + src[1]
	vsubw.s16 q6, q6, d5	// q6 => C4
	vmull.s16 q7, d4, d15	// q7 => 74 * src[2]

	vmov.s32 q8, #29		// q8 => 29
	vmov.s32 q9, #74		// q9 => 74
	vmov.s32 q10, #55		// q10=> 55

	vmul.s32 q11, q3, q8	// dst[0]	= 29*C0
	vmul.s32 q12, q6, q9	// dst[4]	= 74*C4
	vmul.s32 q13, q5, q8	// dst[8]	= 29*C2
	vmul.s32 q14, q5, q10	// dst[12	= 55*C2

	vmla.s32 q11, q4, q10	// dst[0]	+= 55*C1
	vmla.s32 q13, q3, q10	// dst[8]	+= 55*C0
	vmls.s32 q14, q4, q8	// dst[12]	-= 29*C1

	vadd.s32 q11, q11, q7	// dst[0]	+= C3
	vsub.s32 q13, q13, q7	// dst[8]	-= C3
	vadd.s32 q14, q14, q7	// dst[12]	+= C3

	vqrshrn.s32	d2, q11, #8			// d2 => dst[0]
	vqrshrn.s32 d3, q12, #8			// d3 => dst[4]
    vqrshrn.s32	d4, q13, #8			// d4 => dst[8]
    vqrshrn.s32	d5, q14, #8			// d5 => dst[12]

	vst1.16 {d2-d5}, [r1]
	bx lr
.fnend

.ltorg

.macro tr4 r0, r1, r2, r3
    vsub.s32    q8, \r0, \r3    // EO0
    vadd.s32    q9, \r0, \r3    // EE0
    vadd.s32    q10, \r1, \r2   // EE1
    vsub.s32    q11, \r1, \r2   // EO1

    vmul.s32    \r1, q8, d0[0]  // 83 * EO0
    vmul.s32    \r3, q8, d0[1]  // 36 * EO0
    vshl.s32    q9, q9, #6      // 64 * EE0
    vshl.s32    q10, q10, #6    // 64 * EE1
    vmla.s32    \r1, q11, d0[1] // 83 * EO0 + 36 * EO1
    vmls.s32    \r3, q11, d0[0] // 36 * EO0 - 83 * EO1
    vadd.s32    \r0, q9, q10    // 64 * (EE0 + EE1)
    vsub.s32    \r2, q9, q10    // 64 * (EE0 - EE1)
.endm


.macro tr8 r0, r1, r2, r3
    vmul.s32  q12, \r0, d1[1]   //  89 * src1
    vmul.s32  q13, \r0, d1[0]   //  75 * src1
    vmul.s32  q14, \r0, d2[1]   //  50 * src1
    vmul.s32  q15, \r0, d2[0]   //  18 * src1

    vmla.s32  q12, \r1, d1[0]   //  75 * src3
    vmls.s32  q13, \r1, d2[0]   // -18 * src3
    vmls.s32  q14, \r1, d1[1]   // -89 * src3
    vmls.s32  q15, \r1, d2[1]   // -50 * src3

    vmla.s32  q12, \r2, d2[1]   //  50 * src5
    vmls.s32  q13, \r2, d1[1]   // -89 * src5
    vmla.s32  q14, \r2, d2[0]   //  18 * src5
    vmla.s32  q15, \r2, d1[0]   //  75 * src5

    vmla.s32  q12, \r3, d2[0]   //  18 * src7
    vmls.s32  q13, \r3, d2[1]   // -50 * src7
    vmla.s32  q14, \r3, d1[0]   //  75 * src7
    vmls.s32  q15, \r3, d1[1]   // -89 * src7
.endm

.macro TRANSPOSE8x8 r0 r1 r2 r3 r4 r5 r6 r7
    vtrn.32         \r0, \r4
    vtrn.32         \r1, \r5
    vtrn.32         \r2, \r6
    vtrn.32         \r3, \r7
    vtrn.16         \r0, \r2
    vtrn.16         \r1, \r3
    vtrn.16         \r4, \r6
    vtrn.16         \r5, \r7
    vtrn.8          \r0, \r1
    vtrn.8          \r2, \r3
    vtrn.8          \r4, \r5
    vtrn.8          \r6, \r7
.endm

.macro TRANSPOSE4x4 r0 r1 r2 r3
    vtrn.16         \r0, \r2
    vtrn.16         \r1, \r3
    vtrn.8          \r0, \r1
    vtrn.8          \r2, \r3
.endm

.macro TRANSPOSE4x4_16  r0, r1, r2, r3
    vtrn.32     \r0, \r2            // r0 = [21 20 01 00], r2 = [23 22 03 02]
    vtrn.32     \r1, \r3            // r1 = [31 30 11 10], r3 = [33 32 13 12]
    vtrn.16     \r0, \r1            // r0 = [30 20 10 00], r1 = [31 21 11 01]
    vtrn.16     \r2, \r3            // r2 = [32 22 12 02], r3 = [33 23 13 03]
.endm

.macro TRANSPOSE4x4x2_16  rA0, rA1, rA2, rA3, rB0, rB1, rB2, rB3
	// r0 = [03 02 01 00]
	// r1 = [13 12 11 10]
	// r2 = [23 22 21 20]
	// r3 = [33 32 31 30]
    vtrn.32     \rA0, \rA2
    vtrn.32     \rA1, \rA3
    vtrn.32     \rB0, \rB2
    vtrn.32     \rB1, \rB3
    // r0 = [21 20 01 00]
    // r1 = [31 30 11 10]
    // r2 = [23 22 03 02]
    // r3 = [33 32 13 12]
    vtrn.16     \rA0, \rA1
    vtrn.16     \rA2, \rA3
   	vtrn.16     \rB0, \rB1
    vtrn.16     \rB2, \rB3
    // r0 = [30 20 10 00]
    // r1 = [31 21 11 01]
    // r2 = [32 22 12 02]
    // r3 = [33 23 13 03]

.endm

.align 8
ctr4:
    .word 83            // d0[0] = 83
    .word 36            // d0[1] = 36
ctr8:
    .word 75            // d1[0] = 75
    .word 89            // d1[1] = 89
    .word 18            // d2[0] = 18
    .word 50            // d2[1] = 50


	.globl  x265_dct_8x8_neon
	.type    x265_dct_8x8_neon,%function

x265_dct_8x8_neon:
	.fnstart
	vpush {q4-q7}

    adr r2, ctr4
    vld1.16 {d0-d2}, [r2]
    mov r2, r1

    // DCT-1D
    // top half
    vld1.16 {q12}, [r0]!
    vld1.16 {q13}, [r0]!
    vld1.16 {q14}, [r0]!
    vld1.16 {q15}, [r0]!

    TRANSPOSE4x4x2_16 d24, d26, d28, d30,  d25, d27, d29, d31

    // |--|
    // |24|
    // |26|
    // |28|
    // |30|
    // |25|
    // |27|
    // |29|
    // |31|
    // |--|

	vaddl.s16 q2, d24, d31
    vaddl.s16 q3, d26, d29
    vaddl.s16 q4, d28, d27
    vaddl.s16 q5, d30, d25


    tr4 q2, q3, q4, q5

    vqrshrn.s32 d20, q3, #2
    vqrshrn.s32 d16, q2, #2
    vqrshrn.s32 d17, q4, #2
    vqrshrn.s32 d21, q5, #2

    vsubl.s16 q2, d24, d31
    vsubl.s16 q3, d26, d29
    vsubl.s16 q4, d28, d27
    vsubl.s16 q5, d30, d25

    tr8 q2, q3, q4, q5

    vqrshrn.s32 d18, q12, #2
    vqrshrn.s32 d22, q13, #2
    vqrshrn.s32 d19, q14, #2
    vqrshrn.s32 d23, q15, #2
    vstm r1!, {d16-d23}
    // bottom half
    vld1.16 {q12}, [r0]!
    vld1.16 {q13}, [r0]!
    vld1.16 {q14}, [r0]!
    vld1.16 {q15}, [r0]!

    TRANSPOSE4x4x2_16 d24, d26, d28, d30,  d25, d27, d29, d31

    // |--|
    // |24|
    // |26|
    // |28|
    // |30|
    // |25|
    // |27|
    // |29|
    // |31|
    // |--|

    vaddl.s16 q4, d28, d27
    vaddl.s16 q5, d30, d25
    vaddl.s16 q2, d24, d31
    vaddl.s16 q3, d26, d29

    tr4 q2, q3, q4, q5

    vqrshrn.s32 d20, q3, #2
    vqrshrn.s32 d16, q2, #2
    vqrshrn.s32 d17, q4, #2
    vqrshrn.s32 d21, q5, #2

    vsubl.s16 q2, d24, d31
    vsubl.s16 q3, d26, d29
    vsubl.s16 q4, d28, d27
    vsubl.s16 q5, d30, d25

    tr8 q2, q3, q4, q5

    vqrshrn.s32 d18, q12, #2
    vqrshrn.s32 d22, q13, #2
    vqrshrn.s32 d19, q14, #2
    vqrshrn.s32 d23, q15, #2
    vstm r1, {d16-d23}
    mov r1, r2
    // DCT-2D
    // left half
    // to load every rows first 4 values we need to slide the pointer by 16, skipping other 8 values
    mov r0, #16
    vld1.16 {d24}, [r1], r0
    vld1.16 {d26}, [r1], r0
    vld1.16 {d28}, [r1], r0
    vld1.16 {d30}, [r1], r0
    vld1.16 {d25}, [r1], r0
    vld1.16 {d27}, [r1], r0
    vld1.16 {d29}, [r1], r0
    vld1.16 {d31}, [r1], r0
    mov r1, r2

    TRANSPOSE4x4x2_16 d24, d26, d28, d30,  d25, d27, d29, d31

    // |--|
    // |24|
    // |26|
    // |28|
    // |30|
    // |25|
    // |27|
    // |29|
    // |31|
    // |--|

    vaddl.s16 q4, d28, d27
    vaddl.s16 q5, d30, d25
    vaddl.s16 q2, d24, d31
    vaddl.s16 q3, d26, d29

    tr4 q2, q3, q4, q5

    vqrshrn.s32 d18, q3, #9
    vqrshrn.s32 d16, q2, #9
    vqrshrn.s32 d20, q4, #9
    vqrshrn.s32 d22, q5, #9

    vsubl.s16 q2, d24, d31
    vsubl.s16 q3, d26, d29
    vsubl.s16 q4, d28, d27
    vsubl.s16 q5, d30, d25

    tr8 q2, q3, q4, q5

    vqrshrn.s32 d17, q12, #9
    vqrshrn.s32 d19, q13, #9
    vqrshrn.s32 d21, q14, #9
    vqrshrn.s32 d23, q15, #9

	add r2, #8
    vst1.16 {d16}, [r1], r0
    vst1.16 {d17}, [r1], r0
    vst1.16 {d18}, [r1], r0
    vst1.16 {d19}, [r1], r0
    vst1.16 {d20}, [r1], r0
    vst1.16 {d21}, [r1], r0
    vst1.16 {d22}, [r1], r0
    vst1.16 {d23}, [r1], r0
	mov r1, r2

    // right half
    vld1.16 {d24}, [r1], r0
    vld1.16 {d26}, [r1], r0
    vld1.16 {d28}, [r1], r0
    vld1.16 {d30}, [r1], r0
    vld1.16 {d25}, [r1], r0
    vld1.16 {d27}, [r1], r0
    vld1.16 {d29}, [r1], r0
    vld1.16 {d31}, [r1], r0
    mov r1, r2

    TRANSPOSE4x4x2_16 d24, d26, d28, d30,  d25, d27, d29, d31

    // |--|
    // |24|
    // |26|
    // |28|
    // |30|
    // |25|
    // |27|
    // |29|
    // |31|
    // |--|

    vaddl.s16 q4, d28, d27
    vaddl.s16 q5, d30, d25
    vaddl.s16 q2, d24, d31
    vaddl.s16 q3, d26, d29

    tr4 q2, q3, q4, q5

    vqrshrn.s32 d18, q3, #9
    vqrshrn.s32 d16, q2, #9
    vqrshrn.s32 d20, q4, #9
    vqrshrn.s32 d22, q5, #9

    vsubl.s16 q2, d24, d31
    vsubl.s16 q3, d26, d29
    vsubl.s16 q4, d28, d27
    vsubl.s16 q5, d30, d25

    tr8 q2, q3, q4, q5

    vqrshrn.s32 d17, q12, #9
    vqrshrn.s32 d19, q13, #9
    vqrshrn.s32 d21, q14, #9
    vqrshrn.s32 d23, q15, #9

    vst1.16 {d16}, [r1], r0
    vst1.16 {d17}, [r1], r0
    vst1.16 {d18}, [r1], r0
    vst1.16 {d19}, [r1], r0
    vst1.16 {d20}, [r1], r0
    vst1.16 {d21}, [r1], r0
    vst1.16 {d22}, [r1], r0
    vst1.16 {d23}, [r1]

    vpop {q4-q7}
    bx lr
.fnend


.align 8
pw_tr16: .hword 90, 87, 80, 70,  57, 43, 25,  9     // q0 = [ 9 25 43 57 70 80 87 90]
         .hword 83, 36, 75, 89,  18, 50, 00, 00     // q1 = [ x  x 50 18 89 75 36 83]

ctr16:    	.word 90, 87        // d0
    		.word 80, 70        // d1
    		.word 57, 43        // d2
    		.word 25,  9        // d3


	.globl  x265_dct_16x16_neon
	.type    x265_dct_16x16_neon,%function

x265_dct_16x16_neon:
	.fnstart
  	 push {lr}

    // fill 3 of pipeline stall cycles (dependency link on SP)
    add r2, r2
    adr r3, pw_tr16
    mov r12, #16/4

    vpush {q4-q7}

    // TODO: 16x16 transpose buffer (may share with input buffer in future)
    sub sp, #16*16*2

    vld1.16 {d0-d3}, [r3]
    mov r3, sp
    mov lr, #4*16*2

    // DCT-1D
.loop1:
    // Row[0-3]
    vld1.16 {q8-q9}, [r0]!      // q8  = [07 06 05 04 03 02 01 00], q9  = [0F 0E 0D 0C 0B 0A 09 08]
    vld1.16 {q10-q11}, [r0]!    // q10 = [17 16 15 14 13 12 11 10], q11 = [1F 1E 1D 1C 1B 1A 19 18]
    vld1.16 {q12-q13}, [r0]!    // q12 = [27 26 25 24 23 22 21 20], q13 = [2F 2E 2D 2C 2B 2A 29 28]
    vld1.16 {q14-q15}, [r0]!    // q14 = [37 36 35 34 33 32 31 30], q15 = [3F 3E 3D 3C 3B 3A 39 38]

    // Register map
    // | 16 17 18 19 |
    // | 20 21 22 23 |
    // | 24 25 26 27 |
    // | 28 29 30 31 |

    // Transpose 16x4
    vtrn.32 q8, q12                     // q8  = [25 24 05 04 21 20 01 00], q12 = [27 26 07 06 23 22 03 02]
    vtrn.32 q10, q14                    // q10 = [35 34 15 14 31 30 11 10], q14 = [37 36 17 16 33 32 13 12]
    vtrn.32 q9, q13                     // q9  = [2D 2C 0D 0C 29 28 09 08], q13 = [2F 2E 0F 0E 2B 2A 0B 0A]
    vtrn.32 q11, q15                    // q11 = [3D 3C 1D 1C 39 38 19 18], q15 = [3F 3E 1F 1E 3B 3A 1B 1A]

    vtrn.16 q8, q10                     // q8  = [34 24 14 04 30 20 10 00], q10 = [35 25 15 05 31 21 11 01]
    vtrn.16 q12, q14                    // q12 = [36 26 16 06 32 22 12 02], q14 = [37 27 17 07 33 23 13 03]
    vtrn.16 q13, q15                    // q13 = [3E 2E 1E 0E 3A 2A 1A 0A], q15 = [3F 2F 1F 0F 3B 2B 1B 0B]
    vtrn.16 q9, q11                     // q9  = [3C 2C 1C 0C 38 28 18 08], q11 = [3D 2D 1D 0D 39 29 19 09]

    vswp d26, d27                       // q13 = [3A 2A 1A 0A 3E 2E 1E 0E]
    vswp d30, d31                       // q15 = [3B 2B 1B 0B 3F 2F 1F 0F]
    vswp d18, d19                       // q9  = [38 28 18 08 3C 2C 1C 0C]
    vswp d22, d23                       // q11 = [39 29 19 09 3D 2D 1D 0D]

    // E[0-7] - 10 bits
    vadd.s16 q4, q8, q15                // q4  = [E4 E0]
    vadd.s16 q5, q10, q13               // q5  = [E5 E1]
    vadd.s16 q6, q12, q11               // q6  = [E6 E2]
    vadd.s16 q7, q14, q9                // q7  = [E7 E3]

    // O[0-7] - 10 bits
    vsub.s16 q8, q8, q15                // q8  = [O4 O0]
    vsub.s16 q9, q14, q9                // q9  = [O7 O3]
    vsub.s16 q10, q10, q13              // q10 = [O5 O1]
    vsub.s16 q11, q12, q11              // q11 = [O6 O2]

    // reorder Ex for EE/EO
    vswp d9, d14                        // q4  = [E3 E0], q7  = [E7 E4]
    vswp d11, d12                       // q5  = [E2 E1], q6  = [E6 E5]
    vswp d14, d15                       // q7  = [E4 E7]
    vswp d12, d13                       // q6  = [E5 E6]

    // EE[0-3] - 11 bits
    vadd.s16 q2, q4, q7                 // q2  = [EE3 EE0]
    vadd.s16 q3, q5, q6                 // q3  = [EE2 EE1]

    // EO[0-3] - 11 bits
    vsub.s16 q4, q4, q7                 // q4  = [EO3 EO0]
    vsub.s16 q5, q5, q6                 // q5  = [EO2 EO1]

    // EEx[0-1] - 12 bits
    vadd.s16 d12, d4, d5                // q6  = [EEE1 EEE0]
    vadd.s16 d13, d6, d7
    vsub.s16 d14, d4, d5                // q7  = [EEO1 EEO0]
    vsub.s16 d15, d6, d7

    // NEON Register map
    // Ex -> [q4, q5, q6, q7], Ox -> [q8, q9, q10, q11], Const -> [q0, q1], Free -> [q2, q3, q12, q13, q14, q15]

    // ODD[4,12]
    vmull.s16 q14, d14, d2[0]           // q14 = EEO0 * 83
    vmull.s16 q15, d14, d2[1]           // q15 = EEO0 * 36
    vmlal.s16 q14, d15, d2[1]           // q14+= EEO1 * 36
    vmlsl.s16 q15, d15, d2[0]           // q15+= EEO1 *-83

    vadd.s16 d4, d12, d13               // d4  = (EEE0 + EEE1)
    vsub.s16 d12, d13                   // d12 = (EEE0 - EEE1)

    // Row
    vmull.s16 q12, d16, d0[0]           // q12 =  O0 * 90
    vmull.s16 q13, d8, d2[3]            // q13 = EO0 * 89
    vqrshrn.s32 d14, q14, #3
    vqrshrn.s32 d15, q15, #3             // q7  = [12 4]     -> [12  4]
    vmull.s16 q14, d16, d0[1]           // q14 =  O0 * 87
    vmull.s16 q15, d16, d0[2]           // q15 =  O0 * 80
    vshll.s16 q2, d4, #6                // q2  = (EEE0 + EEE1) * 64 -> [ 0]
    vshll.s16 q6, d12, #6               // q6  = (EEE0 - EEE1) * 64 -> [ 8]

    vmlal.s16 q12, d20, d0[1]           // q12+=  O1 * 87
    vmlal.s16 q13, d10, d2[2]           // q13+= EO1 * 75
    vmlal.s16 q14, d20, d1[0]           // q14+=  O1 * 57
    vmlal.s16 q15, d20, d1[3]           // q15+=  O1 *  9
    vqrshrn.s32 d4, q2, #3               // q2  = [- 0]
    vqrshrn.s32 d12, q6, #3              // q6  = [- 8]

    vmlal.s16 q12, d22, d0[2]           // q12+=  O2 * 80
    vmlal.s16 q13, d11, d3[1]           // q13+= EO2 * 50
    vmlal.s16 q14, d22, d1[3]           // q14+=  O2 *  9
    vmlsl.s16 q15, d22, d0[3]           // q15+=  O2 *-70

    vmlal.s16 q12, d18, d0[3]           // q12+=  O3 * 70
    vmlal.s16 q13, d9,  d3[0]           // q13+= EO3 * 18   -> [ 2]
    vmlsl.s16 q14, d18, d1[1]           // q14+=  O3 *-43
    vmlsl.s16 q15, d18, d0[1]           // q15+=  O3 *-87

    vmlal.s16 q12, d17, d1[0]           // q12+=  O4 * 57
    vmlsl.s16 q14, d17, d0[2]           // q14+=  O4 *-80
    vmlsl.s16 q15, d17, d1[2]           // q15+=  O4 *-25
    vqrshrn.s32 d6, q13, #3              // q3  = [- 2]
    vmull.s16 q13, d8,  d2[2]           // q13 = EO0 * 75

    vmlal.s16 q12, d21, d1[1]           // q12+=  O5 * 43
    vmlsl.s16 q13, d10, d3[0]           // q13+= EO1 *-18
    vmlsl.s16 q14, d21, d0[0]           // q14+=  O5 *-90
    vmlal.s16 q15, d21, d1[0]           // q15+=  O5 * 57

    vmlal.s16 q12, d23, d1[2]           // q12+=  O6 * 25
    vmlsl.s16 q13, d11, d2[3]           // q13+= EO2 *-89
    vmlsl.s16 q14, d23, d0[3]           // q14+=  O6 *-70
    vmlal.s16 q15, d23, d0[0]           // q15+=  O6 * 90

    vmlal.s16 q12, d19, d1[3]           // q12+=  O7 *  9   -> [ 1]
    vmlsl.s16 q13, d9,  d3[1]           // q13+= EO3 *-50   -> [ 6]
    vmlsl.s16 q14, d19, d1[2]           // q14+=  O7 *-25   -> [ 3]
    vmlal.s16 q15, d19, d1[1]           // q15+=  O7 * 43   -> [ 5]
    vqrshrn.s32 d5, q12, #3              // q2  = [1 0]

    vmull.s16 q12, d16, d0[3]           // q12 =  O0 * 70
    vqrshrn.s32 d7, q14, #3              // q3  = [3 2]
    vmull.s16 q14, d16, d1[0]           // q14 =  O0 * 57

    vmlsl.s16 q12, d20, d1[1]           // q12+=  O1 *-43
    vmlsl.s16 q14, d20, d0[2]           // q14+=  O1 *-80

    vmlsl.s16 q12, d22, d0[1]           // q12+=  O2 *-87
    vmlsl.s16 q14, d22, d1[2]           // q14+=  O2 *-25

    vmlal.s16 q12, d18, d1[3]           // q12+=  O3 *  9
    vmlal.s16 q14, d18, d0[0]           // q14+=  O3 * 90

    // Row[0-3]
    vst4.16 {d4-d7}, [r3], lr

    vqrshrn.s32 d5, q15, #3              // q2  = [5 -]
    vqrshrn.s32 d6, q13, #3              // q3  = [- 6]
    vmull.s16 q13, d8,  d3[1]           // q13 = EO0 * 50
    vmlal.s16 q12, d17, d0[0]           // q12+=  O4 * 90
    vmlsl.s16 q14, d17, d1[3]           // q14+=  O4 *-9
    vmull.s16 q15, d16, d1[1]           // q15 =  O0 * 43

    vmlsl.s16 q13, d10, d2[3]           // q13+= EO1 *-89
    vmlal.s16 q12, d21, d1[2]           // q12+=  O5 * 25
    vmlsl.s16 q14, d21, d0[1]           // q14+=  O5 *-87
    vmlsl.s16 q15, d20, d0[0]           // q15+=  O1 *-90

    vmlal.s16 q13, d11, d3[0]           // q13+= EO2 * 18
    vmlsl.s16 q12, d23, d0[2]           // q12+=  O6 *-80
    vmlal.s16 q14, d23, d1[1]           // q14+=  O6 * 43
    vmlal.s16 q15, d22, d1[0]           // q15+=  O2 * 57

    vmlal.s16 q13, d9,  d2[2]           // q13+= EO3 * 75   -> [10]
    vmlsl.s16 q12, d19, d1[0]           // q12+=  O7 *-57   -> [ 7]
    vmlal.s16 q14, d19, d0[3]           // q14+=  O7 * 70   -> [ 9]
    vmlal.s16 q15, d18, d1[2]           // q15+=  O3 * 25
    vmlsl.s16 q15, d17, d0[1]           // q15+=  O4 *-87
    vmlal.s16 q15, d21, d0[3]           // q15+=  O5 * 70
    vmlal.s16 q15, d23, d1[3]           // q15+=  O6 *  9
    vmlsl.s16 q15, d19, d0[2]           // q15+=  O7 *-80   -> [11]
    vmov d4, d14                        // q2  = [5 4]
    vqrshrn.s32 d14, q13, #3             // q7  = [12 10]
    vmull.s16 q13, d8,  d3[0]           // q13 = EO0 * 18
    vqrshrn.s32 d7, q12, #3              // q3  = [7 6]
    vmull.s16 q12, d16, d1[2]           // q12 =  O0 * 25
    vmlsl.s16 q13, d9,  d2[3]           // q13 = EO3 *-89
    vmull.s16 q4, d16, d1[3]            // q4  =  O0 *  9
    vmlsl.s16 q12, d20, d0[3]           // q12+=  O1 *-70
    vmlsl.s16 q13, d10, d3[1]           // q13 = EO1 *-50
    vmlsl.s16 q4, d20, d1[2]            // q4 +=  O1 *-25
    vmlal.s16 q12, d22, d0[0]           // q12+=  O2 * 90
    vmlal.s16 q13, d11, d2[2]           // q13 = EO2 * 75   -> [14]
    vmlal.s16 q4, d22, d1[1]            // q4 +=  O2 * 43
    vmlsl.s16 q12, d18, d0[2]           // q12+=  O3 *-80
    vmlsl.s16 q4, d18, d1[0]            // q4 +=  O3 *-57
    vmlal.s16 q12, d17, d1[1]           // q12+=  O4 * 43
    vqrshrn.s32 d13, q14, #3             // q6  = [9 8]
    vmov d28, d15                       // q14 = [- 12]
    vqrshrn.s32 d15, q15, #3             // q7  = [11 10]
    vqrshrn.s32 d30, q13, #3             // q15 = [- 14]
    vmlal.s16 q4, d17, d0[3]            // q4 +=  O4 * 70
    vmlal.s16 q12, d21, d1[3]           // q12+=  O5 *  9
    vmlsl.s16 q4, d21, d0[2]            // q4 +=  O5 *-80
    vmlsl.s16 q12, d23, d1[0]           // q12+=  O6 *-57
    vmlal.s16 q4, d23, d0[1]            // q4 +=  O6 * 87
    vmlal.s16 q12, d19, d0[1]           // q12+=  O7 * 87   -> [13]
    vmlsl.s16 q4, d19, d0[0]            // q4 +=  O7 *-90   -> [15]

    // Row[4-7]
    vst4.16 {d4-d7}, [r3], lr
    vqrshrn.s32 d29, q12, #3             // q14 = [13 12]
    vqrshrn.s32 d31, q4, #3              // q15 = [15 14]

    // Row[8-11]
    vst4.16 {d12-d15}, [r3], lr

    // Row[12-15]
    vst4.16 {d28-d31}, [r3]!


    // loop into next process group
    sub r3, #3*4*16*2
    subs r12, #1
    bgt .loop1


    // DCT-2D
    // r[0,2,3,12,lr], q[2-15] are free here
    mov r2, sp                          // r3 -> internal temporary buffer
    mov r3, #16*2*2
    mov r12, #16/4                      // Process 4 rows every loop

.loop2:
    vldm r2, {q8-q15}

    // d16 = [30 20 10 00]
    // d17 = [31 21 11 01]
    // q18 = [32 22 12 02]
    // d19 = [33 23 13 03]
    // d20 = [34 24 14 04]
    // d21 = [35 25 15 05]
    // q22 = [36 26 16 06]
    // d23 = [37 27 17 07]
    // d24 = [38 28 18 08]
    // d25 = [39 29 19 09]
    // q26 = [3A 2A 1A 0A]
    // d27 = [3B 2B 1B 0B]
    // d28 = [3C 2C 1C 0C]
    // d29 = [3D 2D 1D 0D]
    // q30 = [3E 2E 1E 0E]
    // d31 = [3F 2F 1F 0F]

    // NOTE: the ARM haven't enough SIMD registers, so I have to process Even & Odd part series.

    // Process Even

    // E
    vaddl.s16 q2,  d16, d31             // q2  = [E30 E20 E10 E00]
    vaddl.s16 q3,  d17, d30             // q3  = [E31 E21 E11 E01]
    vaddl.s16 q4,  d18, d29             // q4  = [E32 E22 E12 E02]
    vaddl.s16 q5,  d19, d28             // q5  = [E33 E23 E13 E03]
    vaddl.s16 q9,  d23, d24             // q9  = [E37 E27 E17 E07]
    vaddl.s16 q8,  d22, d25             // q8  = [E36 E26 E16 E06]
    vaddl.s16 q7,  d21, d26             // q7  = [E35 E25 E15 E05]
    vaddl.s16 q6,  d20, d27             // q6  = [E34 E24 E14 E04]

    // EE & EO
    vadd.s32 q13, q2, q9                // q13 = [EE30 EE20 EE10 EE00]
    vsub.s32 q9, q2, q9                 // q9  = [EO30 EO20 EO10 EO00]

    vadd.s32 q2, q5, q6                 // q2  = [EE33 EE23 EE13 EE03]
    vsub.s32 q12, q5, q6                // q12 = [EO33 EO23 EO13 EO03]

    vadd.s32 q14, q3, q8                // q14 = [EE31 EE21 EE11 EE01]
    vsub.s32 q10, q3, q8                // q10 = [EO31 EO21 EO11 EO01]

    vadd.s32 q15, q4, q7                // q15 = [EE32 EE22 EE12 EE02]
    vsub.s32 q11, q4, q7                // q11 = [EO32 EO22 EO12 EO02]

    // Free=[3,4,5,6,7,8]

    // EEE & EEO
    vadd.s32 q5, q13, q2                // q5  = [EEE30 EEE20 EEE10 EEE00]
    vadd.s32 q6, q14, q15               // q6  = [EEE31 EEE21 EEE11 EEE01]
    vsub.s32 q7, q13, q2                // q7  = [EEO30 EEO20 EEO10 EEO00]
    vsub.s32 q8, q14, q15               // q8  = [EEO31 EEO21 EEO11 EEO01]

    // Convert Const for Dct EE to 32-bits
    adr r0, ctr4
    vld1.32 {d0-d3}, [r0, :64]

    // Register Map (Qx)
    // Free=[2,3,4,13,14,15], Const=[0,1], EEEx=[5,6,7,8], EO=[9,10,11,12]

    vadd.s32 q15, q5, q6                // q15 = EEE0 + EEE1    ->  0
    vmul.s32 q2, q9, d1[1]              // q2  = EO0 * 89       ->  2
    vmul.s32 q3, q7, d0[0]              // q3  = EEO0 * 83      ->  4
    vmul.s32 q4, q9, d1[0]              // q4  = EO0 * 75       ->  6
    vmul.s32 q14, q9, d2[1]             // q14 = EO0 * 50       -> 10

    vshl.s32 q15, #6                    // q15                  -> [ 0]'
    vmla.s32 q2, q10, d1[0]             // q2 += EO1 * 75
    vmla.s32 q3, q8, d0[1]              // q3 += EEO1 * 36      -> [ 4]'
    vmls.s32 q4, q10, d2[0]             // q4 += EO1 *-18
    vmls.s32 q14, q10, d1[1]            // q14+= EO1 *-89
    vmul.s32 q13, q7, d0[1]             // q13 = EEO0 * 36      -> 12

    vqrshrn.s32 d30, q15, #10            // d30                  -> [ 0]
    vqrshrn.s32 d31, q3, #10             // d31                  -> [ 4]
    vmls.s32 q4, q11, d1[1]             // q4 += EO2 *-89
    vsub.s32 q3, q5, q6                 // q3  = EEE0 - EEE1    ->  8
    vmla.s32 q2, q11, d2[1]             // q2 += EO2 * 50
    vmla.s32 q14, q11, d2[0]            // q14+= EO2 * 18
    vmls.s32 q13, q8, d0[0]             // q13+= EEO1 *-83      -> [12]'
    vst1.16 {d30}, [r1]!             // Stroe [ 0]

    vshl.s32 q3, #6                     // q3                   -> [ 8]'
    vmls.s32 q4, q12, d2[1]             // q4 += EO3 *-50       -> [ 6]'
    vmla.s32 q2, q12, d2[0]             // q2 += EO3 * 18       -> [ 2]'
    vqrshrn.s32 d26, q13, #10            // d26                  -> [12]
    vmla.s32 q14, q12, d1[0]            // q14+= EO3 * 75       -> [10]'

    vqrshrn.s32 d30, q3, #10             // d30                  -> [ 8]
    vmul.s32 q3, q9, d2[0]              // q3  = EO0 * 18       -> 14
    vqrshrn.s32 d4, q2, #10              // d4                   -> [ 2]
    vmls.s32 q3, q10, d2[1]             // q3 += EO1 *-50
    vqrshrn.s32 d5, q4, #10              // d30                  -> [ 6]
    vmla.s32 q3, q11, d1[0]             // q3 += EO2 * 75
    vqrshrn.s32 d27, q14, #10            // d27                  -> [10]
    vmls.s32 q3, q12, d1[1]             // q3 += EO3 *-89       -> [14]'

    vst1.16 {d4 }, [r1]!             // Stroe [ 2]
    vst1.16 {d31}, [r1]!             // Stroe [ 4]
    vst1.16 {d5 }, [r1]!             // Stroe [ 6]
    vst1.16 {d30}, [r1]!             // Stroe [ 8]
    vqrshrn.s32 d30, q3, #10             // d30                  -> [14]
    vst1.16 {d27}, [r1]!             // Stroe [10]
    vst1.16 {d26}, [r1]!             // Stroe [12]
    vst1.16 {d30}, [r1]!             // Stroe [14]

    // Process Odd
    sub r1, #(15*16)*2
    vldm r2!, {q8-q15}

    // d8  = [30 20 10 00]
    // d9  = [31 21 11 01]
    // q10 = [32 22 12 02]
    // d11 = [33 23 13 03]
    // d12 = [34 24 14 04]
    // d13 = [35 25 15 05]
    // q14 = [36 26 16 06]
    // d15 = [37 27 17 07]
    // d16 = [38 28 18 08]
    // d17 = [39 29 19 09]
    // q18 = [3A 2A 1A 0A]
    // d19 = [3B 2B 1B 0B]
    // d20 = [3C 2C 1C 0C]
    // d21 = [3D 2D 1D 0D]
    // q22 = [3E 2E 1E 0E]
    // d23 = [3F 2F 1F 0F]

    // O
    vsubl.s16 q2,  d16, d31             // q2  = [O30 O20 O10 O00]
    vsubl.s16 q3,  d17, d30             // q3  = [O31 O21 O11 O01]
    vsubl.s16 q4,  d18, d29             // q4  = [O32 O22 O12 O02]
    vsubl.s16 q5,  d19, d28             // q5  = [O33 O23 O13 O03]
    vsubl.s16 q9,  d23, d24             // q9  = [O37 O27 O17 O07]
    vsubl.s16 q8,  d22, d25             // q8  = [O36 O26 O16 O06]
    vsubl.s16 q7,  d21, d26             // q7  = [O35 O25 O15 O05]
    vsubl.s16 q6,  d20, d27             // q6  = [O34 O24 O14 O04]

    // Load DCT Ox Constant
    adr r0, ctr16
    vld1.32 {d0-d3}, [r0]

    // Register Map (Qx)
    // Free=[10,11,12,13,14,15], Const=[0,1], O=[2,3,4,5,6,7,8,9]

    vmul.s32 q10, q2, d0[0]             // q10 = O0 * 90        ->  1
    vmul.s32 q11, q2, d0[1]             // q11 = O0 * 87        ->  3
    vmul.s32 q12, q2, d1[0]             // q12 = O0 * 80        ->  5
    vmul.s32 q13, q2, d1[1]             // q13 = O0 * 70        ->  7
    vmul.s32 q14, q2, d2[0]             // q14 = O0 * 57        ->  9
    vmul.s32 q15, q2, d2[1]             // q15 = O0 * 43        -> 11

    vmla.s32 q10, q3, d0[1]             // q10+= O1 * 87
    vmla.s32 q11, q3, d2[0]             // q11+= O1 * 57
    vmla.s32 q12, q3, d3[1]             // q12+= O1 *  9
    vmls.s32 q13, q3, d2[1]             // q13+= O1 *-43
    vmls.s32 q14, q3, d1[0]             // q14+= O1 *-80
    vmls.s32 q15, q3, d0[0]             // q15+= O1 *-90

    vmla.s32 q10, q4, d1[0]             // q10+= O2 * 80
    vmla.s32 q11, q4, d3[1]             // q11+= O2 *  9
    vmls.s32 q12, q4, d1[1]             // q12+= O2 *-70
    vmls.s32 q13, q4, d0[1]             // q13+= O2 *-87
    vmls.s32 q14, q4, d3[0]             // q14+= O2 *-25
    vmla.s32 q15, q4, d2[0]             // q15+= O2 * 57

    vmla.s32 q10, q5, d1[1]             // q10+= O3 * 70
    vmls.s32 q11, q5, d2[1]             // q11+= O3 *-43
    vmls.s32 q12, q5, d0[1]             // q12+= O3 *-87
    vmla.s32 q13, q5, d3[1]             // q13+= O3 *  9
    vmla.s32 q14, q5, d0[0]             // q14+= O3 * 90
    vmla.s32 q15, q5, d3[0]             // q15+= O3 * 25

    vmla.s32 q10, q6, d2[0]             // q10+= O4 * 57
    vmls.s32 q11, q6, d1[0]             // q11+= O4 *-80
    vmls.s32 q12, q6, d3[0]             // q12+= O4 *-25
    vmla.s32 q13, q6, d0[0]             // q13+= O4 * 90
    vmls.s32 q14, q6, d3[1]             // q14+= O4 *-9
    vmls.s32 q15, q6, d0[1]             // q15+= O4 *-87

    vmla.s32 q10, q7, d2[1]             // q10+= O5 * 43
    vmls.s32 q11, q7, d0[0]             // q11+= O5 *-90
    vmla.s32 q12, q7, d2[0]             // q12+= O5 * 57
    vmla.s32 q13, q7, d3[0]             // q13+= O5 * 25
    vmls.s32 q14, q7, d0[1]             // q14+= O5 *-87
    vmla.s32 q15, q7, d1[1]             // q15+= O5 * 70

    vmla.s32 q10, q8, d3[0]             // q10+= O6 * 25
    vmls.s32 q11, q8, d1[1]             // q11+= O6 *-70
    vmla.s32 q12, q8, d0[0]             // q12+= O6 * 90
    vmls.s32 q13, q8, d1[0]             // q13+= O6 *-80
    vmla.s32 q14, q8, d2[1]             // q14+= O6 * 43
    vmla.s32 q15, q8, d3[1]             // q15+= O6 *  9

    vmla.s32 q10, q9, d3[1]             // q10+= O7 *  9        -> [ 1]'
    vmls.s32 q11, q9, d3[0]             // q11+= O7 *-25        -> [ 3]'
    vmla.s32 q12, q9, d2[1]             // q12+= O7 * 43        -> [ 5]'
    vqrshrn.s32 d20, q10, #10            // d20                  -> [ 1]
    vmls.s32 q13, q9, d2[0]             // q13+= O7 *-57        -> [ 7]'
    vqrshrn.s32 d21, q11, #10            // d21                  -> [ 3]

    vmul.s32 q11, q2, d3[0]             // q11 = O0 * 25        -> 13
    vmul.s32 q2,  q2, d3[1]             // q2  = O0 *  9        -> 15

    vst1.16 {d20}, [r1]!             // Stroe [ 1]
    vst1.16 {d21}, [r1]!             // Stroe [ 3]

    vmls.s32 q11, q3, d1[1]             // q11+= O1 *-70
    vmls.s32 q2,  q3, d3[0]             // q2 += O1 *-25

    vmla.s32 q14, q9, d1[1]             // q14+= O7 * 70        -> [ 9]'
    vmls.s32 q15, q9, d1[0]             // q15+= O7 *-80        -> [11]'

    vqrshrn.s32 d24, q12, #10            // d24                  -> [ 5]

    vqrshrn.s32 d25, q13, #10            // d25                  -> [ 7]
    vqrshrn.s32 d28, q14, #10            // d28                  -> [ 9]
    vqrshrn.s32 d29, q15, #10            // d29                  -> [11]

    vst1.16 {d24}, [r1]!             // Stroe [ 5]
    vst1.16 {d25}, [r1]!             // Stroe [ 7]
    vst1.16 {d28}, [r1]!             // Stroe [ 9]
    vst1.16 {d29}, [r1]!             // Stroe [11]

    vmla.s32 q11, q4, d0[0]             // q11+= O2 * 90
    vmla.s32 q2,  q4, d2[1]             // q2 += O2 * 43

    vmls.s32 q11, q5, d1[0]             // q11+= O3 *-80
    vmls.s32 q2,  q5, d2[0]             // q2 += O3 *-57

    vmla.s32 q11, q6, d2[1]             // q11+= O4 * 43
    vmla.s32 q2,  q6, d1[1]             // q2 += O4 * 70

    vmla.s32 q11, q7, d3[1]             // q11+= O5 *  9
    vmls.s32 q2,  q7, d1[0]             // q2 += O5 *-80

    vmls.s32 q11, q8, d2[0]             // q11+= O6 *-57
    vmla.s32 q2,  q8, d0[1]             // q2 += O6 * 87

    vmla.s32 q11, q9, d0[1]             // q11+= O7 * 87        -> [13]'
    vmls.s32 q2,  q9, d0[0]             // q2 += O7 *-90        -> [15]'

    vqrshrn.s32 d6, q11, #10             // d6                   -> [13]
    vqrshrn.s32 d7, q2, #10              // d7                   -> [15]
    vst1.16 {d6}, [r1]!              // Stroe [13]
    vst1.16 {d7}, [r1]!              // Stroe [15]

    sub r1, #(17*16-4)*2
    subs r12, #1
    bgt .loop2

    add sp, #16*16*2
    vpop {q4-q7}
    pop {pc}
    .fnend


    .align 8
c1:	 	 .word 90, 87, 80, 70,  57, 43, 25,  9
         .word 83, 36, 75, 89,  18, 50, 00, 00

c2:		 .word 90, 88, 85, 82,  78, 73, 67, 61
         .word 54, 46, 38, 31,  22, 13,  4, 00

	.globl   dct_32x32_neon
	.type    dct_32x32_neon,%function

dct_32x32_neon:
	.fnstart
	push {r4, r5, r6, r7, lr}
	vpush	{q4-q7}

	mov r2, #32/4			// rows counter
	sub sp, #32*32*2		// make stack matrix buffer between first and second stage
    mov r12, sp				// iteration pointer
    mov r3, sp				// stack matrix buffer reference pointer
    mov r7, sp				// stack matrix buffer reference foir second pass
    sub sp, #30*16			// make a buffer for temp vars of first two rows
    mov r5, sp 				// stack temp buffer iteration pointer
    mov r4, sp				// stack temp buffer reference pointer

.loop1_32x32:
	// restore temp vars pointer
	mov r5, r4

	// load first two rows from source
    vld1.16 {q0, q1}, [r0]!
    vld1.16 {q2, q3}, [r0]!
    vld1.16 {q4, q5}, [r0]!
    vld1.16 {q6, q7}, [r0]!


    // transpose the input data
    vtrn.16 q0, q4
    vtrn.16 q1, q5
    vtrn.16 q2, q6
    vtrn.16 q3, q7

    vrev64.32   q4, q4
    vrev64.32   q5, q5
    vrev64.32   q6, q6
    vrev64.32   q7, q7

    vswp    d8, d15
    vswp    d9, d14
    vswp    d10, d13
    vswp    d11, d12

    // 0
    vsubl.s16	q8, d0, d8		//	q8	=> [O0 O2]
    vsubl.s16   q9, d1, d9      //  q9  => [O4 O6]
    vsubl.s16	q10, d2, d10	//	q10	=> [O8 O10]
    vsubl.s16   q11, d3, d11    //  q11 => [O12 O14]
    vsubl.s16	q12, d12, d4	//	q12 => [O15 O13]
    vsubl.s16   q13, d13, d5    //  q13 => [O11 O9]
    vsubl.s16	q14, d14, d6	//	q14 => [O7 O5]
    vsubl.s16   q15, d15, d7    //  q15 => [O3 O1]

	// store to temp buffer
	vstmia r5!, {q8-q15}

	// E
    vaddl.s16    q8, d0, d8      //  q8 => [E0 E2]
    vaddl.s16    q9, d1, d9      //  q9 => [E4 E6]
    vaddl.s16    q10, d2, d10    //  q10 => [E8 E10]
    vaddl.s16    q11, d3, d11    //  q11 => [E12 E14]
    vaddl.s16    q12, d4, d12    //  q12 => [E15 E13]
    vaddl.s16    q13, d5, d13    //  q13 => [E11 E9]
    vaddl.s16    q14, d6, d14    //  q14 => [E7 E5]
    vaddl.s16    q15, d7, d15    //  q15 => [E3 E1]

   	// E0
	vsub.s32	q4, q8, q12		//	q4	=> [E00 E02]
	vsub.s32	q5, q9, q13		//	q5	=> [E04 E06]
	vsub.s32	q6, q14, q10	//	q6 	=> [E07 E05]
	vsub.s32	q7, q15, q11	//	q7 	=> [E03 E01]

 	// EE
    vadd.s32    q0, q8, q12	    //  q0  => [EE0 EE2]
    vadd.s32    q1, q9, q13 	//  q1  => [EE4 EE6]
    vadd.s32    q2, q14, q10    //  q2  => [EE7 EE5]
    vadd.s32    q3, q15, q11    //  q3  => [EE3 EE1]

	// store to temp buffer
    vstmia r5!, {q4-q7}

	// EEE
	vadd.s32	q8, q0, q2		//	q8 	=> [EEE0 EEE2]
	vadd.s32	q9, q3, q1		//	q9	=> [EEE3 EEE1]

	// EEO
	vsub.s32	q10, q0, q2		//	q10 => [EEO0 EEO2]
	vsub.s32	q11, q3, q1		//	q11	=> [EEO3 EEO1]


	// EEEE
	vadd.s32	d24, d16, d18	//	q12	=> [EEEE0 - ]
	vadd.s32	d25, d19, d17	//	q12	=> [EEEE0 EEEE1]

	// EEEO
	vsub.s32	d26, d16, d18	//	q13	=> [EEEO0 - ]
	vsub.s32	d27, d19, d17	//	q13	=> [EEEO0 EEEO1]

	// store EE0, EEEE, EEEO to temp buffer
    vstmia r5!, {q10-q13}

	// load SECOND two rows
    vld1.16 {q0, q1}, [r0]!
    vld1.16 {q2, q3}, [r0]!
    vld1.16 {q4, q5}, [r0]!
    vld1.16 {q6, q7}, [r0]!


    // transpose the input data
    vtrn.16 q0, q4
    vtrn.16 q1, q5
    vtrn.16 q2, q6
    vtrn.16 q3, q7

    vrev64.32   q4, q4
    vrev64.32   q5, q5
    vrev64.32   q6, q6
    vrev64.32   q7, q7

    vswp    d8, d15
    vswp    d9, d14
    vswp    d10, d13
    vswp    d11, d12

    // 0
    vsubl.s16	q8, d0, d8		//	q8	=> [O0 O2]
    vsubl.s16   q9, d1, d9      //  q9  => [O4 O6]
    vsubl.s16	q10, d2, d10	//	q10	=> [O8 O10]
    vsubl.s16   q11, d3, d11    //  q11 => [O12 O14]
    vsubl.s16	q12, d12, d4	//	q12 => [O15 O13]
    vsubl.s16   q13, d13, d5    //  q13 => [O11 O9]
    vsubl.s16	q14, d14, d6	//	q14 => [O7 O5]
    vsubl.s16   q15, d15, d7	//  q15 => [O3 O1]

	// store to temp vars buffer
	vstmia r5!, {q8-q15}

	// E
    vaddl.s16    q8, d0, d8      //  q8 => [E0 E2]
    vaddl.s16    q9, d1, d9      //  q9 => [E4 E6]
    vaddl.s16    q10, d2, d10    //  q10 => [E8 E10]
    vaddl.s16    q11, d3, d11    //  q11 => [E12 E14]
    vaddl.s16    q12, d4, d12    //  q12 => [E15 E13]
    vaddl.s16    q13, d5, d13    //  q13 => [E11 E9]
    vaddl.s16    q14, d6, d14    //  q14 => [E7 E5]
    vaddl.s16    q15, d7, d15    //  q15 => [E3 E1]

   	// E0
	vsub.s32	q4, q8, q12		//	q4	=> [E00 E02]
	vsub.s32	q5, q9, q13		//	q5	=> [E04 E06]
	vsub.s32	q6, q14, q10	//	q6 	=> [E07 E05]
	vsub.s32	q7, q15, q11	//	q7 	=> [E03 E01]

 	// EE
    vadd.s32    q0, q8, q12	    //  q0  => [EE0 EE2]
    vadd.s32    q1, q9, q13 	//  q1  => [EE4 EE6]
    vadd.s32    q2, q14, q10    //  q2  => [EE7 EE5]
    vadd.s32    q3, q15, q11    //  q3  => [EE3 EE1]

	// store to temp vars buffer
    vstmia r5!, {q4-q7}

	// EEE
	vadd.s32	q8, q0, q2		//	q8 	=> [EEE0 EEE2]
	vadd.s32	q9, q3, q1		//	q9	=> [EEE3 EEE1]

	// EEO
	vsub.s32	q10, q0, q2		//	q10 => [EEO0 EEO2]
	vsub.s32	q11, q3, q1		//	q11	=> [EEO3 EEO1]


	// EEEE
	vadd.s32	d24, d16, d18	//	q12	=> [EEEE0 - ]
	vadd.s32	d25, d19, d17	//	q12	=> [EEEE0 EEEE1]

	// EEEO
	vsub.s32	d26, d16, d18	//	q13	=> [EEEO0 - ]
	vsub.s32	d27, d19, d17	//	q13	=> [EEEO0 EEEO1]

	// store EE0 to temp vars buffer
    vstmia r5!, {q10-q11}

	// retrive EEEE and EEEO from temp buffer(first two rows)
	add r5, r4, #14*16			// set offset to EEEE and EEEO
	vldmia r5, {q14-q15}		// q14 => [EEEE0 EEEE1](0,1) q15 => [EEEO0 EEEO1](0,1)

	//  q14 => [EEEE0 EEEE1](0,1)
	//	q12	=> [EEEE0 EEEE1](2,3)
	//  q15 => [EEEO0 EEEO1](0,1)
	//	q13	=> [EEEO0 EEEO1](2,3)
	vswp d29, d24
	vswp d31, d26
	//  q14 => [EEEE0]
	//	q12	=> [EEEE1]
	//  q15 => [EEEO0]
	//	q13	=> [EEEO1]


	// load coeffs
	// q0 => [90, 87, 80, 70]
	// q1 => [57, 43, 25,  9]
	// q2 => [83, 36, 75, 89]
	// q3 => [18, 50, 00, 00]
	adr	lr, c1
	vld1.32 {d0-d3}, [lr]!
	vld1.32 {d4-d7}, [lr]!

	// calc. 0, 8, 16, 24
	// free: q4 - q12
	mov lr, #32*2*8
	mov r12, r3

	vadd.s32	q4, q14, q12		// dst[0]	= (EEEE0+EEEE1)
	vmul.s32	q5, q15, d4[0]		// dst[8] 	= 83*EEEO0
	vsub.s32	q6, q14, q12		// dst[16]	= (EEEE0-EEEE1)
	vmul.s32	q7, q15, d4[1]		// dst[24]	= 36*EEEO0


	vshl.s32 	q4, q4, #6        	// dst[0]	= (EEE0 + EEE1) * 64
	vmla.s32	q5, q13, d4[1]		// dst[8] 	+= 36*EEEO1
	vshl.s32 	q6, q6, #6        	// dst[16]  = (EEE0 - EEE1) * 64
	vmls.s32	q7, q13, d4[0]		// dst[24] 	-= 83*EEEO1

	vqrshrn.s32	d8, q4, #4			// d16 => dst[0]
	vqrshrn.s32 d9, q5, #4			// d17 => dst[8]
    vqrshrn.s32	d10, q6, #4			// d18 => dst[16]
    vqrshrn.s32	d11, q7, #4			// d19 => dst[24]

	vst1.16 {d8}, [r12], lr
	vst1.16 {d9}, [r12], lr
	vst1.16 {d10}, [r12], lr
	vst1.16 {d11}, [r12]


	// retrive EEO from temp vars(0,1) buffer and EEO from stack(2,3)
	add r5, r4, #12*16			// set offset to EEO
	vldmia r5, {q14-q15}
	add r5, r4, #28*16
	vldmia r5, {q12, q13}
	//	q14 => [EEO0 EEO2](0,1)
	//	q15	=> [EEO3 EEO1](0,1)
	//	q12 => [EEO0 EEO2](2,3)
	//	q13	=> [EEO3 EEO1](2,3)

	vswp d29, d24
	vswp d31, d26
	//	q14 => [EEO0]
	//	q15	=> [EEO3]
	//	q12 => [EEO2]
	//	q13	=> [EEO1]
	// q0 => [90, 87, 80, 70]
	// q1 => [57, 43, 25,  9]
	// q2 => [83, 36, 75, 89]
	// q3 => [18, 50, 00, 00]
	// calc. 4, 12, 20, 28

	mov lr, #32*2*8
	add r12, r3, #32*2*4

	vmul.s32	q4, q14, d5[1]		// dst[4] = 89*EEO0
	vmul.s32	q5, q14, d5[0]		// dst[12] = 75*EEO0
	vmul.s32	q6, q14, d6[1]		// dst[20] = 50*EEO0
	vmul.s32	q7, q14, d6[0]		// dst[28] = 18*EEO0

	vmla.s32	q4, q13, d5[0]		// dst[4] += 75*EEO1
	vmls.s32	q5, q13, d6[0]		// dst[12]-= 18*EEO1
	vmls.s32	q6, q13, d5[1]		// dst[20]-= 89*EEO1
	vmls.s32	q7, q13, d6[1]		// dst[28]-= 50*EEO1

	vmla.s32	q4, q12, d6[1]		// dst[4] += 50*EEO2
	vmls.s32	q5, q12, d5[1]		// dst[12]-= 89*EEO2
	vmla.s32	q6, q12, d6[0]		// dst[20]+= 18*EEO2
	vmla.s32	q7, q12, d5[0]		// dst[28]+= 75*EEO2

	vmla.s32	q4, q15, d6[0]		// dst[4] += 18*EEO3
	vmls.s32	q5, q15, d6[1]		// dst[12]-= 50*EEO3
	vmla.s32	q6, q15, d5[0]		// dst[20]+= 75*EEO3
	vmls.s32	q7, q15, d5[1]		// dst[28]-= 89*EEO3

	vqrshrn.s32	d8, q4, #4			// d8 => dst[4]
	vqrshrn.s32 d9, q5, #4			// d9 => dst[12]
    vqrshrn.s32	d10, q6, #4			// d10 => dst[20]
    vqrshrn.s32	d11, q7, #4			// d11 => dst[28]

	vst1.16 {d8}, [r12], lr
	vst1.16 {d9}, [r12], lr
	vst1.16 {d10}, [r12], lr
	vst1.16 {d11}, [r12]


	// retrive EO from temp vars(0,1) buffer and EO from stack(2,3)
	add r5, r4, #8*16			// set offset to EO
	vldmia r5, {q12-q15}
	add r5, r4, #24*16
	vldmia r5, {q8-q11}

	//	q12	=> [E00 E02](0,1)
	//	q13	=> [E04 E06](0,1)
	//	q14	=> [E07 E05](0,1)
	//	q15	=> [E03 E01](0,1)

	//	q8	=> [E00 E02](2,3)
	//	q9	=> [E04 E06](2,3)
	//	q10	=> [E07 E05](2,3)
	//	q11	=> [E03 E01](2,3)
	vswp d25, d16
	vswp d27, d18
	vswp d29, d20
	vswp d31, d22
	//	q12	=> [E00]
	//	q13	=> [E04]
	//	q14	=> [E07]
	//	q15	=> [E03]
	//	q8	=> [E02]
	//	q9	=> [E06]
	//	q10	=> [E05]
	//	q11	=> [E01]
	// q0 => [90, 87, 80, 70]
	// q1 => [57, 43, 25,  9]
	// q2 => [83, 36, 75, 89]
	// q3 => [18, 50, 00, 00]
	// calc. 2, 6, 10, 14

	mov lr, #32*2*4
	add r12, r3, #32*2*2

	vmul.s32	q4, q12, d0[0]		//dst[2]  = 90*EO0
	vmul.s32	q5, q12, d0[1]		//dst[6]  = 87*EO0
	vmul.s32	q6, q12, d1[0]		//dst[10] = 80*EO0
	vmul.s32	q8, q12, d1[1]		//dst[14] = 70*EO0

	vmla.s32	q4, q11, d0[1]		//dst[2] += 87*EO1
	vmla.s32	q5, q11, d2[0]		//dst[6] += 57*EO1
	vmla.s32	q6, q11, d3[1]		//dst[10]+=  9*EO1
	vmls.s32	q8, q11, d2[1]		//dst[14]-= 43*EO1

	vmla.s32	q4, q8, d1[0]		//dst[2] += 80*EO2
	vmla.s32	q5, q8, d3[1]		//dst[6] +=  9*EO2
	vmls.s32	q6, q8, d1[1]		//dst[10]-= 70*EO2
	vmls.s32	q8, q8, d0[1]		//dst[14]-= 87*EO2

	vmla.s32	q4, q15, d1[1]		//dst[2] += 70*EO3
	vmls.s32	q5, q15, d2[1]		//dst[6] -= 43*EO3
	vmls.s32	q6, q15, d0[1]		//dst[10]-= 87*EO3
	vmla.s32	q8, q15, d3[1]		//dst[14]+=  9*EO3

	vmla.s32	q4, q13, d2[0]		//dst[2] += 57*EO4
	vmls.s32	q5, q13, d1[0]		//dst[6] -= 80*EO4
	vmls.s32	q6, q13, d3[0]		//dst[10]-= 25*EO4
	vmla.s32	q8, q13, d0[0]		//dst[14]+= 90*EO4

	vmla.s32	q4, q10, d2[1]		//dst[2] += 43*EO5
	vmls.s32	q5, q10, d0[0]		//dst[6] -= 90*EO5
	vmla.s32	q6, q10, d2[0]		//dst[10]+= 57*EO5
	vmla.s32	q8, q10, d3[0]		//dst[14]+= 25*EO5

	vmla.s32	q4, q9, d3[0]		//dst[2] += 25*EO6
	vmls.s32	q5, q9, d1[1]		//dst[6] -= 70*EO6
	vmla.s32	q6, q9, d0[0]		//dst[10]+= 90*EO6
	vmls.s32	q8, q9, d1[0]		//dst[14]-= 80*EO6

	vmla.s32	q4, q14, d3[1]		//dst[2] +=  9*EO7
	vmls.s32	q5, q14, d3[0]		//dst[6] -= 25*EO7
	vmla.s32	q6, q14, d2[1]		//dst[10]+= 43*EO7
	vmls.s32	q8, q14, d2[0]		//dst[14]-= 57*EO7

	vqrshrn.s32	d8, q4, #4			// d8 => dst[2]
	vqrshrn.s32 d9, q5, #4			// d9 => dst[6]
    vqrshrn.s32	d10, q6, #4			// d10 => dst[10]
    vqrshrn.s32	d11, q7, #4			// d11 => dst[14]

	vst1.16 {d8}, [r12], lr
	vst1.16 {d9}, [r12], lr
	vst1.16 {d10}, [r12], lr
	vst1.16 {d11}, [r12], lr

	vmul.s32	q4, q12, d2[0]		//dst[18] = 57*EO0
	vmul.s32	q5, q12, d2[1]		//dst[22] = 43*EO0
	vmul.s32	q6, q12, d3[0]		//dst[26] = 25*EO0
	vmul.s32	q7, q12, d3[1]		//dst[30] =  9*EO0

	vmls.s32	q4, q11, d1[0]		//dst[18] -= 80*EO1
	vmls.s32	q5, q11, d0[0]		//dst[22] -= 90*EO1
	vmls.s32	q6, q11, d1[1]		//dst[26] -= 70*EO1
	vmls.s32	q7, q11, d3[0]		//dst[30] -= 25*EO1

	vmls.s32	q4, q8, d3[0]		//dst[18] -= 25*EO2
	vmla.s32	q5, q8, d2[0]		//dst[22] += 57*EO2
	vmla.s32	q6, q8, d0[0]		//dst[26] += 90*EO2
	vmla.s32	q7, q8, d2[1]		//dst[30] += 43*EO2

	vmla.s32	q4, q15, d0[0]		//dst[18] += 90*EO3
	vmla.s32	q5, q15, d3[0]		//dst[22] += 25*EO3
	vmls.s32	q6, q15, d1[0]		//dst[26] -= 80*EO3
	vmls.s32	q7, q15, d2[0]		//dst[30] -= 57*EO3

	vmls.s32	q4, q13, d3[1]		//dst[18] -=  9*EO4
	vmls.s32	q5, q13, d0[1]		//dst[22] -= 87*EO4
	vmla.s32	q6, q13, d2[1]		//dst[26] += 43*EO4
	vmla.s32	q7, q13, d1[1]		//dst[30] += 70*EO4

	vmls.s32	q4, q10, d0[1]		//dst[18] -= 87*EO5
	vmla.s32	q5, q10, d1[1]		//dst[22] += 70*EO5
	vmla.s32	q6, q10, d3[1]		//dst[26] +=  9*EO5
	vmls.s32	q7, q10, d1[0]		//dst[30] -= 80*EO5

	vmla.s32	q4, q9, d2[1]		//dst[18] += 43*EO6
	vmla.s32	q5, q9, d3[1]		//dst[22] +=  9*EO6
	vmls.s32	q6, q9, d2[0]		//dst[26] -= 57*EO6
	vmla.s32	q7, q9, d0[1]		//dst[30] += 87*EO6

	vmla.s32	q4, q14, d1[1]		//dst[18] += 70*EO7
	vmls.s32	q5, q14, d1[0]		//dst[22] -= 80*EO7
	vmla.s32	q6, q14, d0[1]		//dst[26] += 87*EO7
	vmls.s32	q7, q14, d0[0]		//dst[30] -= 90*EO7

	vqrshrn.s32	d8, q4, #4			// d8 => dst[18]
	vqrshrn.s32 d9, q5, #4			// d9 => dst[22]
    vqrshrn.s32	d10, q6, #4			// d10 => dst[26]
    vqrshrn.s32	d11, q7, #4			// d11 => dst[30]

	vst1.16 {d8}, [r12], lr
	vst1.16 {d9}, [r12], lr
	vst1.16 {d10}, [r12], lr
	vst1.16 {d11}, [r12], lr

	// and now the sorcery...again :/
	// retrive O from temp vars(0,1) buffer and O from stack(2,3)
	mov r5, r4					// set temp buffer iterator to O
	vldmia r5, {q0-q7}
	add r5, r4, #16*16
	vldmia r5, {q8-q15}

	// (2,3)
	//	q8	=> [O0 O2]
    //  q9  => [O4 O6]
    //	q10	=> [O8 O10]
    //  q11 => [O12 O14]
    //	q12 => [O15 O13]
    //  q13 => [O11 O9]
    //	q14 => [O7 O5]
    //  q15 => [O3 O1]
	vswp d1, d16
	vswp d3, d18
	vswp d5, d20
	vswp d7, d22
	vswp d9, d24
	vswp d11, d26
	vswp d13, d28
	vswp d15, d30

	vswp q6, q13
	vswp q7, q12
	vswp q0, q11
	vswp q1, q10

	// q0-q7 => O[14 10 8 12 15 11 9 13]
	// q8-q15=> O[2 6 4 0 3 7 5 1]

	// make some room for calculation
	add r5, r4, #8*16
	vstmia r4, {q0-q7}

	// load coeffs
	// q0 => [90, 88, 85, 82]
	// q1 => [78, 73, 67, 61]
	// q2 => [54, 46, 38, 31]
	// q3 => [22, 13,  4, 00]
	adr	lr, c2
	vld1.32 {d0-d3}, [lr]!
	vld1.32 {d4-d7}, [lr]!

	// store offset and stride
	mov lr, #32*2*2
	add r12, r3, #32*2*1

	// free regs q5-q7
	vmul.s32	q4, q11, d0[0]		//dst[1] = 90*O0
	vmul.s32	q5, q11, d0[0]		//dst[3] = 90*O0
	vmul.s32	q6, q11, d0[1]		//dst[5] = 88*O0
	vmul.s32	q7, q11, d1[0]		//dst[7] = 85*O0

	vmla.s32	q4, q15, d0[0]		//dst[1] += 90*O1
	vmla.s32	q5, q15, d1[1]		//dst[3] += 82*O1
	vmla.s32	q6, q15, d3[0]		//dst[5] += 67*O1
	vmla.s32	q7, q15, d4[1]		//dst[7] += 46*O1

	vmla.s32	q4, q8, d0[1]		//dst[1] += 88*O2
	vmla.s32	q5, q8, d3[0]		//dst[3] += 67*O2
	vmla.s32	q6, q8, d5[1]		//dst[5] += 31*O2
	vmls.s32	q7, q8, d6[1]		//dst[7] -= 13*O2

	vmla.s32	q4, q12, d1[0]		//dst[1] += 85*O3
	vmla.s32	q5, q12, d4[1]		//dst[3] += 46*O3
	vmls.s32	q6, q12, d6[1]		//dst[5] -= 13*O3
	vmls.s32	q7, q12, d3[0]		//dst[7] -= 67*O3

	vmla.s32	q4, q10, d1[1]		//dst[1] += 82*O4
	vmla.s32	q5, q10, d6[0]		//dst[3] += 22*O4
	vmls.s32	q6, q10, d4[0]		//dst[5] -= 54*O4
	vmls.s32	q7, q10, d0[0]		//dst[7] -= 90*O4

	vmla.s32	q4, q14, d2[0]		//dst[1] += 78*O5
	vmls.s32	q5, q14, d7[0]		//dst[3] -=  4*O5
	vmls.s32	q6, q14, d1[1]		//dst[5] -= 82*O5
	vmls.s32	q7, q14, d2[1]		//dst[7] -= 73*O5

	vmla.s32	q4, q9, d2[1]		//dst[1] += 73*O6
	vmls.s32	q5, q9, d5[1]		//dst[3] -= 31*O6
	vmls.s32	q6, q9, d0[0]		//dst[5] -= 90*O6
	vmls.s32	q7, q9, d6[0]		//dst[7] -= 22*O6

	vmla.s32	q4, q13, d3[0]		//dst[1] += 67*O7
	vmls.s32	q5, q13, d4[0]		//dst[3] -= 54*O7
	vmls.s32	q6, q13, d2[0]		//dst[5] -= 78*O7
	vmla.s32	q7, q13, d5[0]		//dst[7] += 38*O7

	// switch out vars
	vstmia r5, {q8-q15}
	vldmia r4, {q8-q15}

	vmla.s32	q4, q10, d3[1]		//dst[1] += 61*O8
	vmls.s32	q5, q10, d2[1]		//dst[3] -= 73*O8
	vmls.s32	q6, q10, d4[1]		//dst[5] -= 46*O8
	vmla.s32	q7, q10, d1[1]		//dst[7] += 82*O8

	vmla.s32	q4, q14, d4[0]		//dst[1] += 54*O9
	vmls.s32	q5, q14, d1[0]		//dst[3] -= 85*O9
	vmls.s32	q6, q14, d7[0]		//dst[5] -=  4*O9
	vmla.s32	q7, q14, d0[1]		//dst[7] += 88*O9

	vmla.s32	q4, q9, d4[1]		//dst[1] += 46*O10
	vmls.s32	q5, q9, d0[0]		//dst[3] -= 90*O10
	vmla.s32	q6, q9, d5[0]		//dst[5] += 38*O10
	vmla.s32	q7, q9, d4[0]		//dst[7] += 54*O10

	vmla.s32	q4, q13, d5[0]		//dst[1] += 38*O11
	vmls.s32	q5, q13, d0[1]		//dst[3] -= 88*O11
	vmla.s32	q6, q13, d2[1]		//dst[5] += 73*O11
	vmls.s32	q7, q13, d7[0]		//dst[7] -=  4*O11

	vmla.s32	q4, q11, d5[1]		//dst[1] += 31*O12
	vmls.s32	q5, q11, d2[0]		//dst[3] -= 78*O12
	vmla.s32	q6, q11, d0[0]		//dst[5] += 90*O12
	vmls.s32	q7, q11, d3[1]		//dst[7] -= 61*O12

	vmla.s32	q4, q15, d6[0]		//dst[1] += 22*O13
	vmls.s32	q5, q15, d3[1]		//dst[3] -= 61*O13
	vmla.s32	q6, q15, d1[0]		//dst[5] += 85*O13
	vmls.s32	q7, q15, d0[0]		//dst[7] -= 90*O13

	vmla.s32	q4, q8, d6[1]		//dst[1] += 13*O14
	vmls.s32	q5, q8, d5[0]		//dst[3] -= 38*O14
	vmla.s32	q6, q8, d3[1]		//dst[5] += 61*O14
	vmls.s32	q7, q8, d2[0]		//dst[7] -= 78*O14

	vmla.s32	q4, q12, d7[0]		//dst[1] +=  4*O15
	vmls.s32	q5, q12, d6[1]		//dst[3] -= 13*O15
	vmla.s32	q6, q12, d6[0]		//dst[5] += 22*O15
	vmls.s32	q7, q12, d5[1]		//dst[7] -= 31*O15

	vqrshrn.s32	d8, q4, #4			// d8 => dst[1]
	vqrshrn.s32 d9, q5, #4			// d9 => dst[3]
    vqrshrn.s32	d10, q6, #4			// d10 => dst[5]
    vqrshrn.s32	d11, q7, #4			// d11 => dst[7]

	vst1.16 {d8}, [r12], lr
	vst1.16 {d9}, [r12], lr
	vst1.16 {d10}, [r12], lr
	vst1.16 {d11}, [r12], lr


	// load O0-O7
	vldmia r5, {q8-q15}

	vmul.s32	q4, q11, d1[1]		//dst[9]  = 82*O0
	vmul.s32	q5, q11, d2[0]		//dst[11] = 78*O0
	vmul.s32	q6, q11, d2[1]		//dst[13] = 73*O0
	vmul.s32	q7, q11, d3[0]		//dst[15] = 67*O0

	vmla.s32	q4, q15, d6[0]		//dst[9]  += 22*O1
	vmls.s32	q5, q15, d7[0]		//dst[11] -=  4*O1
	vmls.s32	q6, q15, d5[1]		//dst[13] -= 31*O1
	vmls.s32	q7, q15, d4[0]		//dst[15] -= 54*O1

	vmls.s32	q4, q8, d4[0]		//dst[9]  -= 54*O2
	vmls.s32	q5, q8, d1[1]		//dst[11] -= 82*O2
	vmls.s32	q6, q8, d0[0]		//dst[13] -= 90*O2
	vmls.s32	q7, q8, d2[0]		//dst[15] -= 78*O2

	vmls.s32	q4, q12, d0[0]		//dst[9]  -= 90*O3
	vmls.s32	q5, q12, d2[1]		//dst[11] -= 73*O3
	vmls.s32	q6, q12, d6[0]		//dst[13] -= 22*O3
	vmla.s32	q7, q12, d5[0]		//dst[15] += 38*O3

	vmls.s32	q4, q10, d3[1]		//dst[9]  -= 61*O4
	vmla.s32	q5, q10, d6[1]		//dst[11] += 13*O4
	vmla.s32	q6, q10, d2[0]		//dst[13] += 78*O4
	vmla.s32	q7, q10, d1[0]		//dst[15] += 85*O4

	vmla.s32	q4, q14, d6[1]		//dst[9]  += 13*O5
	vmla.s32	q5, q14, d1[0]		//dst[11] += 85*O5
	vmla.s32	q6, q14, d3[0]		//dst[13] += 67*O5
	vmls.s32	q7, q14, d6[0]		//dst[15] -= 22*O5

	vmla.s32	q4, q9, d2[0]		//dst[9]  += 78*O6
	vmla.s32	q5, q9, d3[0]		//dst[11] += 67*O6
	vmls.s32	q6, q9, d5[0]		//dst[13] -= 38*O6
	vmls.s32	q7, q9, d0[0]		//dst[15] -= 90*O6

	vmla.s32	q4, q13, d1[0]		//dst[9]  += 85*O7
	vmls.s32	q5, q13, d6[0]		//dst[11] -= 22*O7
	vmls.s32	q6, q13, d0[0]		//dst[13] -= 90*O7
	vmla.s32	q7, q13, d7[0]		//dst[15] +=  4*O7

	// load O8-O15
	vldmia r4, {q8-q15}

	vmla.s32	q4, q10, d5[1]		//dst[9]  += 31*O8
	vmls.s32	q5, q10, d0[1]		//dst[11] -= 88*O8
	vmls.s32	q6, q10, d6[1]		//dst[13] -= 13*O8
	vmla.s32	q7, q10, d0[0]		//dst[15] += 90*O8

	vmls.s32	q4, q14, d4[1]		//dst[9]  -= 46*O9
	vmls.s32	q5, q14, d3[1]		//dst[11] -= 61*O9
	vmla.s32	q6, q14, d1[1]		//dst[13] += 82*O9
	vmla.s32	q7, q14, d6[1]		//dst[15] += 13*O9

	vmls.s32	q4, q9, d0[0]		//dst[9]  -= 90*O10
	vmla.s32	q5, q9, d5[1]		//dst[11] += 31*O10
	vmla.s32	q6, q9, d3[1]		//dst[13] += 61*O10
	vmls.s32	q7, q9, d0[1]		//dst[15] -= 88*O10

	vmls.s32	q4, q13, d3[0]		//dst[9]  -= 67*O11
	vmla.s32	q5, q13, d0[0]		//dst[11] += 90*O11
	vmls.s32	q6, q13, d4[1]		//dst[13] -= 46*O11
	vmls.s32	q7, q13, d5[1]		//dst[15] -= 31*O11

	vmla.s32	q4, q11, d7[0]		//dst[9]  +=  4*O12
	vmla.s32	q5, q11, d4[0]		//dst[11] += 54*O12
	vmls.s32	q6, q11, d0[1]		//dst[13] -= 88*O12
	vmla.s32	q7, q11, d1[1]		//dst[15] += 82*O12

	vmla.s32	q4, q15, d2[1]		//dst[9]  += 73*O13
	vmls.s32	q5, q15, d5[0]		//dst[11] -= 38*O13
	vmls.s32	q6, q15, d7[0]		//dst[13] -=  4*O13
	vmla.s32	q7, q15, d4[1]		//dst[15] += 46*O13

	vmla.s32	q4, q8, d0[1]		//dst[9]  += 88*O14
	vmls.s32	q5, q8, d0[0]		//dst[11] -= 90*O14
	vmla.s32	q6, q8, d1[0]		//dst[13] += 85*O14
	vmls.s32	q7, q8, d2[1]		//dst[15] -= 73*O14

	vmla.s32	q4, q12, d5[0]		//dst[9]  += 38*O15
	vmls.s32	q5, q12, d4[1]		//dst[11] -= 46*O15
	vmla.s32	q6, q12, d4[0]		//dst[13] += 54*O15
	vmls.s32	q7, q12, d3[1]		//dst[15] -= 61*O15

	vqrshrn.s32	d8, q4, #4			// d8 => dst[9]
	vqrshrn.s32 d9, q5, #4			// d9 => dst[11]
    vqrshrn.s32	d10, q6, #4			// d10 => dst[13]
    vqrshrn.s32	d11, q7, #4			// d11 => dst[15]

	vst1.16 {d8}, [r12], lr
	vst1.16 {d9}, [r12], lr
	vst1.16 {d10}, [r12], lr
	vst1.16 {d11}, [r12], lr

	// load O0-O7
	vldmia r5, {q8-q15}

	// calculate rows 17, 19, 21, 23 in parallel
	vmul.s32	q4, q11, d3[1]		//dst[17] = 61*O0
	vmul.s32	q5, q11, d4[0]		//dst[19] = 54*O0
	vmul.s32	q6, q11, d4[1]		//dst[21] = 46*O0
	vmul.s32	q7, q11, d5[0]		//dst[23] = 38*O0

	vmls.s32	q4, q15, d2[1]		//dst[17] -= 73*O1
	vmls.s32	q5, q15, d1[0]		//dst[19] -= 85*O1
	vmls.s32	q6, q15, d0[0]		//dst[21] -= 90*O1
	vmls.s32	q7, q15, d0[1]		//dst[23] -= 88*O1

	vmls.s32	q4, q8, d4[1]		//dst[17] -= 46*O2
	vmls.s32	q5, q8, d7[0]		//dst[19] -=  4*O2
	vmla.s32	q6, q8, d5[0]		//dst[21] += 38*O2
	vmla.s32	q7, q8, d2[1]		//dst[23] += 73*O2

	vmla.s32	q4, q12, d1[1]		//dst[17] += 82*O3
	vmla.s32	q5, q12, d0[1]		//dst[19] += 88*O3
	vmla.s32	q6, q12, d4[0]		//dst[21] += 54*O3
	vmls.s32	q7, q12, d7[0]		//dst[23] -=  4*O3

	vmla.s32	q4, q10, d5[1]		//dst[17] += 31*O4
	vmls.s32	q5, q10, d4[1]		//dst[19] -= 46*O4
	vmls.s32	q6, q10, d0[0]		//dst[21] -= 90*O4
	vmls.s32	q7, q10, d3[0]		//dst[23] -= 67*O4

	vmls.s32	q4, q14, d0[1]		//dst[17] -= 88*O5
	vmls.s32	q5, q14, d3[1]		//dst[19] -= 61*O5
	vmla.s32	q6, q14, d5[1]		//dst[21] += 31*O5
	vmla.s32	q7, q14, d0[0]		//dst[23] += 90*O5

	vmls.s32	q4, q9, d6[1]		//dst[17] -= 13*O6
	vmla.s32	q5, q9, d1[1]		//dst[19] += 82*O6
	vmla.s32	q6, q9, d3[1]		//dst[21] += 61*O6
	vmls.s32	q7, q9, d4[1]		//dst[23] -= 46*O6

	vmla.s32	q4, q13, d0[0]		//dst[17] += 90*O7
	vmla.s32	q5, q13, d6[1]		//dst[19] += 13*O7
	vmls.s32	q6, q13, d0[1]		//dst[21] -= 88*O7
	vmls.s32	q7, q13, d5[1]		//dst[23] -= 31*O7

	// load O8-O15
	vldmia r4, {q8-q15}

	vmls.s32	q4, q10, d7[0]		//dst[17] -=  4*O8
	vmls.s32	q5, q10, d0[0]		//dst[19] -= 90*O8
	vmla.s32	q6, q10, d6[0]		//dst[21] += 22*O8
	vmla.s32	q7, q10, d1[0]		//dst[23] += 85*O8

	vmls.s32	q4, q14, d0[0]		//dst[17] -= 90*O9
	vmla.s32	q5, q14, d5[0]		//dst[19] += 38*O9
	vmla.s32	q6, q14, d3[0]		//dst[21] += 67*O9
	vmls.s32	q7, q14, d2[0]		//dst[23] -= 78*O9

	vmla.s32	q4, q9, d6[0]		//dst[17] += 22*O10
	vmla.s32	q5, q9, d3[0]		//dst[19] += 67*O10
	vmls.s32	q6, q9, d1[0]		//dst[21] -= 85*O10
	vmla.s32	q7, q9, d6[1]		//dst[23] += 13*O10

	vmla.s32	q4, q13, d1[0]		//dst[17] += 85*O11
	vmls.s32	q5, q13, d2[0]		//dst[19] -= 78*O11
	vmla.s32	q6, q13, d6[1]		//dst[21] += 13*O11
	vmla.s32	q7, q13, d3[1]		//dst[23] += 61*O11

	vmls.s32	q4, q11, d5[0]		//dst[17] -= 38*O12
	vmls.s32	q5, q11, d6[0]		//dst[19] -= 22*O12
	vmla.s32	q6, q11, d2[1]		//dst[21] += 73*O12
	vmls.s32	q7, q11, d0[0]		//dst[23] -= 90*O12

	vmls.s32	q4, q15, d2[0]		//dst[17] -= 78*O13
	vmla.s32	q5, q15, d0[0]		//dst[19] += 90*O13
	vmls.s32	q6, q15, d1[1]		//dst[21] -= 82*O13
	vmla.s32	q7, q15, d4[0]		//dst[23] += 54*O13

	vmla.s32	q4, q8, d4[0]		//dst[17] += 54*O14
	vmls.s32	q5, q8, d5[1]		//dst[19] -= 31*O14
	vmla.s32	q6, q8, d7[0]		//dst[21] +=  4*O14
	vmla.s32	q7, q8, d6[0]		//dst[23] += 22*O14

	vmla.s32	q4, q12, d3[0]		//dst[17] += 67*O15
	vmls.s32	q5, q12, d2[1]		//dst[19] -= 73*O15
	vmla.s32	q6, q12, d2[0]		//dst[21] += 78*O15
	vmls.s32	q7, q12, d1[1]		//dst[23] -= 82*O15

	vqrshrn.s32	d8, q4, #4			// d8 => dst[17]
	vqrshrn.s32 d9, q5, #4			// d9 => dst[19]
    vqrshrn.s32	d10, q6, #4			// d10 => dst[21]
    vqrshrn.s32	d11, q7, #4			// d11 => dst[23]

	vst1.16 {d8}, [r12], lr
	vst1.16 {d9}, [r12], lr
	vst1.16 {d10}, [r12], lr
	vst1.16 {d11}, [r12], lr

	// load O0-O7
	vldmia r5, {q8-q15}

	// calculate rows 25, 27, 29, 31 in parallel
	vmul.s32	q4, q11, d5[1]		//dst[25] = 31*O0
	vmul.s32	q5, q11, d6[0]		//dst[27] = 22*O0
	vmul.s32	q6, q11, d6[1]		//dst[29] = 13*O0
	vmul.s32	q7, q11, d7[0]		//dst[31] =  4*O0

	vmls.s32	q4, q15, d2[0]		//dst[25] -= 78*O1
	vmls.s32	q5, q15, d3[1]		//dst[27] -= 61*O1
	vmls.s32	q6, q15, d5[1]		//dst[29] -= 38*O1
	vmls.s32	q7, q15, d6[1]		//dst[31] -= 13*O1

	vmla.s32	q4, q8, d0[0]		//dst[25] += 90*O2
	vmla.s32	q5, q8, d1[0]		//dst[27] += 85*O2
	vmla.s32	q6, q8, d3[1]		//dst[29] += 61*O2
	vmla.s32	q7, q8, d6[0]		//dst[31] += 22*O2

	vmls.s32	q4, q12, d3[1]		//dst[25] -= 61*O3
	vmls.s32	q5, q12, d0[0]		//dst[27] -= 90*O3
	vmls.s32	q6, q12, d2[0]		//dst[29] -= 78*O3
	vmls.s32	q7, q12, d5[1]		//dst[31] -= 31*O3

	vmla.s32	q4, q10, d7[0]		//dst[25] +=  4*O4
	vmla.s32	q5, q10, d2[1]		//dst[27] += 73*O4
	vmla.s32	q6, q10, d0[1]		//dst[29] += 88*O4
	vmla.s32	q7, q10, d5[0]		//dst[31] += 38*O4

	vmla.s32	q4, q14, d4[0]		//dst[25] += 54*O5
	vmls.s32	q5, q14, d5[0]		//dst[27] -= 38*O5
	vmls.s32	q6, q14, d0[0]		//dst[29] -= 90*O5
	vmls.s32	q7, q14, d4[1]		//dst[31] -= 46*O5

	vmls.s32	q4, q9, d0[1]		//dst[25] -= 88*O6
	vmls.s32	q5, q9, d7[0]		//dst[27] -=  4*O6
	vmla.s32	q6, q9, d1[0]		//dst[29] += 85*O6
	vmla.s32	q7, q9, d4[0]		//dst[31] += 54*O6

	vmla.s32	q4, q13, d1[1]		//dst[25] += 82*O7
	vmla.s32	q5, q13, d4[1]		//dst[27] += 46*O7
	vmls.s32	q6, q13, d2[1]		//dst[29] -= 73*O7
	vmls.s32	q7, q13, d3[1]		//dst[31] -= 61*O7

	// load O8-O15
	vldmia r4, {q8-q15}

	vmls.s32	q4, q10, d5[0]		//dst[25] -= 38*O8
	vmls.s32	q5, q10, d2[0]		//dst[27] -= 78*O8
	vmla.s32	q6, q10, d4[0]		//dst[29] += 54*O8
	vmla.s32	q7, q10, d3[0]		//dst[31] += 67*O8

	vmls.s32	q4, q14, d6[0]		//dst[25] -= 22*O9
	vmla.s32	q5, q14, d0[0]		//dst[27] += 90*O9
	vmls.s32	q6, q14, d5[1]		//dst[29] -= 31*O9
	vmls.s32	q7, q14, d2[1]		//dst[31] -= 73*O9

	vmla.s32	q4, q9, d2[1]		//dst[25] += 73*O10
	vmls.s32	q5, q9, d1[1]		//dst[27] -= 82*O10
	vmla.s32	q6, q9, d7[0]		//dst[29] +=  4*O10
	vmla.s32	q7, q9, d2[0]		//dst[31] += 78*O10

	vmls.s32	q4, q13, d0[0]		//dst[25] -= 90*O11
	vmla.s32	q5, q13, d4[0]		//dst[27] += 54*O11
	vmla.s32	q6, q13, d6[0]		//dst[29] += 22*O11
	vmls.s32	q7, q13, d1[1]		//dst[31] -= 82*O11

	vmla.s32	q4, q11, d3[0]		//dst[25] += 67*O12
	vmls.s32	q5, q11, d6[1]		//dst[27] -= 13*O12
	vmls.s32	q6, q11, d4[1]		//dst[29] -= 46*O12
	vmla.s32	q7, q11, d1[0]		//dst[31] += 85*O12

	vmls.s32	q4, q15, d6[1]		//dst[25] -= 13*O13
	vmls.s32	q5, q15, d5[1]		//dst[27] -= 31*O13
	vmla.s32	q6, q15, d3[0]		//dst[29] += 67*O13
	vmls.s32	q7, q15, d0[1]		//dst[31] -= 88*O13

	vmls.s32	q4, q8, d4[1]		//dst[25] -= 46*O14
	vmla.s32	q5, q8, d3[0]		//dst[27] += 67*O14
	vmls.s32	q6, q8, d1[1]		//dst[29] -= 82*O14
	vmla.s32	q7, q8, d0[0]		//dst[31] += 90*O14

	vmla.s32	q4, q12, d1[0]		//dst[25] += 85*O15
	vmls.s32	q5, q12, d0[1]		//dst[27] -= 88*O15
	vmla.s32	q6, q12, d0[0]		//dst[29] += 90*O15
	vmls.s32	q7, q12, d0[0]		//dst[31] -= 90*O15

	vqrshrn.s32	d8, q4, #4			// d8 => dst[25]
	vqrshrn.s32 d9, q5, #4			// d9 => dst[27]
    vqrshrn.s32	d10, q6, #4			// d10 => dst[29]
    vqrshrn.s32	d11, q7, #4			// d11 => dst[31]

	vst1.16 {d8}, [r12], lr
	vst1.16 {d9}, [r12], lr
	vst1.16 {d10}, [r12], lr
	vst1.16 {d11}, [r12], lr


	// next four columns have to be filled, increment offset
	add r3, #4*2

	subs r2, #1
    bgt .loop1_32x32


//********************************************************* 2nd pass*****************************************************************//

	mov r2, #32/4			// rows counter
	mov r3, r1 				// dst reference pointer

.loop2_32x32:
	// restore temp vars pointer
	mov r5, r4

	// load first two rows from stack buffer
    vld1.16 {q0, q1}, [r7]!
    vld1.16 {q2, q3}, [r7]!
    vld1.16 {q4, q5}, [r7]!
    vld1.16 {q6, q7}, [r7]!


    // transpose the input data
    vtrn.16 q0, q4
    vtrn.16 q1, q5
    vtrn.16 q2, q6
    vtrn.16 q3, q7

    vrev64.32   q4, q4
    vrev64.32   q5, q5
    vrev64.32   q6, q6
    vrev64.32   q7, q7

    vswp    d8, d15
    vswp    d9, d14
    vswp    d10, d13
    vswp    d11, d12

    // 0
    vsubl.s16	q8, d0, d8		//	q8	=> [O0 O2]
    vsubl.s16   q9, d1, d9      //  q9  => [O4 O6]
    vsubl.s16	q10, d2, d10	//	q10	=> [O8 O10]
    vsubl.s16   q11, d3, d11    //  q11 => [O12 O14]
    vsubl.s16	q12, d12, d4	//	q12 => [O15 O13]
    vsubl.s16   q13, d13, d5    //  q13 => [O11 O9]
    vsubl.s16	q14, d14, d6	//	q14 => [O7 O5]
    vsubl.s16   q15, d15, d7    //  q15 => [O3 O1]

	// store to temp buffer
	vstmia r5!, {q8-q15}

	// E
    vaddl.s16    q8, d0, d8      //  q8 => [E0 E2]
    vaddl.s16    q9, d1, d9      //  q9 => [E4 E6]
    vaddl.s16    q10, d2, d10    //  q10 => [E8 E10]
    vaddl.s16    q11, d3, d11    //  q11 => [E12 E14]
    vaddl.s16    q12, d4, d12    //  q12 => [E15 E13]
    vaddl.s16    q13, d5, d13    //  q13 => [E11 E9]
    vaddl.s16    q14, d6, d14    //  q14 => [E7 E5]
    vaddl.s16    q15, d7, d15    //  q15 => [E3 E1]

   	// E0
	vsub.s32	q4, q8, q12		//	q4	=> [E00 E02]
	vsub.s32	q5, q9, q13		//	q5	=> [E04 E06]
	vsub.s32	q6, q14, q10	//	q6 	=> [E07 E05]
	vsub.s32	q7, q15, q11	//	q7 	=> [E03 E01]

 	// EE
    vadd.s32    q0, q8, q12	    //  q0  => [EE0 EE2]
    vadd.s32    q1, q9, q13 	//  q1  => [EE4 EE6]
    vadd.s32    q2, q14, q10    //  q2  => [EE7 EE5]
    vadd.s32    q3, q15, q11    //  q3  => [EE3 EE1]

	// store to temp buffer
    vstmia r5!, {q4-q7}

	// EEE
	vadd.s32	q8, q0, q2		//	q8 	=> [EEE0 EEE2]
	vadd.s32	q9, q3, q1		//	q9	=> [EEE3 EEE1]

	// EEO
	vsub.s32	q10, q0, q2		//	q10 => [EEO0 EEO2]
	vsub.s32	q11, q3, q1		//	q11	=> [EEO3 EEO1]


	// EEEE
	vadd.s32	d24, d16, d18	//	q12	=> [EEEE0 - ]
	vadd.s32	d25, d19, d17	//	q12	=> [EEEE0 EEEE1]

	// EEEO
	vsub.s32	d26, d16, d18	//	q13	=> [EEEO0 - ]
	vsub.s32	d27, d19, d17	//	q13	=> [EEEO0 EEEO1]

	// store EE0, EEEE, EEEO to temp buffer
    vstmia r5!, {q10-q13}

	// load SECOND two rows
    vld1.16 {q0, q1}, [r7]!
    vld1.16 {q2, q3}, [r7]!
    vld1.16 {q4, q5}, [r7]!
    vld1.16 {q6, q7}, [r7]!


    // transpose the input data
    vtrn.16 q0, q4
    vtrn.16 q1, q5
    vtrn.16 q2, q6
    vtrn.16 q3, q7

    vrev64.32   q4, q4
    vrev64.32   q5, q5
    vrev64.32   q6, q6
    vrev64.32   q7, q7

    vswp    d8, d15
    vswp    d9, d14
    vswp    d10, d13
    vswp    d11, d12

    // 0
    vsubl.s16	q8, d0, d8		//	q8	=> [O0 O2]
    vsubl.s16   q9, d1, d9      //  q9  => [O4 O6]
    vsubl.s16	q10, d2, d10	//	q10	=> [O8 O10]
    vsubl.s16   q11, d3, d11    //  q11 => [O12 O14]
    vsubl.s16	q12, d12, d4	//	q12 => [O15 O13]
    vsubl.s16   q13, d13, d5    //  q13 => [O11 O9]
    vsubl.s16	q14, d14, d6	//	q14 => [O7 O5]
    vsubl.s16   q15, d15, d7	//  q15 => [O3 O1]

	// store to temp vars buffer
	vstmia r5!, {q8-q15}

	// E
    vaddl.s16    q8, d0, d8      //  q8 => [E0 E2]
    vaddl.s16    q9, d1, d9      //  q9 => [E4 E6]
    vaddl.s16    q10, d2, d10    //  q10 => [E8 E10]
    vaddl.s16    q11, d3, d11    //  q11 => [E12 E14]
    vaddl.s16    q12, d4, d12    //  q12 => [E15 E13]
    vaddl.s16    q13, d5, d13    //  q13 => [E11 E9]
    vaddl.s16    q14, d6, d14    //  q14 => [E7 E5]
    vaddl.s16    q15, d7, d15    //  q15 => [E3 E1]

   	// E0
	vsub.s32	q4, q8, q12		//	q4	=> [E00 E02]
	vsub.s32	q5, q9, q13		//	q5	=> [E04 E06]
	vsub.s32	q6, q14, q10	//	q6 	=> [E07 E05]
	vsub.s32	q7, q15, q11	//	q7 	=> [E03 E01]

 	// EE
    vadd.s32    q0, q8, q12	    //  q0  => [EE0 EE2]
    vadd.s32    q1, q9, q13 	//  q1  => [EE4 EE6]
    vadd.s32    q2, q14, q10    //  q2  => [EE7 EE5]
    vadd.s32    q3, q15, q11    //  q3  => [EE3 EE1]

	// store to temp vars buffer
    vstmia r5!, {q4-q7}

	// EEE
	vadd.s32	q8, q0, q2		//	q8 	=> [EEE0 EEE2]
	vadd.s32	q9, q3, q1		//	q9	=> [EEE3 EEE1]

	// EEO
	vsub.s32	q10, q0, q2		//	q10 => [EEO0 EEO2]
	vsub.s32	q11, q3, q1		//	q11	=> [EEO3 EEO1]


	// EEEE
	vadd.s32	d24, d16, d18	//	q12	=> [EEEE0 - ]
	vadd.s32	d25, d19, d17	//	q12	=> [EEEE0 EEEE1]

	// EEEO
	vsub.s32	d26, d16, d18	//	q13	=> [EEEO0 - ]
	vsub.s32	d27, d19, d17	//	q13	=> [EEEO0 EEEO1]

	// store EE0 to temp vars buffer
    vstmia r5!, {q10-q11}

	// retrive EEEE and EEEO from temp buffer(first two rows)
	add r5, r4, #14*16			// set offset to EEEE and EEEO
	vldmia r5, {q14-q15}		// q14 => [EEEE0 EEEE1](0,1) q15 => [EEEO0 EEEO1](0,1)

	//  q14 => [EEEE0 EEEE1](0,1)
	//	q12	=> [EEEE0 EEEE1](2,3)
	//  q15 => [EEEO0 EEEO1](0,1)
	//	q13	=> [EEEO0 EEEO1](2,3)
	vswp d29, d24
	vswp d31, d26
	//  q14 => [EEEE0]
	//	q12	=> [EEEE1]
	//  q15 => [EEEO0]
	//	q13	=> [EEEO1]


	// load coeffs
	// q0 => [90, 87, 80, 70]
	// q1 => [57, 43, 25,  9]
	// q2 => [83, 36, 75, 89]
	// q3 => [18, 50, 00, 00]
	adrl lr, c1
	vld1.32 {d0-d3}, [lr]!
	vld1.32 {d4-d7}, [lr]!

	// calc. 0, 8, 16, 24
	// free: q4 - q12
	mov lr, #32*2*8
	mov r1, r3

	vadd.s32	q4, q14, q12		// dst[0]	= (EEEE0+EEEE1)
	vmul.s32	q5, q15, d4[0]		// dst[8] 	= 83*EEEO0
	vsub.s32	q6, q14, q12		// dst[16]	= (EEEE0-EEEE1)
	vmul.s32	q7, q15, d4[1]		// dst[24]	= 36*EEEO0


	vshl.s32 	q4, q4, #6        	// dst[0]	= (EEE0 + EEE1) * 64
	vmla.s32	q5, q13, d4[1]		// dst[8] 	+= 36*EEEO1
	vshl.s32 	q6, q6, #6        	// dst[16]  = (EEE0 - EEE1) * 64
	vmls.s32	q7, q13, d4[0]		// dst[24] 	-= 83*EEEO1

	vqrshrn.s32	d8, q4, #11			// d16 => dst[0]
	vqrshrn.s32 d9, q5, #11			// d17 => dst[8]
    vqrshrn.s32	d10, q6, #11		// d18 => dst[16]
    vqrshrn.s32	d11, q7, #11		// d19 => dst[24]

	vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr
	vst1.16 {d10}, [r1], lr
	vst1.16 {d11}, [r1]


	// retrive EEO from temp vars(0,1) buffer and EEO from stack(2,3)
	add r5, r4, #12*16			// set offset to EEO
	vldmia r5, {q14-q15}
	add r5, r4, #28*16
	vldmia r5, {q12, q13}
	//	q14 => [EEO0 EEO2](0,1)
	//	q15	=> [EEO3 EEO1](0,1)
	//	q12 => [EEO0 EEO2](2,3)
	//	q13	=> [EEO3 EEO1](2,3)

	vswp d29, d24
	vswp d31, d26
	//	q14 => [EEO0]
	//	q15	=> [EEO3]
	//	q12 => [EEO2]
	//	q13	=> [EEO1]
	// q0 => [90, 87, 80, 70]
	// q1 => [57, 43, 25,  9]
	// q2 => [83, 36, 75, 89]
	// q3 => [18, 50, 00, 00]
	// calc. 4, 12, 20, 28

	mov lr, #32*2*8
	add r1, r3, #32*2*4

	vmul.s32	q4, q14, d5[1]		// dst[4] = 89*EEO0
	vmul.s32	q5, q14, d5[0]		// dst[12] = 75*EEO0
	vmul.s32	q6, q14, d6[1]		// dst[20] = 50*EEO0
	vmul.s32	q7, q14, d6[0]		// dst[28] = 18*EEO0

	vmla.s32	q4, q13, d5[0]		// dst[4] += 75*EEO1
	vmls.s32	q5, q13, d6[0]		// dst[12]-= 18*EEO1
	vmls.s32	q6, q13, d5[1]		// dst[20]-= 89*EEO1
	vmls.s32	q7, q13, d6[1]		// dst[28]-= 50*EEO1

	vmla.s32	q4, q12, d6[1]		// dst[4] += 50*EEO2
	vmls.s32	q5, q12, d5[1]		// dst[12]-= 89*EEO2
	vmla.s32	q6, q12, d6[0]		// dst[20]+= 18*EEO2
	vmla.s32	q7, q12, d5[0]		// dst[28]+= 75*EEO2

	vmla.s32	q4, q15, d6[0]		// dst[4] += 18*EEO3
	vmls.s32	q5, q15, d6[1]		// dst[12]-= 50*EEO3
	vmla.s32	q6, q15, d5[0]		// dst[20]+= 75*EEO3
	vmls.s32	q7, q15, d5[1]		// dst[28]-= 89*EEO3

	vqrshrn.s32	d8, q4, #11			// d8 => dst[4]
	vqrshrn.s32 d9, q5, #11			// d9 => dst[12]
    vqrshrn.s32	d10, q6, #11		// d10 => dst[20]
    vqrshrn.s32	d11, q7, #11		// d11 => dst[28]

	vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr
	vst1.16 {d10}, [r1], lr
	vst1.16 {d11}, [r1]


	// retrive EO from temp vars(0,1) buffer and EO from stack(2,3)
	add r5, r4, #8*16			// set offset to EO
	vldmia r5, {q12-q15}
	add r5, r4, #24*16
	vldmia r5, {q8-q11}

	//	q12	=> [E00 E02](0,1)
	//	q13	=> [E04 E06](0,1)
	//	q14	=> [E07 E05](0,1)
	//	q15	=> [E03 E01](0,1)

	//	q8	=> [E00 E02](2,3)
	//	q9	=> [E04 E06](2,3)
	//	q10	=> [E07 E05](2,3)
	//	q11	=> [E03 E01](2,3)
	vswp d25, d16
	vswp d27, d18
	vswp d29, d20
	vswp d31, d22
	//	q12	=> [E00]
	//	q13	=> [E04]
	//	q14	=> [E07]
	//	q15	=> [E03]
	//	q8	=> [E02]
	//	q9	=> [E06]
	//	q10	=> [E05]
	//	q11	=> [E01]
	// q0 => [90, 87, 80, 70]
	// q1 => [57, 43, 25,  9]
	// q2 => [83, 36, 75, 89]
	// q3 => [18, 50, 00, 00]
	// calc. 2, 6, 10, 14

	mov lr, #32*2*4
	add r1, r3, #32*2*2

	vmul.s32	q4, q12, d0[0]		//dst[2]  = 90*EO0
	vmul.s32	q5, q12, d0[1]		//dst[6]  = 87*EO0
	vmul.s32	q6, q12, d1[0]		//dst[10] = 80*EO0
	vmul.s32	q8, q12, d1[1]		//dst[14] = 70*EO0

	vmla.s32	q4, q11, d0[1]		//dst[2] += 87*EO1
	vmla.s32	q5, q11, d2[0]		//dst[6] += 57*EO1
	vmla.s32	q6, q11, d3[1]		//dst[10]+=  9*EO1
	vmls.s32	q8, q11, d2[1]		//dst[14]-= 43*EO1

	vmla.s32	q4, q8, d1[0]		//dst[2] += 80*EO2
	vmla.s32	q5, q8, d3[1]		//dst[6] +=  9*EO2
	vmls.s32	q6, q8, d1[1]		//dst[10]-= 70*EO2
	vmls.s32	q8, q8, d0[1]		//dst[14]-= 87*EO2

	vmla.s32	q4, q15, d1[1]		//dst[2] += 70*EO3
	vmls.s32	q5, q15, d2[1]		//dst[6] -= 43*EO3
	vmls.s32	q6, q15, d0[1]		//dst[10]-= 87*EO3
	vmla.s32	q8, q15, d3[1]		//dst[14]+=  9*EO3

	vmla.s32	q4, q13, d2[0]		//dst[2] += 57*EO4
	vmls.s32	q5, q13, d1[0]		//dst[6] -= 80*EO4
	vmls.s32	q6, q13, d3[0]		//dst[10]-= 25*EO4
	vmla.s32	q8, q13, d0[0]		//dst[14]+= 90*EO4

	vmla.s32	q4, q10, d2[1]		//dst[2] += 43*EO5
	vmls.s32	q5, q10, d0[0]		//dst[6] -= 90*EO5
	vmla.s32	q6, q10, d2[0]		//dst[10]+= 57*EO5
	vmla.s32	q8, q10, d3[0]		//dst[14]+= 25*EO5

	vmla.s32	q4, q9, d3[0]		//dst[2] += 25*EO6
	vmls.s32	q5, q9, d1[1]		//dst[6] -= 70*EO6
	vmla.s32	q6, q9, d0[0]		//dst[10]+= 90*EO6
	vmls.s32	q8, q9, d1[0]		//dst[14]-= 80*EO6

	vmla.s32	q4, q14, d3[1]		//dst[2] +=  9*EO7
	vmls.s32	q5, q14, d3[0]		//dst[6] -= 25*EO7
	vmla.s32	q6, q14, d2[1]		//dst[10]+= 43*EO7
	vmls.s32	q8, q14, d2[0]		//dst[14]-= 57*EO7

	vqrshrn.s32	d8, q4, #11			// d8 => dst[2]
	vqrshrn.s32 d9, q5, #11			// d9 => dst[6]
    vqrshrn.s32	d10, q6, #11		// d10 => dst[10]
    vqrshrn.s32	d11, q7, #11		// d11 => dst[14]

	vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr
	vst1.16 {d10}, [r1], lr
	vst1.16 {d11}, [r1], lr

	vmul.s32	q4, q12, d2[0]		//dst[18] = 57*EO0
	vmul.s32	q5, q12, d2[1]		//dst[22] = 43*EO0
	vmul.s32	q6, q12, d3[0]		//dst[26] = 25*EO0
	vmul.s32	q7, q12, d3[1]		//dst[30] =  9*EO0

	vmls.s32	q4, q11, d1[0]		//dst[18] -= 80*EO1
	vmls.s32	q5, q11, d0[0]		//dst[22] -= 90*EO1
	vmls.s32	q6, q11, d1[1]		//dst[26] -= 70*EO1
	vmls.s32	q7, q11, d3[0]		//dst[30] -= 25*EO1

	vmls.s32	q4, q8, d3[0]		//dst[18] -= 25*EO2
	vmla.s32	q5, q8, d2[0]		//dst[22] += 57*EO2
	vmla.s32	q6, q8, d0[0]		//dst[26] += 90*EO2
	vmla.s32	q7, q8, d2[1]		//dst[30] += 43*EO2

	vmla.s32	q4, q15, d0[0]		//dst[18] += 90*EO3
	vmla.s32	q5, q15, d3[0]		//dst[22] += 25*EO3
	vmls.s32	q6, q15, d1[0]		//dst[26] -= 80*EO3
	vmls.s32	q7, q15, d2[0]		//dst[30] -= 57*EO3

	vmls.s32	q4, q13, d3[1]		//dst[18] -=  9*EO4
	vmls.s32	q5, q13, d0[1]		//dst[22] -= 87*EO4
	vmla.s32	q6, q13, d2[1]		//dst[26] += 43*EO4
	vmla.s32	q7, q13, d1[1]		//dst[30] += 70*EO4

	vmls.s32	q4, q10, d0[1]		//dst[18] -= 87*EO5
	vmla.s32	q5, q10, d1[1]		//dst[22] += 70*EO5
	vmla.s32	q6, q10, d3[1]		//dst[26] +=  9*EO5
	vmls.s32	q7, q10, d1[0]		//dst[30] -= 80*EO5

	vmla.s32	q4, q9, d2[1]		//dst[18] += 43*EO6
	vmla.s32	q5, q9, d3[1]		//dst[22] +=  9*EO6
	vmls.s32	q6, q9, d2[0]		//dst[26] -= 57*EO6
	vmla.s32	q7, q9, d0[1]		//dst[30] += 87*EO6

	vmla.s32	q4, q14, d1[1]		//dst[18] += 70*EO7
	vmls.s32	q5, q14, d1[0]		//dst[22] -= 80*EO7
	vmla.s32	q6, q14, d0[1]		//dst[26] += 87*EO7
	vmls.s32	q7, q14, d0[0]		//dst[30] -= 90*EO7

	vqrshrn.s32	d8, q4, #11			// d8 => dst[18]
	vqrshrn.s32 d9, q5, #11			// d9 => dst[22]
    vqrshrn.s32	d10, q6, #11		// d10 => dst[26]
    vqrshrn.s32	d11, q7, #11		// d11 => dst[30]

	vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr
	vst1.16 {d10}, [r1], lr
	vst1.16 {d11}, [r1], lr

	// and now the sorcery...again :/
	// retrive O from temp vars(0,1) buffer and O from stack(2,3)
	mov r5, r4					// set temp buffer iterator to O
	vldmia r5, {q0-q7}
	add r5, r4, #16*16
	vldmia r5, {q8-q15}

	// (2,3)
	//	q8	=> [O0 O2]
    //  q9  => [O4 O6]
    //	q10	=> [O8 O10]
    //  q11 => [O12 O14]
    //	q12 => [O15 O13]
    //  q13 => [O11 O9]
    //	q14 => [O7 O5]
    //  q15 => [O3 O1]
	vswp d1, d16
	vswp d3, d18
	vswp d5, d20
	vswp d7, d22
	vswp d9, d24
	vswp d11, d26
	vswp d13, d28
	vswp d15, d30

	vswp q6, q13
	vswp q7, q12
	vswp q0, q11
	vswp q1, q10

	// q0-q7 => O[14 10 8 12 15 11 9 13]
	// q8-q15=> O[2 6 4 0 3 7 5 1]

	// make some room for calculation
	add r5, r4, #8*16
	vstmia r4, {q0-q7}

	// load coeffs
	// q0 => [90, 88, 85, 82]
	// q1 => [78, 73, 67, 61]
	// q2 => [54, 46, 38, 31]
	// q3 => [22, 13,  4, 00]
	adrl	lr, c2
	vld1.32 {d0-d3}, [lr]!
	vld1.32 {d4-d7}, [lr]!

	// store offset and stride
	mov lr, #32*2*2
	add r1, r3, #32*2*1
	pldw [r5]
	pld [r4]
	// free regs q5-q7
	vmul.s32	q4, q11, d0[0]		//dst[1] = 90*O0
	vmul.s32	q5, q11, d0[0]		//dst[3] = 90*O0
	vmul.s32	q6, q11, d0[1]		//dst[5] = 88*O0
	vmul.s32	q7, q11, d1[0]		//dst[7] = 85*O0

	vmla.s32	q4, q15, d0[0]		//dst[1] += 90*O1
	vmla.s32	q5, q15, d1[1]		//dst[3] += 82*O1
	vmla.s32	q6, q15, d3[0]		//dst[5] += 67*O1
	vmla.s32	q7, q15, d4[1]		//dst[7] += 46*O1

	vmla.s32	q4, q8, d0[1]		//dst[1] += 88*O2
	vmla.s32	q5, q8, d3[0]		//dst[3] += 67*O2
	vmla.s32	q6, q8, d5[1]		//dst[5] += 31*O2
	vmls.s32	q7, q8, d6[1]		//dst[7] -= 13*O2

	vmla.s32	q4, q12, d1[0]		//dst[1] += 85*O3
	vmla.s32	q5, q12, d4[1]		//dst[3] += 46*O3
	vmls.s32	q6, q12, d6[1]		//dst[5] -= 13*O3
	vmls.s32	q7, q12, d3[0]		//dst[7] -= 67*O3

	vmla.s32	q4, q10, d1[1]		//dst[1] += 82*O4
	vmla.s32	q5, q10, d6[0]		//dst[3] += 22*O4
	vmls.s32	q6, q10, d4[0]		//dst[5] -= 54*O4
	vmls.s32	q7, q10, d0[0]		//dst[7] -= 90*O4

	vmla.s32	q4, q14, d2[0]		//dst[1] += 78*O5
	vmls.s32	q5, q14, d7[0]		//dst[3] -=  4*O5
	vmls.s32	q6, q14, d1[1]		//dst[5] -= 82*O5
	vmls.s32	q7, q14, d2[1]		//dst[7] -= 73*O5

	vmla.s32	q4, q9, d2[1]		//dst[1] += 73*O6
	vmls.s32	q5, q9, d5[1]		//dst[3] -= 31*O6
	vmls.s32	q6, q9, d0[0]		//dst[5] -= 90*O6
	vmls.s32	q7, q9, d6[0]		//dst[7] -= 22*O6

	vmla.s32	q4, q13, d3[0]		//dst[1] += 67*O7
	vmls.s32	q5, q13, d4[0]		//dst[3] -= 54*O7
	vmls.s32	q6, q13, d2[0]		//dst[5] -= 78*O7
	vmla.s32	q7, q13, d5[0]		//dst[7] += 38*O7

	// switch out vars
	vstmia r5, {q8-q15}
	vldmia r4, {q8-q15}
	pld [r5]

	vmla.s32	q4, q10, d3[1]		//dst[1] += 61*O8
	vmls.s32	q5, q10, d2[1]		//dst[3] -= 73*O8
	vmls.s32	q6, q10, d4[1]		//dst[5] -= 46*O8
	vmla.s32	q7, q10, d1[1]		//dst[7] += 82*O8

	vmla.s32	q4, q14, d4[0]		//dst[1] += 54*O9
	vmls.s32	q5, q14, d1[0]		//dst[3] -= 85*O9
	vmls.s32	q6, q14, d7[0]		//dst[5] -=  4*O9
	vmla.s32	q7, q14, d0[1]		//dst[7] += 88*O9

	vmla.s32	q4, q9, d4[1]		//dst[1] += 46*O10
	vmls.s32	q5, q9, d0[0]		//dst[3] -= 90*O10
	vmla.s32	q6, q9, d5[0]		//dst[5] += 38*O10
	vmla.s32	q7, q9, d4[0]		//dst[7] += 54*O10

	vmla.s32	q4, q13, d5[0]		//dst[1] += 38*O11
	vmls.s32	q5, q13, d0[1]		//dst[3] -= 88*O11
	vmla.s32	q6, q13, d2[1]		//dst[5] += 73*O11
	vmls.s32	q7, q13, d7[0]		//dst[7] -=  4*O11

	vmla.s32	q4, q11, d5[1]		//dst[1] += 31*O12
	vmls.s32	q5, q11, d2[0]		//dst[3] -= 78*O12
	vmla.s32	q6, q11, d0[0]		//dst[5] += 90*O12
	vmls.s32	q7, q11, d3[1]		//dst[7] -= 61*O12

	vmla.s32	q4, q15, d6[0]		//dst[1] += 22*O13
	vmls.s32	q5, q15, d3[1]		//dst[3] -= 61*O13
	vmla.s32	q6, q15, d1[0]		//dst[5] += 85*O13
	vmls.s32	q7, q15, d0[0]		//dst[7] -= 90*O13

	vmla.s32	q4, q8, d6[1]		//dst[1] += 13*O14
	vmls.s32	q5, q8, d5[0]		//dst[3] -= 38*O14
	vmla.s32	q6, q8, d3[1]		//dst[5] += 61*O14
	vmls.s32	q7, q8, d2[0]		//dst[7] -= 78*O14

	vmla.s32	q4, q12, d7[0]		//dst[1] +=  4*O15
	vmls.s32	q5, q12, d6[1]		//dst[3] -= 13*O15
	vmla.s32	q6, q12, d6[0]		//dst[5] += 22*O15
	vmls.s32	q7, q12, d5[1]		//dst[7] -= 31*O15

	vqrshrn.s32	d8, q4, #11			// d8 => dst[1]
	vqrshrn.s32 d9, q5, #11			// d9 => dst[3]
    vqrshrn.s32	d10, q6, #11		// d10 => dst[5]
    vqrshrn.s32	d11, q7, #11		// d11 => dst[7]

	vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr
	vst1.16 {d10}, [r1], lr
	vst1.16 {d11}, [r1], lr


	// load O0-O7
	vldmia r5, {q8-q15}
	pld [r4]

	vmul.s32	q4, q11, d1[1]		//dst[9]  = 82*O0
	vmul.s32	q5, q11, d2[0]		//dst[11] = 78*O0
	vmul.s32	q6, q11, d2[1]		//dst[13] = 73*O0
	vmul.s32	q7, q11, d3[0]		//dst[15] = 67*O0

	vmla.s32	q4, q15, d6[0]		//dst[9]  += 22*O1
	vmls.s32	q5, q15, d7[0]		//dst[11] -=  4*O1
	vmls.s32	q6, q15, d5[1]		//dst[13] -= 31*O1
	vmls.s32	q7, q15, d4[0]		//dst[15] -= 54*O1

	vmls.s32	q4, q8, d4[0]		//dst[9]  -= 54*O2
	vmls.s32	q5, q8, d1[1]		//dst[11] -= 82*O2
	vmls.s32	q6, q8, d0[0]		//dst[13] -= 90*O2
	vmls.s32	q7, q8, d2[0]		//dst[15] -= 78*O2

	vmls.s32	q4, q12, d0[0]		//dst[9]  -= 90*O3
	vmls.s32	q5, q12, d2[1]		//dst[11] -= 73*O3
	vmls.s32	q6, q12, d6[0]		//dst[13] -= 22*O3
	vmla.s32	q7, q12, d5[0]		//dst[15] += 38*O3

	vmls.s32	q4, q10, d3[1]		//dst[9]  -= 61*O4
	vmla.s32	q5, q10, d6[1]		//dst[11] += 13*O4
	vmla.s32	q6, q10, d2[0]		//dst[13] += 78*O4
	vmla.s32	q7, q10, d1[0]		//dst[15] += 85*O4

	vmla.s32	q4, q14, d6[1]		//dst[9]  += 13*O5
	vmla.s32	q5, q14, d1[0]		//dst[11] += 85*O5
	vmla.s32	q6, q14, d3[0]		//dst[13] += 67*O5
	vmls.s32	q7, q14, d6[0]		//dst[15] -= 22*O5

	vmla.s32	q4, q9, d2[0]		//dst[9]  += 78*O6
	vmla.s32	q5, q9, d3[0]		//dst[11] += 67*O6
	vmls.s32	q6, q9, d5[0]		//dst[13] -= 38*O6
	vmls.s32	q7, q9, d0[0]		//dst[15] -= 90*O6

	vmla.s32	q4, q13, d1[0]		//dst[9]  += 85*O7
	vmls.s32	q5, q13, d6[0]		//dst[11] -= 22*O7
	vmls.s32	q6, q13, d0[0]		//dst[13] -= 90*O7
	vmla.s32	q7, q13, d7[0]		//dst[15] +=  4*O7

	// load O8-O15
	vldmia r4, {q8-q15}
	pld [r5]

	vmla.s32	q4, q10, d5[1]		//dst[9]  += 31*O8
	vmls.s32	q5, q10, d0[1]		//dst[11] -= 88*O8
	vmls.s32	q6, q10, d6[1]		//dst[13] -= 13*O8
	vmla.s32	q7, q10, d0[0]		//dst[15] += 90*O8

	vmls.s32	q4, q14, d4[1]		//dst[9]  -= 46*O9
	vmls.s32	q5, q14, d3[1]		//dst[11] -= 61*O9
	vmla.s32	q6, q14, d1[1]		//dst[13] += 82*O9
	vmla.s32	q7, q14, d6[1]		//dst[15] += 13*O9

	vmls.s32	q4, q9, d0[0]		//dst[9]  -= 90*O10
	vmla.s32	q5, q9, d5[1]		//dst[11] += 31*O10
	vmla.s32	q6, q9, d3[1]		//dst[13] += 61*O10
	vmls.s32	q7, q9, d0[1]		//dst[15] -= 88*O10

	vmls.s32	q4, q13, d3[0]		//dst[9]  -= 67*O11
	vmla.s32	q5, q13, d0[0]		//dst[11] += 90*O11
	vmls.s32	q6, q13, d4[1]		//dst[13] -= 46*O11
	vmls.s32	q7, q13, d5[1]		//dst[15] -= 31*O11

	vmla.s32	q4, q11, d7[0]		//dst[9]  +=  4*O12
	vmla.s32	q5, q11, d4[0]		//dst[11] += 54*O12
	vmls.s32	q6, q11, d0[1]		//dst[13] -= 88*O12
	vmla.s32	q7, q11, d1[1]		//dst[15] += 82*O12

	vmla.s32	q4, q15, d2[1]		//dst[9]  += 73*O13
	vmls.s32	q5, q15, d5[0]		//dst[11] -= 38*O13
	vmls.s32	q6, q15, d7[0]		//dst[13] -=  4*O13
	vmla.s32	q7, q15, d4[1]		//dst[15] += 46*O13

	vmla.s32	q4, q8, d0[1]		//dst[9]  += 88*O14
	vmls.s32	q5, q8, d0[0]		//dst[11] -= 90*O14
	vmla.s32	q6, q8, d1[0]		//dst[13] += 85*O14
	vmls.s32	q7, q8, d2[1]		//dst[15] -= 73*O14

	vmla.s32	q4, q12, d5[0]		//dst[9]  += 38*O15
	vmls.s32	q5, q12, d4[1]		//dst[11] -= 46*O15
	vmla.s32	q6, q12, d4[0]		//dst[13] += 54*O15
	vmls.s32	q7, q12, d3[1]		//dst[15] -= 61*O15

	vqrshrn.s32	d8, q4, #11			// d8 => dst[9]
	vqrshrn.s32 d9, q5, #11			// d9 => dst[11]
    vqrshrn.s32	d10, q6, #11		// d10 => dst[13]
    vqrshrn.s32	d11, q7, #11		// d11 => dst[15]

	vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr
	vst1.16 {d10}, [r1], lr
	vst1.16 {d11}, [r1], lr

	// load O0-O7
	vldmia r5, {q8-q15}
	pld [r4]

	// calculate rows 17, 19, 21, 23 in parallel
	vmul.s32	q4, q11, d3[1]		//dst[17] = 61*O0
	vmul.s32	q5, q11, d4[0]		//dst[19] = 54*O0
	vmul.s32	q6, q11, d4[1]		//dst[21] = 46*O0
	vmul.s32	q7, q11, d5[0]		//dst[23] = 38*O0

	vmls.s32	q4, q15, d2[1]		//dst[17] -= 73*O1
	vmls.s32	q5, q15, d1[0]		//dst[19] -= 85*O1
	vmls.s32	q6, q15, d0[0]		//dst[21] -= 90*O1
	vmls.s32	q7, q15, d0[1]		//dst[23] -= 88*O1

	vmls.s32	q4, q8, d4[1]		//dst[17] -= 46*O2
	vmls.s32	q5, q8, d7[0]		//dst[19] -=  4*O2
	vmla.s32	q6, q8, d5[0]		//dst[21] += 38*O2
	vmla.s32	q7, q8, d2[1]		//dst[23] += 73*O2

	vmla.s32	q4, q12, d1[1]		//dst[17] += 82*O3
	vmla.s32	q5, q12, d0[1]		//dst[19] += 88*O3
	vmla.s32	q6, q12, d4[0]		//dst[21] += 54*O3
	vmls.s32	q7, q12, d7[0]		//dst[23] -=  4*O3

	vmla.s32	q4, q10, d5[1]		//dst[17] += 31*O4
	vmls.s32	q5, q10, d4[1]		//dst[19] -= 46*O4
	vmls.s32	q6, q10, d0[0]		//dst[21] -= 90*O4
	vmls.s32	q7, q10, d3[0]		//dst[23] -= 67*O4

	vmls.s32	q4, q14, d0[1]		//dst[17] -= 88*O5
	vmls.s32	q5, q14, d3[1]		//dst[19] -= 61*O5
	vmla.s32	q6, q14, d5[1]		//dst[21] += 31*O5
	vmla.s32	q7, q14, d0[0]		//dst[23] += 90*O5

	vmls.s32	q4, q9, d6[1]		//dst[17] -= 13*O6
	vmla.s32	q5, q9, d1[1]		//dst[19] += 82*O6
	vmla.s32	q6, q9, d3[1]		//dst[21] += 61*O6
	vmls.s32	q7, q9, d4[1]		//dst[23] -= 46*O6

	vmla.s32	q4, q13, d0[0]		//dst[17] += 90*O7
	vmla.s32	q5, q13, d6[1]		//dst[19] += 13*O7
	vmls.s32	q6, q13, d0[1]		//dst[21] -= 88*O7
	vmls.s32	q7, q13, d5[1]		//dst[23] -= 31*O7

	// load O8-O15
	vldmia r4, {q8-q15}
	pld [r5]

	vmls.s32	q4, q10, d7[0]		//dst[17] -=  4*O8
	vmls.s32	q5, q10, d0[0]		//dst[19] -= 90*O8
	vmla.s32	q6, q10, d6[0]		//dst[21] += 22*O8
	vmla.s32	q7, q10, d1[0]		//dst[23] += 85*O8

	vmls.s32	q4, q14, d0[0]		//dst[17] -= 90*O9
	vmla.s32	q5, q14, d5[0]		//dst[19] += 38*O9
	vmla.s32	q6, q14, d3[0]		//dst[21] += 67*O9
	vmls.s32	q7, q14, d2[0]		//dst[23] -= 78*O9

	vmla.s32	q4, q9, d6[0]		//dst[17] += 22*O10
	vmla.s32	q5, q9, d3[0]		//dst[19] += 67*O10
	vmls.s32	q6, q9, d1[0]		//dst[21] -= 85*O10
	vmla.s32	q7, q9, d6[1]		//dst[23] += 13*O10

	vmla.s32	q4, q13, d1[0]		//dst[17] += 85*O11
	vmls.s32	q5, q13, d2[0]		//dst[19] -= 78*O11
	vmla.s32	q6, q13, d6[1]		//dst[21] += 13*O11
	vmla.s32	q7, q13, d3[1]		//dst[23] += 61*O11

	vmls.s32	q4, q11, d5[0]		//dst[17] -= 38*O12
	vmls.s32	q5, q11, d6[0]		//dst[19] -= 22*O12
	vmla.s32	q6, q11, d2[1]		//dst[21] += 73*O12
	vmls.s32	q7, q11, d0[0]		//dst[23] -= 90*O12

	vmls.s32	q4, q15, d2[0]		//dst[17] -= 78*O13
	vmla.s32	q5, q15, d0[0]		//dst[19] += 90*O13
	vmls.s32	q6, q15, d1[1]		//dst[21] -= 82*O13
	vmla.s32	q7, q15, d4[0]		//dst[23] += 54*O13

	vmla.s32	q4, q8, d4[0]		//dst[17] += 54*O14
	vmls.s32	q5, q8, d5[1]		//dst[19] -= 31*O14
	vmla.s32	q6, q8, d7[0]		//dst[21] +=  4*O14
	vmla.s32	q7, q8, d6[0]		//dst[23] += 22*O14

	vmla.s32	q4, q12, d3[0]		//dst[17] += 67*O15
	vmls.s32	q5, q12, d2[1]		//dst[19] -= 73*O15
	vmla.s32	q6, q12, d2[0]		//dst[21] += 78*O15
	vmls.s32	q7, q12, d1[1]		//dst[23] -= 82*O15

	vqrshrn.s32	d8, q4, #11			// d8 => dst[17]
	vqrshrn.s32 d9, q5, #11			// d9 => dst[19]
    vqrshrn.s32	d10, q6, #11		// d10 => dst[21]
    vqrshrn.s32	d11, q7, #11		// d11 => dst[23]

	vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr
	vst1.16 {d10}, [r1], lr
	vst1.16 {d11}, [r1], lr

	// load O0-O7
	vldmia r5, {q8-q15}
	pld [r4]

	// calculate rows 25, 27, 29, 31 in parallel
	vmul.s32	q4, q11, d5[1]		//dst[25] = 31*O0
	vmul.s32	q5, q11, d6[0]		//dst[27] = 22*O0
	vmul.s32	q6, q11, d6[1]		//dst[29] = 13*O0
	vmul.s32	q7, q11, d7[0]		//dst[31] =  4*O0

	vmls.s32	q4, q15, d2[0]		//dst[25] -= 78*O1
	vmls.s32	q5, q15, d3[1]		//dst[27] -= 61*O1
	vmls.s32	q6, q15, d5[1]		//dst[29] -= 38*O1
	vmls.s32	q7, q15, d6[1]		//dst[31] -= 13*O1

	vmla.s32	q4, q8, d0[0]		//dst[25] += 90*O2
	vmla.s32	q5, q8, d1[0]		//dst[27] += 85*O2
	vmla.s32	q6, q8, d3[1]		//dst[29] += 61*O2
	vmla.s32	q7, q8, d6[0]		//dst[31] += 22*O2

	vmls.s32	q4, q12, d3[1]		//dst[25] -= 61*O3
	vmls.s32	q5, q12, d0[0]		//dst[27] -= 90*O3
	vmls.s32	q6, q12, d2[0]		//dst[29] -= 78*O3
	vmls.s32	q7, q12, d5[1]		//dst[31] -= 31*O3

	vmla.s32	q4, q10, d7[0]		//dst[25] +=  4*O4
	vmla.s32	q5, q10, d2[1]		//dst[27] += 73*O4
	vmla.s32	q6, q10, d0[1]		//dst[29] += 88*O4
	vmla.s32	q7, q10, d5[0]		//dst[31] += 38*O4

	vmla.s32	q4, q14, d4[0]		//dst[25] += 54*O5
	vmls.s32	q5, q14, d5[0]		//dst[27] -= 38*O5
	vmls.s32	q6, q14, d0[0]		//dst[29] -= 90*O5
	vmls.s32	q7, q14, d4[1]		//dst[31] -= 46*O5

	vmls.s32	q4, q9, d0[1]		//dst[25] -= 88*O6
	vmls.s32	q5, q9, d7[0]		//dst[27] -=  4*O6
	vmla.s32	q6, q9, d1[0]		//dst[29] += 85*O6
	vmla.s32	q7, q9, d4[0]		//dst[31] += 54*O6

	vmla.s32	q4, q13, d1[1]		//dst[25] += 82*O7
	vmla.s32	q5, q13, d4[1]		//dst[27] += 46*O7
	vmls.s32	q6, q13, d2[1]		//dst[29] -= 73*O7
	vmls.s32	q7, q13, d3[1]		//dst[31] -= 61*O7

	// load O8-O15
	vldmia r4, {q8-q15}

	vmls.s32	q4, q10, d5[0]		//dst[25] -= 38*O8
	vmls.s32	q5, q10, d2[0]		//dst[27] -= 78*O8
	vmla.s32	q6, q10, d4[0]		//dst[29] += 54*O8
	vmla.s32	q7, q10, d3[0]		//dst[31] += 67*O8

	vmls.s32	q4, q14, d6[0]		//dst[25] -= 22*O9
	vmla.s32	q5, q14, d0[0]		//dst[27] += 90*O9
	vmls.s32	q6, q14, d5[1]		//dst[29] -= 31*O9
	vmls.s32	q7, q14, d2[1]		//dst[31] -= 73*O9

	vmla.s32	q4, q9, d2[1]		//dst[25] += 73*O10
	vmls.s32	q5, q9, d1[1]		//dst[27] -= 82*O10
	vmla.s32	q6, q9, d7[0]		//dst[29] +=  4*O10
	vmla.s32	q7, q9, d2[0]		//dst[31] += 78*O10

	vmls.s32	q4, q13, d0[0]		//dst[25] -= 90*O11
	vmla.s32	q5, q13, d4[0]		//dst[27] += 54*O11
	vmla.s32	q6, q13, d6[0]		//dst[29] += 22*O11
	vmls.s32	q7, q13, d1[1]		//dst[31] -= 82*O11

	vmla.s32	q4, q11, d3[0]		//dst[25] += 67*O12
	vmls.s32	q5, q11, d6[1]		//dst[27] -= 13*O12
	vmls.s32	q6, q11, d4[1]		//dst[29] -= 46*O12
	vmla.s32	q7, q11, d1[0]		//dst[31] += 85*O12

	vmls.s32	q4, q15, d6[1]		//dst[25] -= 13*O13
	vmls.s32	q5, q15, d5[1]		//dst[27] -= 31*O13
	vmla.s32	q6, q15, d3[0]		//dst[29] += 67*O13
	vmls.s32	q7, q15, d0[1]		//dst[31] -= 88*O13

	vmls.s32	q4, q8, d4[1]		//dst[25] -= 46*O14
	vmla.s32	q5, q8, d3[0]		//dst[27] += 67*O14
	vmls.s32	q6, q8, d1[1]		//dst[29] -= 82*O14
	vmla.s32	q7, q8, d0[0]		//dst[31] += 90*O14

	vmla.s32	q4, q12, d1[0]		//dst[25] += 85*O15
	vmls.s32	q5, q12, d0[1]		//dst[27] -= 88*O15
	vmla.s32	q6, q12, d0[0]		//dst[29] += 90*O15
	vmls.s32	q7, q12, d0[0]		//dst[31] -= 90*O15

	vqrshrn.s32	d8, q4, #11			// d8 => dst[25]
	vqrshrn.s32 d9, q5, #11			// d9 => dst[27]
    vqrshrn.s32	d10, q6, #11		// d10 => dst[29]
    vqrshrn.s32	d11, q7, #11		// d11 => dst[31]

	vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr
	vst1.16 {d10}, [r1], lr
	vst1.16 {d11}, [r1], lr


	// next four columns have to be filled, increment offset
	add r3, #4*2

	subs r2, #1
    bgt .loop2_32x32

	add sp, #32*32*2		// stack buffer between first and second stage
	add sp, #30*16

	vpop	{q4-q7}
	pop	{r4, r5, r6, r7, lr}
	bx lr
	.fnend



