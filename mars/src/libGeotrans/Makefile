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

LIB = $(TOP_DIR)/src/lib

# Compilation Flags
CFLAGS = -g -O -ansi -Wall 

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


