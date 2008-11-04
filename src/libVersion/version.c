/***********************************************************************
 *
 * TITLE:
 *	version.c
 *
 * AUTHOR:
 *	Will Duquette
 *
 * DESCRIPTION:
 *	libVersion Tcl Commands
 *
 ***********************************************************************/

#include <stdio.h>

#include "version.h"


/*
 * Static Function Prototypes
 */

static int version_versionCmd  (ClientData, Tcl_Interp*, int, 
                                Tcl_Obj* CONST argv[]);

/*
 * Public Function Definitions
 */

/***********************************************************************
 *
 * FUNCTION:
 *	Version_Init()
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
Version_Init(Tcl_Interp *interp)
{
    /* Define the commands. */
    Tcl_CreateObjCommand(interp, "::minlib::version", 
                         version_versionCmd, NULL, NULL);

    return TCL_OK;
}


/*
 * Command Procedures
 *
 * The functions in this section are all Tcl command definitions,
 * with the standard calling sequence.  Rather than repeat the same
 * description over again, the header comment for each will 
 * describe the implemented Tcl command, along with any notable
 * details about the implementation.
 */

/***********************************************************************
 *
 * FUNCTION:
 *	version
 *
 * INPUTS:
 *	none
 *
 * RETURNS:
 *	The Minerva version number.
 *
 * DESCRIPTION:
 *	The Minerva version number has the form "x.y.z", where x, y, and z
 *	are integers.  If this is the product of an engineering build
 *      rather than an official build, it will return exactly the string 
 *      the development branch, e.g., "1.0.x"
 */

static int 
version_versionCmd(ClientData cd, Tcl_Interp *interp, 
                int objc, Tcl_Obj* CONST objv[])
{
    if (objc != 1) {
        Tcl_WrongNumArgs(interp, 1, objv, NULL);
        return TCL_ERROR;
    }

    Tcl_SetResult(interp, MINERVA_VERSION, TCL_STATIC);
    return TCL_OK;
}

