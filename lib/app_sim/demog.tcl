#-----------------------------------------------------------------------
# TITLE:
#    demog.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Demographic Model, main module.
#
#    This module is responsible for computing demographics for neighborhoods
#    and neighborhood groups.  The data is stored in the demog_n and
#    demog_ng tables; entries in these tables are created and deleted by
#    nbhood(sim) and nbgroups(sim) respectively, as neighborhoods and
#    neighborhood groups come and go.
#
#-----------------------------------------------------------------------

snit::type demog {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Initialization

    # init
    #
    # Initializes the module before the simulation first starts to run.

    typemethod init {} {
        # NEXT, Demog is up.
        log normal demog "Initialized"
    }

    #-------------------------------------------------------------------
    # Analysis

    # analyze
    #
    # Computes demog_ng(n,g) and demog_n(n) for all n, g.
    #
    # This acts as a mutator, to make it easier to use
    # in undo scripts.

    typemethod analyze {} {
        $type ComputeNG
        $type ComputeN

        # Notify the GUI that demographics may have changed.
        notifier send $type <Update>

        return [mytypemethod analyze]
    }

    typemethod ComputeNG {} {
        # FIRST, get explicit and displaced personnel.
        rdb eval {
            UPDATE demog_ng
            SET explicit =  0,
                displaced = 0
        }

        rdb eval {
            SELECT origin                            AS origin,
                   g                                 AS g,
                   total(personnel)                  AS explicit,
                   total(
                       CASE WHEN n != origin
                       THEN personnel ELSE 0 END
                   )                                 AS displaced
            FROM units
            GROUP BY origin, g
        } {
            rdb eval {
                UPDATE demog_ng
                SET explicit  = $explicit,
                    displaced = $displaced
                WHERE n=$origin AND g=$g
            }
        }

        # NEXT, compute implicit and population
        rdb eval {
            SELECT n, g, basepop
            FROM nbgroups
        } {
            rdb eval {
                UPDATE demog_ng
                SET implicit   = $basepop - explicit  - attrition,
                    population = $basepop - displaced - attrition
                WHERE n=$n AND g=$g
            }
        }
    }

    typemethod ComputeN {} {
        # FIRST, get total implicit population and labor force
        set lff [parmdb get demog.laborForceFraction.NONE]

        rdb eval {
            SELECT n, total(implicit) AS implicit
            FROM demog_ng
            GROUP BY n
        } {
            set pop($n) $implicit
            set labor($n) [expr {$lff * $implicit}]
        }

        # NEXT, get total personnel
        rdb eval {
            SELECT n, a, total(personnel) AS personnel
            FROM units
            WHERE gtype='CIV' AND n != ''
            GROUP BY n, a
        } {
            set pop($n) [expr {$pop($n) + $personnel}]
            set lff [parmdb get demog.laborForceFraction.$a]
            set labor($n) [expr {$labor($n) + $lff * $personnel}]
        }

        # NEXT, save pop and labor
        foreach n [array names pop] {
            set P $pop($n)
            set L $labor($n)

            rdb eval {
                UPDATE demog_n
                SET population  = $P,
                    labor_force = $L
                WHERE n = $n
            }
        }
    }

    #-------------------------------------------------------------------
    # Queries

    # getng n g ?parm?
    #
    # n     A neighborhood
    # g     A group in the neighborhood
    # parm  A demog_ng column
    #
    # Retrieves a row dictionary, or a particular column value.

    typemethod getng {n g {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM demog_ng WHERE n=$n AND g=$g} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }


    # getn n ?parm?
    #
    # n     A neighborhood
    # parm  A demog_n column
    #
    # Retrieves a row dictionary, or a particular column value.

    typemethod getn {n {parm ""}} {
        # FIRST, get the data
        rdb eval {SELECT * FROM demog_n WHERE n=$n} row {
            if {$parm ne ""} {
                return $row($parm)
            } else {
                unset row(*)
                return [array get row]
            }
        }

        return ""
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the simulation in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # the change cannot be undone, the mutator returns the empty string.

    # mutate attrit n g casualties
    #
    # n           Neighborhood in which attrition occurs
    # g           Group to which attrition occurs
    # casualties  The number of casualties
    #
    # Removes the specified number of casualties from the 
    # implicit population of g in n, if possible.

    typemethod {mutate attrit} {n g casualties} {
        # FIRST, prepare to undo
        set undo [list]

        # NEXT, get the group's data
        set dict [demog getng $n $g]

        if {[dict size $dict] == 0} {
            log warning demog \
                "mutate attrit -- $g is not resident in $n"
            return
        }

        # NEXT, attrit the group
        lappend undo [$type AttritNbgroup $dict $casualties]
        lappend undo [$type analyze]

        return [join $undo \n]
    }

    # AttritNbgroup dict casualties
    #
    # dict        demog_ng row dictionary
    # casualties  The number of casualties
    #
    # Attrits the group, returning an undo script

    typemethod AttritNbgroup {dict casualties} {

        dict with dict {
            # FIRST, save the undo command
            lappend undo [mytypemethod SetAttrition $n $g $attrition]


            # NEXT, attrit implicit population, noting overkill.
            # Note that we can kill all but 1, but have to leave at
            # least 1.
            let take {min($implicit - 1, $casualties)}
            let implicit {$implicit - $take}
            let casualties {$casualties - $take}
            let newAttrition {$attrition + $take}

            # NEXT, apply the casualties to the group
            log normal aam \
   "Group $n $g takes $take casualties, leaving $implicit implicit population"

            $type SetAttrition $n $g $newAttrition

            # NEXT, update the demographics accordingly.
            lappend undo [$type analyze]

            # NEXT, if casualties is not zero, we attrited more than were
            # available.
            if {$casualties > 0} {
                log normal aam \
           "Overkill; $casualties casualties could not be taken by $g in $n."
            }

            return [join $undo \n]
        }
    }

    # SetAttrition n g attrition
    #
    # n           Neighborhood
    # g           Group resident in n
    # attrition   New accumulated attrition value
    #
    # Sets the cumulative attrition value for the n and g

    typemethod SetAttrition {n g attrition} {
        rdb eval {
            UPDATE demog_ng
            SET attrition = $attrition
            WHERE n=$n AND g=$g
        }
    }
}

