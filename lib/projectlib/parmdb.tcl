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
# First, define the parameter value types used in this database

# Nominal coverage
::marsutil::range ::projectlib::parmdb_nomcoverage \
    -min 0.1 -max 1.0 -format "%+5.2f"


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

            $ps define activity.FRC.$a.assignedToActive \
                ::projectlib::ipositive 1 {
                    Number of personnel which must be assigned to the
                    activity to yield one person actively performing the
                    activity given a typical schedule, i.e., a 24x7 activity
                    requires the assigned personnel to work shifts.
                }

            $ps define activity.FRC.$a.coverage ::simlib::coverage {
                25.0 1000
            } {
                The parameters (c, d) that determine the
                coverage fraction function for this force activity.  Coverage
                depends on the asset density, which is the number
                of active personnel per d people in the population.  If the 
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

            $ps define activity.ORG.$a.assignedToActive \
                ::projectlib::ipositive 1 {
                    Number of personnel which must be assigned to the
                    activity to yield one person actively performing the
                    activity given a typical schedule, i.e., a 24x7 activity
                    requires the assigned personnel to work shifts.
                }

 
            $ps define activity.ORG.$a.coverage ::simlib::coverage {
                25.0 1000
            } {
                The parameters (c, d) that determine the
                coverage fraction function for this activity.  Coverage
                depends on the asset density, which is the number
                of active personnel per d people in the population.  If the 
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

        # ada.* parameters
        $ps subset ada {
            Athena Driver Assessment rule/rule set parameters.
        }

        # Global parameters
        #
        # TBD

        # Actsit global parameters
        $ps subset ada.actsit {
            Parameters for the activity situation rule sets in general.
        }

        $ps define ada.actsit.nominalCoverage \
            ::projectlib::parmdb_nomcoverage 0.66 \
            {
                The nominal coverage fraction for activity rule sets.  
                Input magnitudes are specified for this nominal coverage, 
                i.e., if a change is specified as "cov * M+" the input 
                will be "M+" when "cov" equals the nominal coverage.  The 
                valid range is 0.1 to 1.0.
        }

        # Ensit global parameters
        $ps subset ada.ensit {
            Parameters for the environmental situation rule sets in general.
        }

        $ps define ada.ensit.nominalCoverage \
            ::projectlib::parmdb_nomcoverage 1.0 \
            {
                The nominal coverage fraction for environmental
                situation rule sets.
                Input magnitudes are specified for this nominal coverage, 
                i.e., if a change is specified as "cov * M+" the input 
                will be "M+" when "cov" equals the nominal coverage.  The 
                valid range is 0.1 to 1.0.
        }

        # First, give each an "active" flag.
        foreach name [eadaruleset names] {
            $ps subset ada.$name "
                Parameters for ADA rule set $name.
            "

            $ps define ada.$name.active ::projectlib::boolean yes {
                Indicates whether the rule set is active or not.
            }

            # NEXT, set the default cause to the first one, it will
            # be overridden below.
            set causedef [ecause name 0]

            $ps define ada.$name.cause ::projectlib::ecause $causedef {
                The "cause" for all GRAM inputs produced by this
                rule set.  The value must be an ecause(n) short name.
            }

            $ps define ada.$name.nearFactor ::simlib::rfraction 0.25 {
                Strength of indirect satisfaction effects in neighborhoods
                which consider themselves "near" to the neighborhood in
                which the rule set fires.
            }

            $ps define ada.$name.farFactor ::simlib::rfraction 0.1 {
                Strength of indirect satisfaction effects in neighborhoods
                which consider themselves "far" from the neighborhood in
                which the rule set fires.
            }


            # Add standard parameters for Activity rule sets
            if {$name in {
                CHKPOINT
                CMOCONST
                CMODEV
                CMOEDU
                CMOEMP
                CMOIND
                CMOINF
                CMOLAW
                CMOMED
                CMOOTHER
                COERCION
                CRIMINAL
                CURFEW
                GUARD
                ORGCONST
                ORGEDU
                ORGEMP
                ORGIND
                ORGINF
                ORGMED
                ORGOTHER
                PATROL
                PSYOP
            }} {
                $ps define ada.$name.mitigates ::projectlib::leensit {} {
                    List of environmental situation types mitigated by this
                    activity.  Note not all rule sets support this.
                }
            }
        }

        # Rule Set: BADFOOD
        $ps setdefault ada.BADFOOD.cause          HUNGER
        $ps setdefault ada.BADFOOD.nearFactor     0.0
        $ps setdefault ada.BADFOOD.farFactor      0.0

        # Rule Set: BADWATER
        $ps setdefault ada.BADWATER.cause         THIRST
        $ps setdefault ada.BADWATER.nearFactor    0.0
        $ps setdefault ada.BADWATER.farFactor     0.0

        # Rule Set: BIO
        $ps setdefault ada.BIO.cause              BIO
        $ps setdefault ada.BIO.nearFactor         0.5
        $ps setdefault ada.BIO.farFactor          0.25

         # Rule Set: CHEM
        $ps setdefault ada.CHEM.cause             CHEM
        $ps setdefault ada.CHEM.nearFactor        0.1
        $ps setdefault ada.CHEM.farFactor         0.0

       # Rule Set: CHKPOINT
        $ps setdefault ada.CHKPOINT.cause         CHKPOINT
        $ps setdefault ada.CHKPOINT.nearFactor    0.25
        $ps setdefault ada.CHKPOINT.farFactor     0.0

        # Rule Set: CMOCONST
        $ps setdefault ada.CMOCONST.cause         CMOCONST
        $ps setdefault ada.CMOCONST.nearFactor    0.75
        $ps setdefault ada.CMOCONST.farFactor     0.25
        $ps setdefault ada.CMOCONST.mitigates     {
            BADFOOD  BADWATER BIO CHEM COMMOUT DISASTER DISEASE EPIDEMIC 
            FOODSHRT FUELSHRT GARBAGE  INDSPILL MOSQUE  NOWATER ORDNANCE 
            PIPELINE POWEROUT REFINERY SEWAGE
        }

        # Rule Set: CMODEV
        $ps setdefault ada.CMODEV.cause           CMODEV
        $ps setdefault ada.CMODEV.nearFactor      0.5
        $ps setdefault ada.CMODEV.farFactor       0.1

        # Rule Set: CMOEDU
        $ps setdefault ada.CMOEDU.cause           CMOEDU
        $ps setdefault ada.CMOEDU.nearFactor      0.75
        $ps setdefault ada.CMOEDU.farFactor       0.5
        $ps setdefault ada.CMOEDU.mitigates       {}

        # Rule Set: CMOEMP
        $ps setdefault ada.CMOEMP.cause           CMOEMP
        $ps setdefault ada.CMOEMP.nearFactor      0.75
        $ps setdefault ada.CMOEMP.farFactor       0.5
        $ps setdefault ada.CMOEMP.mitigates       {}

        # Rule Set: CMOIND
        $ps setdefault ada.CMOIND.cause           CMOIND
        $ps setdefault ada.CMOIND.nearFactor      0.75
        $ps setdefault ada.CMOIND.farFactor       0.25
        $ps setdefault ada.CMOIND.mitigates       {
            COMMOUT  FOODSHRT FUELSHRT INDSPILL NOWATER PIPELINE
            POWEROUT REFINERY
        }

        # Rule Set: CMOINF
        $ps setdefault ada.CMOINF.cause           CMOINF
        $ps setdefault ada.CMOINF.nearFactor      0.75
        $ps setdefault ada.CMOINF.farFactor       0.25
        $ps setdefault ada.CMOINF.mitigates       {
            BADWATER COMMOUT NOWATER POWEROUT SEWAGE
        }

        # Rule Set: CMOLAW
        $ps setdefault ada.CMOLAW.cause           CMOLAW
        $ps setdefault ada.CMOLAW.nearFactor      0.5
        $ps setdefault ada.CMOLAW.farFactor       0.25

        # Rule Set: CMOMED
        $ps setdefault ada.CMOMED.cause           CMOMED
        $ps setdefault ada.CMOMED.nearFactor      0.75
        $ps setdefault ada.CMOMED.farFactor       0.25
        $ps setdefault ada.CMOMED.mitigates       {
            BIO CHEM DISASTER DISEASE EPIDEMIC
        }

        # Rule Set: CMOOTHER
        $ps setdefault ada.CMOOTHER.cause         CMOOTHER
        $ps setdefault ada.CMOOTHER.nearFactor    0.25
        $ps setdefault ada.CMOOTHER.farFactor     0.1
        $ps setdefault ada.CMOOTHER.mitigates     {
            BADFOOD  BADWATER BIO CHEM COMMOUT DISASTER DISEASE EPIDEMIC 
            FOODSHRT FUELSHRT GARBAGE  INDSPILL MOSQUE  NOWATER ORDNANCE 
            PIPELINE POWEROUT REFINERY SEWAGE
        }

        # Rule Set: COERCION
        $ps setdefault ada.COERCION.cause         COERCION
        $ps setdefault ada.COERCION.nearFactor    0.5
        $ps setdefault ada.COERCION.farFactor     0.2

        # Rule Set: COMMOUT
        $ps setdefault ada.COMMOUT.cause          COMMOUT
        $ps setdefault ada.COMMOUT.nearFactor     0.1
        $ps setdefault ada.COMMOUT.farFactor      0.1

        # Rule Set: CRIMINAL
        $ps setdefault ada.CRIMINAL.cause         CRIMINAL
        $ps setdefault ada.CRIMINAL.nearFactor    0.5
        $ps setdefault ada.CRIMINAL.farFactor     0.2

        # Rule Set: CURFEW
        $ps setdefault ada.CURFEW.cause           CURFEW
        $ps setdefault ada.CURFEW.nearFactor      0.5
        $ps setdefault ada.CURFEW.farFactor       0.0

        # Rule Set: DISASTER
        $ps setdefault ada.DISASTER.cause          DISASTER
        $ps setdefault ada.DISASTER.nearFactor     0.5
        $ps setdefault ada.DISASTER.farFactor      0.25

        # Rule Set: DISEASE
        $ps setdefault ada.DISEASE.cause          SICKNESS
        $ps setdefault ada.DISEASE.nearFactor     0.25
        $ps setdefault ada.DISEASE.farFactor      0.0

        # Rule Set: EPIDEMIC
        $ps setdefault ada.EPIDEMIC.cause         SICKNESS
        $ps setdefault ada.EPIDEMIC.nearFactor    0.5
        $ps setdefault ada.EPIDEMIC.farFactor     0.2

        # Rule Set: FOODSHRT
        $ps setdefault ada.FOODSHRT.cause         HUNGER
        $ps setdefault ada.FOODSHRT.nearFactor    0.0
        $ps setdefault ada.FOODSHRT.farFactor     0.0

        # Rule Set: FUELSHRT
        $ps setdefault ada.FUELSHRT.cause         FUELSHRT
        $ps setdefault ada.FUELSHRT.nearFactor    0.0
        $ps setdefault ada.FUELSHRT.farFactor     0.0

        # Rule Set: GARBAGE
        $ps setdefault ada.GARBAGE.cause          GARBAGE
        $ps setdefault ada.GARBAGE.nearFactor     0.2
        $ps setdefault ada.GARBAGE.farFactor      0.0

        # Rule Set: GUARD
        $ps setdefault ada.GUARD.cause            GUARD
        $ps setdefault ada.GUARD.nearFactor       0.5
        $ps setdefault ada.GUARD.farFactor        0.0

        # Rule Set: INDSPILL
        $ps setdefault ada.INDSPILL.cause         INDSPILL
        $ps setdefault ada.INDSPILL.nearFactor    0.0
        $ps setdefault ada.INDSPILL.farFactor     0.0

        # Rule Set: MOSQUE
        $ps setdefault ada.MOSQUE.cause           MOSQUE
        $ps setdefault ada.MOSQUE.nearFactor      0.2
        $ps setdefault ada.MOSQUE.farFactor       0.1

        # Rule Set: NOWATER
        $ps setdefault ada.NOWATER.cause          THIRST
        $ps setdefault ada.NOWATER.nearFactor     0.0
        $ps setdefault ada.NOWATER.farFactor      0.0

        # Rule Set: ORDNANCE
        $ps setdefault ada.ORDNANCE.cause         ORDNANCE
        $ps setdefault ada.ORDNANCE.nearFactor    0.2
        $ps setdefault ada.ORDNANCE.farFactor     0.0

        # Rule Set: ORGCONST
        $ps setdefault ada.ORGCONST.cause         ORGCONST
        $ps setdefault ada.ORGCONST.nearFactor    0.75
        $ps setdefault ada.ORGCONST.farFactor     0.25
        $ps setdefault ada.ORGCONST.mitigates     {
            BADFOOD BADWATER BIO CHEM COMMOUT DISASTER DISEASE EPIDEMIC 
            FOODSHRT FUELSHRT GARBAGE INDSPILL MOSQUE  NOWATER ORDNANCE 
            PIPELINE POWEROUT REFINERY SEWAGE
        }

        # Rule Set: ORGEDU
        $ps setdefault ada.ORGEDU.cause           ORGEDU
        $ps setdefault ada.ORGEDU.nearFactor      0.75
        $ps setdefault ada.ORGEDU.farFactor       0.5
        $ps setdefault ada.ORGEDU.mitigates       {}

        # Rule Set: ORGEMP
        $ps setdefault ada.ORGEMP.cause           ORGEMP
        $ps setdefault ada.ORGEMP.nearFactor      0.75
        $ps setdefault ada.ORGEMP.farFactor       0.5
        $ps setdefault ada.ORGEMP.mitigates       {}

        # Rule Set: ORGIND
        $ps setdefault ada.ORGIND.cause           ORGIND
        $ps setdefault ada.ORGIND.nearFactor      0.75
        $ps setdefault ada.ORGIND.farFactor       0.25
        $ps setdefault ada.ORGIND.mitigates       {
            COMMOUT  FOODSHRT FUELSHRT INDSPILL NOWATER PIPELINE
            POWEROUT REFINERY
        }

        # Rule Set: ORGINF
        $ps setdefault ada.ORGINF.cause           ORGINF
        $ps setdefault ada.ORGINF.nearFactor      0.75
        $ps setdefault ada.ORGINF.farFactor       0.25
        $ps setdefault ada.ORGINF.mitigates       {
            BADWATER COMMOUT NOWATER POWEROUT SEWAGE
        }

        # Rule Set: ORGMED
        $ps setdefault ada.ORGMED.cause           ORGMED
        $ps setdefault ada.ORGMED.nearFactor      0.75
        $ps setdefault ada.ORGMED.farFactor       0.25
        $ps setdefault ada.ORGMED.mitigates       {
            BIO CHEM DISASTER DISEASE EPIDEMIC
        }

        # Rule Set: ORGOTHER
        $ps setdefault ada.ORGOTHER.cause         ORGOTHER
        $ps setdefault ada.ORGOTHER.nearFactor    0.25
        $ps setdefault ada.ORGOTHER.farFactor     0.1
        $ps setdefault ada.ORGOTHER.mitigates     {
            BADFOOD  BADWATER BIO CHEM COMMOUT DISASTER DISEASE EPIDEMIC
            FOODSHRT FUELSHRT GARBAGE  INDSPILL MOSQUE  NOWATER ORDNANCE
            PIPELINE POWEROUT REFINERY SEWAGE
        }

        # Rule Set: PATROL
        $ps setdefault ada.PATROL.cause           PATROL
        $ps setdefault ada.PATROL.nearFactor      0.5
        $ps setdefault ada.PATROL.farFactor       0.0

        # Rule Set: PIPELINE
        $ps setdefault ada.PIPELINE.cause         PIPELINE
        $ps setdefault ada.PIPELINE.nearFactor    0.0
        $ps setdefault ada.PIPELINE.farFactor     0.0

        # Rule Set: POWEROUT
        $ps setdefault ada.POWEROUT.cause         POWEROUT
        $ps setdefault ada.POWEROUT.nearFactor    0.1
        $ps setdefault ada.POWEROUT.farFactor     0.0

        # Rule Set: PRESENCE
        $ps setdefault ada.PRESENCE.cause         PRESENCE
        $ps setdefault ada.PRESENCE.nearFactor    0.25
        $ps setdefault ada.PRESENCE.farFactor     0.0

        # Rule Set: PSYOP
        $ps setdefault ada.PSYOP.cause            PSYOP
        $ps setdefault ada.PSYOP.nearFactor       0.1
        $ps setdefault ada.PSYOP.farFactor        0.0
        $ps setdefault ada.PSYOP.mitigates        {BIO CHEM}

        # Rule Set: REFINERY
        $ps setdefault ada.REFINERY.cause         REFINERY
        $ps setdefault ada.REFINERY.nearFactor    0.0
        $ps setdefault ada.REFINERY.farFactor     0.0

        # Rule Set: SEWAGE
        $ps setdefault ada.SEWAGE.cause           SEWAGE
        $ps setdefault ada.SEWAGE.nearFactor      0.2
        $ps setdefault ada.SEWAGE.farFactor       0.0

        # Rule parameters
        foreach rule [lsort -dictionary [eadarule names]] {
            $ps subset ada.$rule "
                Parameters for ADA Rule $rule: [eadarule longname $rule]
            "

            $ps define ada.$rule.satgain ::projectlib::rgain 1.0 "
                Satisfaction gain for ADA Rule $rule.
            "

            $ps define ada.$rule.coopgain ::projectlib::rgain 1.0 "
                Cooperation gain for ADA Rule $rule.
            "
        }

        # ensit.* parameters
        $ps subset ensit {
            Environmental situation parameters, by ensit type.
        }

        foreach name [eensit names] {
            $ps subset ensit.$name "
                Parameters for environmental situation type 
                [eensit longname $name].
            "
            $ps define ensit.$name.spawnTime ::projectlib::ioptdays -1 {
                How long until the ensit spawns other ensits, in days.  If
                -1, the ensit never spawns.
            }

            $ps define ensit.$name.spawns ::projectlib::leensit {} {
                List of ensit types spawned by this ensit type.
            }
        }

        # Tweak the specifics
        $ps setdefault ensit.BADFOOD.spawns                DISEASE
        $ps setdefault ensit.BADFOOD.spawnTime             2

        $ps setdefault ensit.BADWATER.spawns               DISEASE
        $ps setdefault ensit.BADWATER.spawnTime            1

        $ps setdefault ensit.BIO.spawns                    EPIDEMIC
        $ps setdefault ensit.BIO.spawnTime                 4

        $ps setdefault ensit.CHEM.spawns                   DISEASE
        $ps setdefault ensit.CHEM.spawnTime                1

        $ps setdefault ensit.INDSPILL.spawns               DISEASE
        $ps setdefault ensit.INDSPILL.spawnTime            2

        $ps setdefault ensit.NOWATER.spawns                DISEASE
        $ps setdefault ensit.NOWATER.spawnTime             4

        $ps setdefault ensit.SEWAGE.spawns                 DISEASE
        $ps setdefault ensit.SEWAGE.spawnTime              2


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
        return "New scenarios will be created with installation defaults."
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



