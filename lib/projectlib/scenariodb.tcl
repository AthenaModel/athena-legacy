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

namespace eval ::projectlib:: {
    namespace export scenariodb
}

#-----------------------------------------------------------------------
# scenario

snit::type ::projectlib::scenariodb {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        namespace import ::marsutil::*
    }

    #-------------------------------------------------------------------
    # Type Variables

    typevariable sqlsection_tempdata {
        concerns {
            { c AUT longname "Autonomy"        gtype CIV }
            { c SFT longname "Physical Safety" gtype CIV }
            { c CUL longname "Culture"         gtype CIV }
            { c QOL longname "Quality of Life" gtype CIV }
        }

        activity {
            { a NONE       longname "None"                       }
            { a CHKPOINT   longname "Checkpoint/Control Point"   }
            { a COERCION   longname "Coercion"                   }
            { a CONSTRUCT  longname "Construction"               }
            { a CRIME      longname "Criminal Activities"        }
            { a CURFEW     longname "Curfew"                     }
            { a EDU        longname "Schools"                    }
            { a EMPLOY     longname "Provide Employment"         }
            { a GUARD      longname "Guard"                      }
            { a INDUSTRY   longname "Support Industry"           }
            { a INFRA      longname "Support Infrastructure"     }
            { a LAWENF     longname "Law Enforcement"            }
            { a MEDICAL    longname "Provide Healthcare"         }
            { a PATROL     longname "Patrol"                     }
            { a PRESENCE   longname "Presence"                   }
            { a PSYOP      longname "PSYOP"                      }
            { a RELIEF     longname "Humanitarian Relief"        }
        }

        activity_gtype {
            { a NONE      gtype CIV assignable 0 }

            { a NONE      gtype FRC assignable 0 }
            { a CHKPOINT  gtype FRC assignable 1 }
            { a COERCION  gtype FRC assignable 1 }
            { a CONSTRUCT gtype FRC assignable 1 }
            { a CRIME     gtype FRC assignable 1 }
            { a CURFEW    gtype FRC assignable 1 }
            { a EDU       gtype FRC assignable 1 }
            { a EMPLOY    gtype FRC assignable 1 }
            { a GUARD     gtype FRC assignable 1 }
            { a INDUSTRY  gtype FRC assignable 1 }
            { a INFRA     gtype FRC assignable 1 }
            { a LAWENF    gtype FRC assignable 1 }
            { a MEDICAL   gtype FRC assignable 1 }
            { a PATROL    gtype FRC assignable 1 }
            { a PRESENCE  gtype FRC assignable 0 }
            { a PSYOP     gtype FRC assignable 1 }
            { a RELIEF    gtype FRC assignable 1 }
            
            { a NONE      gtype ORG assignable 0 }
            { a CONSTRUCT gtype ORG assignable 1 }
            { a EDU       gtype ORG assignable 1 }
            { a EMPLOY    gtype ORG assignable 1 }
            { a INDUSTRY  gtype ORG assignable 1 }
            { a INFRA     gtype ORG assignable 1 }
            { a MEDICAL   gtype ORG assignable 1 }
            { a RELIEF    gtype ORG assignable 1 }
        }
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
        return "scenariodb(n)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions, if any.

    typemethod {sqlsection schema} {} {
        foreach filename {
            scenariodb_entities.sql
            scenariodb_attitude.sql
            scenariodb_ground.sql
            scenariodb_demog.sql
            scenariodb_infrastructure.sql
            scenariodb_econ.sql
            scenariodb_info.sql
            scenariodb_politics.sql
            scenariodb_history.sql
            scenariodb_rebase.sql
            scenariodb_application.sql
        } {
            append out [readfile [file join $::projectlib::library $filename]]
        }

        return $out
    }

    # sqlsection tempschema
    #
    # Returns the section's temporary schema definitions, if any.

    typemethod {sqlsection tempschema} {} {
        readfile [file join $::projectlib::library scenariodb_temp.sql]
    }

    # sqlsection tempdata
    # 
    # Returns the section's temporary data

    typemethod {sqlsection tempdata} {} {
        return $sqlsection_tempdata
    }

    # sqlsection functions
    #
    # Returns a dictionary of function names and command prefixes

    typemethod {sqlsection functions} {} {
        return {
            commafmt   ::marsutil::commafmt
            qaffinity  ::simlib::qaffinity
            qcoop      ::simlib::qcooperation
            qemphasis  ::simlib::qemphasis
            qfancyfmt  ::projectlib::scenariodb::QFancyFmt
            qmag       ::simlib::qmag
            qposition  ::simlib::qposition
            qsat       ::simlib::qsat
            qsaliency  ::simlib::qsaliency
            qsecurity  ::projectlib::qsecurity
            link       ::projectlib::scenariodb::Link
            pair       ::projectlib::scenariodb::Pair
        }
    }

    #-------------------------------------------------------------------
    # Components

    component db                         ;# The sqldocument(n).

    #-------------------------------------------------------------------
    # Options

    delegate option -clock      to db
    delegate option -explaincmd to db


    #-------------------------------------------------------------------
    # Instance variables

    # info array: scalar values
    #
    #  savedChanges    - Number of "total_changes" as of last save point.

    variable info -array {
        savedChanges    0
    }

    #-------------------------------------------------------------------
    # Constructor
    
    constructor {args} {
        # FIRST, create the sqldocument, naming it so that it
        # will be automatically destroyed.  We don't want
        # automatic transaction batching.
        set db [sqldocument ${selfns}::db         \
                    -subject   $self              \
                    -clock     [from args -clock] \
                    -autotrans off                \
                    -rollback  on]

        # NEXT, pass along any other options
        $db configurelist $args

        # NEXT, register the schema sections
        $db register ::marsutil::undostack
        $db register ::simlib::ucurve
        $db register ::simlib::uram
        $db register $type
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


    #-------------------------------------------------------------------
    # SQL Functions

    # Link(url,label)
    #
    # url   - The URL
    # label - The link text
    #
    # Returns an HTML link.

    proc Link {url label} {
        return "<a href=\"$url\">$label</a>"
    }

    # Pair(long,short)
    #
    # long   - The longname of an object
    # short  - The shortname of an object
    #
    # Returns the concatenation of short with long separated by a colon.
    # If short equals long, return short.

    proc Pair {long short} {
        if {$short eq $long} {
            return $short
        }

        return "$short: $long"
    }

    # QFancyFmt(quality,value)
    #
    # quality     - A quality type
    # value       - A quality value
    #
    # Returns "value (longname)", formatting the value using the format
    # subcommand.

    proc QFancyFmt {quality value} {
        return "[$quality format $value] ([$quality longname $value])"
    }
    
}





