#-----------------------------------------------------------------------
# FILE: econ.tcl
#
#   Athena Economics Model singleton
#   This is an experimental econ model for integrating the 6x6 cell
#   model. It will be THE econ model once it is stable and working
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
        econPage   null
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

        if {$cells(A.goods.pop) < 1.0} {
            dict append edict A.goods.pop \
                "Annual per capita demand for goods is less than 1 goods basket."
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
            $ht put "$cell ==> $errmsg"
        }

        return
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
                     -maxiters 1000     \
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

        $type InitializeCGE
    }

    # InitializeCGE
    #
    # Updates the shape cells of the CGE from the data in the SAM.

    typemethod InitializeCGE {} {
        # FIRST, get sectors from the SAM
        set sectors  [$sam index i]

        # NEXT, base prices from the SAM
        foreach i $sectors {
            cge set [list BP.$i [dict get [$sam get] BP.$i]]
        }

        # NEXT, base expenditures/revenues as a starting point for CGE X.i.j's
        foreach i $sectors {
            foreach j $sectors {
                cge set [list Cal::X.$i.$j [dict get [$sam get] BX.$i.$j]]
            }
        }

        # NEXT, base quantities demanded as a starting poing for CGE QD.i.j
        foreach i {goods black pop} {
            foreach j $sectors {
                cge set [list Cal::QD.$i.$j [dict get [$sam get] BQD.$i.$j]]
            }
        }

        # NEXT, shape parameters for the economy
        
        #-------------------------------------------------------------
        # The goods sector
        foreach i {goods black pop} {
            cge set [list f.$i.goods [dict get [$sam get] f.$i.goods]]
        }
       
        foreach i {actors region world} {
            cge set [list t.$i.goods [dict get [$sam get] t.$i.goods]]
        }

        cge set [list k.goods [dict get [$sam get] k.goods]]

        #-------------------------------------------------------------
        # The black sector
        foreach i {goods black pop} {
            cge set [list A.$i.black [dict get [$sam get] A.$i.black]]
        }

        foreach i {actors region world} {
            cge set [list t.$i.black [dict get [$sam get] t.$i.black]]
        }

        #-------------------------------------------------------------
        # The pop sector
        cge set [list k.pop   [dict get [$sam get] k.pop]]

        foreach i {goods black pop} {
            cge set [list f.$i.pop [dict get [$sam get] f.$i.pop]]
        }

        foreach i {actors region world} {
            cge set [list t.$i.pop [dict get [$sam get] t.$i.pop]]
        }

        #-------------------------------------------------------------
        # The actors and region sectors
        foreach i $sectors {
            cge set [list f.$i.actors [dict get [$sam get] f.$i.actors]]
            cge set [list f.$i.region [dict get [$sam get] f.$i.region]]
        }

        #-------------------------------------------------------------
        # The world sector
        cge set [list FAA [dict get [$sam get] FAA]]
        cge set [list FAR [dict get [$sam get] FAR]]

        #-------------------------------------------------------------
        # Base values for Exports
        foreach i {goods black pop} {
            cge set [list BEXPORTS.$i [dict get [$sam get] EXPORTS.$i]]
        }

        #-------------------------------------------------------------
        # A.goods.pop, the unconstrained base demand for goods in 
        # goods basket per year per capita.
        cge set [list A.goods.pop [dict get [$sam get] A.goods.pop]]
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

        $type InitializeCGE

        if {![parmdb get econ.disable]} {
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

        # FIRST, get labor security factor
        set LSF [$type ComputeLaborSecurityFactor]

        # NEXT, calibrate if requested.
        if {$opt eq "-calibrate"} {
            # FIRST, set the input parameters
            cge reset

            array set data [demog getlocal]

            $type InitializeCGE

            cge set [list \
                         BaseConsumers $data(consumers)        \
                         graft         [parmdb get econ.graft] \
                         In::Consumers $data(consumers)        \
                         In::LF        $data(labor_force)      \
                         In::LSF       $LSF]

            # NEXT, calibrate the CGE.
            set status [cge solve]

            set info(econStatus) [lindex $status 0]

            if {$info(econStatus) ne "ok"} {
                set info(econPage) [lindex $status 1]
            } else {
                set info(econPage) null
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
                     In::LF        $data(labor_force) \
                     In::CAP.goods $CAPgoods          \
                     In::LSF       $LSF]

        # Update the CGE.
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
                        -buttons {ok "Ok" db "Go To Detail Browser"}]

       if {$answer eq "db"} {
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
