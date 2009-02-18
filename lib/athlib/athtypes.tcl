#-----------------------------------------------------------------------
# TITLE:
#    athtypes.tcl
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

namespace eval ::athlib:: {
    namespace export  \
        boolean       \
        ecivconcern   \
        econcern      \
        edemeanor     \
        eforcetype    \
        eorgconcern   \
        eorgtype      \
        eproximity    \
        eurbanization \
        eyesno        \
        hexcolor      \
        ident         \
        polygon       \
        qcooperation  \
        qsaliency     \
        qsat          \
        qtrend        \
        rdays         \
        rgrouprel     \
        weight
}

#-------------------------------------------------------------------
# Enumerations

# Civilian Concerns
::marsutil::enum ::athlib::ecivconcern {
    AUT "Autonomy"
    SFT "Physical Safety"
    CUL "Culture"
    QOL "Quality of Life"
}


# Organization Concerns
::marsutil::enum ::athlib::eorgconcern {
    CAS "Casualties"
}


# All Concerns
::marsutil::enum ::athlib::econcern \
    [concat [::athlib::ecivconcern deflist] [::athlib::eorgconcern deflist]]


# Civilian Group Demeanor
::marsutil::enum ::athlib::edemeanor {
    APATHETIC  "Apathetic"
    AVERAGE    "Average"
    AGGRESSIVE "Aggressive"
}


# Force Group Type
::marsutil::enum ::athlib::eforcetype {
    REGULAR        "Regular Military"
    PARAMILITARY   "Paramilitary"
    POLICE         "Police"
    IRREGULAR      "Irregular Military"
    CRIMINAL       "Organized Crime"
}


# Org Group Type
::marsutil::enum ::athlib::eorgtype {
    NGO "Non-Governmental Organization"
    IGO "Intergovernmental Organization"
    CTR "Contractor"
}


# Neighborhood Proximity
#
# 0=here, 1=near, 2=far, 3=remote
::marsutil::enum ::athlib::eproximity {
    HERE   "Here"
    NEAR   "Near"
    FAR    "Far"
    REMOTE "Remote"
}


# Urbanization Level
::marsutil::enum ::athlib::eurbanization {
    RURAL        "Rural"
    SUBURBAN     "Suburban"
    URBAN        "Urban"
}

# Yes/No
::marsutil::enum ::athlib::eyesno {
    YES    "Yes"
    NO     "No"
}

#-------------------------------------------------------------------
# Qualities

# Cooperation
::marsutil::quality ::athlib::qcooperation {
    AC "Always Cooperative"      99.9 100.0 100.0
    VC "Very Cooperative"        80.0  90.0  99.9
    C  "Cooperative"             60.0  70.0  80.0
    MC "Marginally Cooperative"  40.0  50.0  60.0
    U  "Uncooperative"           20.0  30.0  40.0
    VU "Very Uncooperative"       1.0  10.0  20.0
    NC "Never Cooperative"        0.0   0.0   1.0
} -min 0.0 -max 100.0 -format {%5.1f} -bounds yes

# Saliency (Of a Factor)
::marsutil::quality ::athlib::qsaliency {
    CR "Crucial"         1.000
    VI "Very Important"  0.850
    I  "Important"       0.700
    LI "Less Important"  0.550
    UN "Unimportant"     0.400
    NG "Negligible"      0.000
} -min 0.0 -max 1.0 -format {%5.3f}

# Satisfaction
::marsutil::quality ::athlib::qsat {
    VS "Very Satisfied"     80.0
    S  "Satisfied"          40.0
    A  "Ambivalent"          0.0
    D  "Dissatisfied"      -40.0
    VD "Very Dissatisfied" -80.0
} -min -100.0 -max 100.0 -format {%7.2f}

# Satisfaction: Long-Term Trend
::marsutil::quality ::athlib::qtrend {
    VH "Very High"  8.0
    H  "High"       4.0
    N  "Neutral"   -1.0
    L  "Low"       -4.0
    VL "Very Low"  -8.0
} -format {%4.1f}

#-------------------------------------------------------------------
# Ranges

# Duration in decimal days

::marsutil::range ::athlib::rdays \
    -min 0.0 -format "%.1f"

# Group Relationships
::marsutil::range ::athlib::rgrouprel \
    -min -1.0 -max 1.0 -format "%+4.1f"

#-------------------------------------------------------------------
# Boolean type
#
# This differs from the snit::boolean type in that it throws INVALID.

snit::type ::athlib::boolean {
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

snit::type ::athlib::hexcolor {
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

snit::type ::athlib::ident {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Public Type Methods

    # validate name
    #
    # name    Possibly, an identifier
    #
    # Identifiers should begin with a letter, and contain only letters
    # and digits.

    typemethod validate {name} {
        if {![regexp {^[A-Z][A-Z0-9]*$} $name]} {
            return -code error -errorcode INVALID \
           "Identifiers should begin with a letter and contain only letters or digits"
        }

        return $name
    }
}

#-----------------------------------------------------------------------
# polygon type

snit::type ::athlib::polygon {
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

snit::type ::athlib::weight {
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









