	.globl   transpose
	.align 2
	.type    transpose,%function
transpose:
	.fnstart
    vpush           {d8-d15}
    vld1.s16        {q8,q9}, [r0]!
    vld1.s16        {q10,q11}, [r0]!
    vld1.s16        {q12,q13}, [r0]!
    vld1.s16        {q14,q15}, [r0]!

    // transpose the input data
    vswp            d17, d24
    vswp            d23, d30
    vswp            d21, d28
    vswp            d19, d26
    vtrn.32         q8, q10
    vtrn.32         q9, q11
    vtrn.32         q12, q14
    vtrn.32         q13, q15
    vtrn.16         q8, q9
    vtrn.16         q10, q11
    vtrn.16         q12, q13
    vtrn.16         q14, q15

    vst1.s16        {q8,q9}, [r1]!
    vst1.s16        {q10,q11}, [r1]!
    vst1.s16        {q12,q13}, [r1]!
    vst1.s16        {q14,q15}, [r1]!
    vpop			{d8-d15}
	bx lr
	.fnend

.align 8
c1:	 	 .hword 90, 87, 80, 70,  57, 43, 25,  9
         .hword 83, 36, 75, 89,  18, 50, 00, 00

c2:		 .hword 90, 88, 85, 82,  78, 73, 67, 61
         .hword 54, 46, 38, 31,  22, 13,  4, 00

	.globl   dct32
	.align 2
	.type    dct32,%function
dct32:
	.fnstart
	push {lr}
	vpush	{q4-q7}

	adr	r3, c1
	mov r2, #32/4			// rows counter
	sub sp, #32*32*2		// stack buffer between first and second stage
    mov r12, sp				// buffer pointer
    mov lr, r1


