#-----------------------------------------------------------------------
# TITLE:
#    projtypes.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena Data Types
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::projectlib:: {
    namespace export  \
        boolean       \
        eattroe       \
        eattroenf     \
        eattroeuf     \
        ecause        \
        ecivconcern   \
        econcern      \
        edamrule      \
        edamruleset   \
        edefroeuf     \
        edemeanor     \
        eensit       \
        leensit      \
        eforcetype    \
        efrcactivity  \
        eorgactivity  \
        eorgconcern   \
        eorgtype      \
        esitstate     \
        eurbanization \
        eunitshape    \
        eunitsymbol   \
        eyesno        \
        hexcolor      \
        idays         \
        ident         \
        ingpopulation \
        ioptdays      \
        ipositive     \
        iquantity     \
        leensit      \
        polygon       \
        qsecurity     \
        rdays         \
        rgain         \
        rgrouprel     \
        rnomcoverage  \
        rrate         \
        typewrapper   \
        unitname      \
        weight
}

#-------------------------------------------------------------------
# Type Wrapper -- wraps snit::<type> instances so they throw
#                 -errorcode INVALID

snit::type ::projectlib::typewrapper {
    #---------------------------------------------------------------
    # Components

    component basetype

    #---------------------------------------------------------------
    # Options

    delegate option * to basetype

    #---------------------------------------------------------------
    # Constructor

    # typewrapper newtype oldtype ?options....?

    constructor {oldtype args} {
        # FIRST, create the basetype, if need be.
        if {[llength $args] > 0} {
            set basetype [{*}$oldtype ${selfns}::basetype {*}$args]
        } else {
            set basetype $oldtype
        }
    }

    #---------------------------------------------------------------
    # Methods

    delegate method * to basetype


    # validate value
    #
    # value    A value of the type
    #
    # Validates the value, returning it if valid and throwing
    # -errorcode INVALID if not.

    method validate {value} {
        if {[catch {
            {*}$basetype validate $value
        } result]} {
            return -code error -errorcode INVALID $result
        }

        return $value
    }
}



#-------------------------------------------------------------------
# Enumerations

# AAM Attacking ROEs, UF and NF combined
::marsutil::enum ::projectlib::eattroe  {
    DO_NOT_ATTACK   "Do not attack"
    HIT_AND_RUN     "Hit and run"
    STAND_AND_FIGHT "Stand and fight"
    ATTACK          "Attack"
}


# AAM Attacking ROEs, NF only
::marsutil::enum ::projectlib::eattroenf  {
    DO_NOT_ATTACK   "Do not attack"
    HIT_AND_RUN     "Hit and run"
    STAND_AND_FIGHT "Stand and fight"
}


# AAM Attacking ROEs, UF only
::marsutil::enum ::projectlib::eattroeuf  {
    DO_NOT_ATTACK   "Do not attack"
    ATTACK          "Attack"
}


# AAM Defending ROEs, UF only
::marsutil::enum ::projectlib::edefroeuf  {
    HOLD_FIRE             "Hold fire"
    FIRE_BACK_IF_PRESSED  "Fire back if pressed"
    FIRE_BACK_IMMEDIATELY "Fire back immediately"
}



