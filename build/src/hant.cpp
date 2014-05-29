#include <stdio.h>

#if _WINDOWS
	#include <windows.h>
	#include <process.h>
	#include <errno.h>
#else
	#include <sys/stat.h>
	#include <utime.h>
	#include <stdlib.h>
	#include <unistd.h>
#endif

#include <neko.h>

int copyfiletimes(const char *src, const char *dst);

value copy_file_preserving_attributes(value src, value dst)
{
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

value process_run_detached(value command, value args)
{
	val_check( command, string );
	val_check( args, array );
	
	int argsSize = val_array_size(args);
	char** argsNative = new char*[argsSize + 2];
	argsNative[0] = val_string(command);
	argsNative[argsSize + 1] = NULL;
	value* argsPtr = val_array_ptr(args);
	for (int i=1; i<=argsSize; i++, argsPtr++)
	{
		val_check( *argsPtr, string );
		argsNative[i] = val_string(*argsPtr);
	}
	
#if _WINDOWS
	int r = _spawnvp(_P_DETACH, val_string(command), argsNative);
	if (r < 0)
	{
		if (errno == E2BIG)		val_throw(alloc_int(1));
		if (errno == EINVAL)	val_throw(alloc_int(2));
		if (errno == ENOENT)	val_throw(alloc_int(3));
		if (errno == ENOEXEC)	val_throw(alloc_int(4));
		if (errno == ENOMEM)	val_throw(alloc_int(5));
		val_throw(alloc_int(0));
	}
#else
	int r = fork();
	if (r == 0)
	{
		execvp(val_string(command), argsNative);
		exit(0);
	}
#endif
	
	delete [] argsNative;
	
	return alloc_int(r);
}
DEFINE_PRIM(process_run_detached, 2);
/**************************************************************************************/

int copyfiletimes(const char *src, const char *dst)
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

		struct stat srcAttrib;
		struct utimbuf destTimes;
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
