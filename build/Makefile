OBJS	= obj/hant.o
OUT     = ../library/ndll/Linux/hant.ndll
CC      = gcc
CFLAGS	= -shared -fPIC -I/usr/lib/neko/include
LDFLAGS = -shared -lneko

all: $(OBJS)
	$(CC) $(OBJS) -o $(OUT) $(LDFLAGS)

hant.o:
	$(CC) $(CFLAGS) -c hant.cpp

clean:
	rm -f $(OBJS)
	rm -rf $(OUT)
