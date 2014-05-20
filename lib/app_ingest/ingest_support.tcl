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

# NEXT, Create "Drought" CURSE, replacing any existing DROUGHT curse

catch {send CURSE:DELETE -curse_id DROUGHT}
send CURSE:CREATE -curse_id DROUGHT -cause THIRST -s 1.0 -p 0.0 -q 0.0 \
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
    -mag   XS-
send INJECT:SAT:CREATE -curse_id DROUGHT \
    -mode  transient \
    -gtype EXISTING  \
    -g     @SACIV    \
    -c     SFT       \
    -mag   XS-

# NEXT, create VIOLENCE ("Random Violence") CURSE, replacing any
# previous such CURSE.

catch {send CURSE:DELETE -curse_id VIOLENCE}
send CURSE:CREATE -curse_id VIOLENCE -cause UNIQUE -s 1.0 -p 0.0 -q 0.0 \
    -longname "Random Violence against Civilians"
send INJECT:SAT:CREATE -curse_id VIOLENCE \
    -mode  persistent \
    -gtype NEW        \
    -g     @CIVS      \
    -c     SFT        \
    -mag   XS-


# End of ingest_support.tcl
#-------------------------------------------------------------------

