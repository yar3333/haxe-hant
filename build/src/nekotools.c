#include <neko.h>
#include <stdarg.h>

void throwNekoException(char *fmt, ...)
{
    char buffer[1024 * 10];
	
	va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
	
	failure(buffer);
}
