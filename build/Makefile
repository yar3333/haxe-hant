include Makefile-platform
include Makefile-ndll

PROJECT=hant

ifeq ($(PLATFORM),Windows)
	CCFLAGS+= -I $(NEKOPATH)\include
	LDFLAGS+= -L$(NEKOPATH)
endif
