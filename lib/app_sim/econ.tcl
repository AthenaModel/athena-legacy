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

snit::type econ {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Group: Type Components

    # Type Component: cge
    #
    # This is the cellmodel(n) instance containing the CGE model.

    typecomponent cge

    #-------------------------------------------------------------------
    # Group: Non-Checkpointed Type Variables

    # Type Variable: info
    #
    # Miscellaneous non-checkpointed scalar values.
    #
    # changed - 1 if there is unsaved data, and 0 otherwise.

    typevariable info -array {
        changed 0
    }

    #-------------------------------------------------------------------
    # Group: Checkpointed Type Variables

    # Type Variable: startdict
    #
    # Dictionary of initial CGE cell values, as of "econ start".

    typevariable startdict {}

    #-------------------------------------------------------------------
    # Group: Initialization

    # Type Method: init
    #
    # Initializes the module before the simulation first starts to run.

    typemethod init {} {
        log normal econ "init"

        # FIRST, create the CGE.
        set cge [cellmodel cge \
                     -epsilon  0.000001 \
                     -maxiters 1000     \
                     -tracecmd [mytypemethod TraceCGE]]
        cge load [readfile [file join $::app_sim::library eco3x3.cm]]
        
        require {[cge sane]} "The econ model's CGE (eco3x3.cm) is not sane."

        # NEXT, register this type as a saveable
        scenario register ::econ

        # NEXT, Econ is up.
        log normal econ "init complete"
    }

    # Type Method: TraceCGE
    #
    # The cellmodel(n) -tracecmd for the <cge> component.  It simply
    # logs its arguments.

    typemethod TraceCGE {args} {
        if {[lindex $args 0] eq "converge"} {
            log detail econ "solve trace: $args"
        } else {
            log debug econ "solve trace: $args"
        }
    }

    #-------------------------------------------------------------------
    # Group: Assessment Routines

    # Type Method: start
    #
    # Calibrates the CGE.  This is done when the simulation leaves
    # the PREP state and enters time 0.

    typemethod start {} {
        log normal econ "start"

        $type analyze -calibrate
        
        set startdict [$cge get]

        log normal econ "start complete"
    }

    # Type Method: tock
    #
    # Updates the CGE at each econ tock.  Returns 1 if the CGE
    # converged, and 0 otherwise.

    typemethod tock {} {
        log normal econ "tock"

        set result [$type analyze]

        log normal econ "tock complete"

        return $result
    }

    #-------------------------------------------------------------------
    # Group: Analysis


    # Type Method: analyze
    #
    # Solves the CGE to convergence.  If the -calibrate flag is given,
    # then the CGE is first calibrated; this is normally only done during
    # PREP, or during the transition from PREP to PAUSED at time 0.
    #
    # Returns 1 on success, and 0 otherwise.
    #
    # Syntax:
    #   analyze ?-calibrate?

    typemethod analyze {{opt ""}} {
        log detail econ "analyze $opt"

        # FIRST, get labor security factor
        set LSF [$type ComputeLaborSecurityFactor]

        # NEXT, calibrate if requested.
        if {$opt eq "-calibrate"} {
            # FIRST, set the input parameters
            cge reset

            array set data [demog getlocal]

            cge set [list \
                         BP.pop        [parmdb get econ.BaseWage]         \
                         A.goods.pop   [parmdb get econ.GBasketPerCapita] \
                         f.goods.goods [parmdb get econ.f.goods.goods]    \
                         f.pop.goods   [parmdb get econ.f.pop.goods]      \
                         f.goods.pop   [parmdb get econ.f.goods.pop]      \
                         f.pop.pop     [parmdb get econ.f.pop.pop]        \
                         f.goods.else  [parmdb get econ.f.goods.else]     \
                         f.pop.else    [parmdb get econ.f.pop.else]       \
                         BaseConsumers $data(consumers)                   \
                         In::Consumers $data(consumers)                   \
                         In::WF        $data(labor_force)                 \
                         In::LSF       $LSF]

            # NEXT, calibrate the CGE.
            set result [cge solve]

            # NEXT, the data has changed.
            set info(changed) 1

            # NEXT, handle failures.
            if {$result ne "ok"} {
                log warning econ "Failed to calibrate"
                error "Failed to calibrate economic model."
            }

            # NEXT, Compute the initial CAP.goods.
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

        # NEXT, Recompute In through Out given the initial
        # goods capacity.

        # Set the input parameters
        array set data [demog getlocal]

        set CAPgoods [rdb onecolumn {
            SELECT total(pcf*ccf)
            FROM econ_n
        }]

        cge set [list \
                     In::Consumers $data(consumers)   \
                     In::WF        $data(labor_force) \
                     In::CAP.goods $CAPgoods          \
                     In::LSF       $LSF]

        # Update the CGE.
        set result [cge solve In Out]

        # The data has changed.
        set info(changed) 1

        # NEXT, handle failures
        if {$result ne "ok"} {
            log warning econ "Economic analysis failed"

            return 0
        }

        log detail econ "analysis complete"
        return 1
    }

    # Type Method: ComputeLaborSecurityFactor
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
            FROM demog_ng
            JOIN force_ng using (n,g)
            JOIN nbhoods using (n)
            WHERE nbhoods.local
        } {
            set security [qsecurity name $security]
            set factor [parmdb get econ.secFactor.labor.$security]
            let numerator {$numerator + $factor*$labor_force}
        }

        # NEXT, compute the LSF
        let LSF {$numerator/$totalLabor}

        return $LSF
    }



    #-------------------------------------------------------------------
    # Group: Queries

    # Type Methods: Delegated
    #
    # Methods delegated to the <cge> component
    #
    # - get
    # - value

    delegate typemethod get   to cge
    delegate typemethod value to cge
    delegate typemethod eval  to cge

    # Type Method: dump
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

    # Type Method: cge
    #
    # Returns the cellmodel object for the CGE, for use by 
    # browsers.

    typemethod cge {} {
        return $cge
    }

    # Type Method: getstart
    #
    # Returns a dictionary of the starting values for the CGE cells.

    typemethod getstart {} {
        return $startdict
    }

    #-------------------------------------------------------------------
    # Group: Mutators
    #
    # Mutators are used to implement orders that change the scenario in
    # some way.  Mutators assume that their inputs are valid, and returns
    # a script of one or more commands that will undo the change.  When
    # change cannot be undone, the mutator returns the empty string.

    # mutate update parmdict
    #
    # parmdict     A dictionary of group parms
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
            rdb eval {
                SELECT * FROM econ_n
                WHERE n=$n
            } undoData {
                unset undoData(*)
            }

            # NEXT, Update the group
            rdb eval {
                UPDATE econ_n
                SET pcf = nonempty($pcf, pcf)
                WHERE n=$n;

                UPDATE econ_n
                SET cap = pcf*cap0
                WHERE n=$n;
            } {}

            # NEXT, notify the app.
            notifier send ::econ <Entity> update $n

            # NEXT, Return the undo command
            return [mytypemethod mutate update [array get undoData]]
        }
    }

    #-------------------------------------------------------------------
    # Group: saveable(i) interface

    # Type Method: checkpoint
    #
    # Returns a checkpoint of the non-RDB simulation data.  If 
    # -saved is specified, the data is marked unchanged.
    #
    # Syntax:
    #   checkpoint ?-saved?


    typemethod checkpoint {{option ""}} {
        if {$option eq "-saved"} {
            set info(changed) 0
        }

        return [list cge [cge get] startdict $startdict]
    }

    # Type Method: restore
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
        cge set [dict get $checkpoint cge]
        set startdict [dict get $checkpoint startdict]

        if {$option eq "-saved"} {
            set info(changed) 0
        }
    }

    # Type Method: changed
    #
    # Returns 1 if saveable(i) data has changed, and 0 otherwise.
    #
    # Syntax:
    #   changed

    typemethod changed {} {
        return $info(changed)
    }
}

