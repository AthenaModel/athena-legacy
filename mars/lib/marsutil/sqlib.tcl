#-----------------------------------------------------------------------
# TITLE:
#	sqlib.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: marsutil(n) Tcl Utilities
#
#	SQLite utilities
#
#       SQLite is a small SQL database manager for Tcl and other
#       languages.  This module defines a number of tools for use
#       with SQLite database objects.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Exported commands

namespace eval ::marsutil:: {
    namespace export sqlib
}

#-----------------------------------------------------------------------
# sqlib Ensemble

snit::type ::marsutil::sqlib {
    # Make it an ensemble
    pragma -hastypeinfo 0 -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Ensemble subcommands

    # clear db
    #
    # db     The fully-qualified SQLite database command.
    #
    # Deletes all persistent and temporary schema elements from the 
    # database.  Attached databases are ignored.

    typemethod clear {db} {
        set sql [list]

        $db eval {
            SELECT type AS dbtype, name FROM sqlite_master
            WHERE type IN ('table', 'view')
            UNION ALL
            SELECT type AS dbtype, name FROM sqlite_temp_master 
            WHERE type IN ('table', 'view')
        } {
            switch -exact -- $dbtype {
                table {
                    if {![string match "sqlite*" $name]} {
                        lappend sql "DROP TABLE $name;"
                    } else {
                        lappend sql "DELETE FROM $name;"
                    }
                }

                view {
                    lappend sql "DROP VIEW $name;"
                }
                default {
                    # Do nothing
                }
            }
        }

        $db eval [join $sql "\n"]
    }

    # saveas db filename
    #
    # db          The fully-qualified SQLite database command.
    # filename    A file name
    #
    # Saves a copy of the persistent contents of db as a new 
    # database file called filename.  It's an error if filename
    # already exists.

    typemethod saveas {db filename} {
        require {![file exists $filename]} \
            "File already exists: \"$filename\""

        # FIRST, create the saveas database.  This might throw
        # an error if the database cannot be opened.
        sqlite3 sadb $filename

        # NEXT, copy the schema and the user_version
        sadb transaction {
            set ver [$db eval {PRAGMA user_version}]

            sadb eval "PRAGMA user_version=$ver"

            $db eval {
                SELECT sql FROM sqlite_master 
                WHERE sql NOT NULL
                AND name NOT GLOB 'sqlite*'
            } {
                sadb eval $sql
            }
        }

        # NEXT, close the saveas database, and attach it to
        # db temporarily so we can copy tables.  If db is
        # in a transaction, we need to commit it. (Sigh!)

        sadb close

        $db eval "ATTACH DATABASE '$filename' AS saveas"

        # NEXT, copy the tables
        set tableList [$db eval {
            SELECT name FROM sqlite_master 
            WHERE type='table'
            AND name NOT GLOB 'sqlite*'
        }]

        $db transaction {
            foreach table $tableList {
                $db eval "INSERT INTO saveas.$table SELECT * FROM main.$table"
            }
        }

        # NEXT, detach the saveas database.
        $db eval {DETACH DATABASE saveas}
    }

    # compare db1 db2
    #
    # db1     A fully-qualified SQLite database command.
    # db2     Another fully-qualified SQLite database command.
    #
    # Compares the two databases, ignoring attached databases and
    # temporary entities.  Returns a string describing the first
    # difference found, or "" if no differences are found.  This is
    # not a particularly fast operation for large databases.
    #
    # First the schema is compared, and then the content of the
    # individual tables.

    typemethod compare {db1 db2} {
        set rows [list]

        # FIRST, get the rows from db1's master table
        $db1 eval {
            SELECT * FROM sqlite_master
            WHERE name NOT GLOB "sqlite*"
            ORDER BY name
        } row1 {
            lappend rows [array get row1]
        }

        # NEXT, compare them against the rows from db2's master table
        $db2 eval {
            SELECT * FROM sqlite_master
            WHERE name NOT GLOB "sqlite*"
            ORDER BY name
        } row2 {
            if {[llength $rows] == 0} {
                return \
                    "In $db2, found $row2(type) $row2(name), missing in $db1"
            }

            array set row1 [lshift rows]

            if {$row1(name) ne $row2(name)} {
                return \
    "In $db2, found $row2(type) $row2(name), expected $row1(type) $row1(name)"
            }

            foreach column {type tbl_name sql} {
                if {$row1($column) ne $row2($column)} {
                    return \
                        "Mismatch on \"$column\" for $row1(type) $row1(name)"
                }
            }
        }

        if {[llength $rows] > 0} {
            array set row1 [lshift rows]

            return "In $db1, found $row1(type) $row1(name), missing in $db2"
        }

        # NEXT, compare the individual tables.
        set tableList [$db1 eval {
            SELECT name FROM sqlite_master
            WHERE name NOT GLOB 'sqlite*'
            AND type == 'table'
            ORDER BY name
        }]

        foreach table $tableList {
            # FIRST, get all of the rows in db1's table
            set rows [list]
            array unset row1
            array unset row2

            $db1 eval "
                SELECT * FROM $table
            " row1 {
                unset -nocomplain row1(*)
                lappend rows [array get row1]
            }

            # NEXT, compare against each row in db2's table
            $db2 eval "
                SELECT * FROM $table
            " row2 {
                unset -nocomplain row2(*)

                if {[llength $rows] == 0} {
                    return \
                        "Table $table contains more rows in $db2 than in $db1"
                }

                array unset row1
                array set row1 [lshift rows]

                foreach column [array names row1] {
                    if {$row1($column) ne $row2($column)} {
                        return \
      "Mismatch on \"$column\" for table $table:\n$db1: [array get row1]\n$db2: [array get row2]"
                    }
                }
            }

            if {[llength $rows] > 0} {
                return "Table $table contains more rows in $db1 than in $db2"
            }
        }

        return ""
    }


    # tables db
    #
    # db     The fully-qualified SQLite database command.
    #
    # Returns a list of the names of the tables defined in the database.
    # Includes attached databases.

    typemethod tables {db} {
        set cmd {
            SELECT name FROM sqlite_master WHERE type='table'
            UNION ALL
            SELECT name FROM sqlite_temp_master WHERE type='table'
        }

        $db eval {PRAGMA database_list} {
            if {$name != "temp" && $name != "main"} {
                append cmd \
                    "UNION ALL SELECT '$name.' || name FROM $name.sqlite_master
                     WHERE type='table'"
            }
        }

        append cmd { ORDER BY 1 }

        return [$db eval $cmd]
    }

    # schema db ?table?
    #
    # db      The fully-qualified SQLite database command.
    # table   A table name or glob-pattern.
    #
    # Returns the SQL statements that define the schema.  If table
    # is given, returns only those tables/views/indices whose names
    # match the pattern.  Skips attached tables.

    typemethod schema {db {table "*"}} {
        set cmd {
            SELECT sql FROM sqlite_master 
            WHERE name GLOB $table
            AND sql NOT NULL 
            UNION ALL 
            SELECT sql FROM sqlite_temp_master
            WHERE name GLOB $table
            AND sql NOT NULL
        }

        return [join [$db eval $cmd] ";\n\n"]
    }

    # query db sql ?options...?
    #
    # db            The fully-qualified SQLite database command.
    # sql           An SQL query.
    # options       Formatting options
    #
    #   -mode mc|list        Display mode: mc (multicolumn) or list
    #   -maxcolwidth num     Maximum displayed column width, in 
    #                        characters.
    #   -labels list         List of column labels.
    #   -headercols n        Number of header columns (default 0)
    #
    # Executes the query and accumulates the results into a nice
    # formatted output.
    #
    # If -mode is "list", each record is output in two-column
    # format: name  value, etc., with a blank line between records.
    #
    # If -mode is "mc" (the default) then multicolumn output is used.
    # In this mode, long values are truncated to -maxcolwidth.
    #
    # In either case, newlines are escaped.  If -labels is specified,
    # it is a list of column labels which are displayed instead of the 
    # column names used in the query.
    #
    # If -mode is "mc" and -headercols is greater than 0, then 
    # duplicate entries in the leading columns are omitted.

    typemethod query {db sql args} {
        # FIRST, get options.
        array set opts {
            -mode         mc
            -maxcolwidth  30
            -labels       {}
            -headercols   0
        }
        array set opts $args

        # NEXT, if the mode is "list", output the records individually
        if {$opts(-mode) eq "list"} {
            # FIRST, do the query; we'll output the data as we go.
            set out ""
            set labels {}
            set count 0

            $db eval $sql row {
                # FIRST, The first time figure out what the labels are.
                if {[llength $labels] == 0} {
                    # Did they specify labels?
                    if {[llength $opts(-labels)] > 0} {
                        set labels $opts(-labels)
                    } else {
                        set labels $row(*)
                    }

                    # What's the maximum label width?
                    set labelWidth [lmaxlen $labels]
                }

                # NEXT, output the record
                incr count

                if {$count > 1} {
                    append out "\n"
                }

                foreach label $labels name $row(*) {
                    set leader [string repeat " " $labelWidth]

                    regsub -all {\n} [string trimright $row($name)] \
                        "\n$leader  " value

                    append out \
                        [format "%-*s  %s\n" $labelWidth $label $value]
                }
            }
            
            # NEXT, return the result.
            return $out
        }

        # NEXT, if the mode is not "mc", that's an error.
        if {$opts(-mode) ne "mc"} {
            error "invalid -mode: \"$opts(-mode)\""
        }

        # NEXT, get the data; accumulate column widths as we go.
        set rows {}
        set names {}
        $db eval $sql row {
            if {[llength $names] eq 0} {
                set names $row(*)
                unset row(*)

                foreach name $names {
                    set colwidth($name) 0
                }
            }

            foreach name $names {
                set row($name) [string map [list \n \\n] $row($name)]

                set len [string length $row($name)]

                if {$opts(-maxcolwidth) > 0} {
                    if {$len > $opts(-maxcolwidth)} {
                        # At least three characters
                        set len [::marsutil::max $opts(-maxcolwidth) 3]
                        set end [expr {$len - 4}]
                        set row($name) \
                            "[string range $row($name) 0 $end]..."
                    }
                }

                if {$len > $colwidth($name)} {
                    set colwidth($name) $len
                }
            }

            lappend rows [array get row]
        }

        if {[llength $names] == 0} {
            return ""
        }

        # NEXT, include the label widths.
        if {[llength $opts(-labels)] > 0} {
            set labels $opts(-labels)
        } else {
            set labels $names
        }

        foreach label $labels name $names {
            set len [string length $label]

            if {$len > $colwidth($name)} {
                set colwidth($name) $len
            }
        }

        # NEXT, format the header lines.
        set out ""

        foreach label $labels name $names {
            append out [format "%-*s " $colwidth($name) $label]
        }
        append out "\n"

        foreach name $names {
            append out [string repeat "-" $colwidth($name)]
            append out " "

            # Initialize the lastrow array
            set lastrow($name) ""
        }
        append out "\n"
        
        # NEXT, format the rows
        foreach entry $rows {
            array set row $entry

            set i 0
            foreach name $names {
                # Append either the column value or a blank, with the
                # required width
                if {$i < $opts(-headercols) && 
                    $row($name) eq $lastrow($name)} {
                    append out [format "%-*s " $colwidth($name) "\""]
                } else {
                    append out [format "%-*s " $colwidth($name) $row($name)]
                }
                incr i
            }
            append out "\n"

            array set lastrow $entry
        }

        return $out
    }

    # mat db table iname jname ename ?options?
    #
    # db      An sqlite3 database object.
    # table   A table in the database.
    # iname   The name of the "i" or "row" column.
    # jname   The name of the "j" or "column" column.
    # ename   The name of the "element" column.
    # 
    # Options:
    #    -ikeys       A list of the "i" column keys, in the desired order
    #    -jkeys       A list of the "j" column keys, in the desired order
    #    -returnkeys  0|1.  If 1, the key lists are returned.
    #    -defvalue    Value for empty cells.
    #
    # Queries the named table, producing a matrix whose elements are
    # drawn from the element column, with the iname column defining
    # the rows and the jname column defining the columns.  If -ikeys
    # or -jkeys are specified, iname or jname values not included in
    # the lists will be excluded from the output, and the matrix rows
    # and columns will be in the order specified.  Otherwise, there
    # will be a row for each unique value in the iname column and a
    # column for each unique value in the jname column.
    #
    # Normally, the command returns the matrix.  If -returnkeys is 1,
    # the command returns a list {matrix ikeys jkeys}.

    typemethod mat {db table iname jname ename args} {
        # FIRST, get the options
        array set opts {
            -ikeys      ""
            -jkeys      ""
            -returnkeys 0
            -defvalue   ""
        }
        array set opts $args

        # NEXT, if no keys are specified, get the full list.
        if {[llength $opts(-ikeys)] == 0} {
            set opts(-ikeys) [rdb query "
                SELECT $iname FROM $table GROUP BY $iname
            "]
        }

        if {[llength $opts(-jkeys)] == 0} {
            set opts(-jkeys) [rdb query "
                SELECT $jname FROM $table GROUP BY $jname
            "]
        }

        # NEXT, get the matrix.
        set mat [mat new \
                     [llength $opts(-ikeys)] \
                     [llength $opts(-jkeys)] \
                     $opts(-defvalue)]

        rdb eval "
            SELECT $iname AS iname, 
                   $jname AS jname, 
                   $ename AS element
            FROM   $table
            WHERE  $iname IN ('[join $opts(-ikeys) ',']')
            AND    $jname IN ('[join $opts(-jkeys) ',']')
        " {
            set i [lsearch -exact $opts(-ikeys) $iname]
            set j [lsearch -exact $opts(-jkeys) $jname]

            lset mat $i $j $element
        }

        # NEXT, return the result.
        if {$opts(-returnkeys)} {
            return [list $mat $opts(-ikeys) $opts(-jkeys)]
        } else {
            return $mat
        }
    }

    # insert db table dict
    #
    # db      A database handle
    # table   Name of a table in db
    # dict    A dictionary whose keys are column names in the table
    #
    # Inserts the contents of dict into table.  This will be less
    # efficient than an explicit "INSERT INTO" with hardcoded column
    # names, but where performance isn't an issue it wins on 
    # maintainability.
    #
    # WARNING: None of the dict columns can be named "sqlib_table".

    typemethod insert {db table dict} {
        set sqlib_table $table
        set keys [dict keys $dict]

        dict with dict {
            $db eval [tsubst {
                INSERT INTO ${sqlib_table}([join $keys ,])
                VALUES(\$[join $keys ,\$])
            }]
        }
    }

    # replace db table dict
    #
    # db      A database handle
    # table   Name of a table in db
    # dict    A dictionary whose keys are column names in the table
    #
    # Inserts or replaces the contents of dict into table.  This will 
    # be less efficient than an explicit "INSERT OR REPLACE INTO" with 
    # hardcoded column names, but where performance isn't an issue it 
    # wins on  maintainability.
    #
    # WARNING: None of the dict columns can be named "sqlib_table".

    typemethod replace {db table dict} {
        set sqlib_table $table
        set keys [dict keys $dict]

        dict with dict {
            $db eval [tsubst {
                INSERT OR REPLACE INTO ${sqlib_table}([join $keys ,])
                VALUES(\$[join $keys ,\$])
            }]
        }
    }
}





