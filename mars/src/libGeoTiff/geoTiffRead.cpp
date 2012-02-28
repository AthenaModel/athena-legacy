/***********************************************************************
 *
 * TITLE:
 *	geoTiffRead.cpp
 *
 * AUTHOR:
 *	Dave Hanks
 *
 * DESCRIPTION:
 *	Mars: libGeoTiff Tcl Commands
 *
 *	This Tcl binding does basic get commands for a GeoTIFF
 *	image. If the file provided to the reader is not a TIFF
 *	or does not contain GeoTIFF information, an error is 
 *	generated
 *
 ***********************************************************************/

#include <stdio.h>
#include "geoTiffRead.h"

static int geoTiffRead_readerCmd (ClientData, Tcl_Interp*, int,
                               Tcl_Obj* CONST argv[]);

static void geoTiffReader_delete (void*);
static int  geoTiffReader_instanceCmd  (ClientData, Tcl_Interp*,
                                        int, Tcl_Obj* CONST argv[]);


static int geoTiffReader_read (ClientData, Tcl_Interp*, int,
                               Tcl_Obj* CONST argv[]);

static int geoTiffReader_getGeoKeyCmd (ClientData, Tcl_Interp*, int,
                               Tcl_Obj* CONST argv[]);

static int geoTiffReader_getGeoKeyInfoCmd (ClientData, Tcl_Interp*, int,
                               Tcl_Obj* CONST argv[]);

static int geoTiffReader_getGeoFieldCmd (ClientData, Tcl_Interp*, int, 
                               Tcl_Obj* CONST argv[]);


static SubcommandVector geoTiffReaderSubTable [] = {
    {"read",      geoTiffReader_read},
    {"getGeoKey",     geoTiffReader_getGeoKeyCmd},
    {"getGeoKeyInfo", geoTiffReader_getGeoKeyInfoCmd},
    {"getGeoField",   geoTiffReader_getGeoFieldCmd},
    {NULL, NULL}
};

/***********************************************************************
 *
 * FUNCTION:
 *	Geotiff_Init()
 *
 * INPUTS:
 *	interp		A Tcl interpreter
 *
 * RETURNS:
 *	TCL_OK
 *
 * DESCRIPTION:
 *	Initializes the extension's Tcl commands
 */

int
Geotiff_Init(Tcl_Interp *interp)
{
    Tcl_CreateObjCommand(interp, "::marsgui::gtifreader",
                         geoTiffRead_readerCmd, NULL, NULL);

    if (Tcl_PkgProvide(interp, "GeoTiff", "1.0") != TCL_OK)
    { 
        return TCL_ERROR;
    }

    return TCL_OK;
}

/***********************************************************************
 *
 * FUNCTION:
 *	geoTiffRead_readerCmd()
 *
 * INPUTS:
 *	 name       The Tcl command for the reader
 *	 filename   The GeoTIFF file to be read
 *
 * RETURNS:
 *	TCL_OK    if the reader is created without error
 *	TCL_ERROR if not
 *
 * DESCRIPTION:
 *	This instantiates a GeoTiffInfo object for use in
 *	subsequent calls to read information from the GeoTIFF
 *	image. An attempt is made to open the file provided
 *	as a GeoTIFF. If this fails, an error is returned. If
 *	it succeeds an instance of the reader command is created 
 *	and made available in the interpreter.
 */

static int
geoTiffRead_readerCmd (ClientData cd, Tcl_Interp *interp,
                    int objc, Tcl_Obj* CONST objv[])
{
    if (objc != 2) 
    {
        Tcl_WrongNumArgs(interp, 1, objv, "name");
        return TCL_ERROR;
    }

    char* name  = Tcl_GetStringFromObj(objv[1], NULL);

    GeoTiffInfo* gti = new GeoTiffInfo();
    gti->tiff = NULL;
    gti->gtif = NULL;

    Tcl_CreateObjCommand(interp, name, geoTiffReader_instanceCmd, gti,
                         geoTiffReader_delete);

    Tcl_SetResult(interp, name, TCL_VOLATILE);

    return TCL_OK;
}

/***********************************************************************
 *
 * FUNCTION:
 *	geoTiffRead_delete()
 *
 * INPUTS:
 *  None.
 *
 * RETURNS:
 *  Nothing.
 *
 * DESCRIPTION:
 *  This is called when the reader command goes away. It does the cleanup.
 */

static void
geoTiffReader_delete(void* gti)
{
    GeoTiffInfo* GTIFInfo = (GeoTiffInfo*)gti;
    if (GTIFInfo->gtif) GTIFFree  (GTIFInfo->gtif);
    if (GTIFInfo->tiff) XTIFFClose(GTIFInfo->tiff);
    delete GTIFInfo;
}

/***********************************************************************
 *
 * FUNCTION:
 *	geoTiffReader_instanceCmd()
 *
 * INPUTS:
 *  The name of the reader and proc.
 *
 * RETURNS:
 *  The the proc called.
 *
 * DESCRIPTION:
 *  This is called when the reader is meant to perform some proc.
 */

static int
geoTiffReader_instanceCmd(ClientData cd, Tcl_Interp* interp,
                          int objc, Tcl_Obj* CONST objv[])
{
    if (objc < 2)
    {
        Tcl_WrongNumArgs(interp, 1, objv, "subcommand ?arg arg ...?");
        return TCL_ERROR;
    }

    int index = 0;
    
    if (Tcl_GetIndexFromObjStruct(interp, objv[1],
                                 geoTiffReaderSubTable, 
                                 sizeof(SubcommandVector),
                                 "subcommand",
                                 TCL_EXACT,
                                 &index) != TCL_OK)
    {
        return TCL_ERROR;
    }

    return (*geoTiffReaderSubTable[index].proc)(cd, interp, objc, objv);
}

 /***********************************************************************
 *
 * FUNCTION:
 *	geoTiffReader_read()
 *
 * INPUTS:
 *  A filename.
 *
 * RETURNS:
 *  Nothing
 *
 * DESCRIPTION:
 *  This function opens a file and attempts to read it as a GeoTIFF. If
 *  an error is encountered it is returned.
 */

