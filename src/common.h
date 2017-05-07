#ifndef COMMON_HEADER
#define COMMON_HEADER

#define Clip(MIN, MAX, x)		((x > MAX) ? MAX : ((x < MIN) ? MIN : x))
#define Clip3(MAX, X)			((X>(int32_t)MAX) ? MAX : (X<(int32_t)0) ? 0 : X )
#define pixelY(pic, x, y)		pic->Y[Clip3(pic->width - 1, x) +  Clip3(pic->height - 1, y)*pic->width]
#define pixelCb(pic, x, y)		pic->Cb[Clip3((pic->width/pic->SubWidth) - 1, x) +  Clip3((pic->height/pic->SubHeight) - 1, y)*(pic->width/pic->SubWidth)]
#define pixelCr(pic, x, y)		pic->Cr[Clip3((pic->width/pic->SubWidth) - 1, x) +  Clip3((pic->height/pic->SubHeight) - 1, y)*(pic->width/pic->SubWidth)]

#define min(x, y)				( x > y ? y : x )
#define max(x, y)				( x < y ? y : x )

#define		YUV_420		0
#define		YUV_422		1
#define		YUV_444		2

#define		Y_PLANE		0
#define		CB_PLANE	1
#define		CR_PLANE	2

#define		MODE_INTER	0
#define		MODE_INTRA	1

#define 	DEBUG 0

#endif // !COMMON_HEADER
