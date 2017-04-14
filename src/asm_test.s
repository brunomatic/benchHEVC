	.globl   transpose
	.p2align 2
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
