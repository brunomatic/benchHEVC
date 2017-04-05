
#define _CRT_SECURE_NO_DEPRECATE

#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include "types.h"
#include "helper.h"

#define Clip_RGB(x)		((x < 0 ) ? 0 : ((x > 255) ? 255 : x))

/*
	Function genetates raw YCbCr/YUV image - components are separated into different planes
	Supported chroma subsampling: 4:4:4, 4:2:2, 4:2:0
*/
void generatePicture(image * picture, uint32_t w, uint32_t h, uint8_t format) {
	uint32_t x, y;

	// fill in the information about image

	picture->height = h;
	picture->width = w;
	picture->bitDepthY = 8;
	picture->bitDepthC = 8;


	switch (format)
	{
	case YUV_420:
		picture->SubHeight = 2;
		picture->SubWidth = 2;
		picture->format = YUV_420;
		break;
	case YUV_422:
		picture->SubHeight = 1;
		picture->SubWidth = 2;
		picture->format = YUV_422;
		break;
	case YUV_444:
		picture->SubHeight = 1;
		picture->SubWidth = 1;
		picture->format = YUV_444;
	default:
		picture->SubHeight = 1;
		picture->SubWidth = 2;
		picture->format = YUV_422;
		break;
	}


	// allocate memory for Y, Cb. Cr components

	picture->Y = (uint8_t *)malloc(sizeof(uint8_t)* h * w);
	picture->Cb = (uint8_t *)malloc(sizeof(uint8_t)* h * w / picture->SubWidth);
	picture->Cr = (uint8_t *)malloc(sizeof(uint8_t)* h * w / picture->SubWidth);


	// make sahding sample over each component

	for (y = 0; y < h; y++)
	{
		for (x = 0; x < w; x++)
		{
			picture->Y[x + y * picture->width] = (x*4) % 256;
		
		}
	}

	// fill in chroma based on subsampling scheme

	for (y = 0; y < ( h / picture->SubHeight); y++)
	{
		for (x = 0; x < (w / picture->SubWidth); x++)
		{
			picture->Cb[x + y * (picture->width / picture->SubWidth)] = (x*4*picture->SubWidth) % 256;
			picture->Cr[x + y * (picture->width / picture->SubWidth)] = (x*4*picture->SubWidth) % 256;

		}
	}

	


}


/*
	Prints the matrix of a required component
*/
void printPlane(image * img, uint8_t component)
{
	uint32_t i, j;

	if (component == Y_PLANE) {
		printf("Printing Luma plane:\n");
		for (i = 0; i < img->height; i++)
		{
			for (j = 0; j < img->width; j++)
			{
					printf("%d	", img->Y[j + i*img->width]);

			}
			printf("\n");

		}
	}


	if (component == CB_PLANE) {
		printf("Printing Cb plane:\n");
		for (i = 0; i < (img->height / img->SubHeight); i++)
		{
			for (j = 0; j < (img->width / img->SubWidth); j++)
			{
				printf("%d	", img->Cb[j + i*(img->width / img->SubWidth)]);
			}
			printf("\n");

		}	
	}
		
	if (component == CR_PLANE) {
		printf("Printing Cr plane:\n");
		for (i = 0; i < (img->height / img->SubHeight); i++)
		{
			for (j = 0; j < (img->width / img->SubWidth); j++)
			{
				printf("%d	", img->Cr[j + i*(img->width / img->SubWidth)]);
			}
			printf("\n");

		}
	}

}


