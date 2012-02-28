#-----------------------------------------------------------------------
# FILE: gramdb2.tcl
#
#   Parser for the gramdb(5) V2.0 database format.
#
# PACKAGE:
#   simlib(n) -- Simulation Infrastructure Package
#
# PROJECT:
#   Mars Simulation Infrastructure Library
#
# AUTHOR:
#   Will Duquette
#
#-----------------------------------------------------------------------

namespace eval ::simlib:: {
    namespace export gramdb
}

#-----------------------------------------------------------------------
# Module: gramdb
#
# This parser is based on tabletext(n) which provides a generic
# mechanism for loading data from text files into SQLite3 tables.

snit::type ::simlib::gramdb {
    # Make it a singleton
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Import needed commands
        namespace import ::marsutil::* 
    }

    #-------------------------------------------------------------------
    # sqlsection(i) implementation
    #
    # The following variables and routines implement the module's 
    # sqlsection(i) interface.

    # List of the table names.
    typevariable tableNames {
        gramdb_c
        gramdb_civ_g
        gramdb_frc_g
        gramdb_n
        gramdb_mn
        gramdb_gc
        gramdb_civ_fg
        gramdb_frc_fg
        gramdb_coop_fg
    }

    # sqlsection title
    #
    # Returns a human-readable title for the section

    typemethod {sqlsection title} {} {
        return "gramdb(n)"
    }

    # sqlsection schema
    #
    # Returns the section's persistent schema definitions.

    typemethod {sqlsection schema} {} {
        return [readfile [file join $::simlib::library gramdb2.sql]]
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
        return [list]
    }

    #-------------------------------------------------------------------
    # Type Components

    typecomponent tt               ;# tabletext(n) object

    #-------------------------------------------------------------------
    # Lookup Tables

    # Concern Definitions
    typevariable concernDefinitions {
        table gramdb_c {
            record c AUT { }
            record c QOL { }
            record c CUL { } 
            record c SFT { } 
        }
    }

    #-------------------------------------------------------------------
    # Type Variables

    typevariable initialized 0     ;# 1 if initialized, 0 otherwise.
                                    # gramdb is initialized on first use.

    #-------------------------------------------------------------------
    # Initialization

    typemethod Initialize {} {
        # FIRST, skip if we're already initialized
        if {$initialized} {
            return
        }

        set initialized 1

        # NEXT, define the parser.
        set tt [tabletext ${type}::tt]

        #---------------------------------------------------------------
        # Table -- gramdb_c

        $tt table gramdb_c
        
        $tt field gramdb_c c -key                           \
            -validator [mytypemethod ValidateSymbolicName]

        #---------------------------------------------------------------
        # Table -- gramdb_n

        $tt table  gramdb_n                                 \
            -tablevalidator  [mytypemethod Val_gramdb_n]

        $tt field gramdb_n n -key                           \
            -validator [mytypemethod ValidateSymbolicName]

        #---------------------------------------------------------------
        # Table -- gramdb_civ_g

         $tt table gramdb_civ_g                                     \
           -tablevalidator  [mytypemethod Val_gramdb_g]
 
        $tt field gramdb_civ_g g -key                               \
            -validator [mytypemethod ValidateSymbolicName]

        $tt field gramdb_civ_g n -required                          \
            -validator [list $tt validate foreign gramdb_n n]

        $tt field gramdb_civ_g population -required                 \
            -validator [mytypemethod ValidateIntMagnitude]

        #---------------------------------------------------------------
        # Table -- gramdb_frc_g

         $tt table gramdb_frc_g                                  \
           -tablevalidator  [mytypemethod Val_gramdb_g]
 
        $tt field gramdb_frc_g g -key                            \
            -validator [mytypemethod ValidateSymbolicName]

        #---------------------------------------------------------------
        # Table -- gramdb_mn

        $tt table gramdb_mn -dependson gramdb_n                  \
            -tablevalidator  [mytypemethod Val_gramdb_mn]        \
            -recordvalidator [mytypemethod Val_gramdb_mn_record]

        $tt field gramdb_mn m -key                               \
            -validator [list $tt validate foreign gramdb_n n]
        $tt field gramdb_mn n -key                               \
            -validator [list $tt validate foreign gramdb_n n]
        $tt field gramdb_mn proximity                            \
            -validator [list $tt validate vtype eproximity]
        $tt field gramdb_mn effects_delay                        \
            -validator [list $tt validate vtype ::simlib::rmagnitude]


        #---------------------------------------------------------------
        # Table -- gramdb_gc
        
        $tt table gramdb_gc -dependson {gramdb_civ_g gramdb_c} \
            -tablevalidator [mytypemethod Val_gramdb_gc]

        $tt field gramdb_gc g -key \
            -validator [list $tt validate foreign gramdb_civ_g g]
        $tt field gramdb_gc c -key \
            -validator [list $tt validate foreign gramdb_c c]

        $tt field gramdb_gc sat0 \
            -validator [mytypemethod ValidateQuality qsat]
        $tt field gramdb_gc saliency \
            -validator [mytypemethod ValidateQuality qsaliency]
        
        #---------------------------------------------------------------
        # Table -- gramdb_civ_fg
        
        $tt table gramdb_civ_fg -dependson gramdb_civ_g \
            -tablevalidator [mytypemethod Val_gramdb_civ_fg]

        $tt field gramdb_civ_fg f -key \
            -validator [list $tt validate foreign gramdb_civ_g g]
        $tt field gramdb_civ_fg g -key \
            -validator [list $tt validate foreign gramdb_civ_g g]

        $tt field gramdb_civ_fg rel \
            -validator [mytypemethod ValidateQuality qrel]

        #---------------------------------------------------------------
        # Table -- gramdb_frc_fg
        
        $tt table gramdb_frc_fg -dependson gramdb_frc_g \
            -tablevalidator [mytypemethod Val_gramdb_frc_fg]

        $tt field gramdb_frc_fg f -key \
            -validator [list $tt validate foreign gramdb_frc_g g]
        $tt field gramdb_frc_fg g -key \
            -validator [list $tt validate foreign gramdb_frc_g g]

        $tt field gramdb_frc_fg rel \
            -validator [mytypemethod ValidateQuality qrel]

        #---------------------------------------------------------------
        # Table -- gramdb_coop_fg
        
        $tt table gramdb_coop_fg -dependson {gramdb_civ_g gramdb_frc_g} \
            -tablevalidator [mytypemethod Val_gramdb_coop_fg]

        $tt field gramdb_coop_fg f -key \
            -validator [list $tt validate foreign gramdb_civ_g g]
        $tt field gramdb_coop_fg g -key \
            -validator [list $tt validate foreign gramdb_frc_g g]

        $tt field gramdb_coop_fg coop0 \
            -validator [mytypemethod ValidateQuality qcooperation]
    }

    #-------------------------------------------------------------------
    # Generic Validators
    #
    # All validators take at least three arguments:
    #
    # db         The SQLite3 or sqldocument(n) object
    # table      The current table name
    # value      The value to validate
    #
    # Some take additional arguments at the beginning of the argument
    # list, to parameterize the validator.
    

    # ValidateSymbolicName db table value
    #
    # The value must be an "identifier" (see marsutil(n)); it
    # will be converted to uppercase.

    typemethod ValidateSymbolicName {db table value} {
        identifier validate $value
        return [string toupper $value]
    }


    # ValidateQuality qual db table value
    #
    # qual       An quality(n) object
    #
    # Value must be a valid value for the quality; the 
    # equivalent "value" is returned.

    typemethod ValidateQuality {qual db table value} {
        $qual validate $value
        return [$qual value $value]
    }


    # ValidateIntMagnitude db table value
    #
    # The value must be an integer value
    # greater than or equal to zero.

    typemethod ValidateIntMagnitude {db table value} {
        # TBD: Should use count, once count is updated.
        if {![string is integer -strict $value]} {
            invalid "non-integer input: \"$value\""
        }
            
        if {$value < 0} {
            invalid "value is negative: \"$value\""
        }

        return $value
    }

    #-------------------------------------------------------------------
    # Table -- gramdb_civ_g, gramdb_frc_g

    typemethod Val_gramdb_g {db table} {
        # Must have at least one entry
        if {![$db exists "SELECT g FROM $table"]} {
            invalid "Table $table is empty."
        }
    }


    #-------------------------------------------------------------------
    # Table -- gramdb_n

    typemethod Val_gramdb_n {db table} {
        # FIRST, We must have at least one neighborhood
        if {![$db exists {SELECT n FROM gramdb_n}]} {
            invalid "no neighborhoods defined"
        }
    }

    #-------------------------------------------------------------------
    # Table -- gramdb_mn

    typemethod Val_gramdb_mn {db table} {
        # Fill out table with default values: HERE when m==n, FAR otherwise.

        set nbhoods [$db eval {SELECT n FROM gramdb_n}]

        foreach m $nbhoods {
            foreach n $nbhoods {
                let prox {$m == $n ? "HERE" : "FAR"}

                # Insert the record, if it doesn't exist
                $db eval {
                    INSERT OR IGNORE INTO gramdb_mn(m,n) 
                    VALUES($m,$n)
                }
            }
        }
        
        $db eval {
            UPDATE gramdb_mn
            SET proximity = "HERE"
            WHERE m = n AND proximity IS NULL;
            
            UPDATE gramdb_mn
            SET proximity = "FAR"
            WHERE m != n AND proximity IS NULL;
        }
    }
    
    typemethod Val_gramdb_mn_record {db table rowid} {
        # Verify that HERE is set only for m = n,
        # and that effects_delay is 0.0 when m = n.

        $db eval "SELECT * FROM $table WHERE rowid=\$rowid" row {
            if {$row(proximity) ne ""} {
                if {$row(m) eq $row(n)} {
                    if {$row(proximity) ne "HERE"} {
                        invalid "mismatch, proximity must be HERE when m = n"
                    }
                } else {
                    if {$row(proximity) eq "HERE"} {
                        invalid "mismatch, proximity must not be HERE when m != n"
                    }
                }
            }
            
            if {$row(effects_delay) ne "" && $row(m) eq $row(n)} {
                if {$row(effects_delay) != 0.0} {
                    invalid "effects_delay must be 0.0 when m = n"
                }
            }
        }
    }
    
    #-------------------------------------------------------------------
    # Table -- gramdb_gc
    
    typemethod Val_gramdb_gc {db table} {
        # Insert rows for all missing combinations of g and c
        # with compatible types.  We'll get the defaults from the
        # schema.
        
        $db eval {
            SELECT g,c
            FROM gramdb_civ_g JOIN gramdb_c
        } {
            $db eval {
                INSERT OR IGNORE INTO gramdb_gc(g,c) VALUES($g,$c)
            }
        }
    }

    #-------------------------------------------------------------------
    # Table -- gramdb_civ_fg

    typemethod Val_gramdb_civ_fg {db table} {
        # Fill out table with default values: 1.0 when f==g, 0.0 otherwise.
        # Insert rows for all missing combinations of f and g.

        $db eval {
            SELECT F.g AS f,
                   G.g AS g
            FROM gramdb_civ_g AS F JOIN gramdb_civ_g AS G    
        } {
            if {$f eq $g} {
                set rel 1.0
            } else {
                set rel 0.0
            }

            $db eval {
                INSERT OR IGNORE INTO gramdb_civ_fg(f,g,rel) 
                VALUES($f,$g,$rel)
            }
        }
    }

    #-------------------------------------------------------------------
    # Table -- gramdb_frc_fg

    typemethod Val_gramdb_frc_fg {db table} {
        # Fill out table with default values: 1.0 when f==g, 0.0 otherwise.
        # Insert rows for all missing combinations of f and g.

        $db eval {
            SELECT F.g AS f,
                   G.g AS g
            FROM gramdb_frc_g AS F JOIN gramdb_frc_g AS G    
        } {
            if {$f eq $g} {
                set rel 1.0
            } else {
                set rel 0.0
            }

            $db eval {
                INSERT OR IGNORE INTO gramdb_frc_fg(f,g,rel) 
                VALUES($f,$g,$rel)
            }
        }
    }
    
    #-------------------------------------------------------------------
    # Table -- gramdb_coop_fg

    typemethod Val_gramdb_coop_fg {db table} {
        # Fill out table with default values.
        
        $db eval {
            SELECT F.g AS f,
                   G.g AS g
            FROM gramdb_civ_g AS F JOIN gramdb_frc_g AS G    
        } {
            $db eval {
                INSERT OR IGNORE INTO gramdb_coop_fg(f,g,coop0) 
                VALUES($f,$g,50.0)
            }
        }
    }

    
    #-------------------------------------------------------------------
    # Public Type Methods: Loading data

    # loadfile dbfile ?db?
    #
    # dbfile     A gramdb(5) text file
    # db         An sqldocument(n) in which to load the data.  One is
    #            created if no database is specified.
    #
    # Parses the contents of the named file into the relevant tables
    # in the db, returning the name of the db.

    typemethod loadfile {dbfile {db ""}} {
        $type Initialize

        if {$db eq ""} {
            set db [$type CreateDatabase]
        } elseif {$type ni [$db sections]} {
            error "schema not defined"
        }

        $db unlock $tableNames
        $tt loadfile $db $dbfile $concernDefinitions
        $db lock $tableNames

        return $db
    }

    # load text ?db?
    #
    # text       A gramdb(5) text string
    # db         An sqldocument(n) in which to load the data.  One is
    #            created if no database is specified.
    #
    # Parses the contents of the text string into the relevant tables
    # in the db, returning the name of the db.

    typemethod load {text {db ""}} {
        $type Initialize

        if {$db eq ""} {
            set db [$type CreateDatabase]
        } elseif {$type ni [$db sections]} {
            error "schema not defined"
        }

        $db unlock $tableNames
        $tt load $db $text $concernDefinitions
        $db lock $tableNames

        return
    }

    # mkperfdb db options...
    #
    # db         An sqldocument(n) in which to load the data.
    #
    # Options:
    #
    #   -nbhoods   num    Number of neighborhoods; defaults to 10
    #   -civgroups num    Number of civilian groups per nbhood; defaults to 2
    #   -frcgroups num    Number of force groups; defaults to 4
    #
    # Populates a gramdb2 database for performance testing
    # given the option values.  The database will have these characteristics:
    #
    # * -nbhoods neighborhoods.
    # * -civgroups civilian groups in each neighborhood.
    # * -frcgroups force groups
    # * All proximities are NEAR.
    # * All effects_delays are 0.0.
    # * All satisfaction levels are 0.0.
    # * All saliencies are 1.0.
    # * All cooperation levels are 50.0
    # * All populations are 1000
    # * All relationships are 1.0, -0.5, +0.5.

    typemethod mkperfdb {db args} {
        # FIRST, get the defaults
        array set opts {
            -nbhoods   10
            -civgroups 2
            -frcgroups 4
        }

        # NEXT, get the option values.
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -nbhoods   -
                -civgroups -
                -frcgroups {
                    set opts($opt) [lshift args]
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }

        # NEXT, make sure the schema is defined.
        if {$type ni [$db sections]} {
            error "schema not defined"
        }

        # NEXT, clear just the gramdb2 tables.
        $db eval {
            DELETE FROM gramdb_c;
            DELETE FROM gramdb_civ_g;
            DELETE FROM gramdb_frc_g;
            DELETE FROM gramdb_n;
            DELETE FROM gramdb_mn;
            DELETE FROM gramdb_gc;
            DELETE FROM gramdb_civ_fg;
            DELETE FROM gramdb_frc_fg;
            DELETE FROM gramdb_coop_fg;
        }

        # NEXT, gramdb_c
        $db eval {
            INSERT INTO gramdb_c(c) VALUES('AUT');
            INSERT INTO gramdb_c(c) VALUES('CUL');
            INSERT INTO gramdb_c(c) VALUES('QOL');
            INSERT INTO gramdb_c(c) VALUES('SFT');
        }

        # NEXT, gramdb_n
        for {set i 1} {$i <= $opts(-nbhoods)} {incr i} {
            set n "N$i"

            $db eval {
                INSERT INTO gramdb_n(n) VALUES($n);
            }
        }

        # NEXT, gramdb_civ_g
        set letters "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        $db eval {SELECT n FROM gramdb_n} {
            for {set i 0} {$i < $opts(-civgroups)} {incr i} {
                set g "C[string range $n 1 end][string index $letters $i]"

                $db eval {
                    INSERT INTO gramdb_civ_g(g,n,population)
                    VALUES($g,$n,1000)
                }
            }
        }

        # NEXT, gramdb_frc_g
        for {set i 1} {$i <= $opts(-frcgroups)} {incr i} {
            set g "F$i"

            $db eval {
                INSERT INTO gramdb_frc_g(g) VALUES($g);
            }
        }

        # NEXT, gramdb_mn
        $db eval {
            SELECT M.n AS m, N.n AS n
            FROM gramdb_n AS M JOIN gramdb_n AS N
        } {
            if {$m eq $n} {
                set proximity HERE
            } else {
                set proximity NEAR
            }

            $db eval {
                INSERT INTO gramdb_mn(m,n,proximity,effects_delay)
                VALUES($m,$n,$proximity,0.0);
            }
        }

        # NEXT, gramdb_gc
        $db eval {
            INSERT INTO gramdb_gc(g,c)
            SELECT g, c FROM gramdb_civ_g JOIN gramdb_c
        }

        # NEXT, gramdb_civ_fg
        set rels {0.5 -0.5}

        set i 0

        $db eval {
            SELECT F.g AS f, G.g AS g
            FROM gramdb_civ_g AS F JOIN gramdb_civ_g AS g
        } {
            if {[string index $f end] eq [string index $g end]} {
                let rel 1.0
            } else {
                let ndx {$i % 2}
                set rel [lindex $rels $ndx]
            }

            incr i

            $db eval {
                INSERT INTO gramdb_civ_fg(f,g,rel)
                VALUES($f,$g,$rel)
            }
        }

        # NEXT, gramdb_frc_fg
        set rels {0.5 -0.5}

        set i 0

        $db eval {
            SELECT F.g AS f, G.g AS g
            FROM gramdb_frc_g AS F JOIN gramdb_frc_g AS g
        } {
            if {$f eq $g} {
                let rel 1.0
            } else {
                let ndx {$i % 2}
                set rel [lindex $rels $ndx]
            }

            incr i

            $db eval {
                INSERT INTO gramdb_frc_fg(f,g,rel)
                VALUES($f,$g,$rel)
            }
        }

        # NEXT, gramdb_coop_fg
        $db eval {
            SELECT F.g AS f, G.g AS g
            FROM gramdb_civ_g AS F JOIN gramdb_frc_g AS g
        } {
            $db eval {
                INSERT INTO gramdb_coop_fg(f,g,coop0)
                VALUES($f,$g,50.0)
            }
        }
    }
  
    # loader db gram
    #
    # db     An sqldocument(n) with gramdb(5) data
    # gram   A gram(n)
    #
    # Loads the gramdb(5) data into the gram(n).  This command is
    # intended to be used as a gram(n) -loadcmd, like this:
    #
    #   -loadcmd [list ::simlib::gramdb loader $db]
    #
    # where $db is the name of the sqldocument(n) containing the
    # gramdb(5) data.
    
    typemethod loader {db gram} {
        $gram load nbhoods {*}[$db eval {
            SELECT n FROM gramdb_n
            ORDER BY n
        }]
        
        $gram load nbrel {*}[$db eval {
            SELECT m, n, proximity, effects_delay FROM gramdb_mn
            ORDER BY m,n
        }]

        $gram load civg {*}[$db eval {
            SELECT g,n,population FROM gramdb_civ_g
            ORDER BY g
        }]

        $gram load civrel {*}[$db eval {
            SELECT f, g, rel FROM gramdb_civ_fg
            ORDER BY f, g
        }]

        $gram load concerns {*}[$db eval {
            SELECT c FROM gramdb_c
            ORDER BY c
        }]

        $gram load sat {*}[$db eval {
            SELECT g, c, sat0, saliency FROM gramdb_gc
            ORDER BY g, c
        }]

        $gram load frcg {*}[$db eval {
            SELECT g FROM gramdb_frc_g
            ORDER BY g
        }]

        $gram load frcrel {*}[$db eval {
            SELECT f, g, rel FROM gramdb_frc_fg
            ORDER BY f, g
        }]

        $gram load coop {*}[$db eval {
            SELECT f, g, coop0 FROM gramdb_coop_fg
            ORDER BY f, g
        }]
    }

    #-------------------------------------------------------------------
    # Other Private Routines

    # CreateDatabase
    #
    # Creates an in-memory run-time database if one is not specified.

    typemethod CreateDatabase {} {
        set db [sqldocument %AUTO%]
        $db register $type
        $db open :memory:
        $db clear

        return $db
    }
    
    # invalid message
    #
    # message    An error string
    #
    # Throws the error with -errorcode INVALID
    
    proc invalid {message} {
        return -code error -errorcode INVALID $message
    }
}



