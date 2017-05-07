#include "timing.h"

/*
 Handle different OS differently ;)
 */
#ifdef _WIN32

#include <windows.h>
double get_time()
{
	LARGE_INTEGER t, f;
	QueryPerformanceCounter(&t);
	QueryPerformanceFrequency(&f);
	return (double)t.QuadPart / (double)f.QuadPart;
}

#else

#include <time.h>

double get_time() {
	struct timespec time;
	clock_gettime(CLOCK_MONOTONIC, &time);
	return time.tv_sec + time.tv_nsec * 1e-9;
}

#endif