# DAM Rules
::marsutil::enum ::projectlib::edamrule {
    ADJUST-1-1    "Magic Satisfaction Adjustment"
    ADJUST-1-2    "Magic Satisfaction Set"
    ADJUST-2-1    "Magic Cooperation Adjustment"
    ADJUST-2-2    "Magic Cooperation Set"

    BADFOOD-1-1   "Food supply is contaminated"
    BADFOOD-2-1   "Food supply continues to be contaminated"
    BADFOOD-2-2   "Food supply is no longer contaminated"
    BADFOOD-3-1   "Food contamination is resolved by outsiders"
    BADFOOD-3-2   "Food contamination is resolved by locals"

    BADWATER-1-1  "Water supply is contaminated"
    BADWATER-2-1  "Water supply continues to be contaminated"
    BADWATER-2-2  "Water supply is no longer contaminated"
    BADWATER-3-1  "Water contamination is resolved by outsiders"
    BADWATER-3-2  "Water contamination is resolved by locals"

    CHKPOINT-1-1  "Force group assigned CHECKPOINT activity"
    CHKPOINT-2-1  "Force group no longer operating checkpoints"

    CIVCAS-1-1    "Civilian casualties taken"
    CIVCAS-2-1    "Civilian casualties taken from force group"

    CMOCONST-1-1  "FRC units are doing construction work"
    CMOCONST-2-1  "FRC units no longer doing construction work"

    CMODEV-1-1    "Force units are encouraging light development"
    CMODEV-2-1    "Force units no longer encouraging light development"

    CMOEDU-1-1    "FRC units are teaching local civilians"
    CMOEDU-2-1    "FRC units no longer teaching local civilians"

    CMOEMP-1-1    "FRC units are providing employment"
    CMOEMP-2-1    "FRC units no longer providing employment"

    CMOIND-1-1    "FRC units are aiding industry"
    CMOIND-2-1    "FRC units no longer aiding industry"

    CMOINF-1-1    "FRC units are improving infrastructure"
    CMOINF-2-1    "FRC units no longer improving infrastructure"

    CMOLAW-1-1    "Force units are enforcing the law"
    CMOLAW-2-1    "Force units no longer enforcing the law"

    CMOMED-1-1    "FRC units are providing healthcare"
    CMOMED-2-1    "FRC units no longer providing healthcare"

    CMOOTHER-1-1  "FRC units are doing other CMO activities"
    CMOOTHER-2-1  "FRC units no longer doing other CMO activities"

    COERCION-1-1  "Force units coercing local civilians"
    COERCION-2-1  "Force units no longer coercing local civilians"

    COMMOUT-1-1   "Communications go out"
    COMMOUT-2-1   "Communications remain out"
    COMMOUT-2-2   "Communications are no longer out"
    COMMOUT-3-1   "Communications are restored by outsiders"
    COMMOUT-3-2   "Communications are restored by locals"

    CRIMINAL-1-1  "Force units engaging in criminal activities"
    CRIMINAL-2-1  "Force units no longer engaging in criminal activities"

    CURFEW-1-1    "Force units enforcing curfew"
    CURFEW-2-1    "Force units no longer enforcing curfew"

    DISASTER-1-1  "Disaster occurred in the neighborhood"
    DISASTER-2-1  "Disaster continues"
    DISASTER-2-2  "Disaster has ended"
    DISASTER-3-1  "Disaster resolved by outsiders"
    DISASTER-3-2  "Disaster resolved by locals"

    DISEASE-1-1   "Unhealthy conditions begin to cause disease"
    DISEASE-2-1   "Unhealthy conditions continue to cause disease"
    DISEASE-2-2   "Unhealthy conditions are gone"
    DISEASE-3-1   "Unhealthy conditions are resolved by outsiders"
    DISEASE-3-2   "Unhealthy conditions are resolved by locals"

    DISPLACED-1-1 "Displaced persons living in neighborhood"
    DISPLACED-2-1 "Displaced persons no longer living in neighborhood"

    DMGCULT-1-1   "A sacred site is damaged"
    DMGCULT-2-1   "Damage has not been resolved"
    DMGCULT-2-2   "Damage is no longer causing resentment"
    DMGCULT-3-1   "Damage is resolved by outsiders"
    DMGCULT-3-2   "Damage is resolved by locals"

    DMGSACRED-1-1 "A sacred site is damaged"
    DMGSACRED-2-1 "Damage has not been resolved"
    DMGSACRED-2-2 "Damage is no longer causing resentment"
    DMGSACRED-3-1 "Damage is resolved by outsiders"
    DMGSACRED-3-2 "Damage is resolved by locals"

    EPIDEMIC-1-1  "Epidemic begins to spread"
    EPIDEMIC-2-1  "Epidemic continues to spread"
    EPIDEMIC-2-2  "Epidemic is no longer spreading"
    EPIDEMIC-3-1  "Spread of epidemic is halted by outsiders"
    EPIDEMIC-3-2  "Spread of epidemic is halted by locals"

    FOODSHRT-1-1  "Food has run short"
    FOODSHRT-1-2  "Food is available"
    FOODSHRT-2-1  "Food shortage is ended by outsiders"
    FOODSHRT-2-2  "Food shortage is ended by locals"

    FUELSHRT-1-1  "Fuel begins to run short"
    FUELSHRT-2-1  "Fuel continues to be in short supply"
    FUELSHRT-2-2  "Fuel is no longer in short supply"
    FUELSHRT-3-1  "Fuel shortage is resolved by outsiders"
    FUELSHRT-3-2  "Fuel shortage is resolved by locals"

    GARBAGE-1-1   "Garbage begins to accumulate"
    GARBAGE-2-1   "Garbage is piled in the streets"
    GARBAGE-2-2   "Garbage is no longer piled in the streets"
    GARBAGE-3-1   "Garbage is cleaned up by outsiders"
    GARBAGE-3-2   "Garbage is cleaned up by locals"

    GUARD-1-1     "Force units guarding"
    GUARD-2-1     "Force units no longer guarding"

    INDSPILL-1-1  "Industrial spill occurs"
    INDSPILL-2-1  "Industrial spill has not been cleaned up"
    INDSPILL-2-2  "Industrial spill has been cleaned up"
    INDSPILL-3-1  "Industrial spill is cleaned up by outsiders"
    INDSPILL-3-2  "Industrial spill is cleaned by locals"

    MINEFIELD-1-1 "Minefield is placed"
    MINEFIELD-2-1 "Minefield remains"
    MINEFIELD-2-2 "Minefield has been cleared"
    MINEFIELD-3-1 "Minefield is cleared by outsiders"
    MINEFIELD-3-2 "Minefield is cleared by locals"

    NOWATER-1-1   "Water becomes unavailable"
    NOWATER-2-1   "Water continues to be unavailable"
    NOWATER-2-2   "Water is available"
    NOWATER-3-1   "Water supply is restored by outsiders"
    NOWATER-3-2   "Water supply is restored by locals"

    ORDNANCE-1-1  "Unexploded ordnance is found"
    ORDNANCE-2-1  "Unexploded ordnance remains"
    ORDNANCE-2-2  "Unexploded ordnance is gone"
    ORDNANCE-3-1  "Unexploded ordnance is removed by outsiders"
    ORDNANCE-3-2  "Unexploded ordnance is removed by locals"

    ORGCAS-1-1    "NGO personnel killed"
    ORGCAS-1-2    "IGO personnel killed"
    ORGCAS-1-3    "CTR personnel killed"

    ORGCONST-1-1  "ORG units are doing construction work"
    ORGCONST-2-1  "ORG units no longer doing construction work"

    ORGEDU-1-1    "ORG units are teaching local civilians"
    ORGEDU-2-1    "ORG units no longer teaching local civilians"

    ORGEMP-1-1    "ORG units are providing employment"
    ORGEMP-2-1    "ORG units no longer providing employment"

    ORGIND-1-1    "ORG units are aiding industry"
    ORGIND-2-1    "ORG units no longer aiding industry"

    ORGINF-1-1    "ORG units are improving infrastructure"
    ORGINF-2-1    "ORG units no longer improving infrastructure"

    ORGMED-1-1    "ORG units are providing healthcare"
    ORGMED-2-1    "ORG units no longer providing healthcare"

    ORGOTHER-1-1  "ORG units are doing other CMO activities"
    ORGOTHER-2-1  "ORG units no longer doing other CMO activities"

    PATROL-1-1    "Force units patrolling"
    PATROL-2-1    "Force units no longer patrolling"

    PIPELINE-1-1  "Oil pipeline catches fire"
    PIPELINE-2-1  "Oil pipeline is still burning"
    PIPELINE-2-2  "Oil pipeline is no longer burning"
    PIPELINE-3-1  "Oil pipeline fire is extinguished by outsiders"
    PIPELINE-3-2  "Oil pipeline fire is extinguished by locals"

    POWEROUT-1-1  "Power goes out"
    POWEROUT-2-1  "Power remains out"
    POWEROUT-2-2  "Power is back on"
    POWEROUT-3-1  "Power is restored by outsiders"
    POWEROUT-3-2  "Power is restored by locals"

    PSYOP-1-1     "Force units doing PSYOP"
    PSYOP-2-1     "Force units no longer doing PSYOP"

    PRESENCE-1-1  "Presence of force units"
    PRESENCE-2-1  "Force units no longer present"

    REFINERY-1-1  "Oil refinery catches fire"
    REFINERY-2-1  "Oil refinery is still burning"
    REFINERY-2-2  "Oil refinery is no longer burning"
    REFINERY-3-1  "Oil refinery fire is extinguished by outsiders"
    REFINERY-3-2  "Oil refinery fire is extinguished by locals"

    SEWAGE-1-1    "Sewage begins to pool in the streets"
    SEWAGE-2-1    "Sewage has pooled in the streets"
    SEWAGE-2-2    "Sewage is no longer pooled in the streets"
    SEWAGE-3-1    "Sewage is cleaned up by outsiders"
    SEWAGE-3-2    "Sewage is cleaned up by locals"
}

