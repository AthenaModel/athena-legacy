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

# Average Loss Exchange Ratio
::marsutil::range ::projectlib::parmdb_aler \
    -min 0.1 -format "%.2f"

# Nominal coverage
::marsutil::range ::projectlib::parmdb_nomcoverage \
    -min 0.1 -max 1.0 -format "%+5.2f"

# Nominal cooperation
::marsutil::range ::projectlib::parmdb_nomcoop \
    -min 10.0 -max 100.0 -format "%5.1f"

# Positive Days
::marsutil::range ::projectlib::parmdb_posdays \
    -min 0.1 -format "%.2f"


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

        # NEXT, create an "in-memory" scenariodb, for concerns
        # and activities.
        set tempdb ${type}::tempdb
        catch {$tempdb destroy}
        scenariodb $tempdb
        $tempdb open :memory:

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

        # NEXT, Athena Attrition Model parameters

        $ps subset aam {
            Parameters which affect the Athena Attrition Model
        }

        $ps define aam.ticksPerTock ::projectlib::ipositive 7 {
            Defines the frequency of attrition assessments, in ticks.  During
            each attrition assessment, Athena computes all normal 
            attrition, applies it, and then determines the attitude
            implications.  Note that Athena assesses the attitude
            implications of magic attrition occuring between tocks at
            the same time.
        }

        # UFvsNF
        $ps subset aam.UFvsNF {
            Parameters for Uniformed Force vs. Non-uniformed Force
            attrition.
        }

        $ps subset aam.UFvsNF.UF {
            Parameters relating to the Uniformed Force in UF vs. NF
            attrition.
        }

        $ps define aam.UFvsNF.UF.coverageFunction ::simlib::coverage {
            25.0 1000
        } {
            The coverage function used for the coverage of the
            Uniformed Force in the neighborhood, based on the number
            of UF personnel in the neighborhood.
        }

        $ps define aam.UFvsNF.UF.nominalCoverage \
            ::projectlib::parmdb_nomcoverage 0.3 {
            The nominal coverage of the Uniformed Force in the
            neighborhood for this algorithm.  When the UF coverage is
            equal to this value, the time-to-find an NF cell will tend
            to be <tt>aam.UFvsNF.UF.timeToFind</tt>.
        }

        $ps define aam.UFvsNF.UF.nominalCooperation \
            ::projectlib::parmdb_nomcoop 35.0 {
            The nominal cooperation of the neighborhood population 
            with the Uniformed Force.  When the actual cooperation is
            equal to this value, the time-to-find an NF cell will tend
            to be <tt>aam.UFvsNF.UF.timeToFind</tt>.
        }

        $ps define aam.UFvsNF.UF.timeToFind \
            ::projectlib::parmdb_posdays 5.0 {
            The average time for the Uniformed Force to find a 
            Non-uniformed Force cell, in days.
        }

        $ps subset aam.UFvsNF.NF {
            Parameters relating to the Non-uniformed Force in UF vs. NF
            attrition.
        }

        $ps define aam.UFvsNF.NF.coverageFunction ::simlib::coverage {
            12.0 1000
        } {
            The coverage function used for the coverage of the
            Non-uniformed Force in the neighborhood, based on the number
            of NF personnel in the neighborhood.
        }

        $ps define aam.UFvsNF.NF.nominalCoverage \
            ::projectlib::parmdb_nomcoverage 0.4 {
            The nominal coverage of the Non-uniformed Force in the
            neighborhood for this algorithm.  When the NF coverage is
            equal to this value, the time-to-find an NF cell will tend
            to be <tt>aam.UFvsNF.UF.timeToFind</tt>.
        }

        $ps define aam.UFvsNF.NF.cellSize \
            ::projectlib::ipositive 7 {
            The average number of Non-uniformed Force personnel per 
            NF cell.  Ultimately, this might be allowed to vary by
            group and neighborhood.
        }

        $ps subset aam.UFvsNF.ECDA {
            The Expected Collateral Damage per Attack, i.e., the
            expected number of civilians killed per non-uniformed cell
            attacked by a uniformed force.  The actual value depends
            on the urbanization level.
        }

        foreach ul [::projectlib::eurbanization names] {
            $ps define aam.UFvsNF.ECDA.$ul ::projectlib::iquantity 0 {
                The ECDA for this urbanization level, i.e., the
                expected number of civilians killed per non-uniformed cell
                attacked by a uniformed force.            
            }
        }

        $ps setdefault aam.UFvsNF.ECDA.RURAL    1
        $ps setdefault aam.UFvsNF.ECDA.SUBURBAN 3
        $ps setdefault aam.UFvsNF.ECDA.URBAN    5

        # NFvsUF

        $ps subset aam.NFvsUF {
            Parameters for Non-uniformed Force vs. Uniformed Force
            attrition.
        }

        $ps subset aam.NFvsUF.UF {
            Parameters relating to the Uniformed Force in NF vs. UF
            attrition.
        }

        $ps define aam.NFvsUF.UF.coverageFunction ::simlib::coverage {
            25.0 1000
        } {
            The coverage function used for the coverage of the
            Uniformed Force in the neighborhood, based on the number
            of UF personnel in the neighborhood.
        }

        $ps define aam.NFvsUF.UF.nominalCoverage \
            ::projectlib::parmdb_nomcoverage 0.2 {
            The nominal coverage of the Uniformed Force in the
            neighborhood for this algorithm.
        }

        $ps subset aam.NFvsUF.HIT_AND_RUN {
            Parameters relating to the Non-uniformed Force in NF vs. UF
            attrition when the Non-uniformed Force is using
            Hit-and-Run tactics.
        }

        $ps define aam.NFvsUF.HIT_AND_RUN.nominalCooperation \
            ::projectlib::parmdb_nomcoop 70.0 {
            The nominal cooperation of the neighborhood civilians
            with the Non-uniformed Force for this algorithm.
        }

        $ps define aam.NFvsUF.HIT_AND_RUN.minUFcasualties \
            ::projectlib::ipositive 4 {
            The number of Uniformed Force personnel the Non-uniformed
            wishes to kill in any hit-and-run attack.
        }

        $ps define aam.NFvsUF.HIT_AND_RUN.maxNFcasualties \
            ::projectlib::ipositive 1 {
            The maximum number of casualties the Non-uniformed Force
            is prepared to take in order to kill the required
            number of Uniformed Force personnel.  If it will cost the
            NF more personnel than this, they will not attack.
        }

        $ps define aam.NFvsUF.HIT_AND_RUN.ALER \
            ::projectlib::parmdb_aler 3.0 {
            The Average Loss Exchange Ratio: the average number of UF
            casualties per NF casualty, assuming that the UF fires
            back.
        }

        $ps subset aam.NFvsUF.STAND_AND_FIGHT {
            Parameters relating to the Non-uniformed Force in NF vs. UF
            attrition when the Non-uniformed Force is using
            Stand-and-Fight tactics.
        }

        $ps define aam.NFvsUF.STAND_AND_FIGHT.nominalCooperation \
            ::projectlib::parmdb_nomcoop 70.0 {
            The nominal cooperation of the neighborhood civilians
            with the Non-uniformed Force for this algorithm.
        }

        $ps define aam.NFvsUF.STAND_AND_FIGHT.minUFcasualties \
            ::projectlib::ipositive 40 {
            The minimum number of Uniformed Force casualties required
            by any stand-and-fight attack.  If the NF cannot kill at
            least this many UF personnel, it will not attack.
        }

        $ps define aam.NFvsUF.STAND_AND_FIGHT.maxNFcasualties \
            ::projectlib::ipositive 10 {
            The number of personnel the Non-uniformed Force
            is willing to expend in a single attack, killing as many
            UF personnel as possible.
        }

        $ps define aam.NFvsUF.STAND_AND_FIGHT.ALER \
            ::projectlib::parmdb_aler 6.0 {
            The Average Loss Exchange Ratio: the average number of UF
            casualties per NF casualty, assuming that the UF fires
            back.
        }

        $ps subset aam.NFvsUF.ECDC {
            The Expected Collateral Damage per Casualty, i.e., the
            expected number of civilians killed per non-uniformed casualty
            when a uniformed force is defending against non-uniformed
            attack.  The actual value depends
            on the urbanization level.
        }

        foreach ul [::projectlib::eurbanization names] {
            $ps define aam.NFvsUF.ECDC.$ul ::projectlib::iquantity 0 {
                The ECDC for this urbanization level, i.e., the
                expected number of civilians killed per non-uniformed casualty
                when a uniformed force is defending.
            }
        }

        $ps setdefault aam.NFvsUF.ECDC.RURAL    6
        $ps setdefault aam.NFvsUF.ECDC.SUBURBAN 12
        $ps setdefault aam.NFvsUF.ECDC.URBAN    18


        # NEXT, Activity Parameters

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

            $ps define activity.FRC.$a.shifts \
                ::projectlib::ipositive 1 {
                    Number of personnel which must be assigned to the
                    activity to yield one person actively performing the
                    activity given a typical schedule, i.e., the number
                    of shifts.  For example, a 24x7 activity will 
                    require the assigned personnel to work three or
                    four shifts. 
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

            $ps define activity.ORG.$a.shifts \
                ::projectlib::ipositive 1 {
                    Number of personnel which must be assigned to the
                    activity to yield one person actively performing the
                    activity given a typical schedule, i.e., the number
                    of shifts.  For example, a 24x7 activity will 
                    require the assigned personnel to work three or
                    four shifts. 
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
        $ps setdefault activity.FRC.PSYOP.minSecurity               L
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

        # dam.* parameters
        $ps subset dam {
            Driver Assessment Model rule/rule set parameters.
        }

        # Global parameters
        #
        # TBD

        # Actsit global parameters
        $ps subset dam.actsit {
            Parameters for the activity situation rule sets in general.
        }

        $ps define dam.actsit.nominalCoverage \
            ::projectlib::parmdb_nomcoverage 0.66 \
            {
                The nominal coverage fraction for activity rule sets.  
                Input magnitudes are specified for this nominal coverage, 
                i.e., if a change is specified as "cov * M+" the input 
                will be "M+" when "cov" equals the nominal coverage.  The 
                valid range is 0.1 to 1.0.
        }

        # Ensit global parameters
        $ps subset dam.ensit {
            Parameters for the environmental situation rule sets in general.
        }

        $ps define dam.ensit.nominalCoverage \
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
        foreach name [edamruleset names] {
            $ps subset dam.$name "
                Parameters for DAM rule set $name.
            "

            $ps define dam.$name.active ::projectlib::boolean yes {
                Indicates whether the rule set is active or not.
            }

            # NEXT, set the default cause to the first one, it will
            # be overridden below.
            set causedef [ecause name 0]

            $ps define dam.$name.cause ::projectlib::ecause $causedef {
                The "cause" for all GRAM inputs produced by this
                rule set.  The value must be an ecause(n) short name.
            }

            $ps define dam.$name.nearFactor ::simlib::rfraction 0.25 {
                Strength of indirect satisfaction effects in neighborhoods
                which consider themselves "near" to the neighborhood in
                which the rule set fires.
            }

            $ps define dam.$name.farFactor ::simlib::rfraction 0.1 {
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
                $ps define dam.$name.mitigates ::projectlib::leensit {} {
                    List of environmental situation types mitigated by this
                    activity.  Note not all rule sets support this.
                }
            }
        }

        # Add parameters for Attrition rule sets
        $ps define dam.CIVCAS.Zsat ::marsutil::zcurve {0.3 1.0 100.0 2.0} {
            Z-curve used to compute the casualty multiplier used in
            the CIVCAS satisfaction rules from the number of civilian
            casualties.
        }

        $ps define dam.CIVCAS.Zcoop ::marsutil::zcurve {0.3 1.0 100.0 2.0} {
            Z-curve used to compute the casualty multiplier used in
            the CIVCAS cooperation rule from the number of civilian
            casualties.
        }

        $ps define dam.ORGCAS.Zsat ::marsutil::zcurve {0.3 1.0 100.0 2.0} {
            Z-curve used to compute the casualty multiplier used in
            the ORGCAS rule set from the number of organization
            casualties.
        }


        # Rule Set: BADFOOD
        $ps setdefault dam.BADFOOD.cause          HUNGER
        $ps setdefault dam.BADFOOD.nearFactor     0.0
        $ps setdefault dam.BADFOOD.farFactor      0.0

        # Rule Set: BADWATER
        $ps setdefault dam.BADWATER.cause         THIRST
        $ps setdefault dam.BADWATER.nearFactor    0.0
        $ps setdefault dam.BADWATER.farFactor     0.0

        # Rule Set: CHKPOINT
        $ps setdefault dam.CHKPOINT.cause         CHKPOINT
        $ps setdefault dam.CHKPOINT.nearFactor    0.25
        $ps setdefault dam.CHKPOINT.farFactor     0.0

        # Rule Set: CIVCAS
        $ps setdefault dam.CIVCAS.cause           CIVCAS
        $ps setdefault dam.CIVCAS.nearFactor      0.25
        $ps setdefault dam.CIVCAS.farFactor       0.1

        # Rule Set: CMOCONST
        $ps setdefault dam.CMOCONST.cause         CMOCONST
        $ps setdefault dam.CMOCONST.nearFactor    0.75
        $ps setdefault dam.CMOCONST.farFactor     0.25
        $ps setdefault dam.CMOCONST.mitigates     {
            BADFOOD  BADWATER COMMOUT  DISASTER DISEASE  DMGCULT DMGSACRED
            EPIDEMIC FOODSHRT FUELSHRT GARBAGE  INDSPILL MINEFIELD NOWATER 
            ORDNANCE PIPELINE POWEROUT REFINERY SEWAGE
        }

        # Rule Set: CMODEV
        $ps setdefault dam.CMODEV.cause           CMODEV
        $ps setdefault dam.CMODEV.nearFactor      0.5
        $ps setdefault dam.CMODEV.farFactor       0.1

        # Rule Set: CMOEDU
        $ps setdefault dam.CMOEDU.cause           CMOEDU
        $ps setdefault dam.CMOEDU.nearFactor      0.75
        $ps setdefault dam.CMOEDU.farFactor       0.5
        $ps setdefault dam.CMOEDU.mitigates       {}

        # Rule Set: CMOEMP
        $ps setdefault dam.CMOEMP.cause           CMOEMP
        $ps setdefault dam.CMOEMP.nearFactor      0.75
        $ps setdefault dam.CMOEMP.farFactor       0.5
        $ps setdefault dam.CMOEMP.mitigates       {}

        # Rule Set: CMOIND
        $ps setdefault dam.CMOIND.cause           CMOIND
        $ps setdefault dam.CMOIND.nearFactor      0.75
        $ps setdefault dam.CMOIND.farFactor       0.25
        $ps setdefault dam.CMOIND.mitigates       {
            COMMOUT  FOODSHRT FUELSHRT INDSPILL NOWATER PIPELINE
            POWEROUT REFINERY
        }

        # Rule Set: CMOINF
        $ps setdefault dam.CMOINF.cause           CMOINF
        $ps setdefault dam.CMOINF.nearFactor      0.75
        $ps setdefault dam.CMOINF.farFactor       0.25
        $ps setdefault dam.CMOINF.mitigates       {
            BADWATER COMMOUT NOWATER POWEROUT SEWAGE
        }

        # Rule Set: CMOLAW
        $ps setdefault dam.CMOLAW.cause           CMOLAW
        $ps setdefault dam.CMOLAW.nearFactor      0.5
        $ps setdefault dam.CMOLAW.farFactor       0.25

        # Rule Set: CMOMED
        $ps setdefault dam.CMOMED.cause           CMOMED
        $ps setdefault dam.CMOMED.nearFactor      0.75
        $ps setdefault dam.CMOMED.farFactor       0.25
        $ps setdefault dam.CMOMED.mitigates       {
            DISASTER DISEASE EPIDEMIC
        }

        # Rule Set: CMOOTHER
        $ps setdefault dam.CMOOTHER.cause         CMOOTHER
        $ps setdefault dam.CMOOTHER.nearFactor    0.25
        $ps setdefault dam.CMOOTHER.farFactor     0.1
        $ps setdefault dam.CMOOTHER.mitigates     {
            BADFOOD  BADWATER COMMOUT  DISASTER DISEASE  DMGCULT DMGSACRED
            EPIDEMIC FOODSHRT FUELSHRT GARBAGE  INDSPILL MINEFIELD NOWATER
            ORDNANCE PIPELINE POWEROUT REFINERY SEWAGE
        }

        # Rule Set: COERCION
        $ps setdefault dam.COERCION.cause         COERCION
        $ps setdefault dam.COERCION.nearFactor    0.5
        $ps setdefault dam.COERCION.farFactor     0.2

        # Rule Set: COMMOUT
        $ps setdefault dam.COMMOUT.cause          COMMOUT
        $ps setdefault dam.COMMOUT.nearFactor     0.1
        $ps setdefault dam.COMMOUT.farFactor      0.1

        # Rule Set: CRIMINAL
        $ps setdefault dam.CRIMINAL.cause         CRIMINAL
        $ps setdefault dam.CRIMINAL.nearFactor    0.5
        $ps setdefault dam.CRIMINAL.farFactor     0.2

        # Rule Set: CURFEW
        $ps setdefault dam.CURFEW.cause           CURFEW
        $ps setdefault dam.CURFEW.nearFactor      0.5
        $ps setdefault dam.CURFEW.farFactor       0.0

        # Rule Set: DISASTER
        $ps setdefault dam.DISASTER.cause         DISASTER
        $ps setdefault dam.DISASTER.nearFactor    0.5
        $ps setdefault dam.DISASTER.farFactor     0.25

        # Rule Set: DISEASE
        $ps setdefault dam.DISEASE.cause          SICKNESS
        $ps setdefault dam.DISEASE.nearFactor     0.25
        $ps setdefault dam.DISEASE.farFactor      0.0

        # Rule Set: DMGCULT
        $ps setdefault dam.DMGCULT.cause          DMGCULT
        $ps setdefault dam.DMGCULT.nearFactor     0.2
        $ps setdefault dam.DMGCULT.farFactor      0.1

        # Rule Set: DMGSACRED
        $ps setdefault dam.DMGSACRED.cause        DMGSACRED
        $ps setdefault dam.DMGSACRED.nearFactor   0.2
        $ps setdefault dam.DMGSACRED.farFactor    0.1

        # Rule Set: EPIDEMIC
        $ps setdefault dam.EPIDEMIC.cause         SICKNESS
        $ps setdefault dam.EPIDEMIC.nearFactor    0.5
        $ps setdefault dam.EPIDEMIC.farFactor     0.2

        # Rule Set: FOODSHRT
        $ps setdefault dam.FOODSHRT.cause         HUNGER
        $ps setdefault dam.FOODSHRT.nearFactor    0.0
        $ps setdefault dam.FOODSHRT.farFactor     0.0

        # Rule Set: FUELSHRT
        $ps setdefault dam.FUELSHRT.cause         FUELSHRT
        $ps setdefault dam.FUELSHRT.nearFactor    0.0
        $ps setdefault dam.FUELSHRT.farFactor     0.0

        # Rule Set: GARBAGE
        $ps setdefault dam.GARBAGE.cause          GARBAGE
        $ps setdefault dam.GARBAGE.nearFactor     0.2
        $ps setdefault dam.GARBAGE.farFactor      0.0

        # Rule Set: GUARD
        $ps setdefault dam.GUARD.cause            GUARD
        $ps setdefault dam.GUARD.nearFactor       0.5
        $ps setdefault dam.GUARD.farFactor        0.0

        # Rule Set: INDSPILL
        $ps setdefault dam.INDSPILL.cause         INDSPILL
        $ps setdefault dam.INDSPILL.nearFactor    0.0
        $ps setdefault dam.INDSPILL.farFactor     0.0

        # Rule Set: MINEFIELD
        $ps setdefault dam.MINEFIELD.cause        ORDNANCE
        $ps setdefault dam.MINEFIELD.nearFactor   0.2
        $ps setdefault dam.MINEFIELD.farFactor    0.0

        # Rule Set: NOWATER
        $ps setdefault dam.NOWATER.cause          THIRST
        $ps setdefault dam.NOWATER.nearFactor     0.0
        $ps setdefault dam.NOWATER.farFactor      0.0

        # Rule Set: ORDNANCE
        $ps setdefault dam.ORDNANCE.cause         ORDNANCE
        $ps setdefault dam.ORDNANCE.nearFactor    0.2
        $ps setdefault dam.ORDNANCE.farFactor     0.0

        # Rule Set: ORGCAS
        $ps setdefault dam.ORGCAS.cause           ORGCAS
        $ps setdefault dam.ORGCAS.nearFactor      0.25
        $ps setdefault dam.ORGCAS.farFactor       0.1

        # Rule Set: ORGCONST
        $ps setdefault dam.ORGCONST.cause         ORGCONST
        $ps setdefault dam.ORGCONST.nearFactor    0.75
        $ps setdefault dam.ORGCONST.farFactor     0.25
        $ps setdefault dam.ORGCONST.mitigates     {
            BADFOOD  BADWATER COMMOUT  DISASTER DISEASE  DMGCULT DMGSACRED
            EPIDEMIC FOODSHRT FUELSHRT GARBAGE  INDSPILL MINEFIELD NOWATER 
            ORDNANCE PIPELINE POWEROUT REFINERY SEWAGE
        }

        # Rule Set: ORGEDU
        $ps setdefault dam.ORGEDU.cause           ORGEDU
        $ps setdefault dam.ORGEDU.nearFactor      0.75
        $ps setdefault dam.ORGEDU.farFactor       0.5
        $ps setdefault dam.ORGEDU.mitigates       {}

        # Rule Set: ORGEMP
        $ps setdefault dam.ORGEMP.cause           ORGEMP
        $ps setdefault dam.ORGEMP.nearFactor      0.75
        $ps setdefault dam.ORGEMP.farFactor       0.5
        $ps setdefault dam.ORGEMP.mitigates       {}

        # Rule Set: ORGIND
        $ps setdefault dam.ORGIND.cause           ORGIND
        $ps setdefault dam.ORGIND.nearFactor      0.75
        $ps setdefault dam.ORGIND.farFactor       0.25
        $ps setdefault dam.ORGIND.mitigates       {
            COMMOUT  FOODSHRT FUELSHRT INDSPILL NOWATER PIPELINE
            POWEROUT REFINERY
        }

        # Rule Set: ORGINF
        $ps setdefault dam.ORGINF.cause           ORGINF
        $ps setdefault dam.ORGINF.nearFactor      0.75
        $ps setdefault dam.ORGINF.farFactor       0.25
        $ps setdefault dam.ORGINF.mitigates       {
            BADWATER COMMOUT NOWATER POWEROUT SEWAGE
        }

        # Rule Set: ORGMED
        $ps setdefault dam.ORGMED.cause           ORGMED
        $ps setdefault dam.ORGMED.nearFactor      0.75
        $ps setdefault dam.ORGMED.farFactor       0.25
        $ps setdefault dam.ORGMED.mitigates       {
            DISASTER DISEASE EPIDEMIC
        }

        # Rule Set: ORGOTHER
        $ps setdefault dam.ORGOTHER.cause         ORGOTHER
        $ps setdefault dam.ORGOTHER.nearFactor    0.25
        $ps setdefault dam.ORGOTHER.farFactor     0.1
        $ps setdefault dam.ORGOTHER.mitigates     {
            BADFOOD  BADWATER COMMOUT  DISASTER DISEASE  DMGCULT DMGSACRED
            EPIDEMIC FOODSHRT FUELSHRT GARBAGE  INDSPILL MINEFIELD NOWATER 
            ORDNANCE PIPELINE POWEROUT REFINERY SEWAGE
        }

        # Rule Set: PATROL
        $ps setdefault dam.PATROL.cause           PATROL
        $ps setdefault dam.PATROL.nearFactor      0.5
        $ps setdefault dam.PATROL.farFactor       0.0

        # Rule Set: PIPELINE
        $ps setdefault dam.PIPELINE.cause         PIPELINE
        $ps setdefault dam.PIPELINE.nearFactor    0.0
        $ps setdefault dam.PIPELINE.farFactor     0.0

        # Rule Set: POWEROUT
        $ps setdefault dam.POWEROUT.cause         POWEROUT
        $ps setdefault dam.POWEROUT.nearFactor    0.1
        $ps setdefault dam.POWEROUT.farFactor     0.0

        # Rule Set: PRESENCE
        $ps setdefault dam.PRESENCE.cause         PRESENCE
        $ps setdefault dam.PRESENCE.nearFactor    0.25
        $ps setdefault dam.PRESENCE.farFactor     0.0

        # Rule Set: PSYOP
        $ps setdefault dam.PSYOP.cause            PSYOP
        $ps setdefault dam.PSYOP.nearFactor       0.1
        $ps setdefault dam.PSYOP.farFactor        0.0

        # Rule Set: REFINERY
        $ps setdefault dam.REFINERY.cause         REFINERY
        $ps setdefault dam.REFINERY.nearFactor    0.0
        $ps setdefault dam.REFINERY.farFactor     0.0

        # Rule Set: SEWAGE
        $ps setdefault dam.SEWAGE.cause           SEWAGE
        $ps setdefault dam.SEWAGE.nearFactor      0.2
        $ps setdefault dam.SEWAGE.farFactor       0.0

        # Rule parameters
        foreach rule [lsort -dictionary [edamrule names]] {
            $ps subset dam.$rule "
                Parameters for DAM Rule $rule: [edamrule longname $rule]
            "

            $ps define dam.$rule.satgain ::projectlib::rgain 1.0 "
                Satisfaction gain for DAM Rule $rule.
            "

            $ps define dam.$rule.coopgain ::projectlib::rgain 1.0 "
                Cooperation gain for DAM Rule $rule.
            "
        }

        # demog.* parameters
        $ps subset demog {
            Demographics Model parameters.
        }

        $ps subset demog.laborForceFraction {
            Labor force as a fraction of the population, by 
            civilian activity.
        }

        $tempdb eval {
            SELECT a FROM activity_gtype WHERE gtype = 'CIV'
        } {
            $ps define demog.laborForceFraction.$a ::simlib::rfraction 0.6 "
                Fraction of civilians doing activity $a that
                are in the labor force.
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
        $ps setdefault ensit.BADFOOD.spawnTime             1

        $ps setdefault ensit.BADWATER.spawns               DISEASE
        $ps setdefault ensit.BADWATER.spawnTime            1

        $ps setdefault ensit.INDSPILL.spawns               DISEASE
        $ps setdefault ensit.INDSPILL.spawnTime            5

        $ps setdefault ensit.NOWATER.spawns                DISEASE
        $ps setdefault ensit.NOWATER.spawnTime             1

        $ps setdefault ensit.SEWAGE.spawns                 DISEASE
        $ps setdefault ensit.SEWAGE.spawnTime              30


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

        # NEXT, destroy tempdb
        $tempdb destroy
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



