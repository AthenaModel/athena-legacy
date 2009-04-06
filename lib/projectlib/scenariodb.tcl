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
# XML IMPORT/EXPORT:
#    scenariodb(n) supports automated export and import of scenario
#    files.
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
        return [readfile [file join $::projectlib::library scenariodb.sql]]
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

    delegate option -clock to db

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
        # FIRST, create the sqldocument, naming it so that it
        # will be automatically destroyed.  We don't want
        # automatic transaction batching.
        set db [sqldocument ${selfns}::db          \
                    -clock     [from args -clock] \
                    -autotrans off                 \
                    -rollback  on]
    }

    #-------------------------------------------------------------------
    # Public Methods: sqldocument(n)

    # Delegated methods
    delegate method * to db

    # safeeval args...
    #
    # Like "eval", but authorized only to query, not to change

    method safeeval {args} {
        # Allow SELECTs only.
        $db authorizer [myproc RdbAuthorizer]

        set command [list $db eval {*}$args]

        set code [catch {
            uplevel 1 $command
        } result]
        
        # Open it up again.
        $db authorizer ""

        if {$code} {
            error "query error: $result"
        } else {
            return $result
        }
    }


    # safequery sql
    #
    # Like "query", but authorized only to query, not to change

    method safequery {sql} {
        # Allow SELECTs only.
        $db authorizer [myproc RdbAuthorizer]

        set code [catch {$db query $sql} result]
        
        # Open it up again.
        $db authorizer ""

        if {$code} {
            error "query error: $result"
        } else {
            return $result
        }
    }

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
    # XML Import/Export
    #
    # The schema is as follows:
    #
    #    <database>
    #        <table name="thetable">
    #            <row>
    #                <column name="thecolumn">
    #                value
    #                </column>
    #            </row>
    #        </table>
    #    </database>

    # export ?-exclude? ?tables?
    #
    # tables      A list of table names
    #
    # Exports the database as XML.  If tables is given, exports the named
    # tables.  If -exclude tables is given, exports all *but* the named
    # tables.
    
    method export {args} {
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
        set doc  [dom createDocument database]
        set root [$doc documentElement]

        # NEXT, add the user_version of the schema to the root.
        set version [$db onecolumn {PRAGMA user_version}]

        if {$version ne ""} {
            $root setAttribute dbschema $version
        }
        
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
            $self ExportTable $doc $name
        }
        
        # NEXT, return the document
        set output [$doc asXML -indent 4 -doctypeDeclaration yes]
        $doc delete
        
        return $output
    }

    # ExportTable doc table
    #
    # doc      a tDOM document object
    # table    The name of a table in the DB
    #
    # Adds a table element to the XML document for this table.

    method ExportTable {doc table} {
        # FIRST, add a "table" element for this table
        set root  [$doc documentElement]
        set tnode [$doc createElement table]

        $tnode setAttribute name $table

        # NEXT, get the column types
        $db eval "PRAGMA table_info('$table')" tinfo {
            set ctype($tinfo(name)) $tinfo(type)
        }

        # NEXT, add each row.
        set count 0

        $db eval "SELECT * FROM $table" row {
            unset -nocomplain row(*)
            incr count

            set rnode [$doc createElement row]
            $tnode appendChild $rnode

            foreach col [array names row] {
                set cnode [$doc createElement column]
                $rnode appendChild $cnode
                $cnode setAttribute name $col

                if {$ctype($col) eq "BLOB"} {
                    binary scan $row($col) H* hex
                    set vnode [$doc createTextNode $hex]
                } else {
                    set vnode [$doc createTextNode $row($col)]
                }

                $cnode appendChild $vnode
            }
        }

        # NEXT, if there were any rows, save this table.  Otherwise,
        # destroy it.
        if {$count > 0} {
            $root appendChild $tnode
        } else {
            $tnode delete
        }
    }

    # import xmltext ?options...?
    #
    # xmltext   XML text
    #
    # -clear         Clears the RDB, defining the current schema, prior
    #                to importing.
    # -logcmd cmd    A command prefix taking a message string as its 
    #                single argument.
    #
    # Imports the XML text into the database.  Imported tables replace
    # existing content; other tables are left alone.
    

    method import {xmltext args} {
        # FIRST, get the options
        array set opts {
            -clear  0
            -logcmd ""
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -clear  { set opts(-clear) 1               }
                -logcmd { set opts(-logcmd) [lshift args]  }
                default { error "Unknown option: \"$opt\"" }
            }
        }

        # NEXT, parse the XML input
        set doc [dom parse $xmltext]
        set root [$doc documentElement]

        # NEXT, clear the DB, if desired
        if {$opts(-clear)} {
            $db clear
        }

        # NEXT, get the schema version.
        # TBD: Ultimately, we'll need to handle this explicitly.
        set version [$root getAttribute dbschema]
        
        $db eval "PRAGMA user_version=$version"

        # NEXT, import the tables
        try {
            foreach node [$root getElementsByTagName table] {
                $self ImportTable $node $opts(-logcmd)
            }
        } finally {
            $doc delete
        }
    }

    method ImportTable {tnode logcmd} {
        # FIRST, get the table's name
        set table [$tnode getAttribute name]

        # NEXT, verify that the table exists.
        if {![$db exists "PRAGMA table_info('$table')"]} {
            callwith $logcmd "Skipping $table"
            return
        }

        callwith $logcmd "Importing $table"

        # NEXT, get the table's column names and BLOB columns
        set blobs [list]
        set ocols [list]

        $db eval "PRAGMA table_info('$table')" tinfo {
            lappend ocols $tinfo(name)

            if {$tinfo(type) eq "BLOB"} {
                lappend blobs $tinfo(name)
            }
        }

        # NEXT, get the rows.
        set rnodes [$tnode getElementsByTagName row]

        # NEXT, all rows will have the same columns.  Get the actual list
        # of columns from the first row.
        set rdict [$self ImportRow [lindex $rnodes 0]]

        set cnames [dict keys $rdict]

        # NEXT, use the names to create the query we'll use to insert
        # data into the database.

        foreach name $cnames {
            if {$name in $ocols} {
                lappend ccols $name
                lappend cvars "\$row($name)"
            } else {
                callwith $logcmd "    Skipping undefined column $name"
            }
        }

        set query [tsubst {
            |<--
            INSERT OR REPLACE INTO ${table}([join $ccols ,])
            VALUES([join $cvars ,])
        }]

        # NEXT, import the rows.
        $db eval "DELETE FROM $table;"

        foreach rnode $rnodes {
            array set row [$self ImportRow $rnode]

            foreach name $blobs {
                set row($name) [binary format H* $row($name)]
            }

            $db eval $query
        }
    }

    # ImportRow rnode
    #
    # rnode    A row node.
    #
    # Returns the row's data as a dictionary.

    method ImportRow {rnode} {
        set rdict [list]

        foreach cnode [$rnode getElementsByTagName column] {
            lappend rdict [$cnode getAttribute name] [$cnode text]
        }

        return $rdict
    }

    #-------------------------------------------------------------------
    # Procs

    # RdbAuthorizer op args
    #
    # op        The SQLite operation
    # args      Related arguments; ignored.
    #
    # Allows SELECTs and READs, which are needed to query the database;
    # all other operations are denied.

    proc RdbAuthorizer {op args} {
        if {$op eq "SQLITE_SELECT" || $op eq "SQLITE_READ"} {
            return SQLITE_OK
        } elseif {$op eq "SQLITE_FUNCTION"} {
            return SQLITE_OK
        } else {
            return SQLITE_DENY
        }
    }
}





