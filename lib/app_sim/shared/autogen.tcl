#-----------------------------------------------------------------------
# TITLE:
#    autogen.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#    athena_sim(1): Autogen Ensemble
#
#    This module manages automatic scenario generation.  It is
#    responsible for all aspects of scenario generation generally used
#    for testing Athena. Automtically generated scenarios can be used
#    for load testing, unit testing or for use by the automated
#    test suite.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# autogen ensemble

snit::type autogen {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent rdb    ;# The runtime database


    #-------------------------------------------------------------------
    # Type Variables

    # info array
    #
    # aidx    activity index for ASSIGN tactics

    typevariable info -array {
        aidx 0
    }

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Set the rdb typecomponent

        set rdb ::rdb
    }

    # scenario args
    #
    # Arguments:
    #
    # -actors     number of actors to create
    # -nbhoods    number of nbhoods to create
    # -frcgroups  number of FRC groups to create
    # -civgroups  number of CIV groups to create
    # -orggroups  number of ORG groups to create
    # -topics     number of belief system topics to create
    # -nostrategy flag indicating that strategies should not be created
    #
    # This method creates a scenario using the optional arguments 
    # supplied. Default numbers are used for any argument that is
    # omitted.

    typemethod scenario {args} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, default options
        array set opts {
            -actors     3
            -nbhoods    10
            -frcgroups  3
            -civgroups  6
            -orggroups  2
            -topics     3 
            -strategy   1
        }

        # NEXT, parse input options and error check
        while {[llength $args] > 0} {
            set opt [lshift args]
            switch -exact -- $opt {
                -actors {
                    set opts(-actors) [lshift args]
                    if {![string is integer -strict $opts(-actors)]} {
                        error "-actors: must be integer"
                    }

                    if {$opts(-actors) < 1} {
                        error "-actors: must be positive integer"
                    }
                }

                -nb {
                    set opts(-nbhoods) [lshift args]
                    if {![string is integer -strict $opts(-nbhoods)]} {
                        error "-nb: must be integer"
                    }

                    if {$opts(-nbhoods) < 2} {
                        error "-nb: must be integer >= 2"
                    }

                    if {$opts(-nbhoods) > 999} {
                        error "-nb: max nbhoods is 999"
                    }
                }

                -frcg {
                    set opts(-frcgroups) [lshift args]
                    if {![string is integer -strict $opts(-frcgroups)]} {
                        error "-frcg: must be integer"
                    }

                    if {$opts(-frcgroups) < 1} {
                        error "-frcg: must be positive integer"
                    }
                }

                -civg {
                    set opts(-civgroups) [lshift args]
                    if {![string is integer -strict $opts(-civgroups)]} {
                        error "-civg: must be integer"
                    }

                    if {$opts(-civgroups) < 1} {
                        error "-civg: must be positive integer"
                    }
                }

                -orgg {
                    set opts(-orggroups) [lshift args]
                    if {![string is integer -strict $opts(-orggroups)]} {
                        error "-orgg: must be integer"
                    }

                    if {$opts(-orggroups) < 0} {
                        error "-orgg: must be >= 0"
                    }
                }

                -topics {
                    set opts(-topics) [lshift args]
                    if {![string is integer -strict $opts(-topics)]} {
                        error "-topics: must be integer"
                    }

                    if {$opts(-topics) < 1} {
                        error "-topics: must be >= 1"
                    }
                }

                -nostrategy {
                    set opts(-strategy) 0
                }

                default {
                    error "Unknown option: $opt"
                }
            }
        }

        # NEXT, all inputs check out, blank out the scenario
        scenario new
        
        # NEXT, create scenario entities, order matters
        autogen Actors    $opts(-actors)
        autogen Nbhoods   $opts(-nbhoods)   
        autogen CivGroups $opts(-civgroups)
        autogen OrgGroups $opts(-orggroups)
        autogen FrcGroups $opts(-frcgroups)
        autogen BSystem   $opts(-topics)

        # NEXT, if actor strategies are desired, create them
        if {$opts(-strategy)} {
            autogen strategy
        }
    }

    # actors ?num?
    #
    # num   number of actors to create
    #
    # This method will create the requested number of actors provided
    # all error checking passes.

    typemethod actors {{num 3}} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, no actors can exist currently
        if {[llength [actor names]] > 0} {
            error "Actors already exist, must delete them first"
        }

        if {![string is integer -strict $num]} {
            error "argument must be integer"
        }

        if {$num < 1} {
            error "argument must be >= 1"
        }

        # NEXT, error checking passed, create the actors
        autogen Actors $num
    }

    # nbhoods ?num?
    #
    # num   number of nbhoods to create
    #
    # This method will create the requested number of nbhoods provided
    # all error checking passes.

    typemethod nbhoods {{num 10}} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, no nbhoods can exists and we must already have actors
        if {[llength [nbhood names]] > 0} {
            error "Nbhoods already exist, must delete them first"
        }

        if {[llength [actor names]] == 0} {
            error "Must create actors first"
        }

        if {![string is integer -strict $num]} {
            error "argument must be integer"
        }

        if {$num < 2} {
            error "argument must be >= 2"
        }

        if {$num > 999} {
            error "argument must be <= 999"
        }

        # NEXT, error checking passed, create the nbhoods
        autogen Nbhoods $num
    }


    # civgroups ?num?
    #
    # num  number of CIV groups to create per neighborhood
    #
    # This method will create the requested number of CIV groups in
    # each neighborhood provided all error checking passes.

    typemethod civgroups {{num 6}} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, there must already be neighborhoods and no CIV groups
        if {[llength [nbhood names]] == 0} {
            error "Must create nbhoods first"
        }

        if {[llength [civgroup names]] > 0} {
            error "CIV groups already exist, must delete them first"
        }

        if {![string is integer -strict $num]} {
            error "argument must be integer"
        }

        if {$num < 1} {
            error "argument must be >= 1"
        }

        # NEXT, error checking passed, create the CIV groups
        autogen CivGroups $num
    }

    # orggroups ?num?
    #
    # num  number of ORG groups to create
    #
    # This method will create the requested number of ORG groups
    # provided all error checking passes.

    typemethod orggroups {{num 2}} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, there can be no ORG groups and we must have actor(s)
        if {[llength [orggroup names]] > 0} {
            error "ORG groups already exist, must delete them first"
        }

        if {[llength [actor names]] == 0} {
            error "Must create actors first"
        }

        if {![string is integer -strict $num]} {
            error "argument must be integer"
        }

        if {$num < 1} {
            error "argument must be >= 1"
        }

        # NEXT, error checking passed, create the ORG groups
        autogen OrgGroups $num
    }

    # frcgroups ?num?
    #
    # num  number of FRC groups to create
    #
    # This method will create the requested number of CIV groups
    # provided all error checking passes.

    typemethod frcgroups {{num 3}} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, there must be no FRC groups and at least one actor
        if {[llength [frcgroup names]] > 0} {
            error "FRC groups already exist, must delete them first"
        }

        if {[llength [actor names]] == 0} {
            error "Must create actors first"
        }

        if {![string is integer -strict $num]} {
            error "argument must be integer"
        }

        if {$num < 1} {
            error "argument must be >= 1"
        }

        # NEXT, error checking passed, create the FRC groups
        autogen FrcGroups $num
    }

    # bsystem ?num?
    #
    # num  number of topics to create in the belief system
    #
    # This method will create a belief system with the requested number
    # of topics provided all error checking passes.

    typemethod bsystem {{num 3}} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, there must be no topics and we must have CIV groups and
        # actors defined
        if {[llength [bsystem topic names]] > 0} {
            error "Belief system topics already exist, must delete them first"
        }

        if {[llength [civgroup names]] == 0} {
            error "Must create CIV groups first"
        }

        if {[llength [actor names]] == 0} {
            error "Must create actors first"
        }

        if {![string is integer -strict $num]} {
            error "argument must be integer"
        }

        if {$num < 1} {
            error "argument must be >= 1"
        }

        # NEXT, error checking passes, create the belief system
        autogen BSystem $num
    }

    # strategy
    #
    # This method will create a  set of tactics for each supplied actor.
    # If no arguments are supplied, then DEPLOY and FUNDENI tactics are
    # created for all actors, force groups, org groups and neighborhoods.
    #
    # Arguments:
    #    -actors   List of actors to create tactics for or "ALL"
    #    -civg     CIV groups to consider when creating tactics or "ALL"
    #    -frcg     FRC groups to consider when creating tactics or "ALL"
    #    -frcact   FRC activities to consider when creating tactics or "ALL"
    #    -orgg     ORG groups to consider when creating tactics or "ALL"
    #    -orgact   ORG activities to consider when creating tactics or "ALL"
    #    -nbhoods  Neighborhoods to consider when creating tactics or "ALL"

    typemethod strategy {args} {
        require {[sim state] ne "RUNNING"} "The simulation is running."

        # FIRST, default options
        array set opts {
            -tactics    {DEPLOY FUNDENI}
            -actors     ALL
            -civgroups  ALL
            -frcgroups  ALL
            -frcact     ALL
            -orggroups  ALL
            -orgact     ALL
            -nbhoods    ALL
        }

        # NEXT, must have actors, nbhoods and and least one FRC 
        # or ORG group
        if {[llength [actor names]] == 0} {
            error "Must create actors first"
        }

        if {[llength [nbhood names]] == 0} {
            error "Must create nbhoods first"
        }

        if {[llength [frcgroup names]] == 0 &&
            [llength [orgrooup names]] == 0} {
            error "Must have at least one FRC group or one ORG group"
        }

        # NEXT, parse any arguments
        while {[llength $args] != 0} {
            set opt [lshift args]
            switch -exact -- $opt {
                -actors {
                    set opts(-actors) [lshift args]

                    # NEXT, get the list of actors 
                    set alist [actor names]

                    if {$opts(-actors) ne "ALL"} {
                        foreach act $opts(-actors) {
                            if {$act ni $alist} {
                                error "Unrecognized actor: $act"
                            }
                        }
                    }
                }

                -civg {
                    set opts(-civgroups) [lshift args]

                    set civg [civgroup names]

                    if {$opts(-civgroups) ne "ALL"} {
                        foreach grp $opts(-civgroups) {
                            if {$grp ni $civg} {
                                error "Unrecognized CIV group: $grp"
                            }
                        }
                    }
                }

                -frcg {
                    set opts(-frcgroups) [lshift args]

                    set frcg [frcgroup names]

                    if {$opts(-frcgroups) ne "ALL"} {
                        foreach grp $opts(-frcgroups) {
                            if {$grp ni $frcg} {
                                error "Unrecognized FRC group: $grp"
                            }
                        }
                    }
                }

                -orgg {
                    set opts(-orggroups) [lshift args]
                    
                    set orgg [orggroup names]

                    if {$opts(-orggroups) ne "ALL"} {
                        foreach grp $opts(-orggroups) {
                            if {$grp ni $orgg} {
                                error "Unrecognized ORG group: $grp"
                            }
                        }
                    }
                }

                -nbhoods {
                    set opts(-nbhoods) [lshift args]

                    set nbhoods [nbhood names]

                    if {$opts(-nbhoods) ne "ALL"} {
                        foreach nb $opts(-nbhoods) {
                            if {$nb ni $nbhoods} {
                                error "Unrecognized nbhood: $nb"
                            }
                        }
                    }
                }

                -frcact {
                    set opts(-frcact) [lshift args]

                    set frcacts [activity frc names]

                    if {$opts(-frcact) ne "ALL"} {
                        foreach act $opts(-frcact) {
                            if {$act ni $frcacts} {
                                error "Unrecognized force activity: $act"
                            }
                        }
                    }
                }

                -orgact {
                    set opts(-orgact) [lshift args]

                    set orgacts [activity org names]

                    if {$opts(-orgact) ne "ALL"} {
                        foreach act $opts(-orgact) {
                            if {$act ni $orgacts} {
                                error "Unrecognized org activity: $act"
                            }
                        }
                    }
                }

                default {
                    error "Unknown option: $opt"
                }
            }
        }

        # NEXT, error checking passes, create strategies
        autogen Strategy [array get opts]
    }

    # attroe owner ?args...?
    #
    # owner   - an actor
    #
    # Arguments:
    #
    # -attackers   - a force group or groups owned by owner
    # -max         - maximum number of attacks per week
    #
    # This method creates ATTROE tactics for force groups 
    # owned by the supplied actor. By default, all force groups
    # owned by the actor are given an ATTROE tactic. If the -attacker
    # argument is passed in, then only force groups in that list
    # are given an ATTROE tactic.  The maximum number of tactics
    # defaults to 1.
    #
    # For each neighborhood:
    # For uniformed forces, they are given an ROE of "ATTACK" for
    # non-uniformed forces, they are given an ROE of "STAND_AND_FIGHT"

    typemethod attroe {owner args} {
        # FIRST, default options
        array set opts {
            -attackers {}
            -max 1
        }

        # NEXT, must have actors, nbhoods and and least one FRC 
        # or ORG group
        if {[llength [actor names]] == 0} {
            error "Must create actors first"
        }

        if {[llength [nbhood names]] == 0} {
            error "Must create nbhoods first"
        }

        if {[llength [frcgroup names]] == 0 &&
            [llength [orgrooup names]] == 0} {
            error "Must have at least one FRC group or one ORG group"
        }

        # NEXT, parse arguments
        while {[llength $args] != 0} {
            set opt [lshift args]
            switch -exact -- $opt {
                -attackers {
                    set opts(-attackers) [lshift args]
                }

                -max_attacks {
                    set opts(-max) [lshift args]
                    if {![string is integer $opts(-max)]} {
                        error "$opt must be integer > 0"
                    }

                    if {$opts(-max) < 1} {
                        error "$opt must be integer > 0"
                    }
                }

                default {
                    error "Unknown option: $opt"
                }
            }
        }

        # NEXT, owner must have force groups at disposal
        if {[frcgroup ownedby $owner] eq ""} {
            error "$owner does not own any force groups"
        }

        # NEXT, if no list supplied, use all force owned by actor
        if {$opts(-attackers) eq ""} {
            set agrp [frcgroup ownedby $owner]
        } else {
            set agrp $opts(-attackers)
        }

        # NEXT, step through attackers and set ROE according to
        # whether the force group is uniformed or not
        foreach grp $agrp {
            set grp [frcgroup validate $grp]

            # NOTE: the orders will do further validation

            # NEXT, each uniformed force against all other
            # non-uniformed forces
            if {$grp in [frcgroup uniformed names]} {
                foreach dgrp [frcgroup nonuniformed names] {
                    foreach n [nbhood names] {
                        autogen AttroeTactic $owner   \
                                             $grp     \
                                             $dgrp    \
                                             $n       \
                                             "ATTACK" \
                                             $opts(-max)
                    }
                }
            } else {
                # NEXT, each non-uniformed force against all
                # other uniformed forces
                foreach dgrp [frcgroup uniformed names] {
                    foreach n [nbhood names] {
                        autogen AttroeTactic $owner            \
                                             $grp              \
                                             $dgrp             \
                                             $n                \
                                             "STAND_AND_FIGHT" \
                                             $opts(-max)
                    }
                }
            }
        }
    }

    # assign owner args
    #
    # owner   - an actor
    # 
    # Arguments:
    #    -frcg     Force groups to be assigned activities
    #    -orgg     Org groups to be assigned activities
    #    -nbhoods  The nbhoods in which to do activities
    #    -frcact   The type of force activities to do
    #    -orgact   The type of org activities to do
    #
    # This method assigns activities to groups owned by owner in
    # specified nbhoods. If no arguments are supplied then all groups
    # owned by the owner are assigned appropriate activities in turn
    # in each neighborhood.

    typemethod assign {owner args} {
        # FIRST, default opts and parse args
        array set opts {
            -frcg    {}
            -orgg    {}
            -nbhoods {}
            -frcact  {}
            -orgact  {}
        }

        # NEXT, must have actors, nbhoods and and least one FRC 
        # or ORG group
        if {[llength [actor names]] == 0} {
            error "Must create actors first"
        }

        if {[llength [nbhood names]] == 0} {
            error "Must create nbhoods first"
        }

        if {[llength [frcgroup names]] == 0 &&
            [llength [orgrooup names]] == 0} {
            error "Must have at least one FRC group or one ORG group"
        }

        # NEXT, parse the args
        while {[llength $args] != 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -frcg {
                    set opts(-frcg) [lshift args]
                }

                -orgg {
                    set opts(-orgg) [lshift args]
                }

                -frcact {
                    set opts(-frcact) [lshift args]
                }

                -orgact {
                    set opts(-orgact) [lshift args]
                }

                -nbhoods {
                    set opts(-nbhoods) [lshift args]
                }

                default {
                    error "Unknown option: $opt"
                }
            }
        }

        # NEXT, error checking
        if {$owner ni [actor names]} {
                error "Unrecognized actor: $owner"
        }

        if {$opts(-frcg) eq ""} {
            set opts(-frcg) [frcgroup ownedby $owner] 

        } else {
            foreach g $opts(-frcg) {
                if {$g ni [frcgroup names]} {
                    error "Unrecognized force group: $g"
                }
            }
        }

        if {$opts(-orgg) eq ""} {
            set opts(-orgg) \
                [rdb eval {SELECT g FROM orggroups WHERE a=$owner}]
        } else {
            foreach g $opts(-orgg) {
                if {$g ni [orggroup names]} {
                    error "Unrecognized org group: $g"
                }
            }
        }

        if {$opts(-frcg) eq "" && $opts(-orgg) eq ""} {
            error "Actor $owner does not own any groups"
        }

        # NEXT, get appropriate nbhoods 
        if {$opts(-nbhoods) eq ""} {
            set opts(-nbhoods) [nbhood names]
        } else {
            foreach n $opts(-nbhoods) {
                if {$n ni [nbhood names]} {
                    error "Unrecognized nbhood: $opts(-nbhood)"
                }
            }
        }

        if {$opts(-frcact) eq ""} {
            set opts(-frcact) [activity frc names]
        } else {
            foreach act $opts(-frcact) {
                if {$act ni [activity frc names]} {
                    error "$act is not a valid force activity"
                }
            }
        }

        if {$opts(-orgact) eq ""} {
            set opts(-orgact) [activity org names]
        } else {
            foreach act $opts(-orgact) {
                if {$act ni [activity org names]} {
                    error "$act is not a valid force activity"
                }
            }
        }

        set aidx 0
        # NEXT, create ASSIGN for force groups
        foreach g $opts(-frcg) {
            foreach n $opts(-nbhoods) {

                set act [lindex $opts(-frcact) $aidx]
                # NEXT, create the tactic
                autogen AssignTactic $owner \
                                     $g     \
                                     $n     \
                                     $act   \
                                     100

               incr aidx
               if {[expr {$aidx % [llength $opts(-frcact)]}] == 0} {
                   set aidx 0
               }
           }
       }

       set aidx 0
       # NEXT, create assign for org groups
       foreach g $opts(-orgg) {
           foreach n $opts(-nbhoods) {
               set act [lindex $opts(-orgact) $aidx]
               # NEXT, create the tactic
               autogen AssignTactic $owner \
                                    $g     \
                                    $n     \
                                    $act   \
                                    100

               incr aidx
               if {[expr {$aidx % [llength $opts(-orgact)]}] == 0} {
                   set aidx 0
               }
           }
       }

    }

    # Actors num
    #
    # num   - number of actors to create
    #
    # This method creates the desired number of actors called "Ann"
    # where nn is an integer from 0 to num - 1. Each actor supports
    # himself.

    typemethod Actors {num} {
        for {set i 0} {$i < $num} {incr i} {
            set parms(a) "A[format "%02d" $i]"
            set parms(supports) "SELF"
            set parms(cash_on_hand) "500B"

            order send cli ACTOR:CREATE [array get parms]
        }
    }

    # Nbhoods num
    #
    # num  - number of nbhoods to create
    #
    # This method creates numn nbhoods called "Ni" where i is and
    # integer from 0 to numn-1. Each nbhood is 10x10 pixels in size
    # laid out in columns of 8. Actors are assigned as contollers
    # of each nbhood in turn. Nbhood proximity is HERE for nbhoods
    # that have i +/- 1 from the current nbhood, and FAR for all
    # others. Proximity is symmetric.

    typemethod Nbhoods {num} {

        set actors [rdb eval {SELECT a FROM actors}]

        set numa [llength $actors]

        # FIRST, get the map projection to map from canvas
        # coordinates to map reference coordinates
        set proj [map projection]
        set j -1
        set k 0

        # NEXT, cycle through requested nbhoods
        for {set i 0} {$i < $num} {incr i} {

            # NEXT, start a new row if necessary
            if {[expr {$i % 99}] == 0} {
                incr j
            }

            # NEXT, determine polygon coords in canvas space
            let x1 {($i % 99) * 10.0}
            let x2 {$x1 + 10.0}
            let y1 {$j  * 10.0}
            let y2 {$y1 + 10.0}

            # NEXT, reference point is in the center of the 10x10
            # square
            let refptx {($x1 + $x2) / 2.0}
            let refpty {$y1 + 5.0}
            
            # NEXT, convert to mapref strings
            set refpt [$proj c2ref 100.0 $refptx $refpty]
            set pts [list \
                        [$proj c2ref 100.0 $x1 $y1]   \
                        [$proj c2ref 100.0 $x2 $y1]   \
                        [$proj c2ref 100.0 $x2 $y2] \
                        [$proj c2ref 100.0 $x1 $y2]]

            set parms(n)        "N[format "%02d" $i]"
            set parms(refpoint) $refpt
            set parms(polygon)  $pts

            # NEXT, set the controlling actor
            set parms(controller) [lindex $actors $k]

            order send cli NBHOOD:CREATE [array get parms]
            
            # NEXT, increase the actor counter, unless we
            # need to go back to the first actor
            incr k

            if {[expr {$k % $numa}] == 0} {
                set k 0
            }
        }
        
        # NEXT, prepare for nbhood proximity
        array unset parms

        # NEXT, FAR nbhoods. We will override appropriate
        # nbhoods with a proximity of NEAR in the next step
        for {set i 0} {$i < $num} {incr i} {
            for {set j 0} {$j < $num} {incr j} {
                if {$i == $j} {
                    continue
                }

                # Symmetric
                lappend parms(ids) [list "N[format "%02d" $i]" \
                                         "N[format "%02d" $j]"]
                lappend parms(ids) [list "N[format "%02d" $j]" \
                                         "N[format "%02d" $i]"]
            }
        }

        set parms(proximity) "FAR"
        order send cli NBREL:UPDATE:MULTI [array get parms]

        # NEXT, prepare for NEAR nbhoods
        array unset parms

        # NEXT, NEAR nbhoods are nbhoods that have i = +/- 1
        # from current nbhood.
        for {set i 0} {$i < $num} {incr i} {
            if {$i > 0 && $i < $num-1} {
                set j1 [format "%02d" [expr {$i - 1}]]
                set j2 [format "%02d" [expr {$i + 1}]]

                lappend parms(ids) [list "N[format "%02d" $i]" N$j1]
                lappend parms(ids) [list "N[format "%02d" $i]" N$j2]

                # Symmetric
                lappend parms(ids) [list N$j1 "N[format "%02d" $i]"]
                lappend parms(ids) [list N$j2 "N[format "%02d" $i]"]
            }
        }

        set parms(proximity) "NEAR"

        order send cli NBREL:UPDATE:MULTI [array get parms]
    }

    # Civgroups num 
    #
    # num   - number of CIV groups per nbhood
    #
    # This method creates numc civilian groups per neighborhood. The
    # ID of each civgroup is determined by the neighborhood and group.
    # Thus, group "C01" is civilian group 0 in nbhood 1. Each group
    # is given a base population of some multiple of 10000. The first
    # group is given no population. Every other group is a subsistence
    # agriculture group.

    typemethod CivGroups {num} {
        set nbhoods [rdb eval {SELECT n FROM nbhoods}]

        set numn [llength $nbhoods]
        set housing [ehousing names]
        set nhousing [llength $housing]

        # FIRST, step through number of civgroups per nbhood.
        for {set i 0} {$i < $num} {incr i} {

            # NEXT, set base pop, which is zero for the first group
            let parms(basepop) {$i*10000}

            # NEXT, by default, not subsistence farmers. This is 
            # overridden for the last group in each neighborhood
            set parms(sa_flag) 0
            set parms(lfp) 60

            set ctr 0

            # NEXT, step through neighborhoods creating groups as we go
            for {set j 0} {$j < $numn} {incr j} {
                set parms(g) C$j$i
                set parms(n) [lindex $nbhoods $j]

                # NEXT set housing
                set parms(housing) [lindex $housing $ctr]

                # NEXT cycle to next housing index, returning to the
                # first if necessary
                incr ctr
                if {[expr {$ctr % $nhousing}] == 0} {
                    set ctr 0
                }

                # NEXT, last group in each neighborhood is subsistence 
                # farmers
                if {$j == $numn-1} {
                    set parms(sa_flag) 1
                    set parms(lfp) 0

                    # SA can only be at home
                    set parms(housing) AT_HOME
                }

                order send cli CIVGROUP:CREATE [array get parms]
            }
        }
    }

    # OrgGroups num 
    #
    # num   - number of org groups to create
    #
    # This method creates the specified number of ORG groups and has
    # the last actor in the list of actors own all of them. The type
    # of ORG group is assigned in turn. Thus, if there are at least as
    # many ORG groups as there are types, all types will be represented.
    # Each group is given a base personnel of 10000.

    typemethod OrgGroups {num} {
        # FIRST, identify owning actor, its the last one in the list of
        # actors
        set parms(a) [lindex [rdb eval {SELECT a FROM actors}] end]

        # NEXT, have that actors support no one
        set parms(supports) NONE
        order send cli ACTOR:UPDATE [array get parms]

        # NEXT, no longer need the "supports" parm
        unset parms(supports)

        # NEXT, number of orgtypes
        set norgtypes [llength [eorgtype names]]

        set orgtype 0

        # NEXT step through number of orgs creating each one
        for {set i 0} {$i < $num} {incr i} {
            set parms(g) "O[format "%02d" $i]"
            set parms(orgtype) [eorgtype name $orgtype]
            set parms(base_personnel) 100000
            set parms(cost) "1K"

            order send cli ORGGROUP:CREATE [array get parms]

            incr orgtype
            
            # NEXT, go to first orgtype if we are past the last
            if {[expr $orgtype % $norgtypes] == 0} {
                set orgtype 0
            }
        }
    }


    # FrcGroups num
    #
    # num   - number of frc groups to create
    #
    # This method creates the specified number of force groups.
    # Actors are assigned as owners of a force group in turn.
    # If there are ORG groups, the last actor is skipped; he owns
    # the ORG groups. Each force group is given a base personnel
    # of 10000 and force group types are stepped through in turn.
    # If there are at least as many force groups as there are force
    # group types, then at least one of each type is created.

    typemethod FrcGroups {num} {
        # FIRST, get the list of actors
        set actors [rdb eval {SELECT a FROM actors}]

        set numa [llength $actors]

        # NEXT, the number of force group types
        set nfrctypes [llength [eforcetype names]]

        # NEXT, initialize indices for owning actor and for
        # force group type
        set j 0
        set frctype 0

        # NEXT, create each force group
        for {set i 0} {$i < $num} {incr i} {
            set parms(g)              "F[format "%02d" $i]"
            set parms(a)              [lindex $actors $j]
            set parms(forcetype)      [eforcetype name $frctype]
            set parms(base_personnel) 100000
            set parms(cost)           "1K"
            set parms(uniformed)      [expr {$i % 2}]

            order send cli FRCGROUP:CREATE [array get parms]

            incr frctype
            incr j

            # NEXT, if we are at the last force group type 
            # go back to the first one
            if {[expr $frctype % $nfrctypes] == 0} {
                set frctype 0
            }

            # NEXT, if we are at the last actor go back to the
            # first one.
            if {[expr $j % $numa] == 0} {
                set j 0
            }
        }
    }

    # BSystem num
    #
    # num   number of topics to create
    #
    # This method creates the number of requested topics and then
    # goes through actors and civilian groups assigning beliefs
    # to each. There are four possible position/emphasis pairs for
    # each entity. These pairs are cycled through the topics. If
    # there are as many topics as there are pairs (four) then
    # affinities between all entities are homogenous. If tension 
    # is desired, it's best to have three or five topics.

    typemethod BSystem {num} {

        # FIRST, get the actors and civ groups
        set actors [rdb eval {SELECT a FROM actors}]
        set civg   [rdb eval {SELECT g FROM civgroups}]

        # NEXT, create the requested topics
        for {set i 0} {$i < $num} {incr i} {
            set tid "T[format "%02d" $i]"

            set parms(tid) $tid
            set parms(title) $tid
            set parms(affinity) 1

            order send cli BSYSTEM:TOPIC:CREATE [array get parms]
        }

        # NEXT, get the list of topics just created
        set topics [rdb eval {SELECT tid FROM mam_topic}]

        array unset parms

        # NEXT, set up the list of positions and emphases, this
        # list could be expanded
        set pelist [list \
                       [list P+ ASTRONG ] \
                       [list P+ DEXTREME] \
                       [list P- ASTRONG ] \
                       [list P- DEXTREME]]

        # NEXT, give actors their beliefs
        set idx 0
        foreach a $actors {
            foreach t $topics {
                set parms(id) "$a $t"

                # NEXT, set position/emphasis pair 
                lassign [lindex $pelist $idx] parms(position) parms(emphasis)

                order send cli BSYSTEM:BELIEF:UPDATE [array get parms]

                # NEXT, go to next position/emphasis pair
                incr idx

                # NEXT, if we are out of pairs, go back to the first one
                if {[expr {$idx % [llength $pelist]}] == 0} {
                    set idx 0
                }
            }
        }

        # NEXT, give civilians their beliefs
        # Note: pick up position/emphasis pairs where the actors left off
        foreach g $civg {
            foreach t $topics {
                set parms(id) "$g $t"
                lassign [lindex $pelist $idx] parms(position) parms(emphasis)

                order send cli BSYSTEM:BELIEF:UPDATE [array get parms]

                # NEXT, go to next position/emphasis pair
                incr idx

                # NEXT, if we are out of pairs, go back to the first one
                if {[expr {$idx % [llength $pelist]}] == 0} {
                    set idx 0
                }
            }
        }
    }

    # Strategy
    #
    # This method sets up a default set of tactics for each actor if 
    # the -strategy flag is set to 1
    
    typemethod Strategy {args} {
        array set opts [lindex $args 0]

        if {$opts(-actors) eq "ALL"} {
            set opts(-actors) [rdb eval {SELECT a FROM actors}]
        }

        if {$opts(-frcact) eq "ALL"} {
            set opts(-frcact) [activity frc names]
        }

        if {$opts(-orgact) eq "ALL"} {
            set opts(-orgact) [activity org names]
        }

        if {$opts(-nbhoods) eq "ALL"} {
            set opts(-nbhoods) [rdb eval {SELECT n FROM nbhoods}]
        }

        # NEXT, reset activity index
        set info(aidx) 0

        # NEXT, step through each actor setting up group strategy for
        # the groups each actor owns
        if {"DEPLOY" in $opts(-tactics)} {
            foreach a $opts(-actors) {
                set frcgroups \
                    [rdb eval {SELECT g FROM frcgroups WHERE a=$a}]
                set orggroups \
                    [rdb eval {SELECT g FROM orggroups WHERE a=$a}]

                if {$opts(-frcgroups) ne "ALL"} {
                    set frcgroups $opts(-frcgroups)
                }

                autogen GroupStrategy \
                    $a $frcgroups FRC $opts(-frcact) $opts(-nbhoods)

                if {$opts(-orggroups) ne "ALL"} {
                    set orggroups $opts(-orggroups)
                }

                autogen GroupStrategy \
                    $a $orggroups ORG $opts(-orgact) $opts(-nbhoods)
            }
        }

        if {"FUNDENI" in $opts(-tactics)} {
            set civgroups [rdb eval {SELECT g FROM civgroups}]

            if {$opts(-civgroups) ne "ALL"} {
                set civgroups $opts(-civgroups)
            }

            foreach a $opts(-actors) {
                autogen FundENITactic $a $civgroups
            }
        }
    }

    # GroupStrategy  a groups gtype activites
    #
    # a        The actor who owns the groups
    # gtype    The type of groups; FRC or ORG
    #
    # This method deploys and assigns appropriate activities
    # to groups owned by actor a. Activities are assigned in turn
    # to each neighborood. The type of activities depend on whether
    # gtype is FRC or ORG.

    typemethod GroupStrategy {a groups gtype activities nbhoods} {

        # FIRST, set the table name to look up the number of personnel
        set gtable "[string tolower $gtype]groups"

        # NEXT, see if this actor owns any groups of this group type
        set ownedgroups [rdb eval "SELECT g FROM $gtable WHERE a=\$a"]

        # NEXT, no groups, get out
        if {[llength $groups] == 0} {
            return
        }

        # NEXT, error if a group is not owned
        foreach group $groups {
            if {$group ni $ownedgroups} {
                error "$a does not own $group"
            }
        }

        # NEXT, determine activities based on group type
        set actlen [llength $activities]
        
        # NEXT, in case we've gone from a FRC group to an ORG group
        # and the activity counter is out of range, reset it
        if {$info(aidx) > $actlen} {
            set info(aidx) 0
        }

        # NEXT, go through each group mobilizing, deploying and assigning
        # appropriate activities
        foreach g $groups {
            set pers \
                [rdb eval "
                    SELECT base_personnel FROM $gtable
                    WHERE g = \$g
                "]

            autogen DeployTactic $a $g

            # NEXT determine the number of personnel per neighborhood to
            # assign to an activity
            set persPerN [expr {int(floor($pers / [llength $nbhoods]))}]

            # NEXT, go through neighborhoods assigning activities
            foreach n $nbhoods {
                set act [lindex $activities $info(aidx)]

                autogen AssignTactic $a $g $n $act $persPerN

                # NEXT, increment activity counter making sure
                # not to run off the end
                incr info(aidx)
                if {[expr $info(aidx) % $actlen] == 0} {
                    set info(aidx) 0
                }
            }
        }
    }

    # AttroeTactic a f g n roe max
    #
    # a    - an actor
    # f    - an attacking group
    # g    - a defending group
    # n    - a neighborhood
    # roe  - the ROE the attacking group should assume
    # max  - the max number of attacks per week
    #
    # This method creates a parms array from the given arguments
    # and sends an order to create an ATTROE tactic for the given
    # actor. Error checking is assumed.

    typemethod AttroeTactic {a f g n roe max} {
        set parms(owner) $a
        set parms(f)     $f
        set parms(g)     $g
        set parms(n)     $n
        set parms(text1) $roe
        set parms(int1)  $max
    
        order send cli TACTIC:ATTROE:CREATE [array get parms]
    }

    # AssignTactic a g n act pers
    #
    # a       the actor that owns the group 
    # g       the group being assigned the activity
    # n       the neighborhood in which the activity is being assigned
    # act     the activity being assigned
    # pers    the number of personnel in g being assigned the activity
    #
    # This helper method creates an ASSIGN strategy with the
    # supplied arguments as the parms. All other parms are defaulted.

    typemethod AssignTactic {a g n act pers} {
        set parms(owner) $a
        set parms(g)     $g
        set parms(n)     $n
        set parms(text1) $act
        set parms(int1)  $pers

        order send cli TACTIC:ASSIGN:CREATE [array get parms]
    }

    # DeployTactic a g
    #
    # a    the actor that owns the group
    # g    the group being deployed
    #
    # This helper method creates a DEPLOY tactic with the supplied
    # arguments as the parms. The tactic is set up to deploy all 
    # available troops evenly across every neighborhood. All other 
    # parms are defaulted.

    typemethod DeployTactic {a g} {
        set parms(owner) $a
        set parms(g)     $g
        set parms(text1) "ALL"
        set parms(nlist) [rdb eval {SELECT n FROM nbhoods}]

        order send cli TACTIC:DEPLOY:CREATE [array get parms]
    }

    # FundENITactic a grps
    #
    # a      - an actor
    # grps   - the CIV groups to receive ENI funding
    #
    # This method creates a parms array and sends an order to create
    # a FUNDENI tactic for the given actor and list of groups.
    #
    # Error checking has already been done.

    typemethod FundENITactic {a grps} {
        set parms(owner)   $a
        set parms(glist)   $grps
        set parms(x1)      "1K"
        set parms(once)    NO
        set parms(on_lock) YES

        order send cli TACTIC:FUNDENI:CREATE [array get parms]
    }
}