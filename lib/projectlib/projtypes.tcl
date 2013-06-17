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
    namespace export     \
        boolean          \
        eactortype       \
        eattroe          \
        eattroenf        \
        eattroeuf        \
        ecause           \
        ecivconcern      \
        ecomparator      \
        econcern         \
        econdition_type  \
        econdition_state \
        ecurse_state     \
        edamrule         \
        edamruleset      \
        edefroeuf        \
        edemeanor        \
        eensit           \
        eforcetype       \
        efrcactivity     \
        egoal_state      \
        egoal_predicate  \
        ehousing         \
        einjectpart      \
        einject_state    \
        eiom_state       \
        eorgactivity     \
        eorgconcern      \
        eorgtype         \
        epagesize        \
        epayload_state   \
        esitstate        \
        etactic_state    \
        etraining        \
        etopic_state     \
        eurbanization    \
        eunitshape       \
        eunitsymbol      \
        eyesno           \
        iticks           \
        ident            \
        ingpopulation    \
        ioptdays         \
        ipercent         \
        ipositive        \
        iquantity        \
        leensit          \
        money            \
        polygon          \
        qcredit          \
        qsecurity        \
        ratrend          \
        rdtrend          \
        rdays            \
        rgain            \
        rnomcoverage     \
        rnonneg          \
        roleid           \
        rolemap          \
        rpercent         \
        rpercentpm       \
        rrate            \
        typewrapper      \
        unitname         \
        weight
}

#-------------------------------------------------------------------
# Type Wrapper -- wraps snit::<type> instances so they throw
#                 -errorcode INVALID

# TBD: This is no longer strictly necessary; Snit types now have
# the correct behavior.

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