#-------------------------------------------------------------------
# Orders: ECON:*

# ECON:UPDATE
#
# Updates existing neighborhood economic inputs


order define ::econ ECON:UPDATE {
    title "Update Neighborhood Economic Inputs"
    options -sendstates {PREP PAUSED} -table gui_econ_n -tags n

    parm n    key  "Neighborhood"           -tags nbhood
    parm pcf  text "Prod. Capacity Factor"
} {
    # FIRST, prepare the parameters
    prepare n   -toupper  -required -type nbhood
    prepare pcf -toupper            -type rnonneg

    returnOnError

    # During PREP, the pcf is limited to the range 0.1 to 1.0.
    if {[order state] eq "PREP"} {
        validate pcf {
            rpcf0 validate $parms(pcf)
        }
    }

    returnOnError -final

    # NEXT, modify the record
    setundo [$type mutate update [array get parms]]
}

# ECON:UPDATE:MULTI
#
# Updates economic inputs for multiple existing neighborhoods


order define ::econ ECON:UPDATE:MULTI {
    title "Update Economic Inputs for Multiple Neighborhoods"
    options -sendstates {PREP PAUSED} -table gui_econ_n

    parm ids  multi "IDs"
    parm pcf  text  "Prod. Capacity Factor"
} {
    # FIRST, prepare the parameters
    prepare ids -toupper  -required -listof nbhood
    prepare pcf -toupper            -type   rnonneg

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

    foreach n $parms(ids) {
        set parms(n) $n

        lappend undo [$type mutate update [array get parms]]
    }

    setundo [join $undo \n]
}
