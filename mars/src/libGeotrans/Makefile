#---------------------------------------------------------------------
# TITLE:
#    Makefile -- libGeotrans(3) Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Builds the libGeotrans(3) archive library.
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

TOP_DIR = ../..

include $(TOP_DIR)/MakeDefs

LIB = $(TOP_DIR)/src/lib

# Compilation Flags

ifeq ($(MARS_OS),win)
    OS_FLAGS = -mnop-fun-dllimport -pipe -fomit-frame-pointer
else 
    OS_FLAGS = -fPIC
endif

CFLAGS = $(OS_FLAGS) -g -O -ansi -Wall 

# Include Directory

CC  = gcc

INCLPATH = -I$(TOP_DIR)/src/include/geotrans

TARGETS = $(LIB)/libGeotrans.a

OBJS = \
	mgrs.o polarst.o tranmerc.o ups.o utm.o

all: $(TARGETS)

$(LIB)/libGeotrans.a: $(OBJS)
	ar rcvs $@ $(OBJS)

%.o:%.c
	$(CC) -c $(CFLAGS) $(INCLPATH) $< -o $@

clean:
	rm -f *.o $(TARGETS)


