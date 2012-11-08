#if _WINDOWS
	#include <windows.h>
	#include <stdio.h>
	#include <stdlib.h>
	#include <wchar.h>
#else
	#include <sys/stat.h>
	#include <sys/time.h>
	#include <time.h>
	#include <fcntl.h>
	#include <stdio.h>
	#include <utime>
	#include <ctime>
	//#include <cstdio>    // fopen, fclose, fread, fwrite, BUFSIZ
#endif

#include <neko.h>

int copyfiletimes(LPCSTR src, LPCSTR dst);

value copy_file_preserving_attributes(value src, value dst)
{	
    // BUFSIZE default is 8192 bytes
    // BUFSIZE of 1 means one chareter at time
    // good values should fit to blocksize, like 1024 or 4096
    // higher values reduce number of system calls
    // size_t BUFFER_SIZE = 4096;
	char buf[BUFSIZ];
    size_t size;
	FILE *source, *dest;
	int r;

	val_check( src, string );
	val_check( dst, string );

    source = fopen(val_string(src), "rb");
	if (!source)
	{
		return alloc_int(1);
	}

    dest = fopen(val_string(dst), "wb");
	if (!dest)
	{
		fclose(source);
		return alloc_int(2);
	}

    // clean and more secure
    // feof(FILE* stream) returns non-zero if the end of file indicator for stream is set
    while (size = fread(buf, 1, BUFSIZ, source))
	{
        fwrite(buf, 1, size, dest);
    }

    fclose(source);
    fclose(dest);

	r = copyfiletimes(val_string(src), val_string(dst));
	
	return alloc_int(r);
}
DEFINE_PRIM(copy_file_preserving_attributes, 2);

/**************************************************************************************/

int copyfiletimes(LPCSTR src, LPCSTR dst)
{
	#if _WINDOWS

		FILETIME modtime;
		HANDLE fhSrc, fhDst;
	 
		fhSrc = CreateFile(src, GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL);
		if (fhSrc == INVALID_HANDLE_VALUE) 
		{
			return 3;
		}
		if (GetFileTime(fhSrc, NULL, NULL, &modtime) == 0)
		{
			CloseHandle(fhSrc);
			return 3;
		}
		
		CloseHandle(fhSrc);
		
		fhDst = CreateFile(dst, GENERIC_READ | FILE_WRITE_ATTRIBUTES, 0, NULL, OPEN_EXISTING, 0, NULL);
		if (fhDst == INVALID_HANDLE_VALUE) 
		{
			return 4;
		}
		if (SetFileTime(fhDst, NULL, NULL, &modtime) == 0)
		{
			CloseHandle(fhDst);
			return 4;
		}
		
		CloseHandle(fhDst);
		
		return 0;
	
	#else

		stat srcAttrib;
		utimbuf destTimes;
		// get source stat
		if (stat(val_string(src), &srcAttrib) < 0)
		{
			return 1;
		}

		// set dest stat
		destTimes.actime = srcAttrib.st_atime;
		destTimes.modtime = srcAttrib.st_mtime;
		if (utime(val_string(src), &destTimes) < 0)
		{
			return 2;
		}

		return 0;

	#endif
}