# Actor Types
::marsutil::enum ::projectlib::eactortype {
    NORMAL          "Normal"
    PSEUDO          "Pseudo-actor"
}


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
    BADFOOD-1-1   "Food supply begins to be contaminated"
    BADFOOD-1-2   "Food supply continues to be contaminated"
    BADFOOD-2-1   "Food contamination is resolved by locals"

    BADWATER-1-1  "Water supply begins to be contaminated"
    BADWATER-1-2  "Water supply continues to be contaminated"
    BADWATER-2-1  "Water contamination is resolved by locals"

    CHKPOINT-1-1  "Force is manning checkpoints"

    CIVCAS-1-1    "Civilian casualties taken"
    CIVCAS-2-1    "Civilian casualties taken from force group"

    CMOCONST-1-1  "Force is doing construction work"

    CMODEV-1-1    "Force is encouraging light development"

    CMOEDU-1-1    "Force is teaching local civilians"

    CMOEMP-1-1    "Force is providing employment"

    CMOIND-1-1    "Force is aiding industry"

    CMOINF-1-1    "Force is improving infrastructure"

    CMOLAW-1-1    "Force is enforcing the law"

    CMOMED-1-1    "Force is providing health care"

    CMOOTHER-1-1  "Force is doing other CMO activities"

    COERCION-1-1  "Force is coercing local civilians"

    COMMOUT-1-1   "Communications go out"
    COMMOUT-1-2   "Communications remain out"

    CONSUMP-1-1   "Effect of Consumption on Satisfaction"
    CONSUMP-2-1   "Consumption no worse than expected"
    CONSUMP-2-2   "Consumption worse than expected"
    
    CONTROL-1-1   "Neighborhood sees shift in control"
    CONTROL-1-2   "Neighborhood is now in chaos."
    CONTROL-1-3   "Neighborhood is no longer in chaos."
    CONTROL-2-1   "Neighborhood sees shift in control"

    CRIMINAL-1-1  "Force is engaging in criminal activities"

    CULSITE-1-1   "A cultural site is damaged"
    CULSITE-1-2   "Damage has not been resolved"

    CURFEW-1-1    "Force is enforcing a curfew"

    CURSE-1-1     "CURSE Horizontal Relationship Inject"
    CURSE-2-1     "CURSE Vertical Relationship Inject"
    CURSE-3-1     "CURSE Satisfaction Inject"
    CURSE-4-1     "CURSE Cooperation Inject"

    DISASTER-1-1  "Disaster occurred in the neighborhood"
    DISASTER-1-2  "Disaster continues"
    DISASTER-2-1  "Disaster resolved by locals"

    DISEASE-1-1   "Unhealthy conditions begin to cause disease"
    DISEASE-1-2   "Unhealthy conditions continue to cause disease"
    DISEASE-2-1   "Unhealthy conditions are resolved by locals"

    DISPLACED-1-1 "Displaced persons living in neighborhood"

    ENI-1-1       "ENI Services are less than required"
    ENI-1-2       "ENI Services are less than expected"
    ENI-1-3       "ENI Services are as expected"
    ENI-1-4       "ENI Services are better than expected"

    EPIDEMIC-1-1  "Epidemic begins to spread"
    EPIDEMIC-1-2  "Epidemic continues to spread"
    EPIDEMIC-2-1  "Spread of epidemic is halted by locals"

    FOODSHRT-1-1  "Food begins to run short"
    FOODSHRT-1-2  "Food continues to run short"
    FOODSHRT-2-1  "Food shortage is ended by locals"

    FUELSHRT-1-1  "Fuel begins to run short"
    FUELSHRT-1-2  "Fuel continues to be in short supply"
    FUELSHRT-2-1  "Fuel shortage is ended by locals"

    GARBAGE-1-1   "Garbage begins to accumulate"
    GARBAGE-1-2   "Garbage is piled in the streets"
    GARBAGE-2-1   "Garbage is cleaned up by locals"

    GUARD-1-1     "Force is guarding"

    INDSPILL-1-1  "Industrial spill occurs"
    INDSPILL-1-2  "Industrial spill has not been cleaned up"
    INDSPILL-2-1  "Industrial spill is cleaned up by locals"

    IOM-1-1       "Info Ops Message"

    MAGIC-1-1     "Magic Horizontal Relationship Input"
    MAGIC-2-1     "Magic Vertical Relationship Input"
    MAGIC-3-1     "Magic Satisfaction Input"
    MAGIC-4-1     "Magic Cooperation Input"

    MINEFIELD-1-1 "Minefield is placed"
    MINEFIELD-1-2 "Minefield remains"
    MINEFIELD-2-1 "Minefield is cleared by locals"

    MOOD-1-1      "Mood is much worse"
    MOOD-1-2      "Mood is much better"

    NOWATER-1-1   "Water becomes unavailable"
    NOWATER-1-2   "Water continues to be unavailable"
    NOWATER-2-1   "Water supply is restored by locals"

    ORDNANCE-1-1  "Unexploded ordnance is found"
    ORDNANCE-1-2  "Unexploded ordnance remains"
    ORDNANCE-2-1  "Unexploded ordnance is removed by locals"

    ORGCONST-1-1  "ORG is doing construction work"

    ORGEDU-1-1    "ORG is teaching local civilians"

    ORGEMP-1-1    "ORG is employing local civilians"

    ORGIND-1-1    "ORG is aiding industry"

    ORGINF-1-1    "ORG is improving infrastructure"

    ORGMED-1-1    "ORG is providing health care"

    ORGOTHER-1-1  "ORG is doing other CMO activities"

    PATROL-1-1    "Force is patrolling"

    PIPELINE-1-1  "Oil pipeline catches fire"
    PIPELINE-1-2  "Oil pipeline is still burning"
    PIPELINE-2-1  "Oil pipeline fire is extinguished by locals"

    POWEROUT-1-1  "Power goes out"
    POWEROUT-1-2  "Power remains out"
    POWEROUT-2-1  "Power is restored by locals"

    PRESENCE-1-1  "Force is present"

    PSYOP-1-1     "Force is doing PSYOP"

    REFINERY-1-1  "Oil refinery catches fire"
    REFINERY-1-2  "Oil refinery is still burning"
    REFINERY-2-1  "Oil refinery fire is extinguished by locals"

    RELSITE-1-1   "A religious site is damaged"
    RELSITE-1-2   "Damage has not been resolved"
    RELSITE-2-1   "Damage is resolved by locals"

    SEWAGE-1-1    "Sewage begins to pool in the streets"
    SEWAGE-1-2    "Sewage has pooled in the streets"
    SEWAGE-2-1    "Sewage is cleaned up by locals"

    UNEMP-1-1     "Group is suffering from unemployment"
}

