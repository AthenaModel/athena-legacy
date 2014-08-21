#-----------------------------------------------------------------------
# FILE: wizdb.tcl
#
#   WDB Module: in-memory SQLite database.
#
# PACKAGE:
#   wnbhood(n) -- package for athena(1) nbhood ingestion wizard.
#
# PROJECT:
#   Athena Regional Stability Simulation
#
# AUTHOR:
#   Dave Hanks
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# wizdb
#
# wnbhood(n) RDB I/F
#
# This module is responsible for creating an in-memory SQLite3 data
# store and making it available to the application.

snit::type ::wnbhood::wizdb {
    #-------------------------------------------------------------------
    # Type Variables

    # SQL schema

    typevariable schema {
        CREATE TABLE polygons (
            name       TEXT PRIMARY KEY,
            polygon    TEXT
        );
    }
    #-------------------------------------------------------------------
    # Components

    component db  ;# sqldocument(n)

    #-------------------------------------------------------------------
    # constructor

    # constructor
    #
    # Initializes the wdb, which prepares the data structures.
    
    constructor {} {
        install db using sqldocument ${type}::db \
            -rollback off

        $db open :memory:

        $db eval $schema
    }

    destructor {
        catch {$db destroy}
    }

    #-------------------------------------------------------------------
    # Public Methods
    
    delegate method * to db

}