.loop1:
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
    vsub.s16	q8, q0, q4		//	q8	=> [O0 O2 O4 O6]
    vsub.s16	q9, q1, q5		//	q9	=> [O8 O10 O12 O14]
    vsub.s16	q10, q6, q2		//	q10 => [O15 O13 O11 O9]
    vsub.s16	q11, q7, q3		//	q11 => [O7 O5 O3 O1]

    // E
    vadd.s16	q12, q0, q4		//	q12	=> [E0 E2 E4 E6]
    vadd.s16	q13, q1, q5		//	q13	=> [E8 E10 E12 E14]
    vadd.s16	q14, q6, q2		//	q14 => [E15 E13 E11 E9]
    vadd.s16	q15, q7, q3		//	q15 => [E7 E5 E3 E1]

    //	push O to stack for later
    // 	taken regs => q12-q15
    vpush {q8-q11}


	// E0
	vsub.s16	q2, q12, q14	//	q2	=> [E00 E02 E04 E06]
	vsub.s16	q3, q15, q13	//	q3 	=> [E07 E05 E03 E01]

	// EE
	vadd.s16	q0, q12, q14	//	q0	=> [EE0 EE2 EE4 EE6]
	vadd.s16	q1, q15, q13	//	q1 	=> [EE7 EE5 EE3 EE1]

	// push E0 to stack for later
	// taken regs => q0, q1
	vpush {q2, q3}

	// EEE
	vadd.s16	q4, q0, q1		//	q4 	=> [EEE0 EEE2 EEE3 EEE1]

	// EE0
	vsub.s16	d10, d0, d2
	vsub.s16	d11, d3, d1		//	q5	=> [EEO0 EEO2 EEO3 EEO1]

	// push EE0 to stack for later
	// taken regs => q4
	vpush {q5}

	// EEEE & EEEO
	vadd.s16	d12, d8, d9		//	d12	=> [EEEE0 EEEE1]
	vsub.s16	d13, d8, d9		//	d13	=> [EEEO0 EEEO1]

	// push EEEE & EEE0 to stack for later
	// all regs free
	vpush {q6}

	// load next two rows from source so we have 4 values to work on later
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

	// 0 second pair of rows
    vsub.s16	q8, q0, q4		//	q8	=> [O0 O2 O4 O6]
    vsub.s16	q9, q1, q5		//	q9	=> [O8 O10 O12 O14]
    vsub.s16	q10, q6, q2		//	q10 => [O15 O13 O11 O9]
    vsub.s16	q11, q7, q3		//	q11 => [O7 O5 O3 O1]

    // E second pair of rows
    vadd.s16	q12, q0, q4		//	q12	=> [E0 E2 E4 E6]
    vadd.s16	q13, q1, q5		//	q13	=> [E8 E10 E12 E14]
    vadd.s16	q14, q6, q2		//	q14 => [E15 E13 E11 E9]
    vadd.s16	q15, q7, q3		//	q15 => [E7 E5 E3 E1]

	// E0 second pair of rows
	vsub.s16	q2, q12, q14	//	q2	=> [E00 E02 E04 E06]
	vsub.s16	q3, q15, q13	//	q3 	=> [E07 E05 E03 E01]

	// EE second pair of rows
	vadd.s16	q0, q12, q14	//	q0	=> [EE0 EE2 EE4 EE6]
	vadd.s16	q1, q15, q13	//	q1 	=> [EE7 EE5 EE3 EE1]

	// taken regs => q8-q11, q0-q3
	// EEE  second pair of rows
	vadd.s16	q4, q0, q1		//	q4 	=> [EEE0 EEE2 EEE3 EEE1]

	// EE0  second pair of rows
	vsub.s16	d10, d0, d2
	vsub.s16	d11, d3, d1		//	q5	=> [EEO0 EEO2 EEO3 EEO1]

	// taken regs => q8-q11, q2-q3, q5
	// EEEE & EEEO second pair of rows
	vadd.s16	d12, d8, d9		//	d12	=> [EEEE0 EEEE1]
	vsub.s16	d13, d8, d9		//	d13	=> [EEEO0 EEEO1]

	// free regs => q0, q1, q4, q7, q12-q15
	// pop EEEE & EEE0 from previous two rows
	vpop	{q7}

	// q7 => [EEEE0(2,3) EEEE1(2,3) EEEO0(2,3) EEEO1(2,3)]
	// q6 => [EEEE0(0,1) EEEE1(0,1) EEEO0(0,1) EEEO1(0,1)]
	vtrn.32	q7, q6
	// q7 => [EEEE1(0,1) EEEE1(2,3) EEEO1(0,1) EEEO1(2,3)]
	// q6 => [EEEE0(0,1) EEEE0(2,3) EEEO0(0,1) EEEO0(2,3)]

	//load coeffs
	// q0 => [90, 87, 80, 70,  57, 43, 25,  9]
	// q1 => [83, 36, 75, 89,  18, 50, 00, 00]
	vld1.16 {d0-d3}, [r3]
	mov r3, r1

	// 0, 8, 16, 24
	vmull.s16	q12, d13, d2[0]		// dst[8] 	= 83*EEEO0
	vmull.s16	q13, d13, d2[1]		// dst[24]	= 36*EEEO0
	vadd.s16	d8, d12, d14		// dst[0]	= (EEEE0+EEEE1)
	vsub.s16	d9, d12, d14		// dst[16]	= (EEEE0-EEEE1)

	vmlal.s16	q12, d15, d2[1]		// dst[8] 	+= 36*EEEO1
	vmlsl.s16	q13, d15, d2[0]		// dst[24] 	-= 83*EEEO1
	vshll.s16 	q14, d8, #6        	// dst[0]	= (EEE0 + EEE1) * 64
    vshll.s16 	q15, d9, #6        	// dst[16]  = (EEE0 - EEE1) * 64

	mov lr, #32*2*8					// column stride for storing
    vqrshrn.s32	d8, q15, #4			// d8 => dst[16]
    vqrshrn.s32 d9, q13, #4			// d9 => dst[24]
    vqrshrn.s32	d14, q14, #4		// d14=> dst[0]
    vqrshrn.s32	d15, q12, #4		// d15=> dst[8]


	// Store to stack buffer
	// TODO: change to buffer pointer ------------------------------------------
    vst1.16 {d14}, [r1], lr
    vst1.16 {d15}, [r1], lr
    vst1.16 {d8}, [r1], lr
	vst1.16 {d9}, [r1], lr

	// free regs => q12-q15, q4, q7, q6
	// pop to q6
	// q5 => [EEO0(2,3) EEO2(2,3) EEO3(2,3) EEO1(2,3)]
	// q6 => [EEO0(0,1) EEO2(0,1) EEO3(0,1) EEO1(0,1)]
	vpop {q6}

	vtrn.32	q5, q6
	// d10 => [EEO2(0,1) EEO2(2,3)]
	// d11 => [EEO1(0,1) EEO1(2,3)]
	// d12 => [EEO0(0,1) EEO0(2,3)]
	// d13 => [EEO3(0,1) EEO3(2,3)]

	// free regs => q12-q15, q4, q7
	// q0 => [90, 87, 80, 70,  57, 43, 25,  9]
	// q1 => [83, 36, 75, 89,  18, 50, 00, 00]

	// 4, 12, 20, 28
	vmull.s16	q12, d12, d2[3]		// dst[4] = 89*EEO0
	vmull.s16	q13, d12, d2[2]		// dst[12] = 75*EEO0
	vmull.s16	q14, d12, d3[1]		// dst[20] = 50*EEO0
	vmull.s16	q15, d12, d3[0]		// dst[28] = 18*EEO0

	vmlal.s16	q12, d11, d2[2]		// dst[4] += 75*EEO1
	vmlsl.s16	q13, d11, d3[0]		// dst[12]-= 18*EEO1
	vmlsl.s16	q13, d11, d2[3]		// dst[20]-= 89*EEO1
	vmlsl.s16	q13, d11, d3[1]		// dst[28]-= 50*EEO1

	vmlal.s16	q12, d10, d3[1]		// dst[4] += 50*EEO2
	vmlsl.s16	q13, d10, d2[3]		// dst[12]-= 89*EEO2
	vmlal.s16	q14, d10, d3[0]		// dst[20]+= 18*EEO2
	vmlal.s16	q15, d10, d2[2]		// dst[28]+= 75*EEO2

	vmlal.s16	q12, d10, d3[0]		// dst[4] += 18*EEO3
	vmlsl.s16	q13, d10, d3[1]		// dst[12]-= 50*EEO3
	vmlal.s16	q14, d10, d2[2]		// dst[20]+= 75*EEO3
	vmlsl.s16	q15, d10, d2[3]		// dst[28]-= 89*EEO3

	mov r1, r3
	add r1, #32*2*4					// start from row 4
	mov lr, #32*2*8					// column stride for storing
    vqrshrn.s32	d8, q12, #4			// d8 => dst[4]
    vqrshrn.s32 d9, q13, #4			// d9 => dst[12]
    vqrshrn.s32	d14, q14, #4		// d14 => dst[20]
    vqrshrn.s32	d15, q15, #4		// d15 => dst[28]

	vst1.16	{d8}, [r1], lr
	vst1.16	{d9}, [r1], lr
	vst1.16	{d14}, [r1], lr
	vst1.16	{d15}, [r1], lr

	// free regs => q12-q15, q4-q7
	vpop {q4, q5}
	//	q2	=> [E00(2,3) E02(2,3) E04(2,3) E06(2,3)]
	//	q3 	=> [E07(2,3) E05(2,3) E03(2,3) E01(2,3)]
	//	q4	=> [E00(0,1) E02(0,1) E04(0,1) E06(0,1)]
	//	q5 	=> [E07(0,1) E05(0,1) E03(0,1) E01(0,1)]


	vtrn.32 q2, q4
	vtrn.32 q3, q5
	// d4 => [EO2] d5 => [EO6]
	// d6 => [EO5] d7 => [EO1]
	// d8 => [EO0] d9 => [EO4]
	// d10=> [EO7] d11=> [EO3]
	// q0 => [90, 87, 80, 70,  57, 43, 25,  9]
	// q1 => [83, 36, 75, 89,  18, 50, 00, 00]

	vmull.s16	q12, d8, d0[0]		//dst[2]  = 90*EO0
	vmull.s16	q13, d8, d0[1]		//dst[6]  = 87*EO0
	vmull.s16	q14, d8, d0[2]		//dst[10] = 80*EO0
	vmull.s16	q15, d8, d0[3]		//dst[14] = 70*EO0

	vmlal.s16	q12, d7, d0[1]		//dst[2] += 87*EO1
	vmlal.s16	q13, d7, d1[0]		//dst[6] += 57*EO1
	vmlal.s16	q14, d7, d1[3]		//dst[10]+=  9*EO1
	vmlsl.s16	q15, d7, d1[1]		//dst[14]-= 43*EO1

	vmlal.s16	q12, d4, d0[2]		//dst[2] += 80*EO2
	vmlal.s16	q13, d4, d1[3]		//dst[6] +=  9*EO2
	vmlsl.s16	q14, d4, d0[3]		//dst[10]-= 70*EO2
	vmlsl.s16	q15, d4, d0[1]		//dst[14]-= 87*EO2

	vmlal.s16	q12, d11, d0[3]		//dst[2] += 70*EO3
	vmlsl.s16	q13, d11, d1[1]		//dst[6] -= 43*EO3
	vmlsl.s16	q14, d11, d0[1]		//dst[10]-= 87*EO3
	vmlal.s16	q15, d11, d1[3]		//dst[14]+=  9*EO3

	vmlal.s16	q12, d9, d1[0]		//dst[2] += 57*EO4
	vmlsl.s16	q13, d9, d0[2]		//dst[6] -= 80*EO4
	vmlsl.s16	q14, d9, d1[2]		//dst[10]-= 25*EO4
	vmlal.s16	q15, d9, d0[0]		//dst[14]+= 90*EO4

	vmlal.s16	q12, d6, d1[1]		//dst[2] += 43*EO5
	vmlsl.s16	q13, d6, d0[0]		//dst[6] -= 90*EO5
	vmlal.s16	q14, d6, d1[0]		//dst[10]+= 57*EO5
	vmlal.s16	q15, d6, d1[2]		//dst[14]+= 25*EO5


	vmlal.s16	q12, d5, d1[2]		//dst[2] += 25*EO6
	vmlsl.s16	q13, d5, d0[3]		//dst[6] -= 70*EO6
	vmlal.s16	q14, d5, d0[0]		//dst[10]+= 90*EO6
	vmlsl.s16	q15, d5, d0[2]		//dst[14]-= 80*EO6

	vmlal.s16	q12, d10, d1[3]		//dst[2] +=  9*EO7
	vmlsl.s16	q13, d10, d1[2]		//dst[6] -= 25*EO7
	vmlal.s16	q14, d10, d1[1]		//dst[10]+= 43*EO7
	vmlsl.s16	q15, d10, d1[0]		//dst[14]-= 57*EO7

	vqrshrn.s32	d12, q12, #4		// d12 => dst[2]
    vqrshrn.s32 d13, q13, #4		// d13 => dst[6]
    vqrshrn.s32	d14, q14, #4		// d14 => dst[10]
    vqrshrn.s32	d15, q15, #4		// d15 => dst[14]

	mov r1, r3
	add r1, #32*2*2					// start from row 2
	mov lr, #32*2*4					// column stride for storing

	vst1.16	{d12}, [r1], lr
	vst1.16	{d13}, [r1], lr
	vst1.16	{d14}, [r1], lr
	vst1.16	{d15}, [r1], lr


	vmull.s16	q12, d8, d1[0]		//dst[18] = 57*EO0
	vmull.s16	q13, d8, d1[1]		//dst[22] = 43*EO0
	vmull.s16	q14, d8, d1[2]		//dst[26] = 25*EO0
	vmull.s16	q15, d8, d1[3]		//dst[30] =  9*EO0

	vmlsl.s16	q12, d7, d0[2]		//dst[18] -= 80*EO1
	vmlsl.s16	q13, d7, d0[0]		//dst[22] -= 90*EO1
	vmlsl.s16	q14, d7, d0[3]		//dst[26] -= 70*EO1
	vmlsl.s16	q15, d7, d1[2]		//dst[30] -= 25*EO1

	vmlsl.s16	q12, d4, d1[2]		//dst[18] -= 25*EO2
	vmlal.s16	q13, d4, d1[0]		//dst[22] += 57*EO2
	vmlal.s16	q14, d4, d0[0]		//dst[26] += 90*EO2
	vmlal.s16	q15, d4, d1[1]		//dst[30] += 43*EO2

	vmlal.s16	q12, d11, d0[0]		//dst[18] += 90*EO3
	vmlal.s16	q13, d11, d1[2]		//dst[22] += 25*EO3
	vmlsl.s16	q14, d11, d0[2]		//dst[26] -= 80*EO3
	vmlsl.s16	q15, d11, d1[0]		//dst[30] -= 57*EO3

	vmlsl.s16	q12, d9, d1[3]		//dst[18] -=  9*EO4
	vmlsl.s16	q13, d9, d0[1]		//dst[22] -= 87*EO4
	vmlal.s16	q14, d9, d1[1]		//dst[26] += 43*EO4
	vmlal.s16	q15, d9, d0[3]		//dst[30] += 70*EO4

	vmlsl.s16	q12, d6, d0[1]		//dst[18] -= 87*EO5
	vmlal.s16	q13, d6, d0[3]		//dst[22] += 70*EO5
	vmlal.s16	q14, d6, d1[3]		//dst[26] +=  9*EO5
	vmlsl.s16	q15, d6, d0[2]		//dst[30] -= 80*EO5


	vmlal.s16	q12, d5, d1[1]		//dst[18] += 43*EO6
	vmlal.s16	q13, d5, d1[3]		//dst[22] +=  9*EO6
	vmlsl.s16	q14, d5, d1[0]		//dst[26] -= 57*EO6
	vmlal.s16	q15, d5, d0[1]		//dst[30] += 87*EO6

	vmlal.s16	q12, d10, d0[3]		//dst[18] += 70*EO7
	vmlsl.s16	q13, d10, d0[2]		//dst[22] -= 80*EO7
	vmlal.s16	q14, d10, d0[1]		//dst[26] += 87*EO7
	vmlsl.s16	q15, d10, d0[0]		//dst[30] -= 90*EO7

	// free regs => q12-q15, q2-q7

	vqrshrn.s32	d12, q12, #4		// d12 => dst[18]
    vqrshrn.s32 d13, q13, #4		// d13 => dst[22]
    vqrshrn.s32	d14, q14, #4		// d14 => dst[26]
    vqrshrn.s32	d15, q15, #4		// d15 => dst[30]

    vst1.16	{d12}, [r1], lr
	vst1.16	{d13}, [r1], lr
	vst1.16	{d14}, [r1], lr
	vst1.16	{d15}, [r1], lr

