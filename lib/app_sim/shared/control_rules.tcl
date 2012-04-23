#------------------------------------------------------------------------
# TITLE:
#    control_rules.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Driver Assessment Model (DAM): Neighborhood Control rule sets
#
#    ::control_rules is a singleton object implemented as a snit::type.  To
#    initialize it, call "::control_rules init".
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# control_rules

snit::type control_rules {
    # Make it an ensemble
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Look-up tables

    # C11sat -- satisfaction magnitude dict for CONTROL-1-1.  Key
    # is abs(Vdelta), value is unsigned qmag(n).  

    typevariable C11sat {
        1.4 XXXL
        1.0 XXL
        0.6 L
        0.2 M
    }

    # C11acoop -- effect on civgroup f's cooperation
    # with force groups owned by actor a for CONTROL-1-1.  Key is
    # vrel.fa, value is qmag(n).

    typevariable C11acoop -array {
        SUPPORT S+
        LIKE    0
        INDIFF  S-
        DISLIKE M-
        OPPOSE  L-
    }

    # C11bcoop -- effect on civgroup f's cooperation
    # with force groups owned by actor b for CONTROL-1-1.  Key is
    # vrel.fb, value is qmag(n).

    typevariable C11bcoop -array {
        SUPPORT L+
        LIKE    M+
        INDIFF  S+
        DISLIKE 0
        OPPOSE  0
    }

    # C11sat -- effect on civgroup f's satisfaction for CONTROL-1-2
    # Key is vrel.fa, value is qmag(n).

    typevariable C12sat -array {
        SUPPORT XXL-
        LIKE    XL-
        INDIFF  S-
        DISLIKE L+
        OPPOSE  XL+
    }

    # C12acoop -- effect on civgroup f's cooperation with actor a's
    # force groups for CONTROL-1-2
    # Key is vrel.fa, value is qmag(n).

    typevariable C12acoop -array {
        SUPPORT XL+
        LIKE    L+
        INDIFF  S-
        DISLIKE L-
        OPPOSE  XL-
    }

    # C12ccoop -- effect on civgroup f's cooperation with every
    # other actor c's force groups for CONTROL-1-2
    # Key is vrel.fa, value is qmag(n).

    typevariable C12ccoop -array {
        SUPPORT L+
        LIKE    M+
        INDIFF  S+
        DISLIKE 0
        OPPOSE  0
    }

    # C13sat -- effect on civgroup f's satisfaction for CONTROL-1-3
    # Key is vrel.fa, value is qmag(n).

    typevariable C13sat -array {
        SUPPORT XXL+
        LIKE    XL+
        INDIFF  S+
        DISLIKE L-
        OPPOSE  XL-
    }

    # C13bcoop -- effect on civgroup f's cooperation with actor b's
    # force groups for CONTROL-1-3
    # Key is vrel.fa, value is qmag(n).

    typevariable C13bcoop -array {
        SUPPORT L+
        LIKE    M+
        INDIFF  S+
        DISLIKE 0
        OPPOSE  0
    }

    
    #-------------------------------------------------------------------
    # Public Typemethods

    # analyze dict
    #
    # dict  Dictionary of aggregate event attributes:
    #
    #       n            The neighborhood in which control shifted.
    #       a            The actor that lost control, or "" if none.
    #       b            The actor that gained control, or "" if none.
    #       driver_id    The GRAM driver_id ID
    #
    # Calls CONTROL-1 to assess the satisfaction and cooperation
    # implications of the event.

    typemethod analyze {dict} {
        log normal controlr "event CONTROL-1 [list $dict]"

        if {![dam isactive CONTROL]} {
            log warning controlr \
                "event CONTROL-1: ruleset has been deactivated"
            return
        }

        control_rules CONTROL-1 $dict
    }


    #-------------------------------------------------------------------
    # Rule Set: CONTROL: Shift in neighborhood control.
    #
    # Event.  This rule set determines the effect of a shift in
    # control of a neighborhood.


    # CONTROL-1 dict
    #
    # dict  Dictionary of input parameters
    #
    #       n            The neighborhood in which control shifted.
    #       a            The actor that lost control, or "" if none.
    #       b            The actor that gained control, or "" if none.
    #       driver_id    The GRAM driver_id ID
    #
    # Assesses the satisfaction and cooperation implications of the
    # shift in control.

    typemethod CONTROL-1 {dict} {
        dict with dict {
            set flist [civgroup gIn $n]

            dam ruleset CONTROL $driver_id

            dam detail "In Neighborhood:" $n

            # CONTROL-1-1
            #
            # If Actor b has taken control of nbhood n from Actor a,
            # Then for each CIV pgroup f in the neighborhood
            dam rule CONTROL-1-1 {
                $a ne "" && $b ne ""
            } {
                dam detail "Lost Control:"   $a
                dam detail "Gained Control:" $b

                foreach f $flist {
                    # FIRST, get the vertical relationships
                    set Vfa [vrel.ga $f $a]
                    set Vfb [vrel.ga $f $b]

                    # NEXT, get the satisfaction effects.
                    let Vdelta {$Vfb - $Vfa}

                    if {$Vdelta > 0.0} {
                        set sign "+"
                    } elseif {$Vdelta < 0.0} {
                        set sign "-"
                    } else {
                        set sign ""
                    }

                    set mag 0

                    dict for {bound sym} $C11sat {
                        if {$bound < abs($Vdelta)} {
                            set mag $sym$sign
                            break
                        }
                    }
                    
                    dam sat P $f AUT $mag

                    # NEXT, get the cooperation effects with a's troops
                    dam coop P $f [actor frcgroups $a] \
                        $C11acoop([qaffinity name $Vfa])
                    dam coop P $f [actor frcgroups $b] \
                        $C11bcoop([qaffinity name $Vfb])
                }
            }

            # CONTROL-1-2
            #
            # If Actor a has lost control of nbhood n, which is now
            # in chaos,
            # Then for each CIV pgroup f in the neighborhood
            dam rule CONTROL-1-2 {
                $a ne "" && $b eq ""
            } {
                dam detail "Lost Control:" $a

                foreach f $flist {
                    # FIRST, get the vertical relationships
                    set Vsym [qaffinity name [vrel.ga $f $a]]

                    dam sat P $f AUT $C12sat($Vsym)

                    # NEXT, get the cooperation effects with each
                    # actor's troops
                    foreach actor [actor names] {
                        set glist [actor frcgroups $actor]

                        if {$actor eq $a} {
                            set mag $C12acoop($Vsym)
                        } else {
                            set Vc [qaffinity name [vrel.ga $f $actor]]
                            set mag $C12ccoop($Vc)
                        }

                        dam coop P $f $glist $mag
                    }
                }
            }

            # CONTROL-1-3
            #
            # If Actor b has gained control of nbhood n, which was previously
            # in chaos,
            # Then for each CIV pgroup f in the neighborhood
            dam rule CONTROL-1-3 {
                $a eq "" && $b ne ""
            } {
                dam detail "Gained Control:" $b

                foreach f $flist {
                    # FIRST, get the vertical relationships
                    set Vsym [qaffinity name [vrel.ga $f $b]]

                    dam sat P $f AUT $C13sat($Vsym)

                    # NEXT, get the cooperation effects with actor b's
                    # troops.
                    set glist [actor frcgroups $b]
                    set mag $C13bcoop($Vsym)
                    dam coop P $f $glist $mag
                }
            }

        }
    }
}