static int
geoTiffReader_read(ClientData cd, Tcl_Interp* interp,
                   int objc, Tcl_Obj* CONST objv[])
{
    if (objc < 3) 
    {
        Tcl_WrongNumArgs(interp, 1, objv, "filename");
        return TCL_ERROR;
    }

    char* fname = Tcl_GetStringFromObj(objv[2], NULL);

    GeoTiffInfo* gti = (GeoTiffInfo*)cd;

    if ((gti->tiff = XTIFFOpen(fname, "r")) == NULL)
    {
        Tcl_SetResult(interp, "file is not a TIFF", TCL_STATIC);
        return TCL_ERROR;
    }

    gti->gtif = GTIFNew(gti->tiff);

    if (!gti->gtif) 
    {
        Tcl_SetResult(interp, "file is not a GeoTIFF", TCL_STATIC);
        XTIFFClose(gti->tiff);
        gti->tiff = NULL;
        return TCL_ERROR;
    }

    return TCL_OK;
}
 /***********************************************************************
 *
 * FUNCTION:
 *	geoTiffReader_getGeoKeyInfoCmd()
 *
 * INPUTS:
 *  A geo key index.
 *
 * RETURNS:
 *  The information stored in that geo key, if any.
 *
 * DESCRIPTION:
 *  This proc returns information for an arbitrary geo key index. If the
 *  index is not valid, then an error is generated and no information is 
 *  returned.
 */

static int
geoTiffReader_getGeoKeyInfoCmd (ClientData cd, Tcl_Interp *interp,
        int objc, Tcl_Obj* CONST objv[])
{
    GeoTiffInfo* gti = (GeoTiffInfo*)cd;
    int size;
    tagtype_t type;
    geokey_t key;
    int len;

    if (objc < 3)
    {
        Tcl_WrongNumArgs(interp, 1, objv, "geokeyidx");
        return TCL_ERROR;
    }
    int i;

    if (Tcl_GetIntFromObj(interp, objv[2], &i) != TCL_OK)
    {
        return TCL_ERROR;
    }

    key = (geokey_t)i;


    len = GTIFKeyInfo(gti->gtif, key, &size, &type);
    if (len == 0)
    {
        Tcl_SetResult(interp, "no info availble for key", TCL_STATIC);
        return TCL_ERROR;
    }
    
    Tcl_Obj* result = Tcl_GetObjResult(interp);
    Tcl_SetIntObj(result, size);

    return TCL_OK;
}

/***********************************************************************
 *
 * FUNCTION:
 *	geoTiffReader_getGeoKeyCmd()
 *
 * INPUTS:
 *  A geo key value.
 *
 * RETURNS:
 *  The information stored in that geo key, if any.
 *
 * DESCRIPTION:
 *  This proc returns information for an arbitrary geo key. If the
 *  key is not valid, then an error is generated and no information is 
 *  returned.
 */

static int
geoTiffReader_getGeoKeyCmd (ClientData cd, Tcl_Interp *interp,
        int objc, Tcl_Obj* CONST objv[])
{
    GeoTiffInfo* gti = (GeoTiffInfo*)cd;

    geocode_t code;
    geokey_t  key;

    if (objc < 3)
    {
        Tcl_WrongNumArgs(interp, 1, objv, "geokey");
        return TCL_ERROR;
    }
    int i;

    if (Tcl_GetIntFromObj(interp, objv[2], &i) != TCL_OK)
    {
        return TCL_ERROR;
    }

    key = (geokey_t)i;

    if (!GTIFKeyGet(gti->gtif, key, &code, 0, 1))
    {
        Tcl_SetResult(interp, "key not found", TCL_STATIC);
        return TCL_ERROR;
    }
    
    int ret = (int)code;

    Tcl_Obj* result = Tcl_GetObjResult(interp);
    Tcl_SetIntObj(result, ret);

    return TCL_OK;
}

/***********************************************************************
 *
 * FUNCTION:
 *	geoTiffReader_getGeoFieldCmd()
 *
 * INPUTS:
 *  A geo field index.
 *
 * RETURNS:
 *  The information stored in that geo field, if any.
 *
 * DESCRIPTION:
 *  This proc returns information for an arbitrary geo field index. If the
 *  index is not valid, then an error is generated and no information is 
 *  returned.
 */

static int 
geoTiffReader_getGeoFieldCmd (ClientData cd, Tcl_Interp *interp, int objc, 
                               Tcl_Obj* CONST objv[])
{
    double *d_list = NULL;
    uint16  d_list_count;
    ttag_t  field;

    GeoTiffInfo* gti = (GeoTiffInfo*)cd;

    if (objc < 3)
    {
        Tcl_WrongNumArgs(interp, 1, objv, "geofield");
        return TCL_ERROR;
    }
    int i;

    if (Tcl_GetIntFromObj(interp, objv[2], &i) != TCL_OK)
    {
        return TCL_ERROR;
    }

    field = ttag_t(i);

    if (TIFFGetField(gti->tiff, field, &d_list_count, &d_list))
    {

        Tcl_Obj* result = Tcl_GetObjResult(interp);
        for (int i=0; i<d_list_count; i++)
        {
            Tcl_ListObjAppendElement(interp, result,
                                     Tcl_NewDoubleObj(d_list[i]));
        }
    } 

    return TCL_OK;
}


