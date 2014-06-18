#-----------------------------------------------------------------------
# TITLE:
#   ingest_support.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   athena_ingest(1) support script.  
#
#   This is an athena(1) executive script.  Execute it in a scenario
#   to prepare the scenario for ingesting events.
#
#-----------------------------------------------------------------------

# FIRST, add an internal script containing required executive commands.
# This script will load automatically.

script save "athena_ingest(1) Executive Commands" {
    # athena_ingest(1) Executive Commands
    #
    # The commands defined in this script are used by the 
    # ingestion scripts created by the Athena TIGR Ingestion tool,
    # and must be present for the ingested events to function.


    # flood n duration
    #
    # n        - A neighborhood
    # duration - Number of weeks to resolution.
    #
    # Creates a DISASTER abstract situation in the neighborhood,
    # representing a flood.

    proc flood {n duration} {
        send ABSIT:CREATE -n $n -stype DISASTER -coverage 1.0 \
            -inception NO -resolver NONE -rduration $duration
    }
}
script auto "athena_ingest(1) Executive Commands" on
script load "athena_ingest(1) Executive Commands"

# NEXT, create ACCIDENT ("Accident") CURSE, replacing any
# previous such CURSE.

catch {send CURSE:DELETE -curse_id ACCIDENT}
send CURSE:CREATE -curse_id ACCIDENT -cause DISASTER -s 1.0 -p 0.0 -q 0.0 \
    -longname "Accident"
send INJECT:SAT:CREATE -curse_id ACCIDENT \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIV       \
    -c     SFT        \
    -mag   XS-

proc make_accident {block_id n} {
    tactic add $block_id CURSE -curse ACCIDENT \
        -roles [list @CIV [gofer civgroups resident_in $n]]
}

# NEXT, command to create CIVCAS tactics

proc make_civcas {block_id n casualties} {
    tactic add $block_id ATTRIT \
        -mode       NBHOOD      \
        -n          $n          \
        -casualties $casualties
}

# NEXT, create DEMO ("Demonstration") CURSE, replacing any
# previous such CURSE.

catch {send CURSE:DELETE -curse_id DEMO}
send CURSE:CREATE -curse_id DEMO -cause DEMO -s 1.0 -p 0.0 -q 0.0 \
    -longname "Demonstration"
send INJECT:SAT:CREATE -curse_id DEMO \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIVFOR    \
    -c     AUT        \
    -mag   XS+
send INJECT:SAT:CREATE -curse_id DEMO \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIVFOR    \
    -c     CUL        \
    -mag   M+
send INJECT:SAT:CREATE -curse_id DEMO \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIVOPP    \
    -c     AUT        \
    -mag   XS-
send INJECT:SAT:CREATE -curse_id DEMO \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIVOPP    \
    -c     CUL        \
    -mag   XS-
send INJECT:SAT:CREATE -curse_id DEMO \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIVOPP    \
    -c     QOL        \
    -mag   XS-
send INJECT:SAT:CREATE -curse_id DEMO \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIVOPP    \
    -c     SFT        \
    -mag   XS-

proc make_demo {block_id n glist} {
    foreach g $glist {
        set civfor [gofer civgroups mega \
                        -where IN -nlist $n -bygroups LIKING -hlist $g]
        set civopp [gofer civgroups mega \
                        -where IN -nlist $n -bygroups DISLIKING -hlist $g]
        tactic add $block_id CURSE -curse DEMO \
            -roles [list @CIVFOR $civfor @CIVOPP $civopp]
    }
}

# NEXT, Create "DROUGHT" CURSE, replacing any existing DROUGHT curse

catch {send CURSE:DELETE -curse_id DROUGHT}
send CURSE:CREATE -curse_id DROUGHT -cause DISASTER -s 1.0 -p 0.0 -q 0.0 \
    -longname "Drought in Neighborhood"
send INJECT:SAT:CREATE -curse_id DROUGHT \
    -mode  transient \
    -gtype NEW       \
    -g     @NONSACIV \
    -c     AUT       \
    -mag   XS-
send INJECT:SAT:CREATE -curse_id DROUGHT \
    -mode  transient \
    -gtype EXISTING  \
    -g     @NONSACIV \
    -c     QOL       \
    -mag   XS-
send INJECT:SAT:CREATE -curse_id DROUGHT \
    -mode  transient \
    -gtype NEW       \
    -g     @SACIV    \
    -c     AUT       \
    -mag   L-
