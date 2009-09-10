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
    
    constructor {} {
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

    # entity exists name
    #
    # name    An entity name
    #
    # Returns 1 if there is an entity with this name, and 0 otherwise.

    method {entity exists} {name} {
        $db exists {SELECT name FROM helpdb_reserved WHERE name=$name}
    }

    # page exists name
    #
    # name    A page name
    #
    # Returns 1 if the page exists, and 0 otherwise.

    method {page exists} {name} {
        $db exists {SELECT name FROM helpdb_pages WHERE name=$name}
    }

    # page title+text name
    #
    # name    A page name
    #
    # Returns a two-item list of the page's title and body text,
    # or the empty list if the page doesn't exist.

    method {page title+text} {name} {
        $db eval {
            SELECT title, text FROM helpdb_pages WHERE name=$name
        } {
            return [list $title $text]
        }

        return [list]
    }

    # page title name
    #
    # name    A page name
    #
    # Returns the page's title.

    method {page title} {name} {
        return [$db onecolumn {
            SELECT title FROM helpdb_pages WHERE name=$name
        }]
    }

    # page children name
    #
    # name    A page name, or ""
    #
    # Returns the names of the pages which are children of the
    # specified page.  "" is the parent of the toplevel pages.

    method {page children} {name} {
        return [$db eval {
            SELECT name FROM helpdb_pages WHERE parent=$name
        }]
    }

    # page parent name
    #
    # name     Name of a page
    #
    # Returns the name of the parent page, or "" for toplevel pages.

    method {page parent} {name} {
        return [$db onecolumn {
            SELECT parent FROM helpdb_pages WHERE name=$name
        }]
    }

    # search target
    #
    # target    A full-text search query string
    #
    # Returns HTML text of the search results.

    method search {target} {
        # FIRST, nothing gets you nothing.
        if {$target eq ""} {
            return "<b>No search target specified.</b>"
        }

        # NEXT, try to do the query.
        set out ""

        set code [catch {
            set found [$db eval {
                SELECT name, 
                       title,
                       snippet(helpdb_search) AS snippet
                FROM helpdb_search
                WHERE text MATCH $target
                ORDER BY title COLLATE NOCASE;
            }]
        } result]

        if {$code} {
            return [tsubst {
                |<--
                <b>Error in search term: "<code>$target</code>"</b>

                Note that command options (e.g., <code>-info</code>)
                should be entered in double quotes: <code>"-info"</code>.
            }]
        }

        if {[llength $found] == 0} {
            return "<b>No pages match '$target'.</b>"
        }

        set out "<b>Search results for '$target':</b><p>\n<dl>\n"

        foreach {name title snippet} $found {
            append out "<dt><a href=\"$name\">$title</a></dt>\n"
            append out "<dd>$snippet<p></dd>\n\n"
        }

        append out "</dl>\n"

        return $out
    }
}





