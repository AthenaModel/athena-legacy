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
        eactivity     \
        ecivconcern   \
        econcern      \
        edemeanor     \
        eforcetype    \
        efrcactivity  \
        eorgactivity  \
        eorgconcern   \
        eorgtype      \
        eproximity    \
        eurbanization \
        eunitshape    \
        eunitsymbol   \
        eyesno        \
        hexcolor      \
        ident         \
        iquantity     \
        polygon       \
        qcooperation  \
        qsaliency     \
        qsat          \
        qtrend        \
        rdays         \
        rgrouprel     \
        unitname      \
        weight
}

#-------------------------------------------------------------------
# Type Wrapper -- wraps snit::<type> instances so they throw
#                 -errorcode INVALID

snit::type ::projectlib::TypeWrapper {
    #---------------------------------------------------------------
    # Components

    component basetype

    #---------------------------------------------------------------
    # Options

    delegate option * to basetype

    #---------------------------------------------------------------
    # Constructor

    # TypeWrapper newtype oldtype ?options....?

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

# Assignable Unit Activities
#
# eactivity       All assignable activities
# efrcactivity    Assignable Force Activities
# eorgactivity    Assignable Org Activities
#
# TBD: This is temporary.  I need an "activity" type that handles
# the entire family of activities, including all subsets.  The
# mapping from activities to situation types should be done in
# the application.

::projectlib::TypeWrapper ::projectlib::efrcactivity snit::enum -values {
    NONE
    CHECKPOINT
    CMO_CONSTRUCTION
    CMO_DEVELOPMENT
    CMO_EDUCATION
    CMO_EMPLOYMENT
    CMO_HEALTHCARE
    CMO_INDUSTRY
    CMO_INFRASTRUCTURE
    CMO_LAW_ENFORCEMENT
    CMO_OTHER
    COERCION
    CORDON_AND_SEARCH
    CRIMINAL_ACTIVITIES
    CURFEW
    GUARD
    INTERVIEW_SCREEN
    MILITARY_TRAINING
    PATROL
    PSYOP
}

::projectlib::TypeWrapper ::projectlib::eorgactivity snit::enum -values {
    NONE
    CMO_CONSTRUCTION
    CMO_EDUCATION
    CMO_EMPLOYMENT
    CMO_HEALTHCARE
    CMO_INDUSTRY
    CMO_INFRASTRUCTURE
    CMO_OTHER
}

::marsutil::enum ::projectlib::eactivity {
    NONE                    "None"
    CHECKPOINT              "Checkpoint/Control Point"
    CMO_CONSTRUCTION        "CMO -- Construction"
    CMO_DEVELOPMENT         "CMO -- Development (Light)"
    CMO_EDUCATION           "CMO -- Education"
    CMO_EMPLOYMENT          "CMO -- Employment"
    CMO_HEALTHCARE          "CMO -- Healthcare"
    CMO_INDUSTRY            "CMO -- Industry"
    CMO_INFRASTRUCTURE      "CMO -- Infrastructure"
    CMO_LAW_ENFORCEMENT     "CMO -- Law Enforcement"
    CMO_OTHER               "CMO -- Other"
    COERCION                "Coercion"
    CORDON_AND_SEARCH       "Cordon and Search"
    CRIMINAL_ACTIVITIES     "Criminal Activities"
    CURFEW                  "Curfew"
    GUARD                   "Guard"
    INTERVIEW_SCREEN        "Interview/Screen"
    MILITARY_TRAINING       "Military Training"
    PATROL                  "Patrol"
    PSYOP                   "PSYOP"
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
    police         "Civilian Police"
    criminal       "Criminal"
    medical        "ORG - Medical"
    support        "ORG - Support"
    engineer       "ORG - Engineer"
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


# Neighborhood Proximity
#
# 0=here, 1=near, 2=far, 3=remote
::marsutil::enum ::projectlib::eproximity {
    HERE   "Here"
    NEAR   "Near"
    FAR    "Far"
    REMOTE "Remote"
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

#-------------------------------------------------------------------
# Qualities

# Cooperation
::marsutil::quality ::projectlib::qcooperation {
    AC "Always Cooperative"      99.9 100.0 100.0
    VC "Very Cooperative"        80.0  90.0  99.9
    C  "Cooperative"             60.0  70.0  80.0
    MC "Marginally Cooperative"  40.0  50.0  60.0
    U  "Uncooperative"           20.0  30.0  40.0
    VU "Very Uncooperative"       1.0  10.0  20.0
    NC "Never Cooperative"        0.0   0.0   1.0
} -min 0.0 -max 100.0 -format {%5.1f} -bounds yes

# Saliency (Of a Factor)
::marsutil::quality ::projectlib::qsaliency {
    CR "Crucial"         1.000
    VI "Very Important"  0.850
    I  "Important"       0.700
    LI "Less Important"  0.550
    UN "Unimportant"     0.400
    NG "Negligible"      0.000
} -min 0.0 -max 1.0 -format {%5.3f}

# Satisfaction
::marsutil::quality ::projectlib::qsat {
    VS "Very Satisfied"     80.0
    S  "Satisfied"          40.0
    A  "Ambivalent"          0.0
    D  "Dissatisfied"      -40.0
    VD "Very Dissatisfied" -80.0
} -min -100.0 -max 100.0 -format {%7.2f}

# Satisfaction: Long-Term Trend
::marsutil::quality ::projectlib::qtrend {
    VH "Very High"  8.0
    H  "High"       4.0
    N  "Neutral"   -1.0
    L  "Low"       -4.0
    VL "Very Low"  -8.0
} -format {%4.1f}

#-----------------------------------------------------------------------
# Integer Types

# iquantity: non-negative integers
::projectlib::TypeWrapper iquantity snit::integer -min 0

#-------------------------------------------------------------------
# Ranges

# Duration in decimal days

::marsutil::range ::projectlib::rdays \
    -min 0.0 -format "%.1f"

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
