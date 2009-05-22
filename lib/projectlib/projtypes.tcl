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
        eadarule      \
        eadaruleset   \
        ecause        \
        ecivconcern   \
        econcern      \
        edemeanor     \
        eenvsit       \
        leenvsit      \
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
        iquantity     \
        leenvsit      \
        polygon       \
        qsecurity     \
        rdays         \
        rgain         \
        rgrouprel     \
        rnomcoverage  \
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

# ADA Rules
::marsutil::enum ::projectlib::eadarule {
    CHKPOINT-1-1  "Force group assigned CHECKPOINT activity"
    CHKPOINT-2-1  "Force group no longer operating checkpoints"

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

    CRIMINAL-1-1  "Force units engaging in criminal activities"
    CRIMINAL-2-1  "Force units no longer engaging in criminal activities"

    CURFEW-1-1    "Force units enforcing curfew"
    CURFEW-2-1    "Force units no longer enforcing curfew"

    GUARD-1-1     "Force units guarding"
    GUARD-2-1     "Force units no longer guarding"

    PATROL-1-1    "Force units patrolling"
    PATROL-2-1    "Force units no longer patrolling"

    PSYOP-1-1     "Force units doing PSYOP"
    PSYOP-2-1     "Force units no longer doing PSYOP"

    PRESENCE-1-1  "Presence of force units"
    PRESENCE-2-1  "Force units no longer present"

}

# ADA Rule Sets
::marsutil::enum ::projectlib::eadaruleset {
    BADFOOD   "Contaminated Food Supply"
    BADWATER  "Contaminated Water Supply"
    BIO       "Biological Hazard"
    CHEM      "Chemical Hazard"
    CHKPOINT  "Checkpoint/Control Point"
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
    EPIDEMIC  "Epidemic"
    FOODSHRT  "Food Shortage"
    FUELSHRT  "Fuel Shortage"
    GARBAGE   "Garbage in the Streets"
    GUARD     "Guard"
    INDSPILL  "Industrial Spill"
    MOSQUE    "Damage to Mosque"
    NOWATER   "No Water Supply"
    ORDNANCE  "Unexploded Ordnance"
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

# ADA Rule Set Causes.  Most of these
::marsutil::enum ::projectlib::ecause {
    BIO       "Biological Agent"
    CHEM      "Chemical Agent"
    CHKPOINT  "Checkpoint/Control Point"
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
    FUELSHRT  "Fuel Shortage"
    GARBAGE   "Garbage in the Streets"
    GUARD     "Guard"
    HUNGER    "Hunger"
    INDSPILL  "Industrial Spill"
    MOSQUE    "Damage to Mosque"
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
# long name is the full name of the rule set.
::marsutil::enum ::projectlib::eenvsit {
    BADFOOD     "CONTAMINATED.FOOD.SUPPLY"
    BADWATER    "CONTAMINATED.WATER.SUPPLY"
    BIO         "BIOLOGICAL.HAZARD"
    CHEM        "CHEMICAL.HAZARD"
    COMMOUT     "COMMUNICATIONS.OUTAGE"
    DISASTER    "DISASTER"
    DISEASE     "DISEASE"
    EPIDEMIC    "EPIDEMIC"
    FOODSHRT    "FOOD.SHORTAGE"
    FUELSHRT    "FUEL.SHORTAGE"
    GARBAGE     "GARBAGE.IN.THE.STREETS"
    INDSPILL    "INDUSTRIAL.SPILL"
    MOSQUE      "DAMAGE.TO.MOSQUE"
    NOWATER     "NO.WATER"
    ORDNANCE    "UNEXPLODED.ORDNANCE"
    PIPELINE    "OIL.PIPELINE.FIRE"
    POWEROUT    "POWER.OUTAGE"
    REFINERY    "OIL.REFINERY.FIRE"
    SEWAGE      "SEWAGE.SPILL"
}

# List of eenvsit values
::projectlib::typewrapper ::projectlib::leenvsit \
    snit::listtype -type ::projectlib::eenvsit 


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
::projectlib::typewrapper ::projectlib::rgain snit::double -min 0.0

# Group Relationships
::marsutil::range ::projectlib::rgrouprel \
    -min -1.0 -max 1.0 -format "%+4.1f"


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
