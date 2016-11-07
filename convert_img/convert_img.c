#include <stdio.h>
#include <cv.h>
#include <cxcore.h>
#include <highgui.h>

int main(int argc, char *argv[])
{
	if(argc < 3){
		printf("Usage: %s input output\n",argv[0]);
		return 1;
	}
	IplImage *src=cvLoadImage(argv[1],-1);
	if(!src) {
		puts("open fail");
		return 1;
	}
	printf("%s -> %s\n",argv[1],argv[2]);
	cvSaveImage(argv[2],src,0);
	cvReleaseImage(&src);
	return 0;
}
