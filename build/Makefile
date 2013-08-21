ifeq ($(shell getconf LONG_BIT),64)
	X64=1
endif

SRC_DIR=src
OBJ_DIR=obj

OBJS=$(OBJ_DIR)/hant.o

ifdef X64
	OUT=../library/ndll/Linux64/hant.ndll
else
	OUT=../library/ndll/Linux/hant.ndll
endif 

CC=gcc

CFLAGS=-shared -fPIC #-I/usr/lib/neko/include
LDFLAGS=-shared -lneko

build: $(OBJS)
	$(CC) $(OBJS) -o $(OUT) $(LDFLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS)
	rm -rf $(OUT)

all: clean build