# DAM Rule Sets
::marsutil::enum ::projectlib::edamruleset {
    ADJUST    "Magic Adjustment"
    BADFOOD   "Contaminated Food Supply"
    BADWATER  "Contaminated Water Supply"
    CHKPOINT  "Checkpoint/Control Point"
    CIVCAS    "Civilian Casualties"
    CMOCONST  "CMO -- Construction"
    CMODEV    "CMO -- Development"
    CMOEDU    "CMO -- Education"
    CMOEMP    "CMO -- Employment"
    CMOIND    "CMO -- Industry"
    CMOINF    "CMO -- Infrastructure"
    CMOLAW    "CMO -- Law Enforcement"
    CMOMED    "CMO -- Healthcare"
    CMOOTHER  "CMO -- Other"
    COERCION  "Coercion"
    COMMOUT   "Communications Outage"
    CRIMINAL  "Criminal Activities"
    CURFEW    "Curfew"
    DISASTER  "Disaster"
    DISEASE   "Disease"
    DISPLACED "Displaced Persons"
    DMGCULT   "Damage to Cultural Site/Artifact"
    DMGSACRED "Damage to Sacred Site/Artifact"
    EPIDEMIC  "Epidemic"
    FOODSHRT  "Food Shortage"
    FUELSHRT  "Fuel Shortage"
    GARBAGE   "Garbage in the Streets"
    GUARD     "Guard"
    INDSPILL  "Industrial Spill"
    MINEFIELD "Minefield"
    NOWATER   "Interrupted Water Supply"
    ORDNANCE  "Unexploded Ordnance"
    ORGCAS    "Organization Casualties"
    ORGCONST  "ORG -- Construction"
    ORGEDU    "ORG -- Education"
    ORGEMP    "ORG -- Employment"
    ORGIND    "ORG -- Industry"
    ORGINF    "ORG -- Infrastructure"
    ORGMED    "ORG -- Healthcare"
    ORGOTHER  "ORG -- Other"
    PATROL    "Patrol"
    PIPELINE  "Oil Pipeline Fire"
    POWEROUT  "Power Outage"
    PRESENCE  "Mere Presence of Force Units"
    PSYOP     "PSYOP"
    REFINERY  "Oil Refinery Fire"
    SEWAGE    "Sewage Spill"
}