# DAM Rule Sets
::marsutil::enum ::projectlib::edamruleset {
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
    CONSUMP   "Consumption of Goods"
    CONTROL   "Shift in Control of Neighborhood"
    CRIMINAL  "Criminal Activities"
    CULSITE   "Damage to Cultural Site/Artifact"
    CURFEW    "Curfew"
    CURSE     "CURSE Attitude Injects"
    DISASTER  "Disaster"
    DISEASE   "Disease"
    DISPLACED "Displaced Persons"
    ENI       "ENI Services"
    EPIDEMIC  "Epidemic"
    FOODSHRT  "Food Shortage"
    FUELSHRT  "Fuel Shortage"
    GARBAGE   "Garbage in the Streets"
    GUARD     "Guard"
    INDSPILL  "Industrial Spill"
    IOM       "Info Ops Message"
    MAGIC     "Magic Attitude Inputs"
    MINEFIELD "Minefield"
    MOOD      "Civilian Mood Changes"
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
    RELSITE   "Damage to Religious Site/Artifact"
    SEWAGE    "Sewage Spill"
    UNEMP     "Unemployment"
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
    CONSUMP   "Consumption of Goods"
    CONTROL   "Shift in Control of Neighborhood"
    CRIMINAL  "Criminal Activities"
    CULSITE   "Damage to Cultural Site/Artifact"
    CURFEW    "Curfew"
    DISASTER  "Disaster"
    DISPLACED "Displaced Persons"
    ENI       "ENI Services"
    FUELSHRT  "Fuel Shortage"
    GARBAGE   "Garbage in the Streets"
    GUARD     "Guard"
    HUNGER    "Hunger"
    INDSPILL  "Industrial Spill"
    IOM       "Info Ops Message"
    MAGIC     "Magic Input"
    MOOD      "Mood"
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
    RELSITE   "Damage to Religious Site/Artifact"
    SEWAGE    "Sewage Spill"
    SICKNESS  "Sickness"
    THIRST    "Thirst"
    UNEMP     "Unemployment"
}

# Civ group housing
::marsutil::enum ::projectlib::ehousing {
    AT_HOME    "At Home"
    DISPLACED  "Displaced"
    IN_CAMP    "In Camp"
}

# Training Levels
::marsutil::enum ::projectlib::etraining {
    PROFICIENT  "Proficient"
    FULL        "Fully Trained"
    PARTIAL     "Partially Trained"
    NONE        "Not Trained"
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



# Concerns
::marsutil::enum ::projectlib::econcern {
    AUT "Autonomy"
    SFT "Physical Safety"
    CUL "Culture"
    QOL "Quality of Life"
}

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
    ONGOING  Ongoing
    RESOLVED Resolved
}

# Goal State.

::marsutil::enum ::projectlib::egoal_state {
    normal   "normal"
    disabled "disabled"
    invalid  "invalid"
}

# IOM State.

::marsutil::enum ::projectlib::eiom_state {
    normal   "normal"
    disabled "disabled"
    invalid  "invalid"
}


# Tactic State

::marsutil::enum ::projectlib::etactic_state {
    normal   "normal"
    disabled "disabled"
    invalid  "invalid"
}

# Topic State

::marsutil::enum ::projectlib::etopic_state {
    normal   "normal"
    disabled "disabled"
    invalid  "invalid"
}

# Condition Type.  Conditions are attached to
# tactics (and possibly other things).

::marsutil::enum ::projectlib::econdition_type {
    CASH      "Cash-on-hand"
    GOAL      "Goal State"
}

# TBD: Add egoal_predicate: MET, UNMET

::marsutil::enum ::projectlib::egoal_predicate {
    MET   "Met"
    UNMET "Unmet"
}

# Condition State.

::marsutil::enum ::projectlib::econdition_state {
    normal   "normal"
    disabled "disabled"
    invalid  "invalid"
}


# Comparator Type.  Used in conditions

::marsutil::enum ::projectlib::ecomparator {
    EQ "equal to"
    GE "greater than or equal to"
    GT "greater than"
    LE "less than or equal to"
    LT "less than"
}

# CURSE State.

::marsutil::enum ::projectlib::ecurse_state {
    normal   "normal"
    disabled "disabled"
    invalid  "invalid"
}

# CURSE Inject State

::marsutil::enum ::projectlib::einject_state {
    normal   "normal"
    disabled "disabled"
    invalid  "invalid"
}

# IOM Payload State

::marsutil::enum ::projectlib::epayload_state {
    normal   "normal"
    disabled "disabled"
    invalid  "invalid"
}


# Urbanization Level
::marsutil::enum ::projectlib::eurbanization {
    ISOLATED     "Isolated"
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
    CULSITE     "DAMAGE.TO.CULTURAL.SITE"
    DISASTER    "DISASTER"
    DISEASE     "DISEASE"
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
    RELSITE     "DAMAGE.TO.RELIGIOUS.SITE"
    SEWAGE      "SEWAGE.SPILL"
}

# List of eensit values
::projectlib::typewrapper ::projectlib::leensit \
    snit::listtype -type ::projectlib::eensit 

# Payload Part Types
::marsutil::enum ::projectlib::epayloadpart {
    COOP  "Cooperation with force group"
    HREL  "Horizontal relationship with group"
    SAT   "Satisfaction with concern"
    VREL  "Vertical relationship with actor"
}

