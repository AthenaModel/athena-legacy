#-----------------------------------------------------------------------
# TITLE:
#    scenariodb.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Scenario Database Object
#
#    This module defines the scenariodb type.  Instances of the 
#    scenariodb type manage SQLite3 database files which contain 
#    scenario data, including run-time data, for athena_sim(1).
#
#    Typically the application will use scenariodb(n) to create a
#    Run-time Database (RDB) and then load and save external *.adb 
#    files.
#
#    scenario(n) is both a wrapper for sqldocument(n) and an
#    sqlsection(i) defining new database entities.
#
# UNSAVED CHANGES:
#    scenariodb(n) automatically tracks the "total_changes" for this
#    sqlite3 database handle, saving the count of changes whenever the
#    database is in an unchanged state.  The "unsaved" method returns
#    1 if there are unsaved changes, and 0 otherwise.
#
#-----------------------------------------------------------------------

namespace eval ::athlib:: {
    namespace export scenariodb
}

#-----------------------------------------------------------------------
# scenario

snit::type ::athlib::scenariodb {
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
        return "scenariodb(n)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions, if any.

    typemethod {sqlsection schema} {} {
        return [readfile [file join $::athlib::library scenariodb.sql]]
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

    # info array: scalar values
    #
    #  savedChanges     Number of "total_changes" as of last save point.

    variable info -array {
        savedChanges 0
    }

    #-------------------------------------------------------------------
    # Constructor
    
    constructor {args} {
        # FIRST, get the options.
        # TBD: None yet
        # $self configurelist $args

        # NEXT, create the sqldocument, naming it so that it
        # will be automatically destroyed.  We don't want
        # automatic transaction batching.
        set db [sqldocument ${selfns}::db -autotrans off]
    }

    #-------------------------------------------------------------------
    # Public Methods: sqldocument(n)

    # Delegated methods
    delegate method * to db

    # unsaved
    #
    # Returns 1 if there are unsaved changes, as indicated by 
    # savedChanges and the total_changes count, and 0 otherwise.

    method unsaved {} {
        expr {[$db total_changes] > $info(savedChanges)}
    }

    # load filename
    #
    # filename     An .adb file name
    #
    # Loads scenario data from the specified file into the db.
    # It's an error if the file doesn't have a scenario table,
    # or if the user_version doesn't match.

    method load {filename} {
        # FIRST, verify that that the file exists.
        if {![file exists $filename]} {
            error "File does not exist"
        }

        # NEXT, open the database.
        sqlite3 dbToLoad $filename

        # NEXT, Verify that it's a scenario file
        set name [dbToLoad eval {
            SELECT name FROM sqlite_master
            WHERE name = 'scenario'
        }]

        if {$name eq ""} {
            dbToLoad close
            error "File is not a scenario file."
        }

        # NEXT, get the user versions
        set v1 [$db eval {PRAGMA user_version;}]
        set v2 [dbToLoad eval {PRAGMA user_version;}]

        dbToLoad close

        if {$v1 != $v2} {
            error \
                "Scenario file mismatch: got version $v2, expected version $v1"
        }

        # NEXT, clear the db, and attach the database to load.
        $db clear

        $db eval "
            ATTACH DATABASE '$filename' AS source;
        "

        # NEXT, copy the tables, skipping the sqlite and 
        # sqldocument schema tables.  We'll only copy data for
        # tables that already exist in our schema, and also exist
        # in the dbToLoad.

        set destTables [$db eval {
            SELECT name FROM sqlite_master 
            WHERE type='table'
            AND name NOT GLOB '*sqlite*'
            AND name NOT glob 'sqldocument_*'
        }]

        set sourceTables [$db eval {
            SELECT name FROM source.sqlite_master 
            WHERE type='table'
            AND name NOT GLOB '*sqlite*'
        }]

        $db transaction {
            foreach table $destTables {
                if {$table ni $sourceTables} {
                    continue
                }

                $db eval "INSERT INTO main.$table SELECT * FROM source.$table"
            }
        }

        # NEXT, detach the loaded database.
        $db eval {DETACH DATABASE source;}

        # NEXT, As of this point all changes are saved.
        $self marksaved
    }

    # clear
    #
    # Wraps sqldocument(n) clear; sets count of saved changes

    method clear {} {
        # FIRST, clear the database
        $db clear

        # NEXT, As of this point all changes are saved.
        $self marksaved
    }

    # open ?filename?
    #
    # Wraps sqldocument(n) open; sets count of saved changes

    method open {{filename ""}} {
        # FIRST, open the database
        $db open $filename

        # NEXT, As of this point all changes are saved.
        $self marksaved
    }

    # saveas filename
    #
    # Wraps sqldocument(n) saveas; sets count of saved changes

    method saveas {filename} {
        # FIRST, save the database
        $db saveas $filename

        # NEXT, As of this point all changes are saved.
        $self marksaved
    }

    # marksaved
    #
    # Marks the database saved.

    method marksaved {} {
        set info(savedChanges) [$db total_changes]
    }
}