# DAM Rule Set Causes
::marsutil::enum ::projectlib::ecause {
    CHKPOINT  "Checkpoint/Control Point"
    CIVCAS    "Civilian Casualties"
    CMOCONST  "CMO -- Construction"
    CMODEV    "CMO -- Development"
    CMOEDU    "CMO -- Education"
    CMOEMP    "CMO -- Employment"
    CMOIND    "CMO -- Industry"
    CMOINF    "CMO -- Infrastructure"
    CMOLAW    "CMO -- Law Enforcement"
    CMOMED    "CMO -- Healthcare"
    CMOOTHER  "CMO -- Other"
    COERCION  "Coercion"
    COMMOUT   "Communications Outage"
    CRIMINAL  "Criminal Activities"
    CURFEW    "Curfew"
    DISASTER  "Disaster"
    DISPLACED "Displaced Persons"
    DMGCULT   "Damage to Cultural Site/Artifact"
    DMGSACRED "Damage to Sacred Site/Artifact"
    FUELSHRT  "Fuel Shortage"
    GARBAGE   "Garbage in the Streets"
    GUARD     "Guard"
    HUNGER    "Hunger"
    INDSPILL  "Industrial Spill"
    MOSQUE    "Damage to Mosque"
    ORDNANCE  "Unexploded Ordnance/Minefield"
    ORGCAS    "Organization Casualties"
    ORGCONST  "ORG -- Construction"
    ORGEDU    "ORG -- Education"
    ORGEMP    "ORG -- Employment"
    ORGIND    "ORG -- Industry"
    ORGINF    "ORG -- Infrastructure"
    ORGMED    "ORG -- Healthcare"
    ORGOTHER  "ORG -- Other"
    PATROL    "Patrol"
    PIPELINE  "Oil Pipeline Fire"
    POWEROUT  "Power Outage"
    PRESENCE  "Mere Presence of Force Units"
    PSYOP     "PSYOP"
    REFINERY  "Oil Refinery Fire"
    SEWAGE    "Sewage Spill"
    SICKNESS  "Sickness"
    THIRST    "Thirst"
}