# Curse Input Part Types
::marsutil::enum ::projectlib::einjectpart {
    COOP  "Coop. change"
    HREL  "Horiz. rel. change"
    SAT   "Sat. change"
    VREL  "Vert. rel. change"
}

# Page Sizes for paged myserver tables

::marsutil::enum ::projectlib::epagesize {
    ALL "All items"
    10  "10 items per page"
    20  "20 items per page"
    50  "50 items per page"
    100 "100 items per page"
} -noindex

#-------------------------------------------------------------------
# Qualities

# Credit
::marsutil::quality ::projectlib::qcredit {
    M   "Most"          0.50 0.75 1.00
    S   "Some"          0.20 0.35 0.50
    N   "Negligible"    0.00 0.10 0.20
} -bounds yes -format {%.2f}

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

# iminlines: Minimum value for prefs.maxlines
::projectlib::typewrapper ::projectlib::iminlines snit::integer -min 100

# ipositive: positive integers
::projectlib::typewrapper ::projectlib::ipositive snit::integer -min 1

# iticks: non-negative ticks
::projectlib::typewrapper ::projectlib::iticks snit::integer -min 0

# ioptdays: days with -1 as sentinal
::projectlib::typewrapper ::projectlib::ioptdays snit::integer -min -1

# ipercent: integer percentages
::projectlib::typewrapper ::projectlib::ipercent snit::integer -min 0 -max 100


#-------------------------------------------------------------------
# Ranges

# Ascending/Descending trends
::snit::double ::projectlib::ratrend -min 0.0
::snit::double ::projectlib::rdtrend -max 0.0

# Duration in decimal days

::marsutil::range ::projectlib::rdays \
    -min 0.0 -format "%.1f"

# Fraction
::projectlib::typewrapper ::projectlib::rfraction snit::double \
    -min 0.0 \
    -max 1.0

# Non-negative percentage
::projectlib::typewrapper ::projectlib::rpercent snit::double \
    -min   0.0 \
    -max 100.0 

# Positive or negative percentage
::projectlib::typewrapper ::projectlib::rpercentpm snit::double \
    -min -100.0 \
    -max  100.0 

# Gain setting
::marsutil::range ::projectlib::rgain -min 0.0

# Non-negative real number
::marsutil::range ::projectlib::rnonneg -min 0.0

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
    # and digits. Identifiers that begin with "@" are allowed.

    typemethod validate {name} {
        if {![regexp {^[A-Z][A-Z0-9]*$} $name]} {
            return -code error -errorcode INVALID \
  "Identifiers begin with a letter and contain only letters and digits."
        }

        return $name
    }
}

#-----------------------------------------------------------------------
# roleid type

snit::type ::projectlib::roleid {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate name
    #
    # name    Possibly, a role identifier
    #
    # Role identifiers should begin with "@", and contain only letters
    # and digits. 

    typemethod validate {name} {
        if {![regexp {^[@]?[A-Z]+[A-Z0-9]*$} $name]} {
            return -code error -errorcode INVALID \
  "Role identifiers begin with optional \"@\" followed by a letter and contain only letters and digits."
        }

        if {[string range $name 0 0] ne "@"} {
            return "@$name"
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

#-----------------------------------------------------------------------
# Rolemap type
#
# A rolemap must be a list with a rolename mapping to a gofer dictionary.

snit::type ::projectlib::rolemap {
    # Singleton
    pragma -hasinstances no

    # validate value
    #
    # value    Possibly, a rolemap dictionary
    #
    # Returns an error on failure, the value on success

    typemethod validate {value} {
        if {[llength $value] % 2 != 0} {
            return -code error -errorcode INVALID "$value: not a dictionary"
        }

        set rmap [list]
        foreach {role goferdict} $value {
            set gdict [gofer validate $goferdict]
            lappend rmap $role $gdict
        }

        return $rmap
    }
}

#-----------------------------------------------------------------------
# Money type

# A money value is a string defined as for marsutil::moneyscan.  It is
# converted to a real number.

snit::type ::projectlib::money {
    pragma -hasinstances no

    typemethod validate {value} {
        if {[catch {
            set newValue [::marsutil::moneyscan $value]
        } result]} {
            set scanErr 1
        } else {
            set scanErr 0
        }

        if {$scanErr || $newValue < 0.0} {
            return -code error -errorcode INVALID \
                "invalid money value \"$value\", expected positive numeric value with optional K, M, or B suffix"
        }

        return $newValue
    }
}



