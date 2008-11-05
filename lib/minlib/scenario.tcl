#-----------------------------------------------------------------------
# TITLE:
#    scenario.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Minerva Scenario Object
#
#    This module defines the scenario type.  Instances of the 
#    scenario type manage SQLite3 database files which contain 
#    scenario data, including run-time data, for minerva_sim(1).
#
#    Access to the database is document-centric: open/create the 
#    database, read and write until an appropriate save point is 
#    reached, then commit all changes.  In other words, it's expected
#    that any given database file has but one writer at a time, and
#    arbitrarily many writes are batched into a single transaction.
#    Otherwise, each write is a single transaction, and the necessary
#    locking and unlocking causes a major performance hit.
#
#    scenario(n) is both a wrapper for sqldocument(n) and an
#    sqlsection(i) defining new database entities.
#
#-----------------------------------------------------------------------

namespace eval ::minlib:: {
    namespace export scenario
}

#-----------------------------------------------------------------------
# scenario

snit::type ::minlib::scenario {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        namespace import ::marsutil::*

        # Register self as an sqlsection(i) module
        sqldocument register $type
    }

    #-------------------------------------------------------------------
    # Type Variables

    #-------------------------------------------------------------------
    # sqlsection(i)
    #
    # The following variables and routines implement the module's 
    # sqlsection(i) interface.

    # sqlsection title
    #
    # Returns a human-readable title for the section

    typemethod {sqlsection title} {} {
        return "scenario(n)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions, if any.

    typemethod {sqlsection schema} {} {
        return [readfile [file join $::minlib::library scenario.sql]]
    }

    # sqlsection tempschema
    #
    # Returns the section's temporary schema definitions, if any.

    typemethod {sqlsection tempschema} {} {
        return ""
    }

    # sqlsection functions
    #
    # Returns a dictionary of function names and command prefixes

    typemethod {sqlsection functions} {} {
        return ""
    }

    #-------------------------------------------------------------------
    # Components

    component db                         ;# The sqldocument(n).

    #-------------------------------------------------------------------
    # Options

    # TBD

    #-------------------------------------------------------------------
    # Instance variables
    
    # TBD

    #-------------------------------------------------------------------
    # Constructor
    
    constructor {args} {
        # FIRST, get the options.
        # TBD: None yet
        # $self configurelist $args

        # NEXT, create the sqldocument, naming it so that it
        # will be automatically destroyed.
        set db [sqldocument ${selfns}::db]
    }

    #-------------------------------------------------------------------
    # Public Methods: sqldocument(n)

    # Delegated methods
    delegate method * to db

}









