#-----------------------------------------------------------------------
# TITLE:
#	simtypes.tcl
#
# AUTHOR:
#	Will Duquette
#
# DESCRIPTION:
#       Mars: simlib(n) module: Type Definitions
#
# 	This module defines basic data types used by simlib(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::simlib:: {
    namespace export   \
        egrouptype     \
        eproximity     \
        qcooperation   \
        qduration      \
        qmag           \
        qrel           \
        qsaliency      \
        qsat           \
        qtrend         \
        rfraction      \
        rmagnitude
}

#-----------------------------------------------------------------------
# Qualities
#
# Qualities relate English-language ratings, like "Very Good" to numeric
# values.  All quality names begin with "q".

# Cooperation
::marsutil::quality ::simlib::qcooperation {
    AC "Always Cooperative"      99.9 100.0 100.0
    VC "Very Cooperative"        80.0  90.0  99.9
    C  "Cooperative"             60.0  70.0  80.0
    MC "Marginally Cooperative"  40.0  50.0  60.0
    U  "Uncooperative"           20.0  30.0  40.0
    VU "Very Uncooperative"       1.0  10.0  20.0
    NC "Never Cooperative"        0.0   0.0   1.0
} -min 0.0 -max 100.0 -format {%5.1f} -bounds yes

# Reaction Time, in days, for GRAM level events
# 
# TBD: We'll be replacing this with just a time in decimal days.
::marsutil::quality ::simlib::qduration {
    XL "X_LONG"  5.0
    L  "LONG"    2.5
    M  "MEDIUM"  1.0
    S  "SHORT"   0.1
    XS "X_SHORT" 0.042
} -format {%3.1f} -min 0.0

# Magnitude: satisfaction and cooperation inputs
::marsutil::quality ::simlib::qmag {
    XXXXL+ "XXXX_LARGE_PLUS"   30.0
    XXXL+  "XXX_LARGE_PLUS"    20.0
    XXL+   "XX_LARGE_PLUS"     15.0
    XL+    "X_LARGE_PLUS"      10.0
    L+     "LARGE_PLUS"         7.5
    M+     "MEDIUM_PLUS"        5.0
    S+     "SMALL_PLUS"         3.0
    XS+    "X_SMALL_PLUS"       2.0
    XXS+   "XX_SMALL_PLUS"      1.5
    XXXS+  "XXX_SMALL_PLUS"     1.0
    XXXS-  "XXX_SMALL_MINUS"   -1.0
    XXS-   "XX_SMALL_MINUS"    -1.5
    XS-    "X_SMALL_MINUS"     -2.0
    S-     "SMALL_MINUS"       -3.0
    M-     "MEDIUM_MINUS"      -5.0
    L-     "LARGE_MINUS"       -7.5
    XL-    "X_LARGE_MINUS"    -10.0
    XXL-   "XX_LARGE_MINUS"   -15.0
    XXXL-  "XXX_LARGE_MINUS"  -20.0
    XXXXL- "XXXX_LARGE_MINUS" -30.0
} -format {%5.2f}

# Relationship between two groups
::marsutil::quality ::simlib::qrel {
    FRIEND  "Friend"      0.3   0.5   1.0
    NEUTRAL "Neutral"    -0.1   0.1   0.3
    ENEMY   "Enemy"      -1.0  -0.5  -0.1
} -bounds yes -format {%+4.1f}

# Saliency (Of a concern)
::marsutil::quality ::simlib::qsaliency {
    CR "Crucial"         1.000
    VI "Very Important"  0.850
    I  "Important"       0.700
    LI "Less Important"  0.550
    UN "Unimportant"     0.400
    NG "Negligible"      0.000
} -min 0.0 -max 1.0 -format {%5.3f}

# Satisfaction
::marsutil::quality ::simlib::qsat {
    VS "Very Satisfied"     80.0
    S  "Satisfied"          40.0
    A  "Ambivalent"          0.0
    D  "Dissatisfied"      -40.0
    VD "Very Dissatisfied" -80.0
} -min -100.0 -max 100.0 -format {%7.2f}


# Satisfaction: Long-Term Trend
::marsutil::quality ::simlib::qtrend {
    VH "Very High"  8.0
    H  "High"       4.0
    N  "Neutral"   -1.0
    L  "Low"       -4.0
    VL "Very Low"  -8.0
} -format {%4.1f}

    
#-------------------------------------------------------------------
# Enumerations
#
# By convention, enumeration names begin with the letter "e".


# Group Types

::marsutil::enum ::simlib::egrouptype {
    CIV "CIVILIAN"
    ORG "ORGANIZATION"
    FRC "FORCE"
}


# Neighborhood Proximity
#
# 0=here, 1=near, 2=far, 3=remote
::marsutil::enum ::simlib::eproximity {
    HERE   "Here"
    NEAR   "Near"
    FAR    "Far"
    REMOTE "Remote"
}

#-------------------------------------------------------------------
# Range and Integer Types

# Fraction
::marsutil::range ::simlib::rfraction \
    -min 0.0 -max 1.0 -format "%4.2f"

# Non-negative decimal numbers
::marsutil::range ::simlib::rmagnitude \
    -min 0.0 -format "%.2f"







