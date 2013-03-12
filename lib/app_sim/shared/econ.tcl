#-----------------------------------------------------------------------
# FILE: econ.tcl
#
#   Athena Economics Model singleton
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#    Dave Hanks
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module: econ
#
# This module is responsible for computing the economics of the
# region for this scenario.  The three primary entry points are:
# <init>, to be called at start-up; <calibrate>, which calibrates the 
# model when the simulation leaves the PREP state and enters time 0, 
# and <advance>, to be called when time is advanced for the economic model.
#
# CREATION/DELETION:
#    econ_n records are created explicitly by nbhood(sim) as 
#    neighborhoods are created, and are deleted by cascading delete.

snit::type econ {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    # Type Component: cge
    #
    # This is the cellmodel(n) instance containing the CGE model.

    typecomponent cge

    # Type Component: sam
    #
    # This is the cellmodel(n) instance containing the SAM model.

    typecomponent sam

    #-------------------------------------------------------------------
    # Non-Checkpointed Type Variables

    # Type Variable: info
    #
    # Miscellaneous non-checkpointed scalar values.
    #
    # changed - 1 if there is unsaved data, and 0 otherwise.

    typevariable info -array {
        changed 0
        econStatus ok
        econPage   {}
    }

    #-------------------------------------------------------------------
    # Checkpointed Type Variables

    # Type Variable: startdict
    #
    # Dictionary of initial CGE cell values, as of "econ start".

    typevariable startdict {}

    #-------------------------------------------------------------------
    # Sanity Check

    # checker ?ht?
    #
    # ht - An htools buffer
    #
    # Computes the sanity check, and formats the results into the buffer
    # for inclusion indo an HTML page. Returns an esanity value, either
    # OK or WARNING.

    typemethod checker {{ht ""}} {
        # FIRST, if econ is disabled, always return OK
        if {[parmdb get econ.disable]} {
            return OK
        }

        # NEXT, perform the checks and return status
        set edict [$type DoSanityCheck]

        if {[dict size $edict] == 0} {
            return OK
        }

        if {$ht ne ""} {
            $type DoSanityReport $ht $edict
        }

        return ERROR
    }

    # DoSanityCheck
    #
    # Performs a sanity check on the various parts of the econ module. 
    # This primarily checks key cells in the SAM to see if there is data
    # that just doesn't make sense. Problems are reported back in a
    # dict, if there are any.

    typemethod DoSanityCheck {} {
        set edict [dict create]

        array set cells [$sam get]

        let URfrac {$cells(BaseUR) / 100.0}

        # FIRST, turbulence cannot be greater than the unemployment rate
        if {$URfrac < [parmdb get econ.turFrac]} {
            dict append edict BaseUR \
                "The unemployment rate, $cells(BaseUR)%, must be greater than or equal to econ.turFrac."
        }

        # NEXT, per capita demand for goods must be reasonable
        if {$cells(BA.goods.pop) < 1.0} {
            dict append edict BA.goods.pop \
                "Annual per capita demand for goods is less than 1 goods basket."
        }

        # NEXT, base consumers must not be too low.
        if {$cells(BaseConsumers) < 100} {
            dict append edict BaseConsumers \
                "Base number of consumers must not be less than 100."
        }

        # NEXT, no base prices can be zero.
        if {$cells(BP.goods) == 0.0} {
            dict append edict BP.goods \
                "Base price of goods must not be zero."
        }

        if {$cells(BP.black) == 0.0} {
            dict append edict BP.black \
                "Base price in black market must not be zero."
        }

        if {$cells(BP.pop) == 0.0} {
            dict append edict BP.pop \
                "Base price in the pop sector must not be zero."
        }

        # The goods sector and pop sectors must have revenue and expenditures,
        # otherwise what's the point
        if {$cells(BREV.goods) == 0.0} {
            dict append edict BREV.goods \
                "There must be revenue in the goods sector."
        }

        if {$cells(BREV.pop) == 0.0} {
            dict append edict BREV.pop \
                "There must be revenue in the pop sector."
        }

        if {$cells(BEXP.goods) == 0.0} {
            dict append edict BEXP.goods \
                "There must be expenditures in the goods sector."
        }

        if {$cells(BEXP.pop) == 0.0} {
            dict append edict BEXP.pop \
                "There must be expenditures in the pop sector."
        }

        if {$cells(XT.pop.goods) == 0.0} {
            dict append edict BX.pop.goods \
                "There must be a money flow from the goods sector to the pop sector."
        }

        # NEXT, Cobb-Douglas coefficients in the goods sector must add up 
        # to 1.0 within a reasonable epsilon and cannot be greater than 1.0. 
        # The black sector is assumed to never have money flow into it from
        # the goods sector, thus f.black.goods == 0.0
        let f_goods {$cells(f.goods.goods) + $cells(f.pop.goods)}

        if {![Within $f_goods 1.0 0.001]} {
            dict append edict f.goods \
                "The Cobb-Douglas coefficients in the goods sector do not sum to 1.0"
        }

        # NEXT, Cobb-Douglas coefficients in the pop sector must add up to 1.0
        # within a reasonable epsilon
        let f_pop {
            $cells(f.goods.pop) + $cells(f.black.pop) + $cells(f.pop.pop)
        }

        if {![Within $f_pop 1.0 0.001]} {
            dict append edict f.pop \
                "The Cobb-Douglas coefficients in the pop sector do not sum to 1.0"
        }

        if {$cells(BNR.black) < 0.0} {
            dict append edict NR.black \
                "Net Rev. in the black sector is negative. Either the feedstock price is too high or the unit price is too low."
        }

        notifier send ::econ <Check>
        return $edict
    }

    # DoSanityReport ht edict
    #
    # ht    - an htools(n) buffer
    # edict - a dictionary of errors to be formatted for HTML output
    #
    # This method takes any errors from the sanity check and formats
    # them for output to the htools buffer.

    typemethod DoSanityReport {ht edict} {
        $ht subtitle "Econ Model Warnings/Errors"

        $ht putln "Certain cells in the SAM have problems. This is likely "
        $ht putln "due to incorrect data being entered in the SAM. Details "
        $ht putln "are below."

        $ht para

        dict for {cell errmsg} $edict {
            $ht br
            $ht putln "$cell ==> $errmsg"
        }

        return
    }

    # Initialization

    # init
    #
    # Initializes the module before the simulation first starts to run.

    typemethod init {} {
        log normal econ "init"

        # FIRST, create the SAM
        set sam [cellmodel sam \
                     -epsilon 0.000001 \
                     -maxiters 1       \
                     -tracecmd [mytypemethod TraceSAM]]

        sam load \
            [readfile [file join $::app_sim_shared::library sam6x6.cm]]

        log detail econ "Read SAM from [file join $::app_sim_shared::library sam6x6.cm]"

        require {[sam sane]} "The econ model's SAM is not sane."

        set result [sam solve]

        # NEXT, handle failures.
        if {$result ne "ok"} {
            log warning econ "Failed to solve SAM"
            error "Failed to solve SAM model."
        }

        # NEXT, create the CGE.
        set cge [cellmodel cge \
                     -epsilon  0.000001 \
                     -maxiters 1000     \
                     -failcmd  [mytypemethod CGEFailure] \
                     -tracecmd [mytypemethod TraceCGE]]
        cge load [readfile [file join $::app_sim_shared::library cge6x6.cm]]

        log detail econ "Read CGE from [file join $::app_sim_shared::library cge6x6.cm]"
        
        require {[cge sane]} "The econ model's CGE (cge6x6.cm) is not sane."

        # NEXT, register this type as a saveable
        scenario register ::econ

        # NEXT, Econ is up.
        log normal econ "init complete"
    }


    # report ht
    #
    # ht   - an htools object used to build the report
    #
    # This method creates an HTML report that reports on the status of
    # the econ model providing some insight if there has been a failure
    # for some reason.

    typemethod report {ht} {
        # FIRST, if everything is fine, not much to report
        if {$info(econStatus) eq "ok"} {
            if {![parmdb get econ.disable]} {
                $ht putln "The econ model is enabled and is operating without "
                $ht putln "error."
            } else {
                $ht putln "The econ model has been disabled."
            }
        } else {
            # NEXT, the CGE has either diverged or has errors, generate
            # the appropriate report 

            if {$info(econStatus) eq "diverge"} {
                $ht putln "The econ model was not able to converge on the "
                $ht put   "$info(econPage) page.  "
            } elseif {$info(econStatus) eq "errors"} {
                $ht putln "The econ model has encountered one or more errors. "
                $ht putln "The list of cells and their problems are: "
                
                $ht para
                
                # NEXT, create a table of cells and their errors
                $ht push

                foreach {cell} [$cge cells error] {
                    set err [$cge cellinfo error $cell]
                    $ht tr {
                        $ht td left {$ht put $cell}
                        $ht td left {$ht put $err}
                    }
                }
                set text [$ht pop]

                $ht table {
                    "Cell Name" "Error"
                } {
                    $ht putln $text
                }

                set solutions {}

                # NEXT, look for some possible problems usually it is the
                # actor's sector that causes problems.
                array set cells [$cge get]
                if {$cells(t.actors.goods) >= 1.0 ||
                    $cells(t.region.goods) >= 1.0 ||
                    $cells(t.world.goods)  >= 1.0} {
                }

                if {[llength $solutions] > 0} {

                    $ht para
                    $ht putln "Troubleshooting suggestions:"
                    $ht para
                    $ht put "<ul>"

                    foreach solution $solutions {
                        $ht put "<li> $solution"
                    }

                    $ht put "</ul>"
                    $ht para
                }
            }

            $ht para

            $ht putln "Because of this the econ model has been disabled "
            $ht put   "automatically. "

            $ht para

            $ht put   "A file called cgedebug.cmsnap that contains the set "
            $ht put   "of initial conditions that led to this problem "
            $ht put   "is located in [file normalize [workdir join ..]] "
            $ht put   "and can be used for debugging this problem."

            $ht para

            $ht putln "You can continue to run Athena with the model "
            $ht put   "disabled or you can return to PREP and try to "
            $ht put   "fix the problem."
        }
    }

    # TraceCGE
    #
    # The cellmodel(n) -tracecmd for the cell model components.  It simply
    # logs arguments.

    typemethod TraceCGE {args} {
        if {[lindex $args 0] eq "converge"} {
            log detail econ "cge solve trace: $args"
        } else {
            log debug econ "cge solve trace: $args"
        }
    }

    # TraceSAM
    #
    # The cellmodel(n) -tracecmd for the cell model components.  It simply
    # logs arguments.

    typemethod TraceSAM {args} {
        if {[lindex $args 0] eq "converge"} {
            log detail econ "sam solve trace: $args"
        } else {
            log debug econ "sam solve trace: $args"
        }
    }

    # CGEFailure msg page
    #
    # msg    - the type of error: diverge or errors
    # page   - the page in the CGE that the failure occurred
    #
    # This is called by the CGE cellmodel(n) if there is a failure
    # when trying to solve. It will prompt the user to output an 
    # initialization file that can be used with mars_cmtool(1) to 
    # further analyze any problems.

    typemethod CGEFailure {msg page} {
        # FIRST, log the warning
        log warning econ "CGE Failed to solve: $msg $page"
        
        # NEXT, open a debug file for use in analyzing the problem
        set filename [workdir join .. cgedebug.cmsnap]
        set f [open $filename w]

        # NEXT, dump the CGE initial state
        set vdict [$cge initial]
        dict for {cell value} $vdict {
            puts $f "$cell $value"
        }
        close $f
    }

    # reset
    #
    # Resets the econ model to the initial state for both the SAM
    # and the CGE and notifies the GUI

    typemethod reset {} {
        $sam reset
        set result [sam solve]

        if {$result ne "ok"} {
            log warning econ "Failed to reset SAM"
            error "Failed to reset SAM model"
        }

        $cge reset

        notifier send ::econ <SyncSheet> 
    }

    # InitializeActorIncomeTables
    #
    # This method sets up the tables used to track total income as the sum of
    # all income sources and sector by sector tax and tax like rates.

    typemethod InitializeActorIncomeTables {} {
        # FIRST, the total income by actor. A sum of all income sources.
        # Only INCOME actors are represented.
        rdb eval {
            SELECT a FROM actors
            WHERE atype='INCOME'
        } {
            rdb eval {
                INSERT INTO income_a(a, income)
                VALUES($a, 0.0);
            }
        }
    }

    # ComputeActorsSector
    #
    # The flow of money to and from the actors in Athena is mediated by the
    # definition of the actors themselves. This method grabs the income
    # amounts from the individual actors and aggregates that income into
    # money flows from all other sectors. Using those income
    # values, it recomputes the revenue in the actor sector and allocates
    # the revenue per sector depending on how much overhead is spent on
    # each sector.
    # Finally, it sums the total amount of graft for each actor and computes
    # a graft fraction based upon the amount of Foreign Aid for the Region,
    # the FAR cell (which is the same as the BX.region.world cell).

    typemethod ComputeActorsSector {} {
        # FIRST, get the cells from the SAM
        array set sdata [$sam get]

        # NEXT, determine the ratio of actual consumers to the BaseConsumers
        # specified in the SAM, we will scale the income to this
        array set data [demog getlocal]
        let scaled {$data(consumers)/$sdata(BaseConsumers)}

        set Xag 0.0
        set Xap 0.0
        set Xab 0.0
        set Xar 0.0
        set Xaw 0.0

        # NEXT, get the totals of actor income by sector, scaled by the actual
        # number of consumers, income from black market net revenues is 
        # handled differently. Revenue from the region is the graft that
        # is received. Income is multiplied by 52 weeks since the user 
        # specifies income in weeks, but the SAM and CGE have it in years
        rdb eval {
            SELECT total(income_goods)     AS ig,
                   total(income_pop)       AS ip,
                   total(income_black_tax) AS ibt,
                   total(income_world)     AS iw,
                   total(income_graft)     AS igr
            FROM actors_view 
        } {
            let Xag {$ig  * $scaled * 52.0}
            let Xap {$ip  * $scaled * 52.0}
            let Xab {$ibt * $scaled * 52.0}
            let Xaw {$iw  * $scaled * 52.0}
            let Xar {$igr * $scaled * 52.0}
        }

        # NEXT, the expenditures made by budget actors are accounted for as
        # revenue from the world since budget actors have no income
        set budgetXaw [rdb onecolumn {
            SELECT total(goods + black  + pop +
                         actor + region + world)
            FROM expenditures AS E
            JOIN actors AS A ON (E.a = A.a)
            WHERE A.atype = 'BUDGET'
        }]

        let Xaw {$Xaw + ($budgetXaw * 52.0)}

        # NEXT, deal with black market net revenue
        let BNRb {max(0.0, $sdata(BNR.black))}

        # NEXT, the total number of black market net revenue shares owned
        # by actors. If this is zero, then no actor is getting any income
        # from the black market net revenues
        set totalBNRShares \
            [rdb onecolumn {SELECT total(shares_black_nr) FROM actors_view;}]

        # NEXT, get the baseline expenditures from the cash module
        array set exp [cash allocations]

        let Xwa {$exp(world)  * 52.0}
        let Xra {$exp(region) * 52.0}
        let Xga {$exp(goods)  * 52.0}
        let Xba {$exp(black)  * 52.0}
        let Xpa {$exp(pop)    * 52.0}


        # NEXT, extract the pertinent data from the SAM in preparation for
        # the computation of shape parameters.
        set BPg   $sdata(BP.goods)
        set BQDg  $sdata(BQD.goods)
        set BPb   $sdata(BP.black)
        set BQDb  $sdata(BQD.black)
        set BPp   $sdata(BP.pop)
        set BQDp  $sdata(BQD.pop)
        set BREVw $sdata(BREV.world)
        set FAR   $sdata(BFAR)
 
        # NEXT compute the rates based on the base case data and
        # fill in the income_a table rates and set each actors
        # initial income. NOTE: mulitiplication by 52 because amounts in
        # the SAM are in years and actors in Athena get income in
        # weeks.
        rdb eval {
            SELECT * FROM actors
            WHERE atype = 'INCOME'
        } data {
            let t_goods      {$data(income_goods) * 52.0 / ($BPg * $BQDg)}
            let t_pop        {$data(income_pop)   * 52.0 / ($BPp * $BQDp)}

            if {$BREVw > 0.0} {
                let t_world  {$data(income_world) * 52.0 / $BREVw}
            } else {
                set t_world 0.0
                set data(income_world) 0.0
            }

            if {$FAR > 0.0} {
                let graft_region {$data(income_graft) * 52.0 / $FAR}
            } else {
                set graft_region 0.0
            }

            # NEXT, the black market may not have any product
            if {$BQDb > 0.0} {
                let t_black {$data(income_black_tax) * 52.0 / ($BPb * $BQDb)}
            } else {
                set t_black 0.0
                set data(income_black_tax) 0.0
            }

            # NEXT, distribute black market net revenue shares. If there
            # aren't any, then no actor is getting a cut.
            if {$totalBNRShares > 0} {
                let cut_black {$data(shares_black_nr)  / $totalBNRShares}
            } else {
                set cut_black 0.0
            }

            # NEXT, total income from the black sector is the tax rate
            # income plus the cut of the black market profit (aka net
            # revenue). NOTE: since net revenue is in years in the SAM we
            # divide by 52 to get actor income in weeks.
            let income_tot_black {
                $data(income_black_tax) + max(0.0, ($cut_black * $BNRb / 52.0))
            }

            # NEXT, total income for this actor
            let total_income {
                $data(income_goods) + $income_tot_black   + 
                $data(income_pop)   + $data(income_world) +
                $data(income_graft) 
            }

            # NEXT, set this actors rates and initial income
            rdb eval {
                UPDATE income_a 
                SET t_goods      = $t_goods,
                    t_black      = $t_black,
                    t_pop        = $t_pop,
                    t_world      = $t_world,
                    graft_region = $graft_region,
                    cut_black    = $cut_black,
                    income       = $total_income
                WHERE a=$data(a)
            }
        }

        # NEXT, Set the SAM values from the actor data and solve
        $sam set [list BX.goods.actors  $Xga]
        $sam set [list BX.pop.actors    $Xpa]
        $sam set [list BX.black.actors  $Xba]
        $sam set [list BX.region.actors $Xra]
        $sam set [list BX.world.actors  $Xwa]

        $sam set [list BX.actors.goods  $Xag]
        $sam set [list BX.actors.pop    $Xap]
        $sam set [list BX.actors.black  $Xab]
        $sam set [list BX.actors.region $Xar]
        $sam set [list BX.actors.world  $Xaw]

        # NEXT, if no actor is getting income from black market net revenue,
        # then ALL of the net revenue goes into the world sector. We also
        # need to tell the CGE that actors are not getting any black market
        # profits
        set Xwb $sdata(XT.world.black)

        if {$totalBNRShares == 0} {
            # NEXT, need to subtract out Xab since it was just computed we
            # do not want to double count when the SAM is solved
            let Xwb {$Xwb + $BNRb - $Xab}
            cge set [list Flag.ActorsGetBNR 0]
            sam set [list Flag.ActorsGetBNR 0]
        } else {
            cge set [list Flag.ActorsGetBNR 1]
            sam set [list Flag.ActorsGetBNR 1]
        }

        $sam set [list BX.world.black $Xwb]

        # NEXT, compute the composte graft fraction
        set graft_frac \
            [rdb onecolumn {SELECT total(graft_region) FROM income_a;}]

        $sam set [list graft $graft_frac]

        set result [$sam solve]
        # NEXT, handle failures.
        if {$result ne "ok"} {
            puts $result
            log warning econ "Failed to solve SAM"
            error "Failed to solve SAM model after actor data was loaded."
        }

        # NEXT, notify the GUI to sync to the latest data
        notifier send ::econ <SyncSheet> 
    }

    # InitializeCGE
    #
    # Updates the actors sector in the SAM and then initializes the CGE
    # from the SAM

    typemethod InitializeCGE {} {
        # FIRST, deal with the actors sector in the SAM
        $type ComputeActorsSector

        # NEXT, get sectors and data from the SAM
        set sectors  [$sam index i]
        array set samdata [$sam get]

        # NEXT, base prices from the SAM
        foreach i $sectors {
            cge set [list BP.$i $samdata(BP.$i)]
        }

        # NEXT, base expenditures/revenues as a starting point for 
        # CGE BX.i.j's
        foreach i $sectors {
            foreach j $sectors {
                cge set [list BX.$i.$j $samdata(XT.$i.$j)]
            }
        }

        # NEXT, base quantities demanded as a starting point for 
        # CGE BQD.i.j's
        foreach i {black} {
            foreach j $sectors {
                cge set [list BQD.$i.$j $samdata(BQD.$i.$j)]
            }
        }

        # NEXT, the base GDP
        cge set [list BaseGDP $samdata(BaseGDP)]

        # NEXT, shape parameters for the economy
        
        #-------------------------------------------------------------
        # The goods sector
        foreach i {goods black pop} {
            cge set [list f.$i.goods $samdata(f.$i.goods)]
        }
       
        foreach i {actors region world} {
            cge set [list t.$i.goods $samdata(t.$i.goods)]
        }

        cge set [list k.goods $samdata(k.goods)]

        #-------------------------------------------------------------
        # The black sector
        foreach i {goods black pop} {
            cge set [list A.$i.black $samdata(A.$i.black)]
        }

        foreach i {actors region world} {
            cge set [list t.$i.black $samdata(t.$i.black)]
        }

        #-------------------------------------------------------------
        # The pop sector
        cge set [list k.pop $samdata(k.pop)]

        foreach i {goods black pop} {
            cge set [list f.$i.pop $samdata(f.$i.pop)]
        }

        foreach i {actors region world} {
            cge set [list t.$i.pop $samdata(t.$i.pop)]
        }

        #-------------------------------------------------------------
        # The actors and region sectors
        foreach i $sectors {
            cge set [list f.$i.actors $samdata(f.$i.actors)]
            cge set [list f.$i.region $samdata(f.$i.region)]
        }

        #-------------------------------------------------------------
        # The world sector
        cge set [list BFAA $samdata(BFAA)]
        cge set [list BFAR $samdata(BFAR)]

        #-------------------------------------------------------------
        # Base values for Exports
        foreach i {goods black pop} {
            cge set [list BEXPORTS.$i $samdata(BEXPORTS.$i)]
        }

        #-------------------------------------------------------------
        # A.goods.pop, the unconstrained base demand for goods in 
        # goods basket per year per capita.
        cge set [list BA.goods.pop $samdata(BA.goods.pop)]

        #-------------------------------------------------------------
        # graft, the percentage skimmed off FAR by all actors
        $cge set [list graft $samdata(graft)]

        #-------------------------------------------------------------
        # remittances to the populace
        $cge set [list BREM $samdata(BREM)]

        #-------------------------------------------------------------
        # subsistence agriculture wages, at or near poverty level
        $cge set [list BaseSubWage $samdata(BaseSubWage)]
    }

    #-------------------------------------------------------------------
    # Assessment Routines

    # ok
    #
    # Returns 1 if the economy is "ok" and 0 otherwise.

    typemethod ok {} {
        return [expr {$info(econStatus) eq "ok"}]
    }

    # start
    #
    # Calibrates the CGE.  This is done when the simulation leaves
    # the PREP state and enters time 0.

    typemethod start {} {
        log normal econ "start"

        # FIRST, clear out actor income tables.
        rdb eval {DELETE FROM income_a;}

        if {![parmdb get econ.disable]} {
            # FIRST, reset the CGE
            cge reset

            # NEXT, convert flag to canonical form, the cell model 
            # requires this.
            # TBD: should cellmodel(n) be changed to handle symbolic 
            # "yes" and "no"?
            set flag \
                [::projectlib::boolean validate [parm get econ.REMisTaxed]]

            sam set [list Flag.REMisTaxed $flag]

            $type InitializeActorIncomeTables

            $type InitializeCGE

            $type analyze -calibrate

            set startdict [$cge get]

            log normal econ "start complete"
        } else {
            log warning econ "disabled"

            # Lock the parameter; if the economic model is disabled
            # at start, it can't be re-enabled.
            parmdb lock econ.disable
        }

    }

    # tock
    #
    # Updates the CGE at each econ tock.  Returns 1 if the CGE
    # converged, and 0 otherwise.

    typemethod tock {} {
        log normal econ "tock"

        if {![parmdb get econ.disable]} {
            $type analyze

            log normal econ "tock complete"
        } else {
            log warning econ "disabled"
            return 1
        }

        if {$info(econStatus) ne "ok"} {
            return 0
        }

        return 1
    }

    #-------------------------------------------------------------------
    # Analysis


    # analyze
    #
    # Solves the CGE to convergence.  If the -calibrate flag is given,
    # then the CGE is first calibrated; this is normally only done during
    # PREP, or during the transition from PREP to PAUSED at time 0.
    #
    # Returns 1 on success, and 0 otherwise.
    #

    typemethod analyze {{opt ""}} {
        log detail econ "analyze $opt"

        # FIRST, get labor and consumer security factors
        set LSF [$type ComputeLaborSecurityFactor]
        set CSF [$type ComputeConsumerSecurityFactor]

        # NEXT, SAM data
        array set samdata [$sam get]

        # NEXT, calibrate if requested.
        if {$opt eq "-calibrate"} {
            # FIRST, demographics
            array set demdata [demog getlocal]

            # NEXT, some globals. These only need to get set during
            # calibration
            cge set [list Global::REMChangeRate $samdata(REMChangeRate)]

            # NEXT some calibration tuning parameters
            cge set [list GDPExponent     [parm get econ.gdpExp]]
            cge set [list EmpExponent     [parm get econ.empExp]]
            cge set [list TurFrac         [parm get econ.turFrac]]
            cge set [list Flag.REMisTaxed \
                [::projectlib::boolean validate [parm get econ.REMisTaxed]]]

            # NEXT, the base unemployed
            let baseUnemp {$demdata(labor_force) * $samdata(BaseUR) / 100.0}

            # NEXT, demographic data
            cge set [list \
                         BaseConsumers $demdata(consumers)     \
                         BaseUnemp     $baseUnemp              \
                         Cal::BPp      $samdata(BP.pop)        \
                         BaseLF        $demdata(labor_force)   \
                         In::Consumers $demdata(consumers)     \
                         In::LF        $demdata(labor_force)   \
                         In::LSF       $LSF                    \
                         In::CSF       $CSF]



            # NEXT, subsistence wage, the poverty level
            cge set [list In::SubWage $samdata(BaseSubWage)]

            # NEXT, foreign aid to the region
            cge set [list In::FAR $samdata(BFAR)]

            # NEXT, foreign aid to actors
            cge set [list In::FAA $samdata(BFAA)]

            # NEXT, remittances
            cge set [list In::REM $samdata(BREM)]

            # NEXT, exports
            foreach i {goods black pop} {
                cge set [list In::EXPORTS.$i $samdata(BEXPORTS.$i)]
            }

            # NEXT, black market capacity
            cge set [list In::CAP.black  $samdata(BaseCAP.black)]

            # NEXT, number engaged in subsistence agriculture
            let subsisters {$demdata(population) - $demdata(consumers)}
            cge set [list BaseSubsisters $subsisters]
            cge set [list In::Subsisters $subsisters]

            # NEXT, actors expenditures. Multiplication by 52 because the
            # CGE has money flows in years.
            array set exp [cash allocations]

            let Xwa {$exp(world)  * 52.0}
            let Xra {$exp(region) * 52.0}
            let Xga {$exp(goods)  * 52.0}
            let Xba {$exp(black)  * 52.0}
            let Xpa {$exp(pop)    * 52.0}

            cge set [list \
                         In::X.world.actors  $Xwa \
                         In::X.region.actors $Xra \
                         In::X.goods.actors  $Xga \
                         In::X.black.actors  $Xba \
                         In::X.pop.actors    $Xpa]       

            # NEXT, actors revenue
            cge set [list \
                         In::X.actors.goods  $samdata(XT.actors.goods)  \
                         In::X.actors.black  $samdata(XT.actors.black)  \
                         In::X.actors.pop    $samdata(XT.actors.pop)    \
                         In::X.actors.region $samdata(XT.actors.region) \
                         In::X.actors.world  $samdata(XT.actors.world)]

            # NEXT, black market feedstocks
            cge set [list \
                        AF.world.black $samdata(AF.world.black) \
                        MF.world.black $samdata(MF.world.black) \
                        PF.world.black $samdata(PF.world.black)]

            # NOTE: if income from graft is ever allowed to change
            # over time, then In::graft should be computed and set
            # here

            # NEXT, calibrate the CGE.
            set status [cge solve]

            set info(econStatus) [lindex $status 0]

            if {$info(econStatus) ne "ok"} {
                set info(econPage) [lindex $status 1]
            } else {
                set info(econPage) {}
            }

            # NEXT, the data has changed.
            set info(changed) 1

            # NEXT, handle failures.
            if {$info(econStatus) ne "ok"} {
                log warning econ "Failed to calibrate: $info(econPage)"
                $type CgeError "CGE Calibration Error"
                return 0
            }

            # NEXT, Compute the initial CAP.goods.
            # NOTE: Should econ.idleFrac come from the CGE?
            array set out [cge get Out -bare]

            let CAPgoods {
                $out(BQS.goods) / (1.0-[parm get econ.idleFrac])
            }

            # NEXT, compute CCF.n, the capacity fraction for each neighborhood.
            set sum 0.0

            rdb eval {
                SELECT nbhoods.n    AS n,
                demog_n.labor_force AS labor_force, 
                econ_n.pcf          AS pcf
                FROM nbhoods
                JOIN demog_n USING (n)
                JOIN econ_n  USING (n)
                WHERE local = 1
            } {
                set pcfs($n) $pcf
                let cf($n) {$pcf * $labor_force}
                let sum    {$sum + $cf($n)}
            }

            foreach n [array names cf] {
                let cf($n) {$cf($n) / $sum}
                let cap0 {$CAPgoods * $cf($n)}
                let ccf {$cap0/$pcfs($n)}
                
                rdb eval {
                    UPDATE econ_n
                    SET ccf  = $ccf,
                    cap0 = $cap0,
                    cap  = $cap0
                    WHERE n = $n
                }
            }
        }

        # NEXT, Recompute In through Out

        # Set the input parameters
        array set demdata [demog getlocal]
        array set exp  [cash allocations]

        # NEXT, multiply expenditures by 52 since the CGE money flows are
        # in years, but actors expenses are weekly
        let Xwa {$exp(world)  * 52.0}
        let Xra {$exp(region) * 52.0}
        let Xga {$exp(goods)  * 52.0}
        let Xba {$exp(black)  * 52.0}
        let Xpa {$exp(pop)    * 52.0}

        set CAPgoods [rdb onecolumn {
            SELECT total(pcf*ccf)
            FROM econ_n
        }]

        let subsisters {$demdata(population) - $demdata(consumers)}

        # NEXT, compute an updated value for REM
        set REM [$type ComputeREM]

        cge set [list \
                     In::Consumers  $demdata(consumers)     \
                     In::Subsisters $subsisters             \
                     In::LF         $demdata(labor_force)   \
                     In::CAP.goods  $CAPgoods               \
                     In::CAP.black  $samdata(BaseCAP.black) \
                     In::LSF        $LSF                    \
                     In::CSF        $CSF                    \
                     In::REM        $REM]


        # NOTE: if income from graft is ever allowed to change
        # over time, then In::graft should be computed and set
        # here

        # NEXT, actors expenditures
        cge set [list \
                     In::X.world.actors  $Xwa \
                     In::X.region.actors $Xra \
                     In::X.goods.actors  $Xga \
                     In::X.black.actors  $Xba \
                     In::X.pop.actors    $Xpa]        



        # Solve the CGE.
        set status [cge solve In Out]
        set info(econStatus) [lindex $status 0]

        if {$info(econStatus) ne "ok"} {
            set info(econPage) [lindex $status 1]
        } else {
            set info(econPage) null
        }

        # The data has changed.
        set info(changed) 1

        # NEXT, handle failures
        if {$info(econStatus) ne "ok"} {
            log warning econ "Economic analysis failed"
            $type CgeError "CGE Solution Error"
            return 0
        }

        # NEXT, use sector revenues to determine actor
        # income sector by sector. NOTE: division by 52 since
        # CGE money flows are in years, but actors get incomes
        # based on a week.
        array set out [$cge get Out -bare]
        
        foreach {actor tg tb tp tw gr cut} [rdb eval {                   
                SELECT a, t_goods, t_black, t_pop,
                       t_world, graft_region, cut_black 
                FROM income_a
        }] {
            let inc_goods    {$out(REV.goods) * $tg  / 52.0}
            let inc_black_t  {$out(REV.black) * $tb  / 52.0}
            let inc_black_nr {$out(NR.black)  * $cut / 52.0}
            let inc_pop      {$out(REV.pop)   * $tp  / 52.0}
            let inc_region   {$out(FAR)       * $gr  / 52.0}
            let inc_world    {$out(REV.world) * $tw  / 52.0}

            # NEXT, protect against negative net revenue in the
            # black sector
            let inc_black_nr {max(0.0, $inc_black_nr)}

            let inc_total {
                $inc_goods + $inc_black_t + $inc_black_nr +
                $inc_pop   + $inc_region  + $inc_world
            }

            # NEXT, update the actor incomes
            rdb eval {
                UPDATE income_a
                SET income       = $inc_total,
                    inc_goods    = $inc_goods,
                    inc_black_t  = $inc_black_t,
                    inc_black_nr = $inc_black_nr,
                    inc_pop      = $inc_pop,
                    inc_region   = $inc_region,
                    inc_world    = $inc_world
                WHERE a = $actor
            }
        }

        # NEXT, actors sector revenues from potentially new income
        # rates, these will be used in the next time step
        rdb eval {
            SELECT total(inc_goods)    * 52.0 AS Xag,
                   total(inc_black_t + 
                         inc_black_nr) * 52.0 AS Xab,
                   total(inc_pop)      * 52.0 AS Xap,
                   total(inc_region)   * 52.0 AS Xar,
                   total(inc_world)    * 52.0 AS Xaw
            FROM income_a
        } {}

        # NEXT, the expenditures made by budget actors are accounted for as
        # revenue from the world since budget actors have no income
        set budgetXaw [rdb onecolumn {
            SELECT total(goods + black  + pop +
                         actor + region + world)
            FROM expenditures AS E
            JOIN actors AS A ON (E.a = A.a)
            WHERE A.atype = 'BUDGET'
        }]

        let Xaw {$Xaw + ($budgetXaw * 52.0)}

        cge set [list \
                    In::X.actors.goods  $Xag \
                    In::X.actors.black  $Xab \
                    In::X.actors.pop    $Xap \
                    In::X.actors.region $Xar \
                    In::X.actors.world  $Xaw] 

        log detail econ "analysis complete"
        
        return 1
    }

    # ComputeLaborSecurityFactor
    #
    # Computes the labor security factor given the security of
    # each local neighborhood group.

    typemethod ComputeLaborSecurityFactor {} {
        # FIRST, get the total number of workers
        set totalLabor [rdb onecolumn {
            SELECT labor_force FROM demog_local
        }]

        # NEXT, get the number of workers who are working given the
        # security levels.

        set numerator 0.0

        rdb eval {
            SELECT labor_force,
                   security
            FROM demog_g
            JOIN civgroups using (g)
            JOIN force_ng using (g)
            JOIN nbhoods using (n)
            WHERE force_ng.n = civgroups.n
            AND   nbhoods.local
        } {
            set security [qsecurity name $security]
            set factor [parmdb get econ.secFactor.labor.$security]
            let numerator {$numerator + $factor*$labor_force}
        }

        # NEXT, compute the LSF
        let LSF {$numerator/$totalLabor}

        return $LSF
    }

    # ComputeConsumerSecurityFactor
    #
    # Computes the consumer security factor given the security of
    # each local neighborhood group.

    typemethod ComputeConsumerSecurityFactor {} {
        # FIRST get the total number of consumers
        set totalCons [rdb onecolumn {
            SELECT consumers FROM demog_local
        }]

        # NEXT, get the number of consumers who are buying things
        # given the security levels.

        set numerator 0.0

        rdb eval {
            SELECT consumers, 
                   security
            FROM demog_g
            JOIN civgroups using (g)
            JOIN force_ng  using (g)
            JOIN nbhoods   using (n)
            WHERE force_ng.n = civgroups.n
            AND   nbhoods.local
        } {
            set security [qsecurity name $security]
            set factor   [parmdb get econ.secFactor.consumption.$security]
            let numerator {$numerator + $factor*$consumers}
        }

        # NEXT, compute the CSF
        let CSF {$numerator/$totalCons}

        return $CSF
    }


    # ComputeREM 
    #
    # Given the global remittance change rate in the CGE
    # compute a new value for remittances and return it.

    typemethod ComputeREM {} {
        array set cgeGlobals [$cge get Global -bare]
        array set cgeInputs  [$cge get In -bare]

        set changeRate $cgeGlobals(REMChangeRate)
        set currRem $cgeInputs(REM)

        # NEXT, no change rate or first tick
        # TBD: is this really necessary?
        if {$changeRate == 0.0 || [simclock delta] == 0} {
            return $currRem
        }

        # NEXT, return new REM, protect against going negative
        # and convert to a weekly fraction from an annual percentage.
        return [expr {
            max(0.0, $currRem + $currRem * ($changeRate/100.0/52.0))
        }]
    }

    # CgeError title
    #
    # This method pops up a dialog to inform the user that because the CGE
    # has failed to solve the econ model is disabled.

    typemethod CgeError {title} {
        append msg "Failure in the econ model caused it to be disabled."
        append msg "\nSee the detail browser for more information."

        parmdb set econ.disable 1
        parmdb lock econ.disable

        set answer [messagebox popup              \
                        -icon warning             \
                        -message $msg             \
                        -parent [app topwin]      \
                        -title  $title            \
                        -buttons {ok "Ok" browser "Go To Detail Browser"}]

       if {$answer eq "browser"} {
           app show my://app/econ
       }
    }


    #-------------------------------------------------------------------
    # Queries

    # Type Methods: Delegated
    #
    # Methods delegated to the <cge> component
    #
    # - get
    # - value

    delegate typemethod get   to cge
    delegate typemethod value to cge
    delegate typemethod eval  to cge

    # samcells
    #
    # Returns the names of all cells found in the SAM

    typemethod samcells {} {
        return [$sam cells]
    }

    # cgecells
    #
    # Returns the names of all the cells found in the CGE

    typemethod cgecells {} {
        return [$cge cells]
    }

    # dump
    #
    # Dumps the cell values and formulas for one or all pages.  If 
    # no _page_ is specified, only the *out* page is included.

    typemethod dump {{page Out}} {
        set pages [linsert [cge pages] 0 all]

        if {$page ni $pages} {
            set pages [join $pages ", "]
            return -code error -errorcode invalid \
                "Invalid page name \"$page\", should be one of: $pages"
        }

        cge dump $page
    }

    # sam
    #
    # Returns either a copy of the SAM or the SAM read in during 
    # initialization. The GUI uses a copy of the SAM for it's
    # purposes.

    typemethod sam {{copy {0}}} {
        # FIRST, create the SAM
        if {$copy} {
            set samcopy [cellmodel samcopy \
                         -epsilon 0.000001 \
                         -maxiters 1       \
                         -tracecmd [mytypemethod TraceSAM]]

            samcopy load \
                [readfile \
                    [file join $::app_sim_shared::library sam6x6.cm]]

            return $samcopy
        }

        return $sam
    }

    # cge
    #
    # Returns the cellmodel object for the CGE, for use by 
    # browsers.

    typemethod cge {} {
        return $cge
    }

    # getstart
    #
    # Returns a dictionary of the starting values for the CGE cells.

    typemethod getstart {} {
        return $startdict
    }

    #-------------------------------------------------------------------
    # Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate update parmdict
    #
    # parmdict     A dictionary of order parms
    #
    #    n                Neighborhood ID
    #    pcf              Production capacity factor for n
    #
    # Updates neighborhood economic inputs given the parms, which are 
    # presumed to be valid.

    typemethod {mutate update} {parmdict} {
        # FIRST, use the dict
        dict with parmdict {
            # FIRST, get the undo information
            set data [rdb grab econ_n {n=$n}]

            # NEXT, Update the group
            rdb eval {
                UPDATE econ_n
                SET pcf = nonempty($pcf, pcf)
                WHERE n=$n;

                UPDATE econ_n
                SET cap = pcf*cap0
                WHERE n=$n;
            } {}

            # NEXT, Return the undo command
            return [list rdb ungrab $data]
        }
    }

    # mutate samcell parmdict
    #
    # parmdict   A dictionary of order parms
    #
    #   id       Cell ID in cellmodel(n) format (ie. BX.actors.actors)
    #   val      The new value for the cellmodel to assume at that cell ID
    #
    # Updates the SAM cell model given the parms, which are presumed to be 
    # valid

    typemethod {mutate samcell} {parmdict} {
        dict with parmdict {
            # FIRST, get the old value, this is for undo
            set oldval [dict get [sam get] $id]

            # NEXT, update the cell model, solve it and notify that the 
            # cell has been updated
            sam set [list $id $val]
            sam solve
            notifier send ::econ <SamUpdate> $id $val

            # NEXT, return the undo command
            return [list econ mutate samcell [list id $id val $oldval]]
        }
    }

    # mutate cgecell parmdict
    #
    # parmdict   A dictionary of order parms
    #
    #   id       Cell ID in cellmodel(n) format (ie. BX.actors.actors)
    #   val      The new value for the cellmodel to assume at that cell ID
    #
    # Updates the CGE cell model given the parms, which are presumed to be 
    # valid

    typemethod {mutate cgecell} {parmdict} {
        dict with parmdict {
            # FIRST, get the old value, this is for undo
            set oldval [dict get [cge get] $id]

            # NEXT, update the cell model, solve it and notify that the 
            # cell has been updated
            cge set [list $id $val]
            cge solve In Out

            notifier send ::econ <CgeUpdate>

            # NEXT, return the undo command
            return [list econ mutate cgecell [list id $id val $oldval]]
        }
    }

    # mutate rebase
    #
    # This method takes the current state of the economy as it is
    # in the "Capacity Constrained" case (aka 'M' page) and sets
    # the appropriate cells in the SAM so that it can be used to
    # initialize the economy back to the state it was in.

    typemethod {mutate rebase} {} {
        # FIRST, get the data from the CGE
        set sectors [cge index i]
        array set cgedata [cge get]

        # NEXT, the base values
        foreach i $sectors {
            foreach j $sectors {
                sam set [list BX.$i.$j $cgedata(M::X.$i.$j)]
            }
        }

        # NEXT, adjust X.pop.world by the T-matrix value
        set Tpw $cgedata(In::REM)

        let Xpw {$cgedata(M::X.pop.world) - $Tpw}
        sam set [list BX.pop.world $Xpw]

        # NEXT, adjust X.world.black by the T-matrix value
        let Twb {
            $cgedata(PF.world.black) * $cgedata(AF.world.black) * \
            $cgedata(M::QD.black)
        }

        let Xwb {$cgedata(M::X.world.black) - $Twb}

        sam set [list BX.world.black $Xwb]

        # NEXT, base prices (only P.pop may have changed)
        foreach i {goods black pop} {
            sam set [list BP.$i $cgedata(M::P.$i)]
        }

        # Note: No need to do BQD's, they'll get recomputed in the SAM

        # NEXT, base unemployment rate
        sam set [list BaseUR $cgedata(M::UR)]

        # NEXT, demographic data
        array set demdata [demog getlocal]

        sam set [list BaseConsumers $demdata(consumers)]
        let subsisters {$demdata(population) - $demdata(consumers)}
        sam set [list BaseSubsisters $subsisters]

        # NEXT, the change rate of remittances may have changed
        sam set [list REMChangeRate $cgedata(Global::REMChangeRate)] 
    }

    #-------------------------------------------------------------------
    # saveable(i) interface

    # checkpoint
    #
    # Returns a checkpoint of the non-RDB simulation data.  If 
    # -saved is specified, the data is marked unchanged.
    #

    typemethod checkpoint {{option ""}} {
        if {$option eq "-saved"} {
            set info(changed) 0
        }

        return [list sam [sam get] cge [cge get] startdict $startdict]
    }

    # restore
    #
    # Restores the non-RDB state of the module to that contained
    # in the _checkpoint_.  If -saved is specified, the data is marked
    # unchanged.
    #
    # Syntax:
    #   restore _checkpoint_ ?-saved?
    #
    #   checkpoint - A string returned by the checkpoint typemethod
    
    typemethod restore {checkpoint {option ""}} {
        # FIRST, restore the checkpoint data
        sam set [dict get $checkpoint sam]
        cge set [dict get $checkpoint cge]

        # NEXT, solve the SAM we need to have all computed values
        # updated
        sam solve

        set startdict [dict get $checkpoint startdict]

        if {$option eq "-saved"} {
            set info(changed) 0
        }
    }

    # changed
    #
    # Returns 1 if saveable(i) data has changed, and 0 otherwise.
    #
    # Syntax:
    #   changed

    typemethod changed {} {
        return $info(changed)
    }

    # Within num val eps
    #
    # num  - some number
    # val  - some value to compare num to
    # eps  - an epsilon to use to see if num is close to val
    #
    # Helper proc that checks to see if a number is within an epsilon of
    # a value. Returns 1 if it is, otherwise 0

    proc Within {num val eps} {
        let diff {abs($num-$val)}
        return [expr {$diff < $eps}]
    }
}

