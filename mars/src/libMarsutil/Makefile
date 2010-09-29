#---------------------------------------------------------------------
# TITLE:
#    Makefile -- libMarsutil Makefile
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Builds the libMarsutil extension
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Settings

TOP_DIR = ../..

include $(TOP_DIR)/MakeDefs


# LDFLAGS += -g -O3 ${LIB_PATH}
LDFLAGS += -g ${LIB_PATH}

CC = gcc

# TCL Paths
TCL_LIB_DIR  = $(MARS_TCL_HOME)/lib
TCL_INC_DIR  = $(MARS_TCL_HOME)/include

DEFINES  = \
	-DUSE_TCL_STUBS

RLIBPATH = -Xlinker -rpath -Xlinker $(TCL_LIB_DIR)

LIBPATH  = \
	-L$(TOP_DIR)/src/lib \
	-L$(TCL_LIB_DIR)     \
	 $(RLIBPATH)

INCLPATH = \
	-I$(TOP_DIR)/src/include \
	-I$(TCL_INC_DIR) 


TARGET = $(TOP_DIR)/lib/marsutil/libMarsutil.so

OBJS = \
	marsutil.o

LIBS = \
	-lGeotrans -lGeostars -lm -ltclstub8.5

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $(LIBPATH) -shared -o $@ $(OBJS) $(LIBS)

%.o:%.c
	$(CC) -c $(DEFINES) $(CPPFLAGS) $(INCLPATH) $< -o $@

clean:
	rm -f *.o $(TARGET) MakeDepends

#-------------------------------------------------------------------
# Dependency checking.
#
# TBD: This should go in src/MakeRules, once we have one.
# DYNAMIC_HEADERS should list any header files that are built
# dynamically.  (Do we still need this?)

depend: MakeDepends

MKDEP = g++ -MM
MKDEPFLAGS = $(DEFINES) $(CPPFLAGS) $(INCLPATH)
DEPEND_SRCS = $(wildcard *.c) $(wildcard *.cpp)

MakeDepends: $(DYNAMIC_HEADERS) $(DEPEND_SRCS)
	@echo Doing make MakeDepends.$(MACH)
	@$(MKDEP) -MF $@ $(MKDEPFLAGS) $(DEPEND_SRCS) 2>MakeDepends.log

include MakeDepends


#-------------------------------------------------------------------
# Standard MakeRules

include $(TOP_DIR)/MakeRules





