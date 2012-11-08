OBJS	= hant.o
CC      = gcc
CFLAGS	= -fPIC -I/usr/lib/neko/include
LDFLAGS = -shared -lneko

all: $(OBJS)
	$(CC) $(LDFLAGS) -o ../../ndll/Linux/hant.ndll hant.o

clean:
	rm -f $(OBJS)
	rm -rf ../../ndll/Linux/hant.ndll