#-------------------------------------------------------------------
# Orders: ECON:*

# ECON:UPDATE
#
# Updates existing neighborhood economic inputs

order define ECON:UPDATE {
    title "Update Neighborhood Economic Inputs"
    options -sendstates {PREP PAUSED TACTIC}

    form {
        rcc "Neighborhood:" -for n
        key n -table gui_econ_n -keys n \
            -loadcmd {orderdialog keyload n *}

        rcc "Proc. Capacity Factor" -for pcf
        text pcf
    }
} {
    # FIRST, prepare the parameters
    prepare n   -toupper  -required -type nbhood
    prepare pcf -toupper  -num      -type rnonneg

    returnOnError

    # During PREP, the pcf is limited to the range 0.1 to 1.0.
    if {[order state] eq "PREP"} {
        validate pcf {
            rpcf0 validate $parms(pcf)
        }
    }

    returnOnError -final

    # NEXT, modify the record
    setundo [econ mutate update [array get parms]]
}

# ECON:UPDATE:MULTI
#
# Updates economic inputs for multiple existing neighborhoods


order define ECON:UPDATE:MULTI {
    title "Update Economic Inputs for Multiple Neighborhoods"
    options -sendstates {PREP PAUSED}

    form {
        rcc "IDs:" -for ids
        multi ids -table gui_econ_n -key n \
            -loadcmd {orderdialog multiload ids *}

        rcc "Proc. Capacity Factor" -for pcf
        text pcf
    }
} {
    # FIRST, prepare the parameters
    prepare ids -toupper  -required -listof nbhood
    prepare pcf -toupper  -num      -type   rnonneg 

    returnOnError

    # During PREP, the pcf is limited to the range 0.1 to 1.0.
    if {[order state] eq "PREP"} {
        validate pcf {
            rpcf0 validate $parms(pcf)
        }
    }

    returnOnError -final

    # NEXT, modify the records
    set undo [list]

    foreach parms(n) $parms(ids) {
        lappend undo [econ mutate update [array get parms]]
    }

    setundo [join $undo \n]
}