//****************CHECKPOINT - up to this point everything is checked and working fine

	// free regs => q12-q15, q2-q7
	vpop {q4-q7}
	// (0,1)
	//	q4	=> [O0	O2	O4	O6]
    //	q5	=> [O8	O10	O12	O14]
    //	q6 	=> [O15	O13	O11	O9]
    //	q7 	=> [O7	O5	O3	O1]
    // (2,3)
	//	q8	=> [O0	O2	O4	O6]
    //	q9	=> [O8	O10	O12	O14]
    //	q10 => [O15	O13	O11	O9]
    //	q11 => [O7	O5	O3	O1]

	vtrn.32 q4, q8
	vtrn.32 q5, q9
	vtrn.32 q6, q10
	vtrn.32 q7, q11
	//	q4	=> [O0	O4]
	//	q8	=> [O2	O6]
	//	q5	=> [O8	O12]
	//	q9	=> [O10	O14]
	//	q6 	=> [O15	O11]
	//	q10 => [O13	O9]
	//	q7 	=> [O7	O3]
	//	q11 => [O5	O1]

	// here comes the fucking sorcery ;)

	//load coeffs
	// q0 => [90, 88, 85, 82,  78, 73, 67, 61]
	// q1 => [54, 46, 38, 31,  22, 13,  4, 00]
	adr lr, c2
	vld1.16 {d0-d3}, [lr]

	// free regs => q12-q15, q2, q3
	// calculate rows 1, 3, 5, 7 in parallel
	mov r1, r3
	add r1, #32*2*1					// start from row 1
	mov lr, #32*2*2					// column stride for storing

	vmull.s16	q12, d8, d0[0]		//dst[1] = 90*O0
	vmull.s16	q13, d8, d0[0]		//dst[3] = 90*O0
	vmull.s16	q14, d8, d0[1]		//dst[5] = 88*O0
	vmull.s16	q15, d8, d0[2]		//dst[7] = 85*O0

	vmlal.s16	q12, d23, d0[0]		//dst[1] += 90*O1
	vmlal.s16	q13, d23, d0[3]		//dst[3] += 82*O1
	vmlal.s16	q14, d23, d1[2]		//dst[5] += 67*O1
	vmlal.s16	q15, d23, d2[1]		//dst[7] += 46*O1

	vmlal.s16	q12, d16, d0[1]		//dst[1] += 88*O2
	vmlal.s16	q13, d16, d1[2]		//dst[3] += 67*O2
	vmlal.s16	q14, d16, d2[3]		//dst[5] += 31*O2
	vmlsl.s16	q15, d16, d3[1]		//dst[7] -= 13*O2

	vmlal.s16	q12, d15, d0[2]		//dst[1] += 85*O3
	vmlal.s16	q13, d15, d2[1]		//dst[3] += 46*O3
	vmlsl.s16	q14, d15, d3[1]		//dst[5] -= 13*O3
	vmlsl.s16	q15, d15, d1[2]		//dst[7] -= 67*O3

	vmlal.s16	q12, d9, d0[3]		//dst[1] += 82*O4
	vmlal.s16	q13, d9, d3[0]		//dst[3] += 22*O4
	vmlsl.s16	q14, d9, d2[0]		//dst[5] -= 54*O4
	vmlsl.s16	q15, d9, d0[0]		//dst[7] -= 90*O4

	vmlal.s16	q12, d22, d1[0]		//dst[1] += 78*O5
	vmlsl.s16	q13, d22, d3[2]		//dst[3] -=  4*O5
	vmlsl.s16	q14, d22, d0[3]		//dst[5] -= 82*O5
	vmlsl.s16	q15, d22, d1[1]		//dst[7] -= 73*O5

	vmlal.s16	q12, d17, d1[1]		//dst[1] += 73*O6
	vmlsl.s16	q13, d17, d2[3]		//dst[3] -= 31*O6
	vmlsl.s16	q14, d17, d0[0]		//dst[5] -= 90*O6
	vmlsl.s16	q15, d17, d3[0]		//dst[7] -= 22*O6

	vmlal.s16	q12, d14, d1[2]		//dst[1] += 67*O7
	vmlsl.s16	q13, d14, d2[0]		//dst[3] -= 54*O7
	vmlsl.s16	q14, d14, d1[0]		//dst[5] -= 78*O7
	vmlal.s16	q15, d14, d2[2]		//dst[7] += 38*O7

	vmlal.s16	q12, d10, d1[3]		//dst[1] += 61*O8
	vmlsl.s16	q13, d10, d1[1]		//dst[3] -= 73*O8
	vmlsl.s16	q14, d10, d2[1]		//dst[5] -= 46*O8
	vmlal.s16	q15, d10, d0[3]		//dst[7] += 82*O8

	vmlal.s16	q12, d21, d2[0]		//dst[1] += 54*O9
	vmlsl.s16	q13, d21, d0[2]		//dst[3] -= 85*O9
	vmlsl.s16	q14, d21, d3[2]		//dst[5] -=  4*O9
	vmlal.s16	q15, d21, d0[1]		//dst[7] += 88*O9

	vmlal.s16	q12, d18, d2[1]		//dst[1] += 46*O10
	vmlsl.s16	q13, d18, d0[0]		//dst[3] -= 90*O10
	vmlal.s16	q14, d18, d2[2]		//dst[5] += 38*O10
	vmlal.s16	q15, d18, d2[0]		//dst[7] += 54*O10

	vmlal.s16	q12, d13, d2[2]		//dst[1] += 38*O11
	vmlsl.s16	q13, d13, d0[1]		//dst[3] -= 88*O11
	vmlal.s16	q14, d13, d1[1]		//dst[5] += 73*O11
	vmlsl.s16	q15, d13, d3[2]		//dst[7] -=  4*O11

	vmlal.s16	q12, d11, d2[3]		//dst[1] += 31*O12
	vmlsl.s16	q13, d11, d1[0]		//dst[3] -= 78*O12
	vmlal.s16	q14, d11, d0[0]		//dst[5] += 90*O12
	vmlsl.s16	q15, d11, d1[3]		//dst[7] -= 61*O12

	vmlal.s16	q12, d20, d3[0]		//dst[1] += 22*O13
	vmlsl.s16	q13, d20, d1[3]		//dst[3] -= 61*O13
	vmlal.s16	q14, d20, d0[2]		//dst[5] += 85*O13
	vmlsl.s16	q15, d20, d0[0]		//dst[7] -= 90*O13

	vmlal.s16	q12, d19, d3[1]		//dst[1] += 13*O14
	vmlsl.s16	q13, d19, d2[2]		//dst[3] -= 38*O14
	vmlal.s16	q14, d19, d1[3]		//dst[5] += 61*O14
	vmlsl.s16	q15, d19, d1[0]		//dst[7] -= 78*O14

	vmlal.s16	q12, d12, d3[2]		//dst[1] +=  4*O15
	vmlsl.s16	q13, d12, d3[1]		//dst[3] -= 13*O15
	vmlal.s16	q14, d12, d3[0]		//dst[5] += 22*O15
	vmlsl.s16	q15, d12, d2[3]		//dst[7] -= 31*O15

	vqrshrn.s32	d4, q12, #4		// d4 => dst[1]
    vqrshrn.s32 d5, q13, #4		// d5 => dst[3]
    vqrshrn.s32	d6, q14, #4		// d6 => dst[5]
    vqrshrn.s32	d7, q15, #4		// d7 => dst[7]

    vst1.16	{d4}, [r1], lr
	vst1.16	{d5}, [r1], lr
	vst1.16	{d6}, [r1], lr
	vst1.16	{d7}, [r1], lr		// pointer stops on row 9

	// free regs => q12-q15, q2, q3
	// calculate rows 9, 11, 13, 15 in parallel
	vmull.s16	q12, d8, d0[3]		//dst[9]  = 82*O0
	vmull.s16	q13, d8, d1[0]		//dst[11] = 78*O0
	vmull.s16	q14, d8, d1[1]		//dst[13] = 73*O0
	vmull.s16	q15, d8, d1[2]		//dst[15] = 67*O0

	vmlal.s16	q12, d23, d3[0]		//dst[9]  += 22*O1
	vmlsl.s16	q13, d23, d3[2]		//dst[11] -=  4*O1
	vmlsl.s16	q14, d23, d2[3]		//dst[13] -= 31*O1
	vmlsl.s16	q15, d23, d2[0]		//dst[15] -= 54*O1

	vmlsl.s16	q12, d16, d2[0]		//dst[9]  -= 54*O2
	vmlsl.s16	q13, d16, d0[3]		//dst[11] -= 82*O2
	vmlsl.s16	q14, d16, d0[0]		//dst[13] -= 90*O2
	vmlsl.s16	q15, d16, d1[0]		//dst[15] -= 78*O2

	vmlsl.s16	q12, d15, d0[0]		//dst[9]  -= 90*O3
	vmlsl.s16	q13, d15, d1[1]		//dst[11] -= 73*O3
	vmlsl.s16	q14, d15, d3[0]		//dst[13] -= 22*O3
	vmlal.s16	q15, d15, d2[2]		//dst[15] += 38*O3

	vmlsl.s16	q12, d9, d1[3]		//dst[9]  -= 61*O4
	vmlal.s16	q13, d9, d3[1]		//dst[11] += 13*O4
	vmlal.s16	q14, d9, d1[0]		//dst[13] += 78*O4
	vmlal.s16	q15, d9, d0[2]		//dst[15] += 85*O4

	vmlal.s16	q12, d22, d3[1]		//dst[9]  += 13*O5
	vmlal.s16	q13, d22, d0[2]		//dst[11] += 85*O5
	vmlal.s16	q14, d22, d1[2]		//dst[13] += 67*O5
	vmlsl.s16	q15, d22, d3[0]		//dst[15] -= 22*O5

	vmlal.s16	q12, d17, d1[0]		//dst[9]  += 78*O6
	vmlal.s16	q13, d17, d1[2]		//dst[11] += 67*O6
	vmlsl.s16	q14, d17, d2[2]		//dst[13] -= 38*O6
	vmlsl.s16	q15, d17, d0[0]		//dst[15] -= 90*O6

	vmlal.s16	q12, d14, d0[2]		//dst[9]  += 85*O7
	vmlsl.s16	q13, d14, d3[0]		//dst[11] -= 22*O7
	vmlsl.s16	q14, d14, d0[0]		//dst[13] -= 90*O7
	vmlal.s16	q15, d14, d3[2]		//dst[15] +=  4*O7

	vmlal.s16	q12, d10, d2[3]		//dst[9]  += 31*O8
	vmlsl.s16	q13, d10, d0[1]		//dst[11] -= 88*O8
	vmlsl.s16	q14, d10, d3[1]		//dst[13] -= 13*O8
	vmlal.s16	q15, d10, d0[0]		//dst[15] += 90*O8

	vmlsl.s16	q12, d21, d2[1]		//dst[9]  -= 46*O9
	vmlsl.s16	q13, d21, d1[3]		//dst[11] -= 61*O9
	vmlal.s16	q14, d21, d0[3]		//dst[13] += 82*O9
	vmlal.s16	q15, d21, d3[1]		//dst[15] += 13*O9

	vmlsl.s16	q12, d18, d0[0]		//dst[9]  -= 90*O10
	vmlal.s16	q13, d18, d2[3]		//dst[11] += 31*O10
	vmlal.s16	q14, d18, d1[3]		//dst[13] += 61*O10
	vmlsl.s16	q15, d18, d0[1]		//dst[15] -= 88*O10

	vmlsl.s16	q12, d13, d1[2]		//dst[9]  -= 67*O11
	vmlal.s16	q13, d13, d0[0]		//dst[11] += 90*O11
	vmlsl.s16	q14, d13, d2[1]		//dst[13] -= 46*O11
	vmlsl.s16	q15, d13, d2[3]		//dst[15] -= 31*O11

	vmlal.s16	q12, d11, d3[2]		//dst[9]  +=  4*O12
	vmlal.s16	q13, d11, d2[0]		//dst[11] += 54*O12
	vmlsl.s16	q14, d11, d0[1]		//dst[13] -= 88*O12
	vmlal.s16	q15, d11, d0[3]		//dst[15] += 82*O12

	vmlal.s16	q12, d20, d1[1]		//dst[9]  += 73*O13
	vmlsl.s16	q13, d20, d2[2]		//dst[11] -= 38*O13
	vmlsl.s16	q14, d20, d3[2]		//dst[13] -=  4*O13
	vmlal.s16	q15, d20, d2[1]		//dst[15] += 46*O13

	vmlal.s16	q12, d19, d0[1]		//dst[9]  += 88*O14
	vmlsl.s16	q13, d19, d0[0]		//dst[11] -= 90*O14
	vmlal.s16	q14, d19, d0[2]		//dst[13] += 85*O14
	vmlsl.s16	q15, d19, d1[1]		//dst[15] -= 73*O14

	vmlal.s16	q12, d12, d2[2]		//dst[9]  += 38*O15
	vmlsl.s16	q13, d12, d2[1]		//dst[11] -= 46*O15
	vmlal.s16	q14, d12, d2[0]		//dst[13] += 54*O15
	vmlsl.s16	q15, d12, d1[3]		//dst[15] -= 61*O15

	vqrshrn.s32	d4, q12, #4		// d4 => dst[9]
    vqrshrn.s32 d5, q13, #4		// d5 => dst[11]
    vqrshrn.s32	d6, q14, #4		// d6 => dst[13]
    vqrshrn.s32	d7, q15, #4		// d7 => dst[15]

    vst1.16	{d4}, [r1], lr
	vst1.16	{d5}, [r1], lr
	vst1.16	{d6}, [r1], lr
	vst1.16	{d7}, [r1], lr		// pointer stops on row 17

	// calculate rows 17, 19, 21, 23 in parallel
	vmull.s16	q12, d8, d1[3]		//dst[17] = 61*O0
	vmull.s16	q13, d8, d2[0]		//dst[19] = 54*O0
	vmull.s16	q14, d8, d2[1]		//dst[21] = 46*O0
	vmull.s16	q15, d8, d2[2]		//dst[23] = 38*O0

	vmlsl.s16	q12, d23, d1[1]		//dst[17] -= 73*O1
	vmlsl.s16	q13, d23, d0[2]		//dst[19] -= 85*O1
	vmlsl.s16	q14, d23, d0[0]		//dst[21] -= 90*O1
	vmlsl.s16	q15, d23, d0[1]		//dst[23] -= 88*O1

	vmlsl.s16	q12, d16, d2[1]		//dst[17] -= 46*O2
	vmlsl.s16	q13, d16, d3[2]		//dst[19] -=  4*O2
	vmlal.s16	q14, d16, d2[2]		//dst[21] += 38*O2
	vmlal.s16	q15, d16, d1[1]		//dst[23] += 73*O2

	vmlal.s16	q12, d15, d0[3]		//dst[17] += 82*O3
	vmlal.s16	q13, d15, d0[1]		//dst[19] += 88*O3
	vmlal.s16	q14, d15, d2[0]		//dst[21] += 54*O3
	vmlsl.s16	q15, d15, d3[2]		//dst[23] -=  4*O3

	vmlal.s16	q12, d9, d2[3]		//dst[17] += 31*O4
	vmlsl.s16	q13, d9, d2[1]		//dst[19] -= 46*O4
	vmlsl.s16	q14, d9, d0[0]		//dst[21] -= 90*O4
	vmlsl.s16	q15, d9, d1[2]		//dst[23] -= 67*O4

	vmlsl.s16	q12, d22, d0[1]		//dst[17] -= 88*O5
	vmlsl.s16	q13, d22, d1[3]		//dst[19] -= 61*O5
	vmlal.s16	q14, d22, d2[3]		//dst[21] += 31*O5
	vmlal.s16	q15, d22, d0[0]		//dst[23] += 90*O5

	vmlsl.s16	q12, d17, d3[1]		//dst[17] -= 13*O6
	vmlal.s16	q13, d17, d0[3]		//dst[19] += 82*O6
	vmlal.s16	q14, d17, d1[3]		//dst[21] += 61*O6
	vmlsl.s16	q15, d17, d2[1]		//dst[23] -= 46*O6

	vmlal.s16	q12, d14, d0[0]		//dst[17] += 90*O7
	vmlal.s16	q13, d14, d3[1]		//dst[19] += 13*O7
	vmlsl.s16	q14, d14, d0[1]		//dst[21] -= 88*O7
	vmlsl.s16	q15, d14, d2[3]		//dst[23] -= 31*O7

	vmlsl.s16	q12, d10, d3[2]		//dst[17] -=  4*O8
	vmlsl.s16	q13, d10, d0[0]		//dst[19] -= 90*O8
	vmlal.s16	q14, d10, d3[0]		//dst[21] += 22*O8
	vmlal.s16	q15, d10, d0[2]		//dst[23] += 85*O8

	vmlsl.s16	q12, d21, d0[0]		//dst[17] -= 90*O9
	vmlal.s16	q13, d21, d2[2]		//dst[19] += 38*O9
	vmlal.s16	q14, d21, d1[2]		//dst[21] += 67*O9
	vmlsl.s16	q15, d21, d1[0]		//dst[23] -= 78*O9

	vmlal.s16	q12, d18, d3[0]		//dst[17] += 22*O10
	vmlal.s16	q13, d18, d1[2]		//dst[19] += 67*O10
	vmlsl.s16	q14, d18, d0[2]		//dst[21] -= 85*O10
	vmlal.s16	q15, d18, d3[1]		//dst[23] += 13*O10

	vmlal.s16	q12, d13, d0[2]		//dst[17] += 85*O11
	vmlsl.s16	q13, d13, d1[0]		//dst[19] -= 78*O11
	vmlal.s16	q14, d13, d3[1]		//dst[21] += 13*O11
	vmlal.s16	q15, d13, d1[3]		//dst[23] += 61*O11

	vmlsl.s16	q12, d11, d2[2]		//dst[17] -= 38*O12
	vmlsl.s16	q13, d11, d3[0]		//dst[19] -= 22*O12
	vmlal.s16	q14, d11, d1[1]		//dst[21] += 73*O12
	vmlsl.s16	q15, d11, d0[0]		//dst[23] -= 90*O12

	vmlsl.s16	q12, d20, d1[0]		//dst[17] -= 78*O13
	vmlal.s16	q13, d20, d0[0]		//dst[19] += 90*O13
	vmlsl.s16	q14, d20, d0[3]		//dst[21] -= 82*O13
	vmlal.s16	q15, d20, d2[0]		//dst[23] += 54*O13

	vmlal.s16	q12, d19, d2[0]		//dst[17] += 54*O14
	vmlsl.s16	q13, d19, d2[3]		//dst[19] -= 31*O14
	vmlal.s16	q14, d19, d3[2]		//dst[21] +=  4*O14
	vmlal.s16	q15, d19, d3[0]		//dst[23] += 22*O14

	vmlal.s16	q12, d12, d1[2]		//dst[17] += 67*O15
	vmlsl.s16	q13, d12, d1[1]		//dst[19] -= 73*O15
	vmlal.s16	q14, d12, d1[0]		//dst[21] += 78*O15
	vmlsl.s16	q15, d12, d0[3]		//dst[23] -= 82*O15

	vqrshrn.s32	d4, q12, #4		// d4 => dst[9]
    vqrshrn.s32 d5, q13, #4		// d5 => dst[19]
    vqrshrn.s32	d6, q14, #4		// d6 => dst[21]
    vqrshrn.s32	d7, q15, #4		// d7 => dst[23]

    vst1.16	{d4}, [r1], lr
	vst1.16	{d5}, [r1], lr
	vst1.16	{d6}, [r1], lr
	vst1.16	{d7}, [r1], lr		// pointer stops on row 25

	// calculate rows 25, 27, 29, 31 in parallel
	vmull.s16	q12, d8, d2[3]		//dst[25] = 31*O0
	vmull.s16	q13, d8, d3[0]		//dst[27] = 22*O0
	vmull.s16	q14, d8, d3[1]		//dst[29] = 13*O0
	vmull.s16	q15, d8, d3[2]		//dst[31] =  4*O0

	vmlsl.s16	q12, d23, d1[0]		//dst[25] -= 78*O1
	vmlsl.s16	q13, d23, d1[3]		//dst[27] -= 61*O1
	vmlsl.s16	q14, d23, d2[3]		//dst[29] -= 38*O1
	vmlsl.s16	q15, d23, d3[1]		//dst[31] -= 13*O1

	vmlal.s16	q12, d16, d0[0]		//dst[25] += 90*O2
	vmlal.s16	q13, d16, d0[2]		//dst[27] += 85*O2
	vmlal.s16	q14, d16, d1[3]		//dst[29] += 61*O2
	vmlal.s16	q15, d16, d3[0]		//dst[31] += 22*O2

	vmlsl.s16	q12, d15, d1[3]		//dst[25] -= 61*O3
	vmlsl.s16	q13, d15, d0[0]		//dst[27] -= 90*O3
	vmlsl.s16	q14, d15, d1[0]		//dst[29] -= 78*O3
	vmlsl.s16	q15, d15, d2[3]		//dst[31] -= 31*O3

	vmlal.s16	q12, d9, d3[2]		//dst[25] +=  4*O4
	vmlal.s16	q13, d9, d1[1]		//dst[27] += 73*O4
	vmlal.s16	q14, d9, d0[1]		//dst[29] += 88*O4
	vmlal.s16	q15, d9, d2[2]		//dst[31] += 38*O4

	vmlal.s16	q12, d22, d2[0]		//dst[25] += 54*O5
	vmlsl.s16	q13, d22, d2[2]		//dst[27] -= 38*O5
	vmlsl.s16	q14, d22, d0[0]		//dst[29] -= 90*O5
	vmlsl.s16	q15, d22, d2[1]		//dst[31] -= 46*O5

	vmlsl.s16	q12, d17, d0[1]		//dst[25] -= 88*O6
	vmlsl.s16	q13, d17, d3[2]		//dst[27] -=  4*O6
	vmlal.s16	q14, d17, d0[2]		//dst[29] += 85*O6
	vmlal.s16	q15, d17, d2[0]		//dst[31] += 54*O6

	vmlal.s16	q12, d14, d0[3]		//dst[25] += 82*O7
	vmlal.s16	q13, d14, d2[1]		//dst[27] += 46*O7
	vmlsl.s16	q14, d14, d1[1]		//dst[29] -= 73*O7
	vmlsl.s16	q15, d14, d1[3]		//dst[31] -= 61*O7

	vmlsl.s16	q12, d10, d2[2]		//dst[25] -= 38*O8
	vmlsl.s16	q13, d10, d1[0]		//dst[27] -= 78*O8
	vmlal.s16	q14, d10, d2[0]		//dst[29] += 54*O8
	vmlal.s16	q15, d10, d1[2]		//dst[31] += 67*O8

	vmlsl.s16	q12, d21, d3[0]		//dst[25] -= 22*O9
	vmlal.s16	q13, d21, d0[0]		//dst[27] += 90*O9
	vmlsl.s16	q14, d21, d2[3]		//dst[29] -= 31*O9
	vmlsl.s16	q15, d21, d1[1]		//dst[31] -= 73*O9

	vmlal.s16	q12, d18, d1[1]		//dst[25] += 73*O10
	vmlsl.s16	q13, d18, d0[3]		//dst[27] -= 82*O10
	vmlal.s16	q14, d18, d3[2]		//dst[29] +=  4*O10
	vmlal.s16	q15, d18, d1[0]		//dst[31] += 78*O10

	vmlsl.s16	q12, d13, d0[0]		//dst[25] -= 90*O11
	vmlal.s16	q13, d13, d2[0]		//dst[27] += 54*O11
	vmlal.s16	q14, d13, d3[0]		//dst[29] += 22*O11
	vmlsl.s16	q15, d13, d0[3]		//dst[31] -= 82*O11

	vmlal.s16	q12, d11, d1[2]		//dst[25] += 67*O12
	vmlsl.s16	q13, d11, d3[1]		//dst[27] -= 13*O12
	vmlsl.s16	q14, d11, d2[1]		//dst[29] -= 46*O12
	vmlal.s16	q15, d11, d0[2]		//dst[31] += 85*O12

	vmlsl.s16	q12, d20, d3[1]		//dst[25] -= 13*O13
	vmlsl.s16	q13, d20, d2[3]		//dst[27] -= 31*O13
	vmlal.s16	q14, d20, d1[2]		//dst[29] += 67*O13
	vmlsl.s16	q15, d20, d0[1]		//dst[31] -= 88*O13

	vmlsl.s16	q12, d19, d2[1]		//dst[25] -= 46*O14
	vmlal.s16	q13, d19, d1[2]		//dst[27] += 67*O14
	vmlsl.s16	q14, d19, d0[3]		//dst[29] -= 82*O14
	vmlal.s16	q15, d19, d0[0]		//dst[31] += 90*O14

	vmlal.s16	q12, d12, d0[2]		//dst[25] += 85*O15
	vmlsl.s16	q13, d12, d0[1]		//dst[27] -= 88*O15
	vmlal.s16	q14, d12, d0[0]		//dst[29] += 90*O15
	vmlsl.s16	q15, d12, d0[0]		//dst[31] -= 90*O15

	vqrshrn.s32	d4, q12, #4		// d4 => dst[9]
    vqrshrn.s32 d5, q13, #4		// d5 => dst[27]
    vqrshrn.s32	d6, q14, #4		// d6 => dst[29]
    vqrshrn.s32	d7, q15, #4		// d7 => dst[31]

    vst1.16	{d4}, [r1], lr
	vst1.16	{d5}, [r1], lr
	vst1.16	{d6}, [r1], lr
	vst1.16	{d7}, [r1], lr
	add r3, #4*2
	mov r1, r3
	subs r2, #1
    bgt .loop1

	add sp, #32*32*2		// stack buffer between first and second stage

	vpop	{q4-q7}
	pop	{lr}
	bx lr
	.fnend
