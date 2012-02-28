#ifndef geoTiffRead_h
#define geoTiffRead_h

#include <iostream>
#include <sstream>
#include <cassert>

using namespace std;

#include <stdlib.h>
#include <tcl.h>
#include "xtiffio.h"
#include "geotiffio.h"
#include "geotiff.h"

/* GeoTiffInfo */
/* Contains pointers to TIFF and GEOTIFF information */
struct GeoTiffInfo {
    TIFF*     tiff;
    GTIF*     gtif;
};

struct SubcommandVector {
    char* name;
    Tcl_ObjCmdProc* proc;
};

extern "C" {
    extern int Geotiff_Init(Tcl_Interp*);
}

#endif  