send INJECT:SAT:CREATE -curse_id DROUGHT \
    -mode  transient \
    -gtype EXISTING  \
    -g     @SACIV    \
    -c     QOL       \
    -mag   L-
send INJECT:SAT:CREATE -curse_id DROUGHT \
    -mode  transient \
    -gtype EXISTING  \
    -g     @SACIV    \
    -c     SFT       \
    -mag   XS-

proc make_drought {block_id n} {
    set nonsa [gofer civgroups mega -where IN -nlist $n -livingby CASH]
    set sa    [gofer civgroups mega -where IN -nlist $n -livingby SA]

    tactic add $block_id CURSE -curse DROUGHT \
        -roles [list @NONSACIV $nonsa @SACIV $sa]
}


# NEXT, create EXPLOSION ("Explosion") CURSE, replacing any
# previous such CURSE.

catch {send CURSE:DELETE -curse_id EXPLOSION}
send CURSE:CREATE -curse_id EXPLOSION -cause CIVCAS -s 1.0 -p 0.0 -q 0.0 \
    -longname "Explosion"
send INJECT:SAT:CREATE -curse_id EXPLOSION \
    -mode  persistent \
    -gtype NEW        \
    -g     @CIV       \
    -c     AUT        \
    -mag   XS-
send INJECT:SAT:CREATE -curse_id EXPLOSION \
    -mode  persistent \
    -gtype NEW        \
    -g     @CIV       \
    -c     SFT        \
    -mag   L-

proc make_explosion {block_id n} {
    tactic add $block_id CURSE -curse EXPLOSION \
        -roles [list @CIV [gofer civgroups resident_in $n]]
}

# NEXT, command to make floods

proc make_flood {block_id n duration} {
    tactic add $block_id EXECUTIVE \
        -command [list flood $n $duration]
}

# NEXT, create RIOT ("Riot") CURSE, replacing any
# previous such CURSE.

catch {send CURSE:DELETE -curse_id RIOT}
send CURSE:CREATE -curse_id RIOT -cause CIVCAS -s 1.0 -p 0.0 -q 0.0 \
    -longname "Riot"
send INJECT:SAT:CREATE -curse_id RIOT \
    -mode  persistent \
    -gtype NEW        \
    -g     @CIV       \
    -c     AUT        \
    -mag   XS-
send INJECT:SAT:CREATE -curse_id RIOT \
    -mode  persistent \
    -gtype NEW        \
    -g     @CIV       \
    -c     QOL        \
    -mag   S-
send INJECT:SAT:CREATE -curse_id RIOT \
    -mode  persistent \
    -gtype NEW        \
    -g     @CIV       \
    -c     SFT        \
    -mag   L-

proc make_riot {block_id n} {
    tactic add $block_id CURSE -curse RIOT \
        -roles [list @CIV [gofer civgroups resident_in $n]]
}


# NEXT, create TRAFFIC ("Traffic") CURSE, replacing any
# previous such CURSE.

catch {send CURSE:DELETE -curse_id TRAFFIC}
send CURSE:CREATE -curse_id TRAFFIC -cause DISASTER -s 1.0 -p 0.0 -q 0.0 \
    -longname "Traffic"
send INJECT:SAT:CREATE -curse_id TRAFFIC \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIV       \
    -c     AUT        \
    -mag   S-
send INJECT:SAT:CREATE -curse_id TRAFFIC \
    -mode  transient  \
    -gtype NEW        \
    -g     @CIV       \
    -c     QOL        \
    -mag   S-

proc make_traffic {block_id n} {
    tactic add $block_id CURSE -curse TRAFFIC \
        -roles [list @CIV [gofer civgroups resident_in $n]]
}

# NEXT, create VIOLENCE ("Random Violence") CURSE, replacing any
# previous such CURSE.

catch {send CURSE:DELETE -curse_id VIOLENCE}
send CURSE:CREATE -curse_id VIOLENCE -cause CIVCAS -s 1.0 -p 0.0 -q 0.0 \
    -longname "Random Violence against Civilians"
send INJECT:SAT:CREATE -curse_id VIOLENCE \
    -mode  persistent \
    -gtype NEW        \
    -g     @CIV       \
    -c     SFT        \
    -mag   XS-

proc make_violence {block_id n} {
    tactic add $block_id CURSE -curse VIOLENCE \
        -roles [list @CIV [gofer civgroups resident_in $n]]
}

# End of ingest_support.tcl
#-------------------------------------------------------------------

