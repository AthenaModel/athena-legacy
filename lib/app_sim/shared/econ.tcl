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
        set edict [$type DoSanityCheck]

        if {[dict size $edict] == 0} {
            return OK
        }

        if {$ht ne ""} {
            $type DoSanityReport $ht $edict
        }

        return WARNING
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

        # FIRST, per capita demand for goods must be reasonable
        if {$cells(A.goods.pop) < 1.0} {
            dict append edict A.goods.pop \
                "Annual per capita demand for goods is less than 1 goods basket."
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

        # NEXT, Cobb-Douglas coefficients in the actors sector must add up to
        # 1.0 within a reasonable epsilon
        let f_actors {
            $cells(f.goods.actors) + $cells(f.black.actors) +
            $cells(f.pop.actors)   + $cells(f.region.actors) +
            $cells(f.world.actors)
        }

        if {![Within $f_actors 1.0 0.001]} {
            dict append edict f.actors \
                "The Cobb-Douglas coefficients in the actors sector do not sum to 1.0"
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
        $ht subtitle "Econ Model Errors"

        $ht putln "Certain cells in the SAM have errors. This is likely "
        $ht putln "due to incorrect data being entered in the SAM. Details "
        $ht putln "are below."

        $ht para

        dict for {cell errmsg} $edict {
            $ht put "$cell ==> $errmsg\n"
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
                     -maxiters 10000    \
                     -failcmd  [mytypemethod CGEFailure] \
                     -tracecmd [mytypemethod TraceCGE]]
        cge load [readfile [file join $::app_sim_shared::library eco6x6.cm]]
        
        require {[cge sane]} "The econ model's CGE (eco6x6.cm) is not sane."

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
            }

            $ht para

            $ht putln "Because of this the econ model has been disabled "
            $ht put   "automatically. "

            $ht para

            $ht put   "A file called cgedebug.txt that contains the set "
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
        set filename [workdir join .. cgedebug.txt]
        set f [open $filename w]

        # NEXT, dump the CGE initial state
        puts $f [$cge initial]
        close $f
    }

    # reset
    #
    # Resets the econ model to the initial state for both the SAM
    # and the CGE

    typemethod reset {} {
        $sam reset
        set result [sam solve]

        if {$result ne "ok"} {
            log warning econ "Failed to reset SAM"
            error "Failed to reset SAM model"
        }

        $cge reset
    }

    # InitializeActorIncomeTables
    #
    # This method sets up the tables used to track total income as the sum of
    # all income sources and sector by sector tax and tax like rates.

    typemethod InitializeActorIncomeTables {} {
        # FIRST, the total income by actor. A sum of all income sources.
        rdb eval {
            SELECT a FROM actors
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
        # is received.
        rdb eval {
            SELECT total(income_goods)     AS ig,
                   total(income_pop)       AS ip,
                   total(income_black_tax) AS ibt,
                   total(income_world)     AS iw,
                   total(income_graft)     AS igr
            FROM actors_view 
        } {
            let Xag {$ig  * $scaled}
            let Xap {$ip  * $scaled}
            let Xab {$ibt * $scaled}
            let Xaw {$iw  * $scaled}
            let Xar {$igr * $scaled}
        }

        set BNRb $sdata(BNR.black)

        # NEXT, revenue is the sum of all the sources of money
        let BREVa {$Xag + $Xap + $Xab + $Xaw + $Xar + $BNRb}

        # NEXT, given the revenue in the actor sector compute the
        # base expenditures using the computed overhead fractions
        set ovShares 0.0
        foreach sector {goods pop black region world} {
            let ovShares {
                $ovShares + [parmdb get econ.shares.overhead.$sector]
            }
        }
        
        foreach sector {goods pop black region world} {
            let ovFrac($sector) {
                [parmdb get econ.shares.overhead.$sector] / $ovShares
            }
        }

        let Xga {$ovFrac(goods)  * $BREVa}
        let Xpa {$ovFrac(pop)    * $BREVa}
        let Xba {$ovFrac(black)  * $BREVa}
        let Xra {$ovFrac(region) * $BREVa}
        let Xwa {$ovFrac(world)  * $BREVa}

        # NEXT, extract the pertinent data from the SAM 
        set BPg   $sdata(BP.goods)
        set BQDg  $sdata(BQD.goods)
        set BPb   $sdata(BP.black)
        set BQDb  $sdata(BQD.black)
        set BPp   $sdata(BP.pop)
        set BQDp  $sdata(BQD.pop)
        set BREVw $sdata(BREV.world)
        set FAR   $sdata(FAR)

        # NEXT, the total number of black market net revenue shares owned
        # by actors. If this is zero, then no actor is getting any income
        # from the black market net revenues
        set totalBNRShares \
            [rdb onecolumn {SELECT total(shares_black_nr) FROM actors_view;}]

        # NEXT, if no actor is getting income from black market net revenue,
        # then ALL of the net revenue goes into the world sector.
        set Xwb $sdata(BX.world.black)

        if {$totalBNRShares == 0} {
            let Xwb {$Xwb + $BNRb}
        }

        # NEXT compute the rates based on the base case data and
        # fill in the income_a table rates and set each actors
        # initial income
        rdb eval {
            SELECT * FROM actors
        } data {
            let t_goods      {$data(income_goods)     / ($BPg * $BQDg)}
            let t_pop        {$data(income_pop)       / ($BPp * $BQDp)}
            let t_world      {$data(income_world)     / $BREVw}
            let graft_region {$data(income_graft)     / $FAR}

            # NEXT, the black market may not have any product
            if {$BQDb > 0.0} {
                let t_black {$data(income_black_tax) / ($BPb * $BQDb)}
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
            # revenue)
            let income_tot_black {
                $data(income_black_tax) + ($cut_black * $BNRb)
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

        # NEXT, set the flow of money from the black market to the
        # world. It may have changed if no actor is getting a cut.
        $sam set [list BX.world.black   $Xwb]

        # NEXT, compute the composte graft fraction
        set graft_frac \
            [rdb onecolumn {SELECT total(graft_region) FROM income_a;}]

        $sam set [list graft $graft_frac]

        set result [$sam solve]
        # NEXT, handle failures.
        if {$result ne "ok"} {
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
                cge set [list BX.$i.$j $samdata(BX.$i.$j)]
            }
        }

        # NEXT, base quantities demanded as a starting point for 
        # CGE BQD.i.j's
        foreach i {goods black pop} {
            foreach j $sectors {
                cge set [list BQD.$i.$j $samdata(BQD.$i.$j)]
            }
        }

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
        cge set [list FAA $samdata(FAA)]
        cge set [list FAR $samdata(FAR)]

        #-------------------------------------------------------------
        # Base values for Exports
        foreach i {goods black pop} {
            cge set [list BEXPORTS.$i $samdata(EXPORTS.$i)]
        }

        #-------------------------------------------------------------
        # A.goods.pop, the unconstrained base demand for goods in 
        # goods basket per year per capita.
        cge set [list A.goods.pop $samdata(A.goods.pop)]

        #-------------------------------------------------------------
        # graft, the percentage skimmed off FAR by all actors
        $cge set [list Bgraft $samdata(graft)]
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

        # NEXT, calibrate if requested.
        if {$opt eq "-calibrate"} {
            # FIRST, demographics
            array set data [demog getlocal]
            cge set [list \
                         BaseConsumers $data(consumers)        \
                         In::Consumers $data(consumers)        \
                         In::LF        $data(labor_force)      \
                         In::LSF       $LSF                    \
                         In::CSF       $CSF]

            # NEXT, actors expenditures
            array set cash [cash expenditures]
            cge set [list \
                         In::X.world.actors  $cash(world)      \
                         In::X.region.actors $cash(region)     \
                         In::X.goods.actors  $cash(goods)      \
                         In::X.black.actors  $cash(black)      \
                         In::X.pop.actors    $cash(pop)]        

            # NEXT, actors revenue
            set Xag [dict get [$sam get] BX.actors.goods]
            set Xab [dict get [$sam get] BX.actors.black]
            set Xap [dict get [$sam get] BX.actors.pop]
            set Xar [dict get [$sam get] BX.actors.region]
            set Xaw [dict get [$sam get] BX.actors.world]

            cge set [list \
                         In::X.actors.goods  $Xag \
                         In::X.actors.black  $Xab \
                         In::X.actors.pop    $Xap \
                         In::X.actors.region $Xar \
                         In::X.actors.world  $Xaw]

            # NEXT, black market feedstocks
            set AFwb [dict get [$sam get] AF.world.black]
            set MFwb [dict get [$sam get] MF.world.black]
            set PFwb [dict get [$sam get] PF.world.black]

            cge set [list \
                        AF.world.black $AFwb \
                        MF.world.black $MFwb \
                        PF.world.black $PFwb]

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
        array set data [demog getlocal]
        array set cash [cash expenditures]

        set CAPgoods [rdb onecolumn {
            SELECT total(pcf*ccf)
            FROM econ_n
        }]

        cge set [list \
                     In::Consumers $data(consumers)    \
                     In::LF        $data(labor_force)  \
                     In::CAP.goods $CAPgoods           \
                     In::LSF       $LSF                \
                     In::CSF       $CSF]

        cge set [list \
                     In::X.world.actors  $cash(world)      \
                     In::X.region.actors $cash(region)     \
                     In::X.goods.actors  $cash(goods)      \
                     In::X.black.actors  $cash(black)      \
                     In::X.pop.actors    $cash(pop)]        

        # NOTE: if income from graft is ever allowed to change
        # over time, then In::graft should be computed and set
        # here

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
        # income
        array set out [$cge get Out -bare]
        
        rdb eval {
            SELECT a            AS actor, 
                   t_goods      AS tg,
                   t_black      AS tb,
                   t_pop        AS tp,
                   t_world      AS tw,
                   graft_region AS gr,
                   cut_black    AS cut
           FROM income_a
        } {
            let total_a {($out(REV.goods) * $tg)  + 
                         ($out(REV.black) * $tb)  +
                         ($out(NR.black)  * $cut) +
                         ($out(REV.pop)   * $tp)  +
                         ($out(REV.world) * $tw)  +
                         ($out(FAR)       * $gr)}

            rdb eval {
                UPDATE income_a
                SET income = $total_a
                WHERE a = $actor
            }
        }

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

    # mutate cell parmdict
    #
    # parmdict   A dictionary of order parms
    #
    #   id       Cell ID in cellmodel(n) format (ie. BX.actors.actors)
    #   val      The new value for the cellmodel to assume at that cell ID
    #
    # Updates the cell model given the parms, which are presumed to be valid

    typemethod {mutate cell} {parmdict} {
        dict with parmdict {
            # FIRST, get the old value, this is for undo
            set oldval [dict get [sam get] $id]

            # NEXT, update the cell model, solve it and notify that the 
            # cell has been updated
            sam set [list $id $val]
            sam solve
            notifier send ::econ <CellUpdate> $id $val

            # NEXT, return the undo command
            return [list econ mutate cell [list id $id val $oldval]]
        }
    }

    typemethod Trace {sub evt args objs} {
        puts "Trace: $sub $evt $args $objs"
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

    setundo [econ mutate cell [array get parms]]
}
