#-----------------------------------------------------------------------
# TITLE:
#   ensit_rules.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Athena Driver Assessment Model (DAM): Environmental Situations
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# driver::ensit: Family ensemble

snit::type driver::ensit {
    # Make it an ensemble
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Public Typemethods

    # assess
    #
    # Assesses the existing ensits by running their rule sets.
    
    typemethod assess {} {
        rdb eval {
            SELECT * FROM ensits ORDER BY s
        } sit {
            set dtype $sit(stype)

            if {![dam isactive $dtype]} {
                log warning $dtype \
                    "driver type has been deactivated"
                return
            }

            if {[demog getn $sit(n) population] == 0} {
                log normal $dtype \
                    "skipping, nbhood $sit(n) is empty."
                return
            }

            # Set up the rule set firing dictionary
            set fdict [dict create]
            dict set fdict dtype     $dtype
            dict set fdict s         $sit(s)
            dict set fdict state     $sit(state)
            dict set fdict n         $sit(n)
            dict set fdict inception $sit(inception)
            dict set fdict coverage  $sit(coverage)
            dict set fdict resolver  $sit(resolver)

            bgcatch {
                log detail $dtype $fdict
                driver::$dtype ruleset $fdict
            }
        }
    }

    #-------------------------------------------------------------------
    # Situation definition

    # define name defscript
    #
    # name        - The situation driver type name
    # defscript   - The definition script
    #
    # Defines a single situation driver type.  All required public
    # subcommands are defined automatically.  The driver type must
    # define the "ruleset" subcommand containing the actual rule set.
    #
    # Note that rule sets can make use of procs defined in the
    # driver::ensit namespace.

    typemethod define {name defscript} {
        # FIRST, define the shared definitions
        set footer "
            delegate typemethod sigline   using {driver::ensit %m $name}
            delegate typemethod narrative using {driver::ensit %m}
            delegate typemethod detail    using {driver::ensit %m}

            typeconstructor {
                namespace path ::driver::ensit::
            }
        "

        driver type define $name {state n} "$defscript\n$footer" 
    }

    #-------------------------------------------------------------------
    # Narrative Type Methods

    # sigline dtype signature
    #
    # dtype     - The driver type
    # signature - The driver signature, {state n}
    #
    # Returns a one-line description of the driver given its signature
    # values.

    typemethod sigline {dtype signature} {
        lassign $signature state n
        return "$dtype [string tolower $state] in $n"
    }

    # narrative fdict
    #
    # fdict - Firing dictionary; see [assess], above.
    #
    # Produces a one-line narrative text string for a given rule firing.
    #
    # NOTE: None of the current rules will fire on resolution unless the
    # resolver is a local group, and so the "resolver eq NONE" case
    # will never be used.  It wasn't also so, however, so we include
    # the case here and in [detail] in case the rules change.

    typemethod narrative {fdict} {
        dict with fdict {}

        set pcov [string trim [percent $coverage]]

        set start "$dtype [string tolower $state]"
        set end   "in {nbhood:$n}"

        if {$state eq "ONGOING"} {
            return "$start $end ($pcov)"
        } elseif {$resolver ni {"NONE" ""}} {
            return "$start by {group:$resolver} $end"
        } else {
            return "$start $end"
        }
    }
    
    # detail fdict 
    #
    # fdict - Firing dictionary; see rulesets, below.
    # ht    - An htools(n) buffer
    #
    # Produces a narrative HTML paragraph including all fdict information.

    typemethod detail {fdict ht} {
        dict with fdict {}

        set pcov [string trim [percent $coverage]]

        $ht putln "An environmental situation of type $dtype"

        if {$state eq "ONGOING"} {
            if {$inception} {
                $ht putln "has begun"
            } else {
                $ht putln "is ongoing"
            } 
            $ht putln "in neighborhood\n"
            $ht link my://app/nbhood/$n $n
            $ht put " with $pcov coverage."
        } else {
            $ht putln "has been resolved"
            if {$resolver ne "NONE"} {
                $ht putln "by group "
                $ht link my://app/group/$resolver $resolver
            }
            $ht putln "in neighborhood "
            $ht link my://app/nbhood/$n $n
            $ht put "."
        }

        $ht para
    }

    #-------------------------------------------------------------------
    # Helper Routines

    # resolverIsLocal g
    #
    # g    A group
    #
    # Returns 1 if g is known and local, and 0 otherwise.
    proc resolverIsLocal {g} {
        expr {$g ne "" && [group isLocal $g]}
    }

    # satinput flist cov con mag ?con mag...?
    #
    # flist - The groups affected
    # cov   - The coverage fraction
    # con   - The affected concern
    # mag   - The nominal magnitude
    #
    # Enters satisfaction inputs for flist and cov.

    proc satinput {flist cov args} {
        assert {[llength $args] != 0 && [llength $args] % 2 == 0}

        set nomCov [parmdb get dam.ensit.nominalCoverage]
        let mult   {$cov/$nomCov}

        set result [list]
        foreach {con mag} $args {
            lappend result $con [mag* $mult $mag]
        }

        dam sat T $flist {*}$result
    }
}