# Unit icon shape (per MIL-STD-2525B)
::marsutil::enum ::projectlib::eunitshape {
    FRIEND   "Friend"
    ENEMY    "Enemy"
    NEUTRAL  "Neutral"
}

# Unit icon symbols

::marsutil::enum ::projectlib::eunitsymbol {
    infantry       "Infantry"
    irregular      "Irregular Military"
    police         "Civilian Police"
    criminal       "Criminal"
    organization   "Organization"
    civilian       "Civilian"
}



# Civilian Concerns
::marsutil::enum ::projectlib::ecivconcern {
    AUT "Autonomy"
    SFT "Physical Safety"
    CUL "Culture"
    QOL "Quality of Life"
}


# Organization Concerns
::marsutil::enum ::projectlib::eorgconcern {
    CAS "Casualties"
}


# All Concerns
::marsutil::enum ::projectlib::econcern \
    [concat [::projectlib::ecivconcern deflist] [::projectlib::eorgconcern deflist]]


# Civilian Group Demeanor
::marsutil::enum ::projectlib::edemeanor {
    APATHETIC  "Apathetic"
    AVERAGE    "Average"
    AGGRESSIVE "Aggressive"
}


# Force Group Type
::marsutil::enum ::projectlib::eforcetype {
    REGULAR        "Regular Military"
    PARAMILITARY   "Paramilitary"
    POLICE         "Police"
    IRREGULAR      "Irregular Military"
    CRIMINAL       "Organized Crime"
}


# Org Group Type
::marsutil::enum ::projectlib::eorgtype {
    NGO "Non-Governmental Organization"
    IGO "Intergovernmental Organization"
    CTR "Contractor"
}

# Situation State
::marsutil::enum ::projectlib::esitstate {
    INITIAL  Initial
    ACTIVE   Active
    INACTIVE Inactive
    ENDED    Ended
}


# Urbanization Level
::marsutil::enum ::projectlib::eurbanization {
    RURAL        "Rural"
    SUBURBAN     "Suburban"
    URBAN        "Urban"
}

