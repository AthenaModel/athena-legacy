#-----------------------------------------------------------------------
# TITLE:
#    helpdb.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    helpdb(n) Help Database Object
#
#    This module defines the helpdb type.  Instances of the 
#    helpdb type manage SQLite3 database files which contain 
#    application help pages.  helpdb(n) files are created using
#    helptool(1) from help(5) input.  helpdb(n) can be used to 
#    open and query help files; helpbrowser(n) provides a GUI
#    browser for help files.
#
#    helpdb(n) is both a wrapper for sqldocument(n) and an
#    sqlsection(i) defining new database entities.
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export helpdb
}

#-----------------------------------------------------------------------
# scenario

snit::type ::projectlib::helpdb {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        namespace import ::marsutil::*

        # Register self as an sqlsection(i) module
        sqldocument register $type
    }

    #-------------------------------------------------------------------
    # sqlsection(i)
    #
    # The following variables and routines implement the module's 
    # sqlsection(i) interface.

    # sqlsection title
    #
    # Returns a human-readable title for the section

    typemethod {sqlsection title} {} {
        return "helpdb(n)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions, if any.

    typemethod {sqlsection schema} {} {
        readfile [file join $::projectlib::library helpdb.sql]
    }

    # sqlsection tempschema
    #
    # Returns the section's temporary schema definitions, if any.

    typemethod {sqlsection tempschema} {} {
        return ""
    }

    # sqlsection tempdata
    # 
    # Returns the section's temporary data

    typemethod {sqlsection tempdata} {} {
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
    # Constructor
    
    constructor {args} {
        # FIRST, create the sqldocument, naming it so that it
        # will be automatically destroyed.  We don't want
        # automatic transaction batching.
        set db [sqldocument ${selfns}::db          \
                    -autotrans off                 \
                    -rollback  off]
    }

    #-------------------------------------------------------------------
    # Public Methods: sqldocument(n)

    # Delegated methods
    delegate method * to db

    # exists name
    #
    # name    A page name
    #
    # Returns 1 if the page exists, and 0 otherwise.

    method exists {name} {
        $db exists {SELECT name FROM helpdb_pages WHERE name=$name}
    }

    # title+text name
    #
    # name    A page name
    #
    # Returns a two-item list of the page's title and body text,
    # or the empty list if the page doesn't exist.

    method title+text {name} {
        $db eval {
            SELECT title, text FROM helpdb_pages WHERE name=$name
        } {
            return [list $title $text]
        }

        return [list]
    }

    # title name
    #
    # name    A page name
    #
    # Returns the page's title.

    method title {name} {
        return [$db onecolumn {
            SELECT title FROM helpdb_pages WHERE name=$name
        }]
    }

    # children name
    #
    # name    A page name, or ""
    #
    # Returns the names of the pages which are children of the
    # specified page.  "" is the parent of the toplevel pages.

    method children {name} {
        return [$db eval {
            SELECT name FROM helpdb_pages WHERE parent=$name
        }]
    }

    # parent name
    #
    # name     Name of a page
    #
    # Returns the name of the parent page, or "" for toplevel pages.

    method parent {name} {
        return [$db onecolumn {
            SELECT parent FROM helpdb_pages WHERE name=$name
        }]
    }
}





