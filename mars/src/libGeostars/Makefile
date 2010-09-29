#---------------------------------------------------------------------
# TITLE:
#    Makefile -- libGeostars(3) Makefile
#
# AUTHOR:
#    Jon Stinzel
#
# DESCRIPTION:
#    Builds the libGeostars(3) archive library.
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

TOP_DIR = ../..

LIB = $(TOP_DIR)/src/lib

# Compilation Flags
CFLAGS = -g -O -Wall

# Include Directory

CC  = gcc

INCLPATH = -I$(TOP_DIR)/src/include/geostars

TARGETS = $(LIB)/libGeostars.a

OBJS = \
	geoEllips.o geoPoint.o geoMag.o


all: $(TARGETS)

$(LIB)/libGeostars.a: $(OBJS)
	ar rcvs $@ $(OBJS)

%.o:%.c
	$(CC) -c $(CFLAGS) $(INCLPATH) $< -o $@

clean:
	rm -f *.o $(TARGETS)