# ECON:SAM:UPDATE 
#
# Updates a single cell in the Social Accounting Matrix (SAM)

order define ECON:SAM:UPDATE {
    title "Update SAM Cell Value"
    options -sendstates {PREP} 

    form {
        rcc "Cell ID:" -for id
        text id

        rcc "Value:" -for val
        text val
    }
} {
    prepare id           -required -type {ptype sam}
    prepare val -toupper -required -type money

    returnOnError -final

    setundo [econ mutate samcell [array get parms]]
}

# ECON:SAM:GLOBAL
#
# Updates a cell but with less restrictive validation

order define ECON:SAM:GLOBAL {
    title "Update SAM Global Value"
    options -sendstates {PREP}

    form {
        rcc "Cell ID:" -for id
        text id

        rcc "Value:" -for val
        text val
    }
} {
    prepare id -required -type {ptype sam}
    prepare val -toupper -type snit::double

    returnOnError -final

    setundo [econ mutate samcell [array get parms]]
}
 
# ECON:CGE:UPDATE 
#
# Updates a single cell in the CGE

order define ECON:CGE:UPDATE {
    title "Update CGE Cell Value"
    options -sendstates {PAUSED TACTIC}

    form {
        rcc "Cell ID:" -for id
        text id

        rcc "Value:" -for val
        text val
    }
} {
    prepare id           -required -type {ptype cge}
    prepare val -toupper -required -type money

    returnOnError -final

    setundo [econ mutate cgecell [array get parms]]
}

# ECON:UPDATE:REMRATE
#
# Updates the change rate for remittances

order define ECON:UPDATE:REMRATE {
    title "Update Remittance Change Rate"
    options -sendstates {PAUSED TACTIC}

    form {
        rcc "Value:" -for val
        text val
        label "%"
    }
} {
    prepare val -toupper -required -type snit::double

    returnOnError -final

    set parms(id) "Global::REMChangeRate"

    setundo [econ mutate cgecell [array get parms]]
}

