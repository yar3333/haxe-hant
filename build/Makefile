ifeq ($(shell getconf LONG_BIT),64)
	PLATFORM=Linux64
else
	PLATFORM=Linux
endif

SRC_DIR=src
OBJ_DIR=obj

OBJS=$(OBJ_DIR)/hant.o

OUT=../library/ndll/$(PLATFORM)/hant.ndll

CC=g++

CFLAGS=-shared -fPIC #-I/usr/lib/neko/include
LDFLAGS=-shared -lneko

build: $(OBJS)
	$(CC) $(OBJS) -o $(OUT) $(LDFLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS)
	rm -f $(OUT)

all: clean build