# Yes/No
::marsutil::enum ::projectlib::eyesno {
    YES    "Yes"
    NO     "No"
}

# The name is the rule set name, e.g., SEWAGE, and the 
# long name is the full name of the situation
::marsutil::enum ::projectlib::eensit {
    BADFOOD     "CONTAMINATED.FOOD.SUPPLY"
    BADWATER    "CONTAMINATED.WATER.SUPPLY"
    COMMOUT     "COMMUNICATIONS.OUTAGE"
    DISASTER    "DISASTER"
    DISEASE     "DISEASE"
    DMGCULT     "DAMAGE.TO.CULTURAL.SITE"
    DMGSACRED   "DAMAGE.TO.SACRED.SITE"
    EPIDEMIC    "EPIDEMIC"
    FOODSHRT    "FOOD.SHORTAGE"
    FUELSHRT    "FUEL.SHORTAGE"
    GARBAGE     "GARBAGE.IN.THE.STREETS"
    INDSPILL    "INDUSTRIAL.SPILL"
    MINEFIELD   "MINE.FIELD"
    NOWATER     "NO.WATER"
    ORDNANCE    "UNEXPLODED.ORDNANCE"
    PIPELINE    "OIL.PIPELINE.FIRE"
    POWEROUT    "POWER.OUTAGE"
    REFINERY    "OIL.REFINERY.FIRE"
    SEWAGE      "SEWAGE.SPILL"
}

# List of eensit values
::projectlib::typewrapper ::projectlib::leensit \
    snit::listtype -type ::projectlib::eensit 


#-------------------------------------------------------------------
# Qualities

# Security
::marsutil::quality ::projectlib::qsecurity {
    H    "High"         25  60  100
    M    "Medium"        5  15   25
    L    "Low"         -25 -10    5
    N    "None"       -100 -60  -25
} -bounds yes -format {%4d}


#-----------------------------------------------------------------------
# Integer Types

# iquantity: non-negative integers
::projectlib::typewrapper ::projectlib::iquantity snit::integer -min 0

# ingpopulation: positive integers
::projectlib::typewrapper ::projectlib::ingpopulation snit::integer -min 1

# ipositive: positive integers
::projectlib::typewrapper ::projectlib::ipositive snit::integer -min 1


# idays: non-negative days
::projectlib::typewrapper ::projectlib::idays snit::integer -min 0

# ioptdays: days with -1 as sentinal
::projectlib::typewrapper ::projectlib::ioptdays snit::integer -min -1


#-------------------------------------------------------------------
# Ranges

# Duration in decimal days

::marsutil::range ::projectlib::rdays \
    -min 0.0 -format "%.1f"

# Fraction
::projectlib::typewrapper ::projectlib::rfraction snit::double \
    -min 0.0 \
    -max 1.0

# Gain setting
::marsutil::range ::projectlib::rgain -min 0.0

# Group Relationships
::marsutil::range ::projectlib::rgrouprel \
    -min -1.0 -max 1.0 -format "%+4.1f"

# Rate setting
::marsutil::range ::projectlib::rrate -min 0.0

#-------------------------------------------------------------------
# Boolean type
#
# This differs from the snit::boolean type in that it throws INVALID.

snit::type ::projectlib::boolean {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate flag
    #
    # flag    Possibly, a boolean value
    #
    # Returns 1 for true and 0 for false.

    typemethod validate {flag} {
        if {[catch {snit::boolean validate $flag} result]} {
            return -code error -errorcode INVALID $result
        }

        if {$flag} {
            return 1
        } else {
            return 0
        }
    }
}


#-----------------------------------------------------------------------
# hexcolor type

