#-----------------------------------------------------------------------
# FILE: gramdb.tcl
#
#   Parser for the gramdb(5) database format.
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
        gramdb_g
        gramdb_n
        gramdb_mn
        gramdb_ng
        gramdb_gc
        gramdb_fg
        gramdb_ngc
        gramdb_nfg
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
        return [readfile [file join $::simlib::library gramdb.sql]]
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
            record c AUT {
                field gtype CIV 
            }

            record c QOL {
                field gtype CIV 
            }

            record c CUL {
                field gtype CIV 
            }

            record c SFT {
                field gtype CIV 
            }

            record c CAS {
                field gtype ORG 
            }

            record c SVC {
                field gtype ORG 
            }
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

        $tt table gramdb_c                                  \
            -tablevalidator [mytypemethod Val_gramdb_c]
        
        $tt field gramdb_c c -key                           \
            -validator [mytypemethod ValidateSymbolicName]

        $tt field gramdb_c gtype -required                  \
            -validator [list $tt validate vtype ::simlib::egrouptype]

        #---------------------------------------------------------------
        # Table -- gramdb_g

         $tt table gramdb_g                                     \
           -tablevalidator  [mytypemethod Val_gramdb_g]         \
           -recordvalidator [mytypemethod Val_gramdb_g_record]
 
        $tt field gramdb_g g -key                                \
            -validator [mytypemethod ValidateSymbolicName]

        $tt field gramdb_g gtype                                 \
            -validator [list $tt validate vtype ::simlib::egrouptype]

        # CIVs and ORGs only
        $tt field gramdb_g rollup_weight                        \
            -validator [list $tt validate vtype ::simlib::rmagnitude]
        
        $tt field gramdb_g effects_factor                       \
            -validator [list $tt validate vtype ::simlib::rmagnitude]

        #---------------------------------------------------------------
        # Table -- gramdb_n

        $tt table  gramdb_n                                 \
            -tablevalidator  [mytypemethod Val_gramdb_n]

        $tt field gramdb_n n -key                           \
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
        # Table -- gramdb_ng

        $tt table gramdb_ng -dependson {gramdb_n gramdb_g}       \
            -tablevalidator  [mytypemethod Val_gramdb_ng]

        $tt field gramdb_ng n -key                               \
            -validator [list $tt validate foreign gramdb_n n]
        $tt field gramdb_ng g -key                               \
            -validator [mytypemethod ValidateCivOrgPgroup] 
        $tt field gramdb_ng rollup_weight                        \
            -validator [list $tt validate vtype ::simlib::rmagnitude]
        $tt field gramdb_ng effects_factor                       \
            -validator [list $tt validate vtype ::simlib::rmagnitude]
        $tt field gramdb_ng population -required                 \
            -validator [mytypemethod ValidateIntMagnitude]

        #---------------------------------------------------------------
        # Table -- gramdb_gc
        
        $tt table gramdb_gc -dependson {gramdb_g gramdb_c} \
            -tablevalidator [mytypemethod Val_gramdb_gc] \
            -recordvalidator [mytypemethod Val_gramdb_gc_record]

        $tt field gramdb_gc g -key \
            -validator [mytypemethod ValidateCivOrgPgroup]
        $tt field gramdb_gc c -key \
            -validator [list $tt validate foreign gramdb_c c]

        $tt field gramdb_gc sat0 \
            -validator [mytypemethod ValidateQuality qsat]
        $tt field gramdb_gc saliency \
            -validator [mytypemethod ValidateQuality qsaliency]
        
        #---------------------------------------------------------------
        # Table -- gramdb_fg
        
        $tt table gramdb_fg -dependson gramdb_g \
            -tablevalidator [mytypemethod Val_gramdb_fg]

        $tt field gramdb_fg f -key \
            -validator [list $tt validate foreign gramdb_g g]
        $tt field gramdb_fg g -key \
            -validator [list $tt validate foreign gramdb_g g]

        $tt field gramdb_fg rel \
            -validator [mytypemethod ValidateQuality qrel]
        $tt field gramdb_fg coop0 \
            -validator [mytypemethod ValidateQuality qcooperation]

        #---------------------------------------------------------------
        # Table -- gramdb_ngc
        
        $tt table gramdb_ngc -dependson {gramdb_n gramdb_g gramdb_c} \
            -tablevalidator  [mytypemethod Val_gramdb_ngc]           \
            -recordvalidator [mytypemethod Val_gramdb_ngc_record]

        $tt field gramdb_ngc n -key \
            -validator [list $tt validate foreign gramdb_n n]
        $tt field gramdb_ngc g -key \
            -validator [mytypemethod ValidateCivOrgPgroup]
        $tt field gramdb_ngc c -key \
            -validator [list $tt validate foreign gramdb_c c]

        $tt field gramdb_ngc sat0 \
            -validator [mytypemethod ValidateQuality qsat]
        $tt field gramdb_ngc saliency \
            -validator [mytypemethod ValidateQuality qsaliency]

        #---------------------------------------------------------------
        # Table -- gramdb_nfg
        
        $tt table gramdb_nfg -dependson {gramdb_n gramdb_g}       \
            -tablevalidator  [mytypemethod Val_gramdb_nfg]        \
            -recordvalidator [mytypemethod Val_gramdb_nfg_record]

        $tt field gramdb_nfg n -key \
            -validator [list $tt validate foreign gramdb_n n]
        $tt field gramdb_nfg f -key \
            -validator [list $tt validate foreign gramdb_g g]
        $tt field gramdb_nfg g -key \
            -validator [list $tt validate foreign gramdb_g g]

        $tt field gramdb_nfg rel \
            -validator [mytypemethod ValidateQuality qrel]
        $tt field gramdb_nfg coop0 \
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


    typemethod ValidateCivOrgPgroup {db table value} {
        $db eval {SELECT gtype FROM gramdb_g WHERE g=$value} {

            if {$gtype in {CIV ORG}} {
                return $value
            } else {
                invalid "expected CIV or ORG group, got: \"$value\""
            }
        }

        invalid "unknown group: \"$value\""
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
    # Table -- gramdb_c

    typemethod Val_gramdb_c {db table} {
        # Must have at least one concern of each type
        foreach gtype {CIV ORG} {
            if {![$db exists {SELECT c FROM gramdb_c WHERE gtype=$gtype}]} {
                invalid "Zero concerns of type $gtype defined"
            }
        }
    }

    #-------------------------------------------------------------------
    # Table -- gramdb_g

    typemethod Val_gramdb_g {db table} {
        # Must have at least one of each type
        foreach gtype {CIV FRC ORG} {
            if {![$db exists {SELECT g FROM gramdb_g WHERE gtype=$gtype}]} {
                invalid "Zero groups of type $gtype defined"
            }
        }
    }

    typemethod Val_gramdb_g_record {db table rowid} {
        # Verify that the necessary fields are defined, given the
        # group type.
        $db eval "SELECT * FROM $table WHERE rowid=\$rowid" row {}

        array set required {
            CIV {
                rollup_weight effects_factor
            }
            ORG {
                rollup_weight effects_factor
            }
            FRC { }
        }

        array set nulls {
            CIV { }
            ORG { }
            FRC {
                rollup_weight effects_factor
            }
        }
        
        foreach field $required($row(gtype)) {
            if {$row($field) eq ""} {
                invalid "missing field: $field"
            }
        }

        foreach field $nulls($row(gtype)) {
            $db eval "
                UPDATE gramdb_g
                SET $field = ''
                WHERE ROWID = \$rowid
            "
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
    # Table -- gramdb_ng
    
    typemethod Val_gramdb_ng {db table} {
        # Fill in missing records.  
        # Population will default to 0 for all missing records.

        $db eval {
            INSERT OR IGNORE INTO gramdb_ng(n,g)
            SELECT n,g
            FROM gramdb_n JOIN gramdb_g
            WHERE gramdb_g.gtype IN ('CIV', 'ORG')
        }

        # Next, default NULL fields to the equivalent values from
        # gramdb_g.
        $db eval {
            SELECT g, rollup_weight, effects_factor FROM gramdb_g
        } {
            $db eval {
                UPDATE gramdb_ng
                SET rollup_weight = COALESCE(rollup_weight,$rollup_weight),
                    effects_factor = COALESCE(effects_factor,$effects_factor)
                WHERE gramdb_ng.g = $g
            }
        }

        # Ensure that there's at least one CIV group in each 
        # neighborhood with non-zero population.
        $db eval {
            SELECT n, TOTAL(population) AS sum
            FROM gramdb_ng JOIN gramdb_g USING (g)
            WHERE gramdb_g.gtype = 'CIV'
            GROUP BY n
        } {
            if {$sum == 0} {
                invalid "neighborhood $n contains no CIV gramdb_g with non-zero population"
            }
        }

        # Ensure that each CIV pgroup has non-zero population in at
        # least one neighborhood.
        $db eval {
            SELECT g, TOTAL(population) AS sum
            FROM gramdb_ng JOIN gramdb_g USING (g)
            WHERE gramdb_g.gtype = 'CIV'
            GROUP BY g
        } {
            if {$sum == 0} {
                invalid "group $g has zero population in all neighborhoods"
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
            FROM gramdb_g JOIN gramdb_c USING (gtype)
        } {
            $db eval {
                INSERT OR IGNORE INTO gramdb_gc(g,c) VALUES($g,$c)
            }
        }
    }

    typemethod Val_gramdb_gc_record {db table rowid} {
        # Verify that the group and concern have the same type.

        $db eval {
            SELECT gramdb_gc.g    AS g,
                   gramdb_g.gtype AS gtype,
                   gramdb_gc.c    AS c,
                   gramdb_c.gtype AS ctype
            FROM gramdb_gc
            JOIN gramdb_g 
            JOIN gramdb_c 
            WHERE gramdb_gc.ROWID=$rowid
            AND   gramdb_g.g = gramdb_gc.g
            AND   gramdb_c.c = gramdb_gc.c
        } {
            if {$gtype ne $ctype} {
                invalid "mismatch, $g is $gtype, $c is $ctype"
            }
        }
    }

    #-------------------------------------------------------------------
    # Table -- gramdb_fg

    typemethod Val_gramdb_fg {db table} {
        # Fill out table with default values: 1.0 when f==g, 0.0 otherwise.
        # Insert rows for all missing combinations of f and g.
        
        $db eval {
            SELECT F.g AS f,
                   G.g AS g
            FROM gramdb_g AS F JOIN gramdb_g AS G    
        } {
            $db eval {
                INSERT OR IGNORE INTO gramdb_fg(f,g) 
                VALUES($f,$g)
            }
        }
        
        $db eval {
            UPDATE gramdb_fg
            SET rel   = COALESCE(rel, 1.0),
                coop0 = COALESCE(coop0, 100.0)
            WHERE f = g;
            
            UPDATE gramdb_fg
            SET rel   = COALESCE(rel, 0.0),
                coop0 = COALESCE(coop0, 50.0)
            WHERE f != g;
        }
    }

    typemethod Val_gramdb_fg_record {db table rowid} {
        # Verify that rel is 1.0 and coop0 is 100 when f=g

        $db eval "SELECT * FROM $table WHERE rowid=\$rowid" row {
            if {$row(f) eq $row(g)} {
                if {$row(rel) ne ""} {
                    if {$row(rel) ne 1.0} {
                        invalid "rel must be 1.0 when f = g"
                    }
                }

                if {$row(coop0) ne ""} {
                    if {$row(coop0) != 100.0} {
                        invalid "coop0 must be 100.0 when f = g"
                    }
                }
            }
        }
    }

    #-------------------------------------------------------------------
    # Table -- gramdb_ngc
    
    typemethod Val_gramdb_ngc {db table} {
        # Copy data from gramdb_gc for all missing combinations of n, g and c
        # with compatible types.
        $db eval {
            INSERT OR IGNORE INTO gramdb_ngc(n,g,c)
            SELECT gramdb_ng.n  AS n,
                   gramdb_ng.g  AS g,
                   gramdb_c.c   AS c
            FROM gramdb_ng
            JOIN gramdb_g USING (g)
            JOIN gramdb_c USING (gtype)
            WHERE gramdb_g.gtype = 'ORG'
            OR    gramdb_ng.population > 0
        }

        $db eval {
            SELECT gramdb_ngc.n       AS n,
                   gramdb_ngc.g       AS g,
                   gramdb_ngc.c       AS c,
                   gramdb_gc.sat0     AS sat0,
                   gramdb_gc.saliency AS saliency
            FROM gramdb_ngc JOIN gramdb_gc USING (g,c)
        } {
            $db eval {
                UPDATE gramdb_ngc
                SET sat0     = COALESCE(sat0,$sat0),
                    saliency = COALESCE(saliency,$saliency)
                WHERE n=$n AND g=$g AND c=$c;
            }
        }
    }

    typemethod Val_gramdb_ngc_record {db table rowid} {
        # Verify that the group and concern have the same type.

        $db eval {
            SELECT gramdb_ngc.g    AS g,
                   gramdb_g.gtype  AS gtype,
                   gramdb_ngc.c    AS c,
                   gramdb_c.gtype  AS ctype
            FROM gramdb_ngc
            JOIN gramdb_g USING (g)
            JOIN gramdb_c ON (gramdb_c.c == gramdb_ngc.c)
            WHERE gramdb_ngc.ROWID=$rowid
        } {
            if {$gtype ne $ctype} {
                invalid "mismatch, $g is $gtype, $c is $ctype"
            }
        }
    }

    #-------------------------------------------------------------------
    # Table -- gramdb_nfg
    
    typemethod Val_gramdb_nfg {db table} {
        # Copy data from gramdb_fg for all missing combinations of n, f and g
        # with compatible types.

        $db eval {
            INSERT OR IGNORE INTO gramdb_nfg(n,f,g)
            SELECT n, f, g
            FROM gramdb_n JOIN gramdb_fg
        }

        $db eval {
            SELECT n, f, g, rel, coop0
            FROM gramdb_n JOIN gramdb_fg
        } {
            $db eval {
                UPDATE gramdb_nfg
                SET rel   = COALESCE(rel,$rel),
                    coop0 = COALESCE(coop0,$coop0)
                WHERE n=$n AND f=$f AND g=$g;
            }
        }
    }

    typemethod Val_gramdb_nfg_record {db table rowid} {
        # Verify that rel is 1.0 and coop0 is 100 when f=g

        $db eval "SELECT * FROM $table WHERE rowid=\$rowid" row {
            if {$row(f) eq $row(g)} {
                if {$row(rel) ne ""} {
                    if {$row(rel) ne 1.0} {
                        invalid "rel must be 1.0 when f = g"
                    }
                }

                if {$row(coop0) ne ""} {
                    if {$row(coop0) == 100.0} {
                        invalid "coop0 must be 100.0 when f = g"
                    }
                }
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
    # Populates a gramdb database for performance testing
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
            DELETE FROM gramdb_g;
            DELETE FROM gramdb_n;
            DELETE FROM gramdb_mn;
            DELETE FROM gramdb_ng;
            DELETE FROM gramdb_ngc;
            DELETE FROM gramdb_nfg;
        }

        # NEXT, gramdb_c
        $db eval {
            INSERT INTO gramdb_c(c,gtype) VALUES('AUT','CIV');
            INSERT INTO gramdb_c(c,gtype) VALUES('CUL','CIV');
            INSERT INTO gramdb_c(c,gtype) VALUES('QOL','CIV');
            INSERT INTO gramdb_c(c,gtype) VALUES('SFT','CIV');
        }

        # NEXT, gramdb_n
        for {set i 1} {$i <= $opts(-nbhoods)} {incr i} {
            set n "N$i"

            $db eval {
                INSERT INTO gramdb_n(n) VALUES($n);
            }
        }

        # NEXT, gramdb_g, gramdb_ng -- CIV groups
        set letters "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        for {set i 0} {$i < $opts(-civgroups)} {incr i} {
            set g "C[string index $letters $i]"

            $db eval {
                INSERT INTO gramdb_g(g,gtype)
                VALUES($g,'CIV');
            }

            $db eval {SELECT n FROM gramdb_n} {
                rdb eval {
                    INSERT INTO gramdb_ng(n,g,population)
                    VALUES($n,$g,1000);
                }
            }
        }

        # NEXT, gramdb_g -- FRC groups
        for {set i 1} {$i <= $opts(-frcgroups)} {incr i} {
            set g "F$i"

            $db eval {
                INSERT INTO gramdb_g(g,gtype) VALUES($g,'FRC');
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

        # NEXT, gramdb_ngc
        $db eval {
            INSERT INTO gramdb_ngc(n,g,c,sat0,saliency)
            SELECT n,g,c,0.0,1.0 FROM gramdb_ng JOIN gramdb_c
        }

        # NEXT, gramdb_nfg -- CIV/CIV
        set rels {0.5 -0.5}

        set i 0

        $db eval {
            SELECT F.n AS n,
                   F.g AS f, 
                   G.g AS g
            FROM gramdb_ng AS F JOIN gramdb_g AS G
            WHERE G.gtype = 'CIV'
        } {
            if {$f eq $g} {
                let rel 1.0
            } else {
                let ndx {[incr i] % 2}
                set rel [lindex $rels $ndx]
            }

            $db eval {
                INSERT INTO gramdb_nfg(n,f,g,rel,coop0)
                VALUES($n,$f,$g,$rel,50.0)
            }
        }

        # NEXT, gramdb_nfg -- FRC/FRC
        set rels {0.5 -0.5}

        set i 0

        $db eval {
            SELECT n, F.g AS f, G.g AS g
            FROM gramdb_n
            JOIN gramdb_g AS F 
            JOIN gramdb_g AS G
            WHERE F.gtype = 'FRC' AND G.gtype='FRC'
        } {
            if {$f eq $g} {
                let rel 1.0
            } else {
                let ndx {$i % 2}
                set rel [lindex $rels $ndx]
            }

            incr i

            $db eval {
                INSERT INTO gramdb_nfg(n,f,g,rel,coop0)
                VALUES($n,$f,$g,$rel,50.0)
            }
        }

        # NEXT, gramdb_nfg -- CIV/FRC
        # Note that CIV/FRC relationship doesn't matter to GRAM.
        $db eval {
            SELECT F.n AS n, 
                   F.g AS f, 
                   G.g AS g
            FROM gramdb_ng AS F JOIN gramdb_g AS G
            WHERE G.gtype = 'FRC'
        } {
            $db eval {
                INSERT INTO gramdb_nfg(n,f,g,rel,coop0)
                VALUES($n,$f,$g,0.0,50.0)
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
        
        $gram load groups {*}[$db eval {
            SELECT g, gtype FROM gramdb_g
            ORDER BY gtype,g
        }]

        $gram load concerns {*}[$db eval {
            SELECT c, gtype FROM gramdb_c
            ORDER BY gtype,c
        }]

        $gram load nbrel {*}[$db eval {
            SELECT m, n, proximity, effects_delay 
            FROM gramdb_mn
            ORDER BY m,n
        }]

        $gram load nbgroups {*}[$db eval {
            SELECT n, g, population, rollup_weight, effects_factor
            FROM gramdb_ng
            ORDER BY n,g
        }]

        $gram load sat {*}[$db eval {
            SELECT n, g, c, sat0, saliency
            FROM gramdb_ngc JOIN gramdb_g USING (g)
            ORDER BY n, gtype, g, c
        }]

        $gram load rel {*}[$db eval {
            SELECT n, f, g, rel
            FROM gramdb_nfg
            ORDER BY n, f, g
        }]

        $gram load coop {*}[$db eval {
            SELECT gramdb_nfg.n     AS n,
                   gramdb_nfg.f     AS f,
                   gramdb_nfg.g     AS g,
                   gramdb_nfg.coop0 AS coop0
            FROM gramdb_nfg
            JOIN gramdb_g AS F ON (gramdb_nfg.f = F.g)
            JOIN gramdb_g AS G ON (gramdb_nfg.g = G.g)
            JOIN gramdb_ng AS NF ON (NF.n = gramdb_nfg.n AND
                                     NF.g = gramdb_nfg.f)
            WHERE F.gtype = 'CIV'
            AND   G.gtype = 'FRC'
            AND   NF.population > 0
            ORDER BY n, f, g
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



