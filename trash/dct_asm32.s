.align 8
c1:	 	 .word 90, 87, 80, 70,  57, 43, 25,  9
         .word 83, 36, 75, 89,  18, 50, 00, 00

c2:		 .word 90, 88, 85, 82,  78, 73, 67, 61
         .word 54, 46, 38, 31,  22, 13,  4, 00

	.globl   dct32
	.type    dct32,%function

dct32:
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

.loop1:
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
    bgt .loop1


//********************************************************* 2nd pass*****************************************************************//

	mov r2, #32/4			// rows counter
	mov r3, r1 				// dst reference pointer

.loop2:
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
    bgt .loop2

	add sp, #32*32*2		// stack buffer between first and second stage
	add sp, #30*16

	vpop	{q4-q7}
	pop	{r4, r5, r6, r7, lr}
	bx lr
	.fnend
