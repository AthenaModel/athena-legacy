#------------------------------------------------------------------------
# TITLE:
#    iom_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Driver Assessment Model (DAM): Info Ops Message (IOM) rule sets.
#
#    ::iom_rules is a singleton object implemented as a snit::type.  To
#    initialize it, call "::iom_rules init".
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# iom_rules

snit::type iom_rules {
    # Make it an ensemble
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Public Typemethods

    # assess dict
    #
    # dict  - Dictionary of relevant BROADCAST tactic parameters:
    #
    #     tsource - The actor who executed the BROADCAST tactic
    #     cap     - The CAP by which the IOM was broadcast.
    #     asource - The attributed source (actor) of the message, or ""
    #               if none.
    #     iom     - The IOM being broadcast
    #
    # Calls the IOM rule set to assess the attitude effects of the 
    # broadcasted IOM's payloads.

    typemethod assess {dict} {
        log normal controlr "event IOM [list $dict]"

        array set data $dict

        # FIRST, if the rule set is inactive, do nothing.
        if {![dam isactive IOM]} {
            log warning controlr \
                "event IOM: ruleset has been deactivated"
            return
        }

        # NEXT, get the model parameters we need.
        set nomCapCov [parm get dam.IOM.nominalCAPcov]

        # NEXT, get the payload data for this IOM.
        set pdict [dict create]

        rdb eval {
            SELECT * FROM payloads
            WHERE iom_id = $data(iom) AND state='normal'
            ORDER BY payload_num
        } row {
            unset -nocomplain row(*)
            dict set pdict $row(payload_num) [array get row]
        }

        # NEXT, determine the covered groups, and the CAPcov for each.
        rdb eval {
            SELECT g      AS f,
                   capcov AS capcov
            FROM capcov
            WHERE k=$data(cap) AND capcov > 0.0
        } {
            # FIRST, scale the capcov given the nominal CAPcov.
            set data(f)      $f
            set data(capcov) $capcov
            let data(adjcov) {$capcov / $nomCapCov}

            # NEXT, compute the resonance of the IOM with group f.
            set data(resonance) \
                [ComputeResonance $data(iom) $data(f) $data(asource)]

            # NEXT, compute the regard of group f for the attributed 
            # source.
            set data(regard) [ComputeRegard $data(f) $data(asource)] 

            # NEXT, compute the acceptability, which is the product
            # of the resonance and the regard.
            let data(accept) {$data(resonance) * $data(regard)}

            # NEXT, call the rule set for this iom and civilian group.
            $type IOM $pdict [array get data]
        }
    }

    # ComputeResonance iom f asource
    #
    # iom     - An Info Ops Message ID
    # f       - A civilian group
    # asource - Attributed source: actor ID, or ""
    #
    # Compute the resonance of the IOM for the group.  The resonance
    # is the mam(n) congruence of the IOM's hook with the group, given
    # the entity commonality of the attributed source, as passed through
    # the Zresonance curve.
    
    proc ComputeResonance {iom f asource} {
        # FIRST, get the semantic hook
        set hook [hook getdict [iom get $iom hook_id]]

        # NEXT, get the entity commonality
        if {$asource eq ""} {
            set theta 1.0
        } else {
            set theta [bsystem entity cget $asource -commonality]
        }

        # NEXT, compute the congruence of the hook with the group's
        # belief system.
        set congruence [bsystem congruence $f $theta $hook]

        # NEXT, compute the resonance
        set Zresonance [parm get dam.IOM.Zresonance]

        return [zcurve eval $Zresonance $congruence]
    }

    # ComputeRegard f asource
    #
    # f       - A civilian group
    # asource - Attributed source: actor ID, or ""
    #
    # Computes the regard of the group for the source, based on the 
    # vertical relationship between the two.  If the source is anonymous, 
    # assume a regard of 1.0.
    
    proc ComputeRegard {f asource} {
        if {$asource eq ""} {
            return 1.0
        } else {
            return [rmf frmore [vrel.ga $f $asource]]
        }
    }

    #-------------------------------------------------------------------
    # Rule Set: IOM: Effects of IOM payloads
    #
    # Event.  This rule set determines the effect of an IOM on
    # a particular civilian group.

    # IOM pdict dict
    #
    # pdict - Dictionary of payload data
    #
    # dicti - Dictionary of input parameters:
    #
    #     tsource     - The actor who executed the BROADCAST tactic
    #     cap         - The CAP by which the IOM was broadcast.
    #     asource     - The attributed source (actor) of the message, 
    #                   or "" if none.
    #     iom         - The IOM being broadcast
    #     f           - The civilian group
    #     capcov      - The CAP's coverage of group f
    #     adjcov      - The adjust coverage (divided by nominal coverage)
    #     resonance   - The resonance of the semantic hook with f
    #     regard      - The regard of group f for the asource
    #     accept      - The acceptability of the IOM to f
    #
    # Assesses the effect of the IOM on a particular civilian group f.

    typemethod IOM {pdict dict} {
        # FIRST, retrieve the payload
        array set data $dict
       
        # NEXT, begin the rule
        set dsig [list $data(tsource) $data(iom)]
        dam ruleset IOM [driver create IOM "Info Ops Message" $dsig] \
            -s 0.0

        # NEXT, put down the general details
        AddIomDetails data $pdict

        # NEXT, get the final factor.
        set factor [expr {$data(adjcov)*$data(accept)}]

        # IOM-1-1
        #
        # Actor tsource has sent an IOM with a factor that affects
        # CIV group g.
        dam rule IOM-1-1 {
            $factor > 0.01
        } {
            dict for {num prec} $pdict {
                dict with prec {
                    set fmag [expr {$factor * $mag }]
                    switch -exact -- $payload_type {
                        COOP { dam coop T $data(f) $g $fmag }
                        HREL { dam hrel T $data(f) $g $fmag }
                        SAT  { dam sat  T $data(f) $c $fmag }
                        VREL { dam vrel T $data(f) $a $fmag }
                        default {
                            error "Unexpected payload type: \"$payload_type\""
                        }
                    }
                }
            }
        }
    }

    #------------------------------------------------------------------
    # Helper Routines

    # AddIomDetails dataVar pdict
    #
    # dataVar   - Name of array containing IOM data
    # pdict     - Dictionary: payload_num => payload record
    #
    # Adds details to the rule firing report for this IOM and its 
    # payloads.

    proc AddIomDetails {dataVar pdict} {
        upvar 1 $dataVar data

        if {$data(asource) eq ""} {
            set data(asource) "none"
        }
   
        dam detailwrap "IOM $data(iom):" [iom get $data(iom) narrative]

        dict for {num prec} $pdict {
            dam detailwrap "  Payload $num:" [dict get $prec narrative] 
        }
        dam details "\n"
    
        dam detail "Affected Group:"  $data(f)
        dam detail "In Neighborhood:" [civgroup getg $data(f) n]
        dam detail "True Source:"     $data(tsource)
        dam detail "CAP in use:"      $data(cap)
        dam detail "Attr. Source:"    $data(asource)
        dam detail "CAP Coverage:" \
            [format "%.2f (scaled to %.2f)" $data(capcov) $data(adjcov)]
        dam detail "Acceptability:" \
            "[format %.2f $data(accept)] = Resonance * Regard"
        dam detail "  Resonance:"     [format %.2f $data(resonance)]
        dam detail "  Regard:"        [format %.2f $data(regard)]
    }
}


