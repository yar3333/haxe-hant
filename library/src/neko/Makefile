OBJS	= hant.o
CC      = gcc
CFLAGS	= -fPIC -I/usr/lib/neko/include
LDFLAGS = -shared -lneko

all: $(OBJS)
	$(CC) $(LDFLAGS) $(CFLAGS) -o ../../ndll/Linux/hant.ndll hant.o

hant.o:
	$(CC) $(CFLAGS) -c hant.cpp

clean:
	rm -f $(OBJS)
	rm -rf ../../ndll/Linux/hant.ndll