/*
	Prints segement of the matrix of a required component
*/
void printPlaneSegment(image * img, uint8_t sizeX, uint8_t sizeY, uint32_t x, uint32_t y, uint8_t component)
{
	uint32_t i, j;

	if (component == Y_PLANE) {
		printf("Printing Luma plane (%d,%d)-(%d,%d)\n", x, y, x+sizeX, y+sizeY);
		for (i = y; i < sizeY; i++)
		{
			for (j = x; j < sizeX; j++)
			{
					printf("%d	", img->Y[j + i*img->width]);

			}
			printf("\n");

		}
	}


	if (component == CB_PLANE) {
		printf("Printing Cb plane (%d,%d)-(%d,%d):\n", x, y, x + sizeX, y + sizeY);
		for (i = y; i < (sizeY / img->SubHeight); i++)
		{
			for (j = x; j < (sizeX / img->SubWidth); j++)
			{
				printf("%d	", img->Cb[j + i*(img->width / img->SubWidth)]);
			}
			printf("\n");

		}	
	}
		
	if (component == CR_PLANE) {
		printf("Printing Cr plane (%d,%d)-(%d,%d):\n", x, y, x + sizeX, y + sizeY);
		for (i = y; i < (sizeY / img->SubHeight); i++)
		{
			for (j = x; j < (sizeX / img->SubWidth); j++)
			{
				printf("%d	", img->Cr[j + i*(img->width / img->SubWidth)]);
			}
			printf("\n");

		}
	}


}


/*
	Function dumps the data into .ppm image
*/
void writeImage(image * img, uint8_t * filename) 
{
	FILE * file;
	uint8_t r, g, b;
	uint32_t temp;
	uint32_t x, y;


	printf("Dumping image in PPM format\n");
	file = fopen(filename, "wb");
	if (!file)
		return;

	fwrite("P6 512 512 255 ", sizeof(uint8_t), 13, file);

	for (y = 0; y < img->height; y++)
	{
		for (x = 0; x < img->width; x++)
		{
			r = (uint8_t)Clip_RGB((img->Y[x + y*img->width] + 1.370705 * img->Cr[(x / img->SubWidth) + (y / img->SubHeight)*(img->width / img->SubWidth)]));
			g = (uint8_t)Clip_RGB((img->Y[x + y*img->width] - 0.337633 * img->Cb[(x / img->SubWidth) + (y / img->SubHeight)*(img->width / img->SubWidth)] - 0.698001 * img->Cr[(x / img->SubWidth) + (y / img->SubHeight)*(img->width / img->SubWidth)]));
			b = (uint8_t)Clip_RGB((img->Y[x + y*img->width] - 1.732446 * img->Cb[(x / img->SubWidth) + (y / img->SubHeight)*(img->width / img->SubWidth)]));
			fwrite(&r, sizeof(uint8_t), 1, file);
			fwrite(&g, sizeof(uint8_t), 1, file);
			fwrite(&b, sizeof(uint8_t), 1, file);
		}
	}

	fclose(file);
	
	
}


/*
	Function prints a square matrix from pointer reference and dimensions
*/
void printMatrix(int16_t * matrix, uint8_t size) {
	uint8_t i, j;

	for ( i = 0; i < size; i++)
	{
		for ( j = 0;  j  < size;  j ++)
		{
			printf("%d	", matrix[i*size + j]);
		}
		printf("\n");
	}
	return;
}


/*
	Function generates random residual matrix
*/
void generateResidual(uint8_t blockSize, int16_t * residual) 
{
	uint8_t i, j;

	srand(time(NULL));

	for (i = 0; i < blockSize; i++)
	{
		for (j = 0; j < blockSize; j++)
		{
			residual[i * blockSize + j] = ((rand() % 512) - 256);
		}

	}

	return;

}

/*
	Function generates random vectors and offsets for interpolation
*/
void generateRandomMV(uint32_t * xPb, uint32_t * yPb, int16_t * mvLX, int16_t * mvCLX, uint32_t width, uint32_t height, uint8_t blockWidth, uint8_t blockHeight) 
{
	srand(time(NULL));

	// pick sth from the picture
	*xPb = (rand() % (width - blockWidth));
	*yPb = (rand() % (height - blockHeight));

	// generate random offset based on x and y of prediction block and random fractional motion vector
	mvLX[0] = ((rand() % (width - blockWidth) - *xPb) << 2)  | (rand() % 4);
	mvLX[1] = ((rand() % (height - blockHeight) - *yPb) << 2) | (rand() % 4);

	// crush two last bits, zero in three more and generate randomly those last three
	mvCLX[0] = ((mvLX[0] >> 2) << 3) | (rand() % 8);
	mvCLX[1] = ((mvLX[1] >> 2) << 3) | (rand() % 8);

	return;
}