#-------------------------------------------------------------------
# Rule Set: BADFOOD: Contaminated Food Supply
#
# Environmental Situation: The local food supply has been contaminated.


driver::ensit define BADFOOD {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule BADFOOD-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XXXS- \
                QOL XXL-
        }

        dam rule BADFOOD-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XXXS- \
                QOL L-
        }

        dam rule BADFOOD-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }
}

#-------------------------------------------------------------------
# Rule Set: BADWATER: Contaminated Water Supply
#
# Environmental Situation: The local water supply has been contaminated.
 
driver::ensit define BADWATER {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule BADWATER-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XXXS- \
                QOL XXL-
        }

        dam rule BADWATER-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XXXS- \
                QOL L-
        }

        dam rule BADWATER-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }
}

#-------------------------------------------------------------------
# Rule Set: COMMOUT: Communications Outage
#
# Environmental Situation: Communications are out in the neighborhood.
 
    
driver::ensit define COMMOUT {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule COMMOUT-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                SFT L-    \
                CUL M-    \
                QOL XXL-
        }

        dam rule COMMOUT-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                SFT S-    \
                CUL S-    \
                QOL XL-
        }
    }
}


#-------------------------------------------------------------------
# Rule Set: CULSITE: Damage to Cultural Site/Artifact
#
# Environmental Situation: A cultural site or artifact is
# damaged, presumably due to kinetic action.
    
driver::ensit define CULSITE {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule CULSITE-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                CUL XXXXL- \
                QOL XXXS-
        }

        dam rule CULSITE-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                CUL XL-
        }
    }
}

#-------------------------------------------------------------------
# Rule Set: DISASTER: Disaster
#
# Environmental Situation: Disaster
    
driver::ensit define DISASTER {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule DISASTER-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                SFT XXL-   \
                QOL XXXXL-
        }

        dam rule DISASTER-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                SFT L-    \
                QOL XXL-
        }

        dam rule DISASTER-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }
}


#-------------------------------------------------------------------
# Rule Set: DISEASE: Disease
#
# Environmental Situation: General disease due to unhealthy conditions.
    
driver::ensit define DISEASE {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule DISEASE-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT L-    \
                SFT XXL-  \
                QOL XXXL-
        }

        dam rule DISEASE-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT S-    \
                SFT L-    \
                QOL XL-
        }

        dam rule DISEASE-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT L+
        }
    }
}

#-------------------------------------------------------------------
# Rule Set: EPIDEMIC: Epidemic
#
# Environmental Situation: Epidemic disease
 
driver::ensit define EPIDEMIC {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule EPIDEMIC-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT XXL-   \
                SFT XL-    \
                QOL XXXXL-
        }

        dam rule EPIDEMIC-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT L-    \
                SFT L-    \
                QOL XXL-
        }

        dam rule EPIDEMIC-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT M+
        }
    }
}


#-------------------------------------------------------------------
# Rule Set: FOODSHRT: Food Shortage
#
# Environmental Situation: There is a food shortage in the neighborhood.
 
driver::ensit define FOODSHRT {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule FOODSHRT-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT M-  \
                QOL XL-
        }

        dam rule FOODSHRT-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-  \
                QOL L-
        }

        dam rule FOODSHRT-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT L+
        }
    }
}


#-------------------------------------------------------------------
# Rule Set: FUELSHRT: Fuel Shortage
#
# Environmental Situation: There is a fuel shortage in the neighborhood.
 
driver::ensit define FUELSHRT {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule FUELSHRT-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT M-           \
                QOL XXXL-
        }

        dam rule FUELSHRT-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-  \
                QOL XL-
        }

        dam rule FUELSHRT-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }
}


#-------------------------------------------------------------------
# Rule Set: GARBAGE: Garbage in the Streets
#
# Environmental Situation: Garbage is piling up in the streets.
 
driver::ensit define GARBAGE {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule GARBAGE-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT L-   \
                SFT XL-  \
                QOL XL-
        }

        dam rule GARBAGE-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-   \
                SFT M-   \
                QOL L-
        }

        dam rule GARBAGE-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }
}



#-------------------------------------------------------------------
# Rule Set: INDSPILL: Industrial Spill
#
# Environmental Situation: Damage to an industrial facility has released
# possibly toxic substances into the surrounding area.
 