snit::type ::projectlib::hexcolor {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate color
    #
    # color    Possibly, a hex color
    #
    # Hex colors begin with a "#" followed by up to 12 hex digits.

    typemethod validate {name} {
        if {![regexp {^\#[[:xdigit:]]{1,12}$} $name]} {
            return -code error -errorcode INVALID \
                "Invalid hexadecimal color specifier, should be \"#RRGGBB\""
        }

        return [string tolower $name]
    }
}


#-----------------------------------------------------------------------
# ident type

snit::type ::projectlib::ident {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate name
    #
    # name    Possibly, an identifier
    #
    # Identifiers should begin with a letter, and contain only letters
    # and digits

    typemethod validate {name} {
        if {![regexp {^[A-Z][A-Z0-9]*$} $name]} {
            return -code error -errorcode INVALID \
  "Identifiers begin with a letter and contain only letters and digits."
        }

        return $name
    }
}

snit::type ::projectlib::unitname {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate name
    #
    # name    Possibly, a unit name
    #
    # Unit names should begin with a letter, and contain only letters,
    # digits, "-", and "/"

    typemethod validate {name} {
        if {![regexp {^[A-Z][A-Z0-9/\-]*$} $name]} {
            return -code error -errorcode INVALID \
  "Unit names begin with a letter and contain only letters, digits, - and /."
        }

        return $name
    }
}


#-----------------------------------------------------------------------
# polygon type

snit::type ::projectlib::polygon {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate coords...
    #
    # coords      A list {x1 y1 x2 y2 x3 y3 ....} of vertices
    #
    # Validates the polygon.  The polygon is valid if:
    #
    # * It has at least three points
    # * There are no duplicated points
    # * No edge intersects any other edge
    #
    # The coordinates can be passed as a single list, or as
    # individual arguments.

    typemethod validate {args} {
        # FIRST, get the coordinate list if passed as one arg.
        if {[llength $args] == 1} {
            set coords [lindex $args 0]
        } else {
            set coords $args
        }

        # NEXT, check the number of coordinates
        set len [llength $coords]
        if {$len % 2 != 0} {
            return -code error -errorcode INVALID \
                "expected even number of coordinates, got $len"
        }

        let size {$len/2}
        if {$size < 3} {
            return -code error -errorcode INVALID \
                "expected at least 3 point(s), got $size"
        }

        # NEXT, check for duplicated points
        for {set i 0} {$i < $len} {incr i 2} {
            for {set j 0} {$j < $len} {incr j 2} {
                if {$i == $j} {
                    continue
                }
                
                lassign [lrange $coords $i $i+1] x1 y1
                lassign [lrange $coords $j $j+1] x2 y2
                
                if  {$x1 == $x2 && $y1 == $y2} {
                    return -code error -errorcode INVALID \
                     "Point [expr {$i/2}] is identical to point [expr {$j/2}]"
                }
            }
        }
        
        # NEXT, check for edge crossings.  Consecutive edges can
        # intersect at their end points.
        set n [clength $coords]
        
        for {set i 0} {$i < $n} {incr i} {
            for {set j [expr {$i + 2}]} {$j <= $i + $n - 2} {incr j} {
                set e1 [cedge $coords $i]
                set e2 [cedge $coords $j]

                set p1 [lrange $e1 0 1]
                set p2 [lrange $e1 2 3]
                set q1 [lrange $e2 0 1]
                set q2 [lrange $e2 2 3]

                if {[intersect $p1 $p2 $q1 $q2]} {
                    return -code error -errorcode INVALID \
                        "Edges $i and $j intersect"
                }
            }
        }


        return $coords
    }
}

#-------------------------------------------------------------------
# Weight type
#
# A weight is a non-negative floating point number.  
# This differs from the snit::double type in that it throws INVALID.

snit::type ::projectlib::weight {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type constructor

    typeconstructor {
        snit::double ${type}::imptype -min 0.0
    }

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate value
    #
    # value    Possibly, a weight value
    #
    # Returns 1 for true and 0 for false.

    typemethod validate {value} {
        if {[catch {imptype validate $value} result]} {
            return -code error -errorcode INVALID $result
        }

        return $value
    }
}

