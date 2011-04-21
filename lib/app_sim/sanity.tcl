#-----------------------------------------------------------------------
# TITLE:
#    sanity.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) Simulation Sanity Checks
#
#    This module defines the "onlock" sanity check, which determines
#    whether the scenario can be locked, and the "ontick" sanity 
#    check, which determines whether simulation execution can proceed.
#
#    NOTE: The strategy sanity check is performed by strategy(sim).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# sanity ensemble

snit::type sanity {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # On-lock Sanity check

    # onlock check
    #
    # Does a sanity check of the model: can we lock the scenario (leave 
    # PREP for PAUSED?)
    # 
    # Returns 1 if sane and 0 otherwise.

    typemethod {onlock check} {} {
        set ht [htools %AUTO%]

        set flag [$type DoOnLockCheck $ht]

        $ht destroy

        return $flag
    }


    # onlock report ht
    # 
    # ht   - An htools buffer.
    #
    # Computes the sanity check, and formats the results into the 
    # ht buffer for inclusion in an HTML page.  This command can
    # presume that the buffer is already initialized and ready to
    # receive the data.

    typemethod {onlock report} {ht} {
        $type DoOnLockCheck $ht
    }


    # DoOnLockCheck ht
    #
    # ht   - An htools buffer
    #
    # Does the sanity check, and returns 1 if sane and 0 otherwise;
    # writes the report into the buffer.

    typemethod DoOnLockCheck {ht} {
        # FIRST, presume that the model is sane.
        set sane 1

        # NEXT, push a buffer onto the stack, for the problems.
        $ht push

        $ht putln "The following problems were found:"
        $ht para

        $ht dl

        # NEXT, Require at least one neighborhood:
        if {[llength [nbhood names]] == 0} {
            set sane 0

            $ht dlitem "No neighborhoods are defined." {
                At least one neighborhood is required.
                Create neighborhoods on the 
                <a href="gui:/tab/viewer">Map</a> tab.
            }
        }

        # NEXT, verify that neighborhoods are properly stacked
        rdb eval {
            SELECT n, obscured_by FROM nbhoods
            WHERE obscured_by != ''
        } {
            set sane 0

            $ht dlitem "Neighborhood Stacking Error." "
                Neighborhood $n is obscured by neighborhood $obscured_by.
                Fix the stacking order on the 
                <a href=\"gui:/tab/nbhoods\">Neighborhoods/Neighborhoods</a>
                tab.
            "
        }

        # NEXT, Require at least one force group
        if {[llength [frcgroup names]] == 0} {
            set sane 0

            $ht dlitem "No force groups are defined." {
                At least one force group is required.  Create force
                groups on the 
                <a href="gui:/tab/frcgroups">Groups/FrcGroups</a> tab.
            }
        }

        # NEXT, Require that each force group has an actor
        set names [rdb eval {SELECT g FROM frcgroups WHERE a IS NULL}]

        if {[llength $names] > 0} {
            set sane 0

            $ht dlitem "Some force groups have no owner." "
                The following force groups have no owning actor:
                [join $names {, }].  Assign owning actors to force
                groups on the 
                <a href=\"gui:/tab/frcgroups\">Groups/FrcGroups</a>
                tab.
            "
        }

        # NEXT, Require that each ORG group has an actor
        set names [rdb eval {SELECT g FROM orggroups WHERE a IS NULL}]

        if {[llength $names] > 0} {
            set sane 0

            $ht dlitem "Some organization groups have no owner." "
                The following organization groups have no owning actor:
                [join $names {, }].  Assign owning actors to
                organization groups on the 
                <a href=\"gui:/tab/orggroups\">Groups/OrgGroups</a>
                tab.
            "
        }

        # NEXT, Require at least one civ group
        if {[llength [civgroup names]] == 0} {
            set sane 0

            $ht dlitem "No civilian groups are defined." {
                At least one civilian group is required.  Create civilian
                groups on the 
                <a href="gui:/tab/civgroups">Groups/CivGroups</a>
                tab.
            }
        }

        # NEXT, collect data on groups and neighborhoods
        rdb eval {
            SELECT g,n FROM civgroups
        } {
            lappend gInN($n)  $g
        }

        # NEXT, Every neighborhood must have at least one group
        # TBD: Is this really required?  Can we insist, instead,
        # that at least one neighborhood must have a group?
        foreach n [nbhood names] {
            if {![info exists gInN($n)]} {
                set sane 0

                $ht dlitem "Neighborhood has no residents" "
                    Neighborhood $n contains no civilian groups;
                    at least one is required.  Create civilian
                    groups and assign them to neighborhoods
                    on the 
                    <a href=\"gui:/tab/civgroups\">Groups/CivGroups</a>
                    tab.
                "
            }
        }

        # NEXT, every ensit must reside in a neighborhood
        set ids [rdb eval {
            SELECT s FROM ensits
            WHERE n = ''
        }]

        if {[llength $ids] > 0} {
            set sane 0

            set ids [join $ids ", "]

            $ht dlitem "Homeless Environmental Situations" "
                The following ensits are outside any neighborhood: $ids.
                Either add neighborhoods around them on the Map tab,
                or delete them on the 
                <a href=\"gui:/tab/ensits\">Neighborhoods/Ensits</a>
                tab.
            "
        }

        # NEXT, you can't have more than one ensit of a type in a 
        # neighborhood.
        rdb eval {
            SELECT count(s) AS count, n, stype
            FROM ensits
            GROUP BY n, stype
            HAVING count > 1
        } {
            set sane 0

            $ht dlitem "Duplicate Environmental Situations" "
                There are duplicate ensits of type $stype in
                neighborhood $n.  Delete all but one of them on the
                <a href=\"gui:/tab/ensits\">Neighborhoods/Ensits</a>
                tab.
            "
        }

        # NEXT, there must be at least 1 local consumer; and hence, there
        # must be at least one local civ group with a sap less than 100.

        if {![rdb exists {
            SELECT sap 
            FROM civgroups JOIN nbhoods USING (n)
            WHERE local AND sap < 100
        }]} {
            set sane 0

            $ht dlitem "No consumers in local economy" {
                There are no consumers in the local economy.  At least
                one civilian group in a "local" neighborhood
                needs to have non-subsistence
                population.  Add or edit civilian groups on the
                <a href="gui:/tab/civgroups">Groups/CivGroups</a>
                tab.
            }
        }

        # NEXT, The econ(sim) CGE Cobb-Douglas parameters must sum to 
        # 1.0.  Therefore, econ.f.*.goods and econ.f.*.pop must sum to
        # <= 1.0, since f.else.goods and f.else.pop can be 0.0, and
        # f.*.else must sum to no more than 0.95, so that f.else.else
        # isn't 0.0.

        let sum {
            [parmdb get econ.f.goods.goods] + 
            [parmdb get econ.f.pop.goods]
        }

        if {$sum > 1.0} {
            set sane 0

            $ht dlitem "Invalid Cobb-Douglas Parameters" {
                econ.f.goods.goods + econ.f.pop.goods > 1.0.  However,
                Cobb-Douglas parameters must sum to 1.0.  Therefore,
                the following must be the case:<p>

                econ.f.goods.goods + econ.f.pop.goods <= 1.0<p>

                Use the
                <a href="my://help/command/parm/set">parm set</a>
                command to edit the parameter values.
            }
        }

        let sum {
            [parmdb get econ.f.goods.pop] + 
            [parmdb get econ.f.pop.pop]
        }

        if {$sum > 1.0} {
            set sane 0
            $ht dlitem "Invalid Cobb-Douglas Parameters" {
                econ.f.goods.pop + econ.f.pop.pop > 1.0.  However,
                Cobb-Douglas parameters must sum to 1.0.  Therefore,
                the following must be the case:<p>

                econ.f.goods.pop + econ.f.pop.pop <= 1.0<p>

                Use the
                <a href="my://help/command/parm/set">parm set</a>
                command to edit the parameter values.
            }
        }


        let sum {
            [parmdb get econ.f.goods.else] + 
            [parmdb get econ.f.pop.else]
        }

        if {$sum > 0.95} {
            set sane 0
            $ht dlitem "Invalid Cobb-Douglas Parameters" {
                econ.f.goods.pop + econ.f.pop.pop > 1.0.  However,
                Cobb-Douglas parameters must sum to 1.0.  Also, the
                value of f.else.else cannot be 0.0.  Therefore,
                the following must be the case:<p>

                econ.f.goods.else + econ.f.pop.else <= 0.95<p>

                Use the
                <a href="my://help/command/parm/set">parm set</a>
                command to edit the parameter values.
            }
        }

        $ht /dl

        set html [$ht pop]

        if {$sane} {
            $ht putln "The scenario is sane."
        } else {
            $ht put $html
        }

        # NEXT, return the result
        return $sane
    }

    #-------------------------------------------------------------------
    # On-Tick Sanity Check

    # ontick check
    #
    # Does a sanity check of the model: can we advance time?
    # 
    # Returns 1 if sane and 0 otherwise.

    typemethod {ontick check} {} {
        set ht [htools %AUTO%]

        set flag [$type DoOnTickCheck $ht]

        $ht destroy

        return $flag
    }


    # ontick report ht
    # 
    # ht   - An htools buffer.
    #
    # Computes the sanity check, and formats the results into the 
    # ht buffer for inclusion in an HTML page.  This command can
    # presume that the buffer is already initialized and ready to
    # receive the data.

    typemethod {ontick report} {ht} {
        $type DoOnTickCheck $ht
    }


    # DoOnTickCheck ht
    #
    # ht   - An htools buffer
    #
    # Does the sanity check, and returns 1 if sane and 0 otherwise;
    # writes the report into the buffer.

    typemethod DoOnTickCheck {ht} {
        # FIRST, presume that the model is sane.
        set sane 1

        # NEXT, push a buffer onto the stack, for the problems.
        $ht push

        # NEXT, Some help for the reader
        $ht putln "<b>Sanity Check(s) Failed.</b>" 
        $ht putln {
            One or more of Athena's on-tick sanity checks has failed; the
            entries below give complete details.  Most checks depend on 
            the economic model; hence, setting the 
            <a href="my://help/parmdb/econ/disable">econ.disable</a> parameter
            to "yes" will disable them and allow the simulation to proceed,
            at the cost of ignoring the economy.  
            (See <a href="my://help/parmdb">Model Parameters</a>
            in the on-line help for information on how to browse and
            set model parameters.)
        }
        
        $ht para

        $ht dl

        # NEXT, has the econ model been disabled?
        let gotEcon {![parmdb get econ.disable]}

        # NEXT, Check econ CGE convergence.
        if {$gotEcon && ![econ ok]} {
            set sane 0

            $ht dlitem "Economy: Diverged" {
                The economic model uses a system of equations called
                a CGE.  The system of equations could not be solved.
                This might be an error in the CGE; alternatively, the
                economy might really be in chaos.
            }
        }

        # NEXT, check a variety of econ result constraints.
        array set cells [econ get]
        array set start [econ getstart]

        if {$gotEcon && $cells(Out::SUM.QS) == 0.0} {
            set sane 0

            $ht dlitem "Economy: Zero Production" {
                The economy has converged to the zero point, i.e., there
                is no consumption or production, and hence no economy.
                Enter 
                <tt><a href="my://help/command/dump/econ">dump econ In</a></tt>
                at the CLI to see the current 
                inputs to the economy; it's likely that there are no
                consumers.
            }
        }

        if {$gotEcon && !$cells(Out::FLAG.QS.NONNEG)} {
            set sane 0

            $ht dlitem "Economy: Negative Quantity Supplied" {
                One of the QS.i cells has a negative value; this implies
                an error in the CGE.  Enter 
                <tt><a href="my://help/command/dump/econ">dump econ</a></tt>
                at the CLI to
                see the full list of CGE outputs.  Consider setting
                the 
                <a href="my://help/parmdb/econ/disable">econ.disable</a>
                parameter to "yes", since the
                economic model is clearly malfunctioning.
            }
        }

        if {$gotEcon && !$cells(Out::FLAG.P.POS)} {
            set sane 0

            $ht dlitem "Economy: Non-Positive Prices" {
                One of the P.i price cells is negative or zero; this implies
                an error in the CGE.  Enter 
                <tt><a href="my://help/command/dump/econ">dump econ</a></tt>
                at the CLI to
                see the full list of CGE outputs.  Consider setting
                the 
                <a href="my://help/parmdb/econ/disable">econ.disable</a>
                parameter to "yes", since the
                economic model is clearly malfunctioning.
            }
        }

        if {$gotEcon && !$cells(Out::FLAG.DELTAQ.ZERO)} {
            set sane 0

            $ht dlitem "Economy: Delta-Q non-zero" {
                One of the deltaQ.i cells is negative or zero; this implies
                an error in the CGE.
                Enter 
                <tt><a href="my://help/command/dump/econ">dump econ</a></tt>
                at the CLI to
                see the full list of CGE outputs.  Consider setting
                the 
                <a href="my://help/parmdb/econ/disable">econ.disable</a>
                parameter to "yes", since the
                economic model is clearly malfunctioning.
            }
        }

        set limit [parmdb get econ.check.MinConsumerFrac]
        if {$gotEcon && 
            $cells(In::Consumers) < $limit * $start(In::Consumers)
        } {
            set sane 0

            $type dlitem "Number of consumers has declined alarmingly" "
                The current number of consumers in the local economy,
                $cells(In::Consumers),
                is less than 
                $limit
                of the starting number.  To change the limit, set the
                value of the 
                <a href=\"my://help/parmdb/econ/check.MinConsumerFrac\">econ.check.MinConsumerFrac</a>
                model parameter.
            "
        }

        set limit [parmdb get econ.check.MinLaborFrac]
        if {$gotEcon && 
            $cells(In::WF) < $limit * $start(In::WF)
        } {
            set sane 0

            $ht dlitem "Number of workers has declined alarmingly" "
                The current number of workers in the local labor force,
                $cells(In::WF), 
                is less than
                $limit
                of the starting number.  To change the limit, set the 
                value of the 
                <a href=\"my://help/parmdb/econ/check.MinLaborFrac\">econ.check.MinLaborFrac</a>
                model parameter.
            "
        }

        set limit [parmdb get econ.check.MaxUR]
        if {$gotEcon && $cells(Out::UR) > $limit} {
            set sane 0

            $ht dlitem "Unemployment skyrockets" "
                The unemployment rate, 
                [format {%.1f%%,} $cells(Out::UR)]
                exceeds the limit of 
                [format {%.1f%%.} $limit]
                To change the limit, set the value of the 
                <a href=\"my://help/parmdb/econ/check.MaxUR\">econ.check.MaxUR</a>
                model parameter.
            "
        }

        set limit [parmdb get econ.check.MinDgdpFrac]
        if {$gotEcon && 
            $cells(Out::DGDP) < $limit * $start(Out::DGDP)
        } {
            set sane 0

            $ht dlitem "DGDP Plummets" "
                The Deflated Gross Domestic Product (DGDP),
                \$[moneyfmt $cells(Out::DGDP)],
                is less than 
                $limit
                of its starting value.  To change the limit, set the
                value of the 
                <a href=\"my://help/parmdb/econ/check.MinDgdpFrac\">econ.check.MinDgdpFrac</a>
                model parameter.
            "
        }

        set min [parmdb get econ.check.MinCPI]
        set max [parmdb get econ.check.MaxCPI]
        if {$gotEcon && $cells(Out::CPI) < $min || 
            $cells(Out::CPI) > $max
        } {
            set sane 0

            $ht dlitem "CPI beyond limits" "
                The Consumer Price Index (CPI), 
                [format {%4.2f,} $cells(Out::CPI)]
                is outside the expected range of
                [format {(%4.2f, %4.2f).} $min $max]
                To change the bounds, set the values of the 
                <a href=\"my://help/parmdb/econ/check.MinCPI\">econ.check.MinCPI</a>
                and 
                <a href=\"my://help/parmdb/econ/check.MaxCPI\">econ.check.MaxCPI</a>
                model parameters.
            "
        }

        $ht /dl

        set html [$ht pop]

        if {$sane} {
            $ht putln "Time can advance."
        } else {
            $ht put $html
        }
        

        # NEXT, return the result
        return $sane
    }
}


