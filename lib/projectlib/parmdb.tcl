#-----------------------------------------------------------------------
# TITLE:
#    parmdb.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena model parameter database
#
#    The module delegates most of its function to parmset(n).
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export parmdb
}

#-------------------------------------------------------------------
# parm

snit::type ::projectlib::parmdb {
    # Make it a singleton
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Typecomponents

    typecomponent ps ;# The parmset(n) object

    #-------------------------------------------------------------------
    # Type Variables

    # Name of the defaults file; set by init
    typevariable defaultsFile

    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod * to ps

    # init
    #
    # Initializes the module

    typemethod init {} {
        # Don't initialize twice.
        if {$ps ne ""} {
            return
        }

        # FIRST, set the defaults file name
        set defaultsFile [file join ~ .athena defaults.parmdb]

        # NEXT, create the parmset.
        set ps [parmset %AUTO%]

        # NEXT, define the "sim" parameters

        $ps subset sim {
            Parameters which affect the behavior of the simulation in
            general.
        }

        $ps define sim.tickSize ::marsutil::ticktype {1 day} {
            Defines the size of the simulation time tick, i.e., the 
            resolution of the simulation clock.  The time tick can be 
            (within reason) any positive number of minutes, hours, or days, 
            expressed as "<number> <units>", e.g., "1 minute", "2 minutes",
            "1 hour", "2 hours", "1 day", "2 days".  This parameter
            cannot be changed at run-time.
        }

        # NEXT, Activity Parameters
        #

        $ps subset activity {
            Parameters which affect the computation of group activity
            coverage.
        }

        $ps subset activity.FRC {
            Parameters which affect the computation of force group 
            activity coverage.
        }

        $ps subset activity.ORG {
            Parameters which affect the computation of organization group 
            activity coverage.
        }

        # FRC activities
        foreach a {
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
            CRIMINAL_ACTIVITIES
            CURFEW
            GUARD
            PATROL
            PRESENCE
            PSYOP
        } {
            $ps subset activity.FRC.$a {
                Parameters relating to this force activity.
            }

            $ps define activity.FRC.$a.minSecurity ::projectlib::qsecurity L {
                Minimum security level required to conduct this
                activity.
            }

            $ps define activity.FRC.$a.coverage ::simlib::coverage {
                25.0 1000
            } {
                The parameters (c, d) that determine the
                coverage fraction function for this force activity.  Coverage
                depends on the asset density, which is the number
                of personnel per d people in the population.  If the 
                density is 0, the coverage is 0.  The coverage 
                fraction increases to 2/3 when density is c.
            }
        }

        # ORG activities
        foreach a {
            CMO_CONSTRUCTION
            CMO_EDUCATION
            CMO_EMPLOYMENT
            CMO_HEALTHCARE
            CMO_INDUSTRY
            CMO_INFRASTRUCTURE
            CMO_OTHER
        } {
            $ps subset activity.ORG.$a {
                Parameters relating to this organization activity.
            }

            $ps subset activity.ORG.$a.minSecurity {
                Minimum security levels required to conduct this
                activity, by organization type.
            }

            foreach orgtype [eorgtype names] {
                 $ps define activity.ORG.$a.minSecurity.$orgtype \
                     ::projectlib::qsecurity H {
                         Minimum security level required to conduct this
                         activity.
                     }
            }
 
            $ps define activity.ORG.$a.coverage ::simlib::coverage {
                25.0 1000
            } {
                The parameters (c, d) that determine the
                coverage fraction function for this activity.  Coverage
                depends on the asset density, which is the number
                of personnel per d people in the population.  If the 
                density is 0, the coverage is 0.  The coverage 
                fraction increases to 2/3 when density is c.
            }
         }

        # FRC Activities

        # Activity: PRESENCE
        $ps setdefault activity.FRC.PRESENCE.minSecurity            N
        $ps setdefault activity.FRC.PRESENCE.coverage               {25 1000}

        # Activity: CHECKPOINT
        $ps setdefault activity.FRC.CHECKPOINT.minSecurity          L
        $ps setdefault activity.FRC.CHECKPOINT.coverage             {25 1000}

        # Activity: CMO_CONSTRUCTION
        $ps setdefault activity.FRC.CMO_CONSTRUCTION.minSecurity    H
        $ps setdefault activity.FRC.CMO_CONSTRUCTION.coverage       {20 1000}

        # Activity: CMO_DEVELOPMENT
        $ps setdefault activity.FRC.CMO_DEVELOPMENT.minSecurity     M
        $ps setdefault activity.FRC.CMO_DEVELOPMENT.coverage        {25 1000}

        # Activity: CMO_EDUCATION
        $ps setdefault activity.FRC.CMO_EDUCATION.minSecurity       H
        $ps setdefault activity.FRC.CMO_EDUCATION.coverage          {20 1000}

        # Activity: CMO_EMPLOYMENT
        $ps setdefault activity.FRC.CMO_EMPLOYMENT.minSecurity      H
        $ps setdefault activity.FRC.CMO_EMPLOYMENT.coverage         {20 1000}

        # Activity: CMO_HEALTHCARE
        $ps setdefault activity.FRC.CMO_HEALTHCARE.minSecurity      H
        $ps setdefault activity.FRC.CMO_HEALTHCARE.coverage         {20 1000}

        # Activity: CMO_INDUSTRY
        $ps setdefault activity.FRC.CMO_INDUSTRY.minSecurity        H
        $ps setdefault activity.FRC.CMO_INDUSTRY.coverage           {20 1000}

        # Activity: CMO_INFRASTRUCTURE
        $ps setdefault activity.FRC.CMO_INFRASTRUCTURE.minSecurity  H
        $ps setdefault activity.FRC.CMO_INFRASTRUCTURE.coverage     {20 1000}

        # Activity: CMO_OTHER
        $ps setdefault activity.FRC.CMO_OTHER.minSecurity           H
        $ps setdefault activity.FRC.CMO_OTHER.coverage              {20 1000}

        # Activity: CMO_LAW_ENFORCEMENT
        $ps setdefault activity.FRC.CMO_LAW_ENFORCEMENT.minSecurity M
        $ps setdefault activity.FRC.CMO_LAW_ENFORCEMENT.coverage    {25 1000}

        # Activity: COERCION
        $ps setdefault activity.FRC.COERCION.minSecurity            M
        $ps setdefault activity.FRC.COERCION.coverage               {12 1000}

        # Activity: CRIMINAL
        $ps setdefault activity.FRC.CRIMINAL_ACTIVITIES.minSecurity M
        $ps setdefault activity.FRC.CRIMINAL_ACTIVITIES.coverage    {10 1000}

        # Activity: CURFEW
        $ps setdefault activity.FRC.CURFEW.minSecurity              M
        $ps setdefault activity.FRC.CURFEW.coverage                 {25 1000}

        # Activity: GUARD
        $ps setdefault activity.FRC.GUARD.minSecurity               L
        $ps setdefault activity.FRC.GUARD.coverage                  {25 1000}

        # Activity: PATROL
        $ps setdefault activity.FRC.PATROL.minSecurity              L
        $ps setdefault activity.FRC.PATROL.coverage                 {25 1000}

        # Activity: PSYOP
        $ps setdefault activity.FRC.PSYOP.minSecurity               M
        $ps setdefault activity.FRC.PSYOP.coverage                  {1 50000}

        # ORG Activities

        # Activity: CMO_CONSTRUCTION
        $ps setdefault activity.ORG.CMO_CONSTRUCTION.minSecurity.IGO   H
        $ps setdefault activity.ORG.CMO_CONSTRUCTION.minSecurity.NGO   H
        $ps setdefault activity.ORG.CMO_CONSTRUCTION.minSecurity.CTR   M
        $ps setdefault activity.ORG.CMO_CONSTRUCTION.coverage          {20 1000}

        # Activity: CMO_EDUCATION
        $ps setdefault activity.ORG.CMO_EDUCATION.minSecurity.IGO      H
        $ps setdefault activity.ORG.CMO_EDUCATION.minSecurity.NGO      H
        $ps setdefault activity.ORG.CMO_EDUCATION.minSecurity.CTR      M
        $ps setdefault activity.ORG.CMO_EDUCATION.coverage             {20 1000}

        # Activity: CMO_EMPLOYMENT
        $ps setdefault activity.ORG.CMO_EMPLOYMENT.minSecurity.IGO     H
        $ps setdefault activity.ORG.CMO_EMPLOYMENT.minSecurity.NGO     H
        $ps setdefault activity.ORG.CMO_EMPLOYMENT.minSecurity.CTR     M
        $ps setdefault activity.ORG.CMO_EMPLOYMENT.coverage            {20 1000}

        # Activity: CMO_HEALTHCARE
        $ps setdefault activity.ORG.CMO_HEALTHCARE.minSecurity.IGO     H
        $ps setdefault activity.ORG.CMO_HEALTHCARE.minSecurity.NGO     H
        $ps setdefault activity.ORG.CMO_HEALTHCARE.minSecurity.CTR     M
        $ps setdefault activity.ORG.CMO_HEALTHCARE.coverage            {20 1000}

        # Activity: CMO_INDUSTRY
        $ps setdefault activity.ORG.CMO_INDUSTRY.minSecurity.IGO       H
        $ps setdefault activity.ORG.CMO_INDUSTRY.minSecurity.NGO       H
        $ps setdefault activity.ORG.CMO_INDUSTRY.minSecurity.CTR       M
        $ps setdefault activity.ORG.CMO_INDUSTRY.coverage              {20 1000}

        # Activity: CMO_INFRASTRUCTURE
        $ps setdefault activity.ORG.CMO_INFRASTRUCTURE.minSecurity.IGO H
        $ps setdefault activity.ORG.CMO_INFRASTRUCTURE.minSecurity.NGO H
        $ps setdefault activity.ORG.CMO_INFRASTRUCTURE.minSecurity.CTR M
        $ps setdefault activity.ORG.CMO_INFRASTRUCTURE.coverage        {20 1000}

        # Activity: CMO_OTHER
        $ps setdefault activity.ORG.CMO_OTHER.minSecurity.IGO          H
        $ps setdefault activity.ORG.CMO_OTHER.minSecurity.NGO          H
        $ps setdefault activity.ORG.CMO_OTHER.minSecurity.CTR          M
        $ps setdefault activity.ORG.CMO_OTHER.coverage                 {20 1000}

        # NEXT, Force/Volatility/Security Parameters
        $ps subset force {
            Parameters which affect the neighborhood force analysis models.
        }

        $ps define force.mood ::simlib::rfraction 0.2 {
            Dial that controls the extent to which a civilian group's mood 
            in a neighborhood affects its force in that neighborhood.
            At 0.0, mood has no effect.  At 1.0, the group's force will
            be doubled if the mood is -100.0 (perfectly dissatisfied) and 
            zeroed  if the mood is +100 (perfectly satisfied).  At the
            default value of 0.2, the effect changes from 1.2 
            when perfectly dissatisfied to 0.8 when perfectly satisfied.
            (This value is denoted "b" in the Athena Analyst Guide.)
        }

        $ps define force.population ::simlib::rfraction 0.01 {
            Dial that controls the fraction of a civilian group's 
            population in a neighborhood  
            that counts toward that group's force in the 
            neighborhood.  Must be no less than 0. (This value is denoted 
            "a" in the Athena Analyst Guide.)
        }

        $ps define force.proximity ::projectlib::rgain 0.1 {
            Dial that controls the extent to which nearby 
            neighborhoods contribute to a group's force in a neighborhood.
            This dial should be larger if neighborhoods are small, and
            smaller if neighborhoods are large.  Set it to 0.0 if 
            nearby neighborhoods have no effect.  Must be no less than
            0.  (This value is denoted "h" in the Athena Analyst Guide.)
        }

        $ps define force.volatility ::projectlib::rgain 1.0 {
            Dial that controls the affect of neighborhood volatility
            on the security of each group in the neighborhood.  Set to 0
            to ignore volatility altogether.  Must be no less than 0.
            (This value is denoted "v" in the Athena Analyst Guide.)
        }

        $ps subset force.demeanor {
            Dial that determines the effect of demeanor on a group's
            force.  Must be no less than 0; set to 1.0 if demeanor should
            have no effect.
        }

        foreach {name value} {
            APATHETIC  0.3
            AVERAGE    1.0
            AGGRESSIVE 1.5
        } {
            $ps define force.demeanor.$name ::projectlib::rgain $value "
                Dial that determines the effect of $name demeanor 
                on a group's force.  Must be no less than 0; set to 1.0 
                if demeanor should have no effect.
            "
        }

        $ps subset force.forcetype {
            For units belonging to force groups, this set of dials
            determines the contribution to force of each person in the unit,
            based on the group's force type.  Must be no less 
            than 0.
        }

        foreach {name value} {
            REGULAR       25
            PARAMILITARY  15
            POLICE        10
            IRREGULAR     20
            CRIMINAL       8
        } {
            $ps define force.forcetype.$name ::projectlib::rgain $value "
                This dial determines the contribution to force of each
                person in a unit, where that unit belongs to an
                force group of force type $name.
                Must be no less than 0.
            "
        }

        $ps subset force.orgtype {
            For units belonging to organization groups, this set of dials
            determines the contribution to force of each person in the unit,
            based on the group's organization type.  Must be no less 
            than 0.
        }

        foreach {name value} {
            NGO 0.0
            IGO 0.0
            CTR 2.0
        } {
            $ps define force.orgtype.$name ::projectlib::rgain $value "
                This dial determines the contribution to force of each
                person in a unit, where that unit belongs to an
                organization group of organization type $name.
                Must be no less than 0.
            "
        }

        # NEXT, define gram parameters
        $ps slave add [list ::simlib::gram parm]

        # NEXT, define rmf parameters
        $ps slave add [list ::simlib::rmf parm]
    }

    # defaults save
    #
    # Saves the current parameters as the default for future
    # scenarios, by saving ~/.athena/defaults.parmdb.

    typemethod {defaults save} {} {
        $ps save $defaultsFile
        return
    }

    # defaults clear
    #
    # Clears the saved defaults by deleting ~/.athena/defaults.parmdb.

    typemethod {defaults clear} {} {
        if {[file exists $defaultsFile]} {
            file delete $defaultsFile
        }
        return
    }

    # defaults load
    #
    # Loads the parameters from the defaults file, if any.  Otherwise,
    # the parameters are reset to the normal defaults.

    typemethod {defaults load} {} {
        if {[file exists $defaultsFile]} {
            $ps load $defaultsFile -safe
        } else {
            $ps reset
        }

        return
    }
}