driver::ensit define INDSPILL {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule INDSPILL-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT M-   \
                SFT XL-  \
                QOL XXL-
        }

        dam rule INDSPILL-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-   \
                SFT S-   \
                QOL L-
        }

        dam rule INDSPILL-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT M+
        }
    }
}


#-------------------------------------------------------------------
# Rule Set: MINEFIELD: Minefield
#
# Environmental Situation: The residents of this neighborhood know that
# there is a minefield in the neighborhood.
 
driver::ensit define MINEFIELD {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule MINEFIELD-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT XXL-    \
                SFT XXXXL-  \
                QOL XXXXL-
        }

        dam rule MINEFIELD-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT L-    \
                SFT XXL-  \
                QOL XXL-
        }

        dam rule MINEFIELD-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT XXL+
        }
    }
}



#-------------------------------------------------------------------
# Rule Set: NOWATER: No Water Supply
#
# Environmental Situation: The local water supply is non-functional;
# no water is available.
 
driver::ensit define NOWATER {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule NOWATER-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT XXL-    \
                QOL XXXXL-
        }

        dam rule NOWATER-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT L-     \
                QOL XXXL-
        }

        dam rule NOWATER-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT M+
        }
    }
}


#-------------------------------------------------------------------
# Rule Set: ORDNANCE: Unexploded Ordnance
#
# Environmental Situation: The residents of this neighborhood know that
# there is unexploded ordnance (probably from cluster munitions)
# in the neighborhood.
 
driver::ensit define ORDNANCE {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule ORDNANCE-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT XL-    \
                SFT XXXXL- \
                QOL XXXL-
        }

        dam rule ORDNANCE-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT L-   \
                SFT XXL- \
                QOL XXL-
        }

        dam rule ORDNANCE-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }
}



#-------------------------------------------------------------------
# Rule Set: PIPELINE: Oil Pipeline Fire
#
# Environmental Situation: Damage to an oil pipeline has caused to catch
# fire.
 
driver::ensit define PIPELINE {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule PIPELINE-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT L-     \
                SFT S-     \
                QOL XXXXL-
        }

        dam rule PIPELINE-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-     \
                SFT XXS-   \
                QOL XXL-
        }

        dam rule PIPELINE-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }
}



#-------------------------------------------------------------------
# Rule Set: POWEROUT: Power Outage
#
# Environmental Situation: Electrical power is off in the local area.
 
driver::ensit define POWEROUT {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule POWEROUT-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT L-   \
                SFT M-   \
                QOL XXL-
        }

        dam rule POWEROUT-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-   \
                SFT S-   \
                QOL L-
        }

        dam rule POWEROUT-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT L+
        }
    }
}

#-------------------------------------------------------------------
# Rule Set: REFINERY: Oil Refinery Fire
#
# Environmental Situation: Damage to an oil refinery has caused it to
# catch fire.
 
driver::ensit define REFINERY {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule REFINERY-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT XXL-   \
                SFT L-     \
                QOL XXXXL-
        }

        dam rule REFINERY-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT L-   \
                SFT M-   \
                QOL XXL-
        }

        dam rule REFINERY-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT XL+
        }
    }
}



#-------------------------------------------------------------------
# Rule Set: RELSITE: Damage to Religious Site/Artifact
#
# Environmental Situation: A religious site or artifact is
# damaged, presumably due to kinetic action.
 
driver::ensit define RELSITE {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule RELSITE-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                SFT XL-   \
                CUL XXXL- \
                QOL L-
        }

        dam rule RELSITE-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT S-   \
                SFT S-   \
                CUL XL-  \
                QOL XS-
        }

        dam rule RELSITE-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT M+
        }
    }
}


#-------------------------------------------------------------------
# Rule Set: SEWAGE: Sewage Spill
#
# Environmental Situation: Sewage is pooling in the streets.
 
driver::ensit define SEWAGE {
    typemethod ruleset {fdict} {
        dict with fdict {}

        set flist [demog gIn $n]

        dam rule SEWAGE-1-1 $fdict {
           $state eq "ONGOING" && $inception
        } {
            satinput $flist $coverage \
                AUT L-    \
                QOL XXXL-
        }

        dam rule SEWAGE-1-2 $fdict {
           $state eq "ONGOING" && !$inception
        } {
            satinput $flist $coverage \
                AUT M-    \
                QOL XL-
        }

        dam rule SEWAGE-2-1 $fdict {
            $state eq "RESOLVED" && [resolverIsLocal $resolver]
        } {
            satinput $flist $coverage  \
                AUT S+
        }
    }
}


