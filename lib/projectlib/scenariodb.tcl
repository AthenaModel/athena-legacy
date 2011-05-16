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
            { a NONE                 longname "None"                       }
            { a CHECKPOINT           longname "Checkpoint/Control Point"   }
            { a CMO_CONSTRUCTION     longname "CMO -- Construction"        }
            { a CMO_DEVELOPMENT      longname "CMO -- Development (Light)" }
            { a CMO_EDUCATION        longname "CMO -- Education"           }
            { a CMO_EMPLOYMENT       longname "CMO -- Employment"          }
            { a CMO_HEALTHCARE       longname "CMO -- Healthcare"          }
            { a CMO_INDUSTRY         longname "CMO -- Industry"            }
            { a CMO_INFRASTRUCTURE   longname "CMO -- Infrastructure"      }
            { a CMO_LAW_ENFORCEMENT  longname "CMO -- Law Enforcement"     }
            { a CMO_OTHER            longname "CMO -- Other"               }
            { a COERCION             longname "Coercion"                   }
            { a CRIMINAL_ACTIVITIES  longname "Criminal Activities"        }
            { a CURFEW               longname "Curfew"                     }
            { a GUARD                longname "Guard"                      }
            { a PATROL               longname "Patrol"                     }
            { a PRESENCE             longname "Presence"                   }
            { a PSYOP                longname "PSYOP"                      }
            { a DISPLACED            longname "Displaced Person/Refugee"   }
            { a IN_CAMP              longname "In Camp"                    }
        }

        activity_gtype {
            { a NONE                 
                gtype        CIV 
                assignable   0 
                stype        {}       
                attrit_order 0}
            { a DISPLACED            
                gtype        CIV 
                assignable   1 
                stype        DISPLACED       
                attrit_order 1}
            { a IN_CAMP              
                gtype        CIV 
                assignable   1 
                stype        {}       
                attrit_order 2}

            { a NONE                 
                gtype        FRC 
                assignable   0 
                stype        {}       
                attrit_order 0}
            { a CHECKPOINT           
                gtype        FRC 
                assignable   1 
                stype        CHKPOINT 
                attrit_order 14}
            { a CMO_CONSTRUCTION     
                gtype        FRC 
                assignable   1 
                stype        CMOCONST 
                attrit_order 1}
            { a CMO_DEVELOPMENT      
                gtype        FRC 
                assignable   1 
                stype        CMODEV   
                attrit_order 2}
            { a CMO_EDUCATION        
                gtype        FRC 
                assignable   1 
                stype        CMOEDU   
                attrit_order 3}
            { a CMO_EMPLOYMENT       
                gtype        FRC 
                assignable   1 
                stype        CMOEMP   
                attrit_order 4}
            { a CMO_HEALTHCARE       
                gtype        FRC 
                assignable   1 
                stype        CMOMED   
                attrit_order 9}
            { a CMO_INDUSTRY         
                gtype        FRC 
                assignable   1 
                stype        CMOIND   
                attrit_order 5}
            { a CMO_INFRASTRUCTURE   
                gtype        FRC 
                assignable   1 
                stype        CMOINF   
                attrit_order 6}
            { a CMO_LAW_ENFORCEMENT  
                gtype        FRC 
                assignable   1 
                stype        CMOLAW   
                attrit_order 7}
            { a CMO_OTHER            
                gtype        FRC 
                assignable   1 
                stype        CMOOTHER 
                attrit_order 8}
            { a COERCION             
                gtype        FRC 
                assignable   1 
                stype        COERCION 
                attrit_order 11}
            { a CRIMINAL_ACTIVITIES  
                gtype        FRC 
                assignable   1 
                stype        CRIMINAL 
                attrit_order 10}
            { a CURFEW               
                gtype        FRC 
                assignable   1 
                stype        CURFEW   
                attrit_order 13}
            { a GUARD                
                gtype        FRC 
                assignable   1 
                stype        GUARD    
                attrit_order 16}
            { a PATROL               
                gtype        FRC 
                assignable   1 
                stype        PATROL   
                attrit_order 15}
            { a PRESENCE             
                gtype        FRC 
                assignable   0 
                stype        PRESENCE 
                attrit_order 0}
            { a PSYOP                
                gtype        FRC 
                assignable   1 
                stype        PSYOP    
                attrit_order 12}
            
            { a NONE                 
                gtype        ORG 
                assignable   0 
                stype        {}       
                attrit_order 0}
            { a CMO_CONSTRUCTION     
                gtype        ORG 
                assignable   1 
                stype        ORGCONST 
                attrit_order 1}
            { a CMO_EDUCATION        
                gtype        ORG 
                assignable   1 
                stype        ORGEDU   
                attrit_order 2}
            { a CMO_EMPLOYMENT       
                gtype        ORG 
                assignable   1 
                stype        ORGEMP   
                attrit_order 3}
            { a CMO_HEALTHCARE       
                gtype        ORG 
                assignable   1 
                stype        ORGMED   
                attrit_order 7}
            { a CMO_INDUSTRY         
                gtype        ORG 
                assignable   1 
                stype        ORGIND   
                attrit_order 4}
            { a CMO_INFRASTRUCTURE   
                gtype        ORG 
                assignable   1 
                stype        ORGINF   
                attrit_order 5}
            { a CMO_OTHER            
                gtype        ORG 
                assignable   1 
                stype        ORGOTHER 
                attrit_order 6}
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
        readfile [file join $::projectlib::library scenariodb.sql]
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
            qfancyfmt  ::projectlib::scenariodb::QFancyFmt
            qaffinity  ::simlib::qaffinity
            qcoop      ::simlib::qcooperation
            qmag       ::simlib::qmag
            qposition  ::simlib::qposition
            qsat       ::simlib::qsat
            qsaliency  ::simlib::qsaliency
            qsecurity  ::projectlib::qsecurity
            qtolerance ::simlib::qtolerance
            link       ::projectlib::scenariodb::Link
            pair       ::projectlib::scenariodb::Pair
            qfancyfmt  ::projectlib::scenariodb::QFancyFmt
        }
    }

    #-------------------------------------------------------------------
    # Components

    component db                         ;# The sqldocument(n).

    #-------------------------------------------------------------------
    # Options

    delegate option -clock to db


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

        # NEXT, register the schema sections
        $db register ::marsutil::eventq
        $db register ::marsutil::reporter
        $db register ::simlib::gram
        $db register ::simlib::mam
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
    # Tcl Import/Export
    #
    # The schema is as follows:
    #
    #    [list <tableName> <tableContent> ...]
    #
    # where <tableContent> is
    #
    #    [list [list <columnName> <columnValue> ...]
    #          ...]
    #
    # I.e., one dict per row.

    # tclexport ?-exclude? ?tables?
    #
    # tables      A list of table names
    #
    # Exports the database as a Tcl string.  If tables is given, 
    # exports the named tables.  If -exclude tables is given, exports 
    # all *but* the named tables.
    
    method tclexport {args} {
        # FIRST, process the arguments
        if {[llength $args] > 2} {
            error \
                "wrong \# args: should be \"$self export ?-exclude? ?tables?\""
        } elseif {[llength $args] == 0} {
            set exclude 0
            set tables [list]
        } elseif {[llength $args] == 1} {
            set exclude 0
            set tables [lindex $args 0]
        } else {
            require {[lindex $args 0] eq "-exclude"} \
                "Unknown option: \"[lindex $args 0]\""

            set exclude 1
            set tables [lindex $args 1]
        }

        # NEXT, create the document
        set output [list]
        
        # NEXT, export each of the requested tables; or all tables.
        if {[llength $tables] == 0} {
            set tables [$self tables]
        } elseif {$exclude} {
            set excluded $tables
            set tables [list]

            foreach name [$self tables] {
                if {$name ni $excluded} {
                    lappend tables $name
                }
            }
        }
        
        foreach name $tables {
            lassign [$db grab $name {}] grabbedName content
            
            # grab returns the empty list if there was nothing to
            # grab; we want to have the table name present with
            # an empty content string, indicated that the table
            # should be empty.  Adds the INSERT tag, so that
            # ungrab will do the right thing.
            lappend output [list $name INSERT] $content
        }
        
        # NEXT, return the document
        return $output
    }


    # tclimport data ?options...?
    #
    # data         - tclexport data set
    #
    # -clear       - Clears the RDB, defining the current schema, prior
    #                to importing.
    #
    # Imports the data into the database.  Imported tables replace
    # existing content; other tables are left alone.
    
    method tclimport {data args} {
        # FIRST, get the options
        array set opts {
            -clear  0
            -logcmd ""
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -clear  { set opts(-clear) 1               }
                default { error "Unknown option: \"$opt\"" }
            }
        }

        # NEXT, do the work in a transaction; deferred 
        # foreign key constraints will be checked at the end.

        $db transaction {
            # NEXT, clear the DB, if desired; otherwise, clear
            # the tables being loaded.
            if {$opts(-clear)} {
                $db clear
            } else {
                foreach {tableSpec content} $data {
                    lassign $tableSpec table tag
                    if {[$db exists "PRAGMA table_info('$table')"]} {
                        $db eval "DELETE FROM $table;"                
                    }
                }
            }

            # NEXT, import the tables
            $db ungrab $data
        }
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

    # Pair(a,b)
    #
    # url   - The URL
    # label - The link text
    #
    # Returns the concatenation of a and b, with b in parens.

    proc Pair {a b} {
        return "$a ($b)"
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





