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

    # C21 -- Effect on civgroup g's vertical relationship with actor a,
    # given vrel.ga,<case> where case is G (gained control), L (lost 
    # control), or N (neither).
    
    typevariable C21 -array {
        SUPPORT,G  L+
        LIKE,G     M+
        INDIFF,G   0
        DISLIKE,G  M-
        OPPOSE,G   L-

        SUPPORT,N  M-
        LIKE,N     S-
        INDIFF,N   0
        DISLIKE,N  0
        OPPOSE,N   0

        SUPPORT,L  L-
        LIKE,L     M-
        INDIFF,L   0
        DISLIKE,L  XS-
        OPPOSE,L   S-
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
    #       driver_id    The driver ID
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
        control_rules CONTROL-2 $dict
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
    #       driver_id    The driver ID
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
                    set Vfa [qaffinity name $Vfa]
                    set Vfb [qaffinity name $Vfb]

                    dam coop P $f [actor frcgroups $a] \
                        $C11acoop($Vfa) "a's group, V.fa=$Vfa"
                    dam coop P $f [actor frcgroups $b] \
                        $C11bcoop($Vfb) "b's group, V.fb=$Vfb"
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
                            set note "a's group, V.fa=$Vsym"
                        } else {
                            set Vc [qaffinity name [vrel.ga $f $actor]]
                            set mag $C12ccoop($Vc)
                            set note "c's group, V.fc=$Vc"
                        }

                        dam coop P $f $glist $mag $note
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
                    dam coop P $f $glist $mag "b's group, V.fb=$Vsym"
                }
            }

        }
    }

    # CONTROL-2 dict
    #
    # dict - Dictionary of input parameters
    #
    #   n          -  The neighborhood in which control shifted.
    #   a          -  The actor that lost control, or "" if none.
    #   b          -  The actor that gained control, or "" if none.
    #   driver_id  -  The driver ID
    #
    # Assesses the vertical relationship implications of the
    # shift in control.

    typemethod CONTROL-2 {dict} {
        set ag [dict get $dict b]
        set al [dict get $dict a]

        set glist [civgroup gIn [dict get $dict n]]
        set alist [actor names]

        dam ruleset CONTROL [dict get $dict driver_id]

        dam detail "In Neighborhood:" [dict get $dict n]
        dam detail "Lost control:"    [expr {$al ne "" ? $al : "none"}]
        dam detail "Gained control:"  [expr {$ag ne "" ? $ag : "none"}]

        dam rule CONTROL-2-1 {1} {
            foreach g $glist {
                foreach a $alist {
                    # FIRST, get the vertical relationship
                    set Vga [qaffinity name [vrel.ga $g $a]]

                    # NEXT, did actor a lose, gain, or neither?
                    if {$a eq $al} {
                        set case L
                        set note "V.ga=$Vga, lost control"
                    } elseif {$a eq $ag} {
                        set case G
                        set note "V.ga=$Vga, gained control"
                    } else {
                        set case N
                        set note "V.ga=$Vga, neither"
                    }

                    # NEXT, enter the vrel input
                    dam vrel P $g $a $C21($Vga,$case) $note
                }
            }
        }
    }
}


