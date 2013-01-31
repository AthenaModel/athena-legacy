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

# Real Quantity
::marsutil::range ::projectlib::parmdb_rquantity \
    -min 0.0 -format "%.2f"

# Loss Exchange Ratio
::marsutil::range ::projectlib::parmdb_ler \
    -min 0.01 -format "%.2f"

# Nominal coverage
::marsutil::range ::projectlib::parmdb_nomcoverage \
    -min 0.1 -max 1.0 -format "%+5.2f"

# Nominal cooperation
::marsutil::range ::projectlib::parmdb_nomcoop \
    -min 10.0 -max 100.0 -format "%5.1f"

# Positive Days
::marsutil::range ::projectlib::parmdb_posdays \
    -min 0.1 -format "%.2f"

# Idle Fraction
::marsutil::range ::projectlib::parmdb_idlefrac \
    -min 0.0 -max 0.9 -format "%.2f"

# Positive Cobb-Douglas parameter
::marsutil::range ::projectlib::parmdb_posCD \
    -min 0.05 -max 1.0 -format "%.2f"

# Non-negative security
snit::integer ::projectlib::parmdb_nnsec \
    -min 1 -max 100


#-------------------------------------------------------------------
# parm

snit::type ::projectlib::parmdb {
    # Make it a singleton
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Typecomponents

    typecomponent ps ;# The parmset(n) object

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

        # FIRST, create the parmset.
        set ps [parmset %AUTO%]

        # NEXT, create an "in-memory" scenariodb, for concerns
        # and activities.
        set tempdb ${type}::tempdb
        catch {$tempdb destroy}
        scenariodb $tempdb
        $tempdb open :memory:

        # NEXT, Simulation Control parameters
        $ps subset sim {
            Parameters that affect the simulation at a basic level.
        }

        $ps define sim.tickTransaction ::snit::boolean yes {
            If yes, the time advance (or tick) activities are wrapped
            in an SQL transaction, which makes them considerably
            faster, but means that RDB changes made during the tick
            are lost if tick code throws an unexpected error.  If no,
            no enclosing transaction is used; the tick activities will
            be much slower, but the data required for debugging will
            remain.
        }

        # NEXT, Athena Attrition Model parameters

        $ps subset aam {
            Parameters that affect the Athena Attrition Model.
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
            Non-uniformed Force cell, in weeks.
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
            $ps define aam.UFvsNF.ECDA.$ul ::projectlib::parmdb_rquantity 0.0 {
                The ECDA for this urbanization level, i.e., the
                expected number of civilians killed per non-uniformed cell
                attacked by a uniformed force.
            }
        }

        $ps setdefault aam.UFvsNF.ECDA.ISOLATED 0.0
        $ps setdefault aam.UFvsNF.ECDA.RURAL    1.0
        $ps setdefault aam.UFvsNF.ECDA.SUBURBAN 3.0
        $ps setdefault aam.UFvsNF.ECDA.URBAN    5.0

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
            ::projectlib::parmdb_nomcoop 50.0 {
            The nominal cooperation of the neighborhood civilians
            with the Non-uniformed Force for this algorithm.
        }

        $ps define aam.NFvsUF.HIT_AND_RUN.ELER \
            ::projectlib::parmdb_ler 0.33 {
            The Expected Loss Exchange Ratio: the expected number of NF
            casualties per UF casualty inflicted, assuming that the
            neighborhood cooperates equally with the NF and UF (and
            that the UF is able to fire back).
        }

        $ps define aam.NFvsUF.HIT_AND_RUN.MAXLER \
            ::projectlib::parmdb_ler 0.25 {
            The Maximum Loss Exchange Ratio: the maximum number of
            NF casualties the NF is willing to accept for each UF
            casualty inflicted.
        }

        $ps define aam.NFvsUF.HIT_AND_RUN.ufCasualties \
            ::projectlib::ipositive 4 {
            The number of Uniformed Force personnel the Non-uniformed
            wishes to kill in any hit-and-run attack.
        }

        $ps subset aam.NFvsUF.STAND_AND_FIGHT {
            Parameters relating to the Non-uniformed Force in NF vs. UF
            attrition when the Non-uniformed Force is using
            Stand-and-Fight tactics.
        }

        $ps define aam.NFvsUF.STAND_AND_FIGHT.nominalCooperation \
            ::projectlib::parmdb_nomcoop 50.0 {
            The nominal cooperation of the neighborhood civilians
            with the Non-uniformed Force for this algorithm.
        }

        $ps define aam.NFvsUF.STAND_AND_FIGHT.ELER \
            ::projectlib::parmdb_ler 3.0 {
            The Expected Loss Exchange Ratio: the expected number of NF
            casualties per UF casualty inflicted, assuming that the
            neighborhood cooperates equally with the NF and UF (and
            that the UF is able to fire back).
        }

        $ps define aam.NFvsUF.STAND_AND_FIGHT.MAXLER \
            ::projectlib::parmdb_ler 4.0 {
            The Maximum Loss Exchange Ratio: the maximum number of
            NF casualties the NF is willing to accept for each UF
            casualty inflicted.
        }

        $ps define aam.NFvsUF.STAND_AND_FIGHT.nfCasualties \
            ::projectlib::ipositive 20 {
            The number of personnel the Non-uniformed Force
            is willing to expend in a single attack, killing as many
            UF personnel as possible, when standing and fighting.
        }

        $ps subset aam.NFvsUF.ECDC {
            The Expected Collateral Damage per Casualty, i.e., the
            expected number of civilians killed per non-uniformed casualty
            when a uniformed force is defending against non-uniformed
            attack.  The actual value depends
            on the urbanization level.
        }

        foreach ul [::projectlib::eurbanization names] {
            $ps define aam.NFvsUF.ECDC.$ul ::projectlib::parmdb_rquantity 0.0 {
                The ECDC for this urbanization level, i.e., the
                expected number of civilians killed per non-uniformed casualty
                when a uniformed force is defending.
            }
        }

        $ps setdefault aam.NFvsUF.ECDC.ISOLATED 0.0
        $ps setdefault aam.NFvsUF.ECDC.RURAL    0.1
        $ps setdefault aam.NFvsUF.ECDC.SUBURBAN 0.15
        $ps setdefault aam.NFvsUF.ECDC.URBAN    0.2


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

            $ps define activity.FRC.$a.cost ::projectlib::money 0 {
                The cost, in dollars, to assign one person to do this
                activity for one strategy tock, i.e., for one week.
                The dollar amount may be defined with a "K", "M", or
                "B" suffix to connote thousands, millions, or billions.
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

            $ps define activity.ORG.$a.cost ::projectlib::money 0 {
                The cost, in dollars, to assign one person to do this
                activity for one strategy tock, i.e., for one week.
                The dollar amount may be defined with a "K", "M", or
                "B" suffix to connote thousands, millions, or billions.
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

        # app.* parameters
        $ps subset app {
            Parameters related to how the Athena application should behave
            under certain circumstances. For now, this is limited to
            only developer user.
        }

        $ps define app.dev ::projectlib::boolean no {
            This flag indicates areas of Athena that should not be
            accessed because they are under development
            and should not be used in the course of running. This flag
            also provides a way of marking the code clearly for these types
            of areas.
        }

        # attitude.* parameters
        $ps subset attitude {
            Parameters related to Athena's attitudes model.  Note that
            parameters implemented by URAM are in the uram.* hierarchy.
        }

        foreach att {COOP HREL SAT VREL} {
            $ps subset attitude.$att {
                Parameters relating to $att curves.
            }

            $ps define attitude.$att.gain ::projectlib::rgain 1.0 {
                The input gain for attitude inputs of this type.
                Increase the gain to make Athena run "hotter",
                decrease it to make Athena run "colder".
            }
        }

        $ps subset attitude.SFT {
            Parameters related to SFT satisfaction curves.
        }

        $ps define attitude.SFT.Znatural ::marsutil::zcurve \
            {-100.0 -100.0 100.0 100.0} {
                A Z-curve for computing the natural level of
                SFT satisfaction curves from the civilian group's
                security.  The default curve simply equates the two.
                The output may not exceed the range (-100.0, +100.0).
            }

        # control.* parameters
        $ps subset control {
            Parameters related to the determination of group/actor
            relationships, actor influence and support, and neighborhood
            control.
        }

        $ps subset control.support {
            Parameters related to the computation of the support of a
            neighborhood for a particular actor.
        }

        $ps define control.support.min ::simlib::rfraction 0.1 {
            The minimum support than actor a can have in neighborhood
            n and still be able to take control of neighborhood n.
        }

        $ps define control.support.vrelMin ::simlib::rfraction 0.2 {
            The minimum V.ga that group g can have for actor a and
            still be deemed to be a supporter of a.
        }

        $ps define control.support.Zsecurity ::marsutil::zcurve \
            {0.0 -25 25 1.0} {
                A Z-curve for computing a group's security factor
                in a neighborhood, that is, the degree to which the
                group can support an actor given their current
                security level.  The input is the group's security
                level, -100 to +100; the output is a factor from 0.0
                to 1.0.
        }

        $ps define control.threshold ::simlib::rfraction 0.5 {
            The minimum influence.na an actor must have to become
            "in control" of a neighborhood.
        }

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
            $ps define dam.$name.cause ::projectlib::ecause MAGIC {
                The "cause" for all URAM inputs produced by this
                rule set.  The value must be an ecause(n) short name.
            }

            $ps define dam.$name.nearFactor ::simlib::rfraction 0.0 {
                Strength of indirect satisfaction effects in neighborhoods
                which consider themselves "near" to the neighborhood in
                which the rule set fires.
            }

            $ps define dam.$name.farFactor ::simlib::rfraction 0.0 {
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

        # Add additional parameters for CIVCAS rule sets
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

        # Rule Set: CMOCONST
        $ps setdefault dam.CMOCONST.cause         CMOCONST
        $ps setdefault dam.CMOCONST.nearFactor    0.75
        $ps setdefault dam.CMOCONST.farFactor     0.25
        $ps setdefault dam.CMOCONST.mitigates     {
            BADFOOD  BADWATER COMMOUT  CULSITE  DISASTER DISEASE
            EPIDEMIC FOODSHRT FUELSHRT GARBAGE  INDSPILL MINEFIELD
            NOWATER  ORDNANCE PIPELINE POWEROUT REFINERY RELSITE   SEWAGE
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
            BADFOOD  BADWATER COMMOUT  CULSITE  DISASTER DISEASE
            EPIDEMIC FOODSHRT FUELSHRT GARBAGE  INDSPILL MINEFIELD
            NOWATER  ORDNANCE PIPELINE POWEROUT REFINERY RELSITE
            SEWAGE
        }

        # Rule Set: COERCION
        $ps setdefault dam.COERCION.cause         COERCION
        $ps setdefault dam.COERCION.nearFactor    0.5
        $ps setdefault dam.COERCION.farFactor     0.2

        # Rule Set: COMMOUT
        $ps setdefault dam.COMMOUT.cause          COMMOUT
        $ps setdefault dam.COMMOUT.nearFactor     0.1
        $ps setdefault dam.COMMOUT.farFactor      0.1

        # Rule Set: CONTROL
        $ps setdefault dam.CONTROL.cause          CONTROL
        $ps setdefault dam.CONTROL.nearFactor     0.2
        $ps setdefault dam.CONTROL.farFactor      0.0

        # Rule Set: CRIMINAL
        $ps setdefault dam.CRIMINAL.cause         CRIMINAL
        $ps setdefault dam.CRIMINAL.nearFactor    0.5
        $ps setdefault dam.CRIMINAL.farFactor     0.2

        # Rule Set: CURFEW
        $ps setdefault dam.CURFEW.cause           CURFEW
        $ps setdefault dam.CURFEW.nearFactor      0.5
        $ps setdefault dam.CURFEW.farFactor       0.0

        # Rule Set: CULSITE
        $ps setdefault dam.CULSITE.cause          CULSITE
        $ps setdefault dam.CULSITE.nearFactor     0.1
        $ps setdefault dam.CULSITE.farFactor      0.1

        # Rule Set: DISASTER
        $ps setdefault dam.DISASTER.cause         DISASTER
        $ps setdefault dam.DISASTER.nearFactor    0.0
        $ps setdefault dam.DISASTER.farFactor     0.0

        # Rule Set: DISEASE
        $ps setdefault dam.DISEASE.cause          SICKNESS
        $ps setdefault dam.DISEASE.nearFactor     0.25
        $ps setdefault dam.DISEASE.farFactor      0.0

        # Rule Set: DISPLACED
        $ps setdefault dam.DISPLACED.active       0
        $ps setdefault dam.DISPLACED.cause        DISPLACED
        $ps setdefault dam.DISPLACED.nearFactor   0.25
        $ps setdefault dam.DISPLACED.farFactor    0.0

        # Rule Set: ENI
        $ps setdefault dam.ENI.cause              ENI
        $ps setdefault dam.ENI.nearFactor         0.25
        $ps setdefault dam.ENI.farFactor          0.0

        # Rule Set: EPIDEMIC
        $ps setdefault dam.EPIDEMIC.cause         SICKNESS
        $ps setdefault dam.EPIDEMIC.nearFactor    0.5
        $ps setdefault dam.EPIDEMIC.farFactor     0.2

        # Rule Set: FOODSHRT
        $ps setdefault dam.FOODSHRT.cause         HUNGER
        $ps setdefault dam.FOODSHRT.nearFactor    0.1
        $ps setdefault dam.FOODSHRT.farFactor     0.0

        # Rule Set: FUELSHRT
        $ps setdefault dam.FUELSHRT.cause         FUELSHRT
        $ps setdefault dam.FUELSHRT.nearFactor    0.1
        $ps setdefault dam.FUELSHRT.farFactor     0.0

        # Rule Set: GARBAGE
        $ps setdefault dam.GARBAGE.cause          GARBAGE
        $ps setdefault dam.GARBAGE.nearFactor     0.0
        $ps setdefault dam.GARBAGE.farFactor      0.0

        # Rule Set: GUARD
        $ps setdefault dam.GUARD.cause            GUARD
        $ps setdefault dam.GUARD.nearFactor       0.5
        $ps setdefault dam.GUARD.farFactor        0.0

        # Rule Set: INDSPILL
        $ps setdefault dam.INDSPILL.cause         INDSPILL
        $ps setdefault dam.INDSPILL.nearFactor    0.0
        $ps setdefault dam.INDSPILL.farFactor     0.0

        # Rule Set: IOM
        $ps setdefault dam.IOM.cause         IOM
        $ps setdefault dam.IOM.nearFactor    0.0
        $ps setdefault dam.IOM.farFactor     0.0

        # Additional parameters for IOM rule set.
        $ps define dam.IOM.nominalCAPcov \
            ::projectlib::parmdb_nomcoverage 0.66 {
            The nominal CAP Coverage fraction for this rule set.  The effect
            magnitudes entered by the user as part of the IOM are
            specified for this nominal coverage, i.e., if the effect is
            "M+" in the IOM, the value will be "M+" when the CAP Coverage
            is the nominal coverage and will be scaled up and down from
            there.  The valid range is 0.1 to 1.0.
        }

        $ps define dam.IOM.Zresonance ::marsutil::zcurve {0.0 0.0 0.6 1.0} {
            A Z-curve for computing the "resonance" of an IOM's semantic
            hook with a civilian group from the civilian group's affinity
            for the hook.  The Z-curve has been chosen so that groups with a
            negative affinity receive no effect.  Some backfiring might be
            reasonable, so the <i>lo</i> value could easily be decreased to,
            say, -0.1.
        }

        # Rule Set: MINEFIELD
        $ps setdefault dam.MINEFIELD.cause        ORDNANCE
        $ps setdefault dam.MINEFIELD.nearFactor   0.2
        $ps setdefault dam.MINEFIELD.farFactor    0.0

        # Rule Set: MOOD
        $ps setdefault dam.MOOD.cause             MOOD
        $ps setdefault dam.MOOD.nearFactor        0.0
        $ps setdefault dam.MOOD.farFactor         0.0

        # Add additional parameters for MOOD rule set
        $ps define dam.MOOD.threshold ::projectlib::parmdb_rquantity 5.0 {
            Delta-mood threshold; changes in civilian mood will only
            affect vertical relationships if the absolute change
            in mood meets or exceeds this threshold.
        }

        # Rule Set: NOWATER
        $ps setdefault dam.NOWATER.cause          THIRST
        $ps setdefault dam.NOWATER.nearFactor     0.1
        $ps setdefault dam.NOWATER.farFactor      0.0

        # Rule Set: ORDNANCE
        $ps setdefault dam.ORDNANCE.cause         ORDNANCE
        $ps setdefault dam.ORDNANCE.nearFactor    0.0
        $ps setdefault dam.ORDNANCE.farFactor     0.0

        # Rule Set: ORGCONST
        $ps setdefault dam.ORGCONST.cause         ORGCONST
        $ps setdefault dam.ORGCONST.nearFactor    0.75
        $ps setdefault dam.ORGCONST.farFactor     0.25
        $ps setdefault dam.ORGCONST.mitigates     {
            BADFOOD  BADWATER COMMOUT  CULSITE  DISASTER DISEASE
            EPIDEMIC FOODSHRT FUELSHRT GARBAGE  INDSPILL MINEFIELD
            NOWATER  ORDNANCE PIPELINE POWEROUT REFINERY RELSITE
            SEWAGE
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
            BADFOOD  BADWATER COMMOUT  CULSITE  DISASTER DISEASE
            EPIDEMIC FOODSHRT FUELSHRT GARBAGE  INDSPILL MINEFIELD
            NOWATER  ORDNANCE PIPELINE POWEROUT REFINERY RELSITE
            SEWAGE
        }

        # Rule Set: UNEMP
        $ps setdefault dam.UNEMP.cause            UNEMP
        $ps setdefault dam.UNEMP.nearFactor       0.2
        $ps setdefault dam.UNEMP.farFactor        0.0

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

        # Rule Set: RELSITE
        $ps setdefault dam.RELSITE.cause          RELSITE
        $ps setdefault dam.RELSITE.nearFactor     0.1
        $ps setdefault dam.RELSITE.farFactor      0.1

        # Rule Set: SEWAGE
        $ps setdefault dam.SEWAGE.cause           SEWAGE
        $ps setdefault dam.SEWAGE.nearFactor      0.2
        $ps setdefault dam.SEWAGE.farFactor       0.0

        # demog.* parameters
        $ps subset demog {
            Demographics Model parameters.
        }

        $ps define demog.Zuaf ::marsutil::zcurve {0.0 5.0 15.0 2.0} {
            Z-curve for the unemployment attitude factor (UAF).
            The input is the unemployed per capita (UPC), which is
            expressed as a percentage of the total population.
            The output is a coefficient used in the
            UNEMP rule set; it should range from 0.0 to 2.0.
        }

        # Economic Model parameters

        $ps subset econ {
            Parameters which affect the Athena Economic Model.
        }

        $ps define econ.disable ::projectlib::boolean no {
            If yes, the Athena economic model is disabled.  The
            economy will not be computed, and economic results will not
            be used.
        }

        $ps define econ.ticksPerTock ::projectlib::ipositive 1 {
            Defines the size of the economic model "tock", in ticks.
            At each tock, Athena updates the economic model with the
            latest demographic data, etc., and computes the new
            state of the economy.
        }

        $ps define econ.idleFrac ::simlib::rfraction 0.25 {
            The idle production capacity for goods, expressed as
            a decimal fraction of the total production capacity.  This
            value can range from 0.0 to 0.9.
        }

        $ps subset econ.check {
            Parameters that control Athena's on-going sanity checks for
            economic model.
        }

        $ps define econ.check.MinConsumerFrac ::simlib::rfraction 0.4 {
            The on-tick sanity check will fail if the total number of
            consumers in the local economy drops to below this
            fraction of its starting value.  Set it to 0.0 to disable
            the check.

        }

        $ps define econ.check.MinLaborFrac ::simlib::rfraction 0.4 {
            The on-tick sanity check will fail if the total number of
            workers in the local labor force drops to below this
            fraction of its starting value.  Set it to 0.0 to disable
            the check.
        }

        $ps define econ.check.MaxUR ::projectlib::iquantity 50 {
            The on-tick sanity check will fail if unemployment
            rate exceeds this value.  Set it to 100 to disable the
            check.
        }

        $ps define econ.check.MinDgdpFrac ::simlib::rfraction 0.5 {
            The on-tick sanity check will fail if the DGDP
            (Deflated Gross Domestic Product) falls drops to below
            this fraction of its starting value.  Set it to 0.0 to
            disable the check.
        }

        $ps define econ.check.MinCPI ::projectlib::parmdb_rquantity 0.7 {
            The on-tick sanity check will fail if the CPI drops
            to below this value.  Set it to 0.0 to disable the check.
        }

        $ps define econ.check.MaxCPI ::projectlib::parmdb_rquantity 1.5 {
            The on-tick sanity check will fail if the CPI rises to
            above this value.  Set it to some large number (e.g., 100.0)
            to effectively disable the check.
        }

        $ps subset econ.secFactor {
            Parameters relating to the effect of security on the economy.
        }

        $ps subset econ.secFactor.consumption {
            A set of factors that decrease a neighborhood group's
            consumption due to the the group's current security level.
        }

        $ps subset econ.secFactor.labor {
            A set of factors that decrease a neighborhood group's
            contribution to the labor force to the the group's current
            security level.
        }

        foreach level [qsecurity names] {
            $ps define econ.secFactor.consumption.$level \
                ::simlib::rfraction 1.0 "
                    Fraction of consumption when a group's security
                    level is $level.
                "

            $ps define econ.secFactor.labor.$level \
                ::simlib::rfraction 1.0 "
                    Fraction of labor force when a group's security
                    level is $level.
                "
        }

        $ps setdefault econ.secFactor.consumption.M 0.95
        $ps setdefault econ.secFactor.consumption.L 0.5
        $ps setdefault econ.secFactor.consumption.N 0.2

        $ps setdefault econ.secFactor.labor.M 0.95
        $ps setdefault econ.secFactor.labor.L 0.5
        $ps setdefault econ.secFactor.labor.N 0.2


        $ps subset econ.shares {
            Allocations of expenditures to CGE sectors, by
            expenditure class and sector.  The allocations are
            specified as shares per sector.  The fraction of money
            allocated to a sector is determined by dividing its
            designated number of shares by the total number of shares
            for this expenditure class.
        }

        foreach class {ASSIGN ATTROE BROADCAST DEPLOY FUNDENI} {
            $ps subset econ.shares.$class "
                Allocations of expenditures to CGE sectors for the
                $class expenditure class.  The allocations are
                specified as shares per sector.  The fraction of money
                allocated to a sector is determined by dividing its
                designated number of shares by the total number of shares
                for the $class expenditure class.
            "

            foreach sector {goods pop black region world} {
                $ps define econ.shares.$class.$sector \
                    ::projectlib::iquantity 0 "
                        Allocation of $class expenditures to the
                        $sector CGE sector, a number of shares greater
                        than or equal to 0.
                    "
            }
        }

        $ps setdefault econ.shares.ASSIGN.goods      4
        $ps setdefault econ.shares.ASSIGN.pop        6
        $ps setdefault econ.shares.ASSIGN.black      0
        $ps setdefault econ.shares.ASSIGN.region     0
        $ps setdefault econ.shares.ASSIGN.world      0
        $ps setdefault econ.shares.ATTROE.goods      4
        $ps setdefault econ.shares.ATTROE.pop        6
        $ps setdefault econ.shares.ATTROE.black      0
        $ps setdefault econ.shares.ATTROE.region     0
        $ps setdefault econ.shares.ATTROE.world      0
        $ps setdefault econ.shares.BROADCAST.goods   4
        $ps setdefault econ.shares.BROADCAST.pop     6
        $ps setdefault econ.shares.BROADCAST.black   0
        $ps setdefault econ.shares.BROADCAST.region  0
        $ps setdefault econ.shares.BROADCAST.world   0
        $ps setdefault econ.shares.DEPLOY.goods      4
        $ps setdefault econ.shares.DEPLOY.pop        6
        $ps setdefault econ.shares.DEPLOY.black      0
        $ps setdefault econ.shares.DEPLOY.region     0
        $ps setdefault econ.shares.DEPLOY.world      0
        $ps setdefault econ.shares.FUNDENI.goods     4
        $ps setdefault econ.shares.FUNDENI.pop       6
        $ps setdefault econ.shares.FUNDENI.black     0
        $ps setdefault econ.shares.FUNDENI.region    0
        $ps setdefault econ.shares.FUNDENI.world     0

        # ensit.* parameters
        $ps subset ensit {
            Environmental situation parameters, by ensit type.
        }

        foreach name [eensit names] {
            $ps subset ensit.$name "
                Parameters for environmental situation type
                [eensit longname $name].
            "

            $ps define ensit.$name.duration ::projectlib::iticks 0 {
                How long until the ensit auto-resolves, in integer
                ticks.  If 0, the ensit never auto-resolves.
            }
        }

        # Tweak the specifics
        $ps setdefault ensit.BADFOOD.duration        2
        $ps setdefault ensit.BADWATER.duration       1
        $ps setdefault ensit.COMMOUT.duration        1
        $ps setdefault ensit.CULSITE.duration        6
        $ps setdefault ensit.DISASTER.duration       6
        $ps setdefault ensit.DISEASE.duration        4
        $ps setdefault ensit.EPIDEMIC.duration       52
        $ps setdefault ensit.FOODSHRT.duration       26
        $ps setdefault ensit.FUELSHRT.duration       4
        $ps setdefault ensit.GARBAGE.duration        6
        $ps setdefault ensit.INDSPILL.duration       12
        $ps setdefault ensit.MINEFIELD.duration      156
        $ps setdefault ensit.NOWATER.duration        2
        $ps setdefault ensit.ORDNANCE.duration       78
        $ps setdefault ensit.PIPELINE.duration       1
        $ps setdefault ensit.POWEROUT.duration       8
        $ps setdefault ensit.REFINERY.duration       1
        $ps setdefault ensit.RELSITE.duration        6
        $ps setdefault ensit.SEWAGE.duration         9

        # NEXT, Force/Volatility/Security Parameters
        $ps subset force {
            Parameters which affect the neighborhood force analysis models.
        }

        $ps define force.maxAttackingStance ::simlib::qaffinity -0.5 {
            A group's stance toward another group is set by the STANCE
            tactic, and defaults to the group's horizontal relationship
            toward the other group.  If, however, the group has been given
            an attacking ROE toward the other group via the ATTROE tactic,
            this implies a negative stance toward that group.  This parameter
            specifies that maximum stance a group can have toward another
            group in a neighborhood in which it has been directed to attack
            that group.
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

        $ps subset force.alpha {
            Alpha is the force multiplier applied to force group personnel
            performing a particular activity when computing the group's
            "own force" in a neighborhood.
        }

        foreach a {
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
            CRIMINAL_ACTIVITIES
            CURFEW
            GUARD
            PATROL
            PSYOP
        } {
            $ps define force.alpha.$a ::projectlib::rgain 1.0 {
                Force multiplier for force group personnel assigned the
                specified activity.  Must be no less than 0.0; the average
                value is 1.0.
            }
        }

        $ps setdefault force.alpha.NONE                1.0
        $ps setdefault force.alpha.CHECKPOINT          1.5
        $ps setdefault force.alpha.CMO_CONSTRUCTION    0.8
        $ps setdefault force.alpha.CMO_DEVELOPMENT     0.8
        $ps setdefault force.alpha.CMO_EDUCATION       0.8
        $ps setdefault force.alpha.CMO_EMPLOYMENT      0.8
        $ps setdefault force.alpha.CMO_HEALTHCARE      0.8
        $ps setdefault force.alpha.CMO_INDUSTRY        0.8
        $ps setdefault force.alpha.CMO_INFRASTRUCTURE  0.8
        $ps setdefault force.alpha.CMO_LAW_ENFORCEMENT 1.5
        $ps setdefault force.alpha.CMO_OTHER           0.8
        $ps setdefault force.alpha.COERCION            1.2
        $ps setdefault force.alpha.CRIMINAL_ACTIVITIES 0.8
        $ps setdefault force.alpha.CURFEW              1.2
        $ps setdefault force.alpha.GUARD               1.7
        $ps setdefault force.alpha.PATROL              2.0
        $ps setdefault force.alpha.PSYOP               1.0

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

        $ps subset force.discipline {
            Dial that determines a force group's level of discipline as
            a function of its training level.  Set all values to  1.0 if
            training should have no effect on discipline.
        }

        foreach {name value} {
            PROFICIENT 1.0
            FULL       0.9
            PARTIAL    0.7
            NONE       0.4
        } {
            $ps define force.discipline.$name ::projectlib::rfraction $value "
                Dial that determines a force group's level of discipline
                given a training level of $name; a number between 0.0 and
                1.0.
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

        $ps subset force.law {
            These parameters relate to the effect of law enforcement
            activities by force groups on the background level of
            criminal activity, and hence on volatility.
        }

        $ps define force.law.suppfrac ::projectlib::rfraction 0.6 {
            Suppressible fraction: the fraction of a civilian group's
            criminal activity that can be suppressed by law enforcement.
        }

        $ps subset force.law.beta {
            These parameters indicate how effective force group activities
            are at reducing volatility in the neighborhood.
        }

        foreach a {
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
            CRIMINAL_ACTIVITIES
            CURFEW
            GUARD
            PATROL
            PSYOP
        } {
            $ps define force.law.beta.$a ::projectlib::rgain 1.0 {
                How effective this activity is at reducing volatility
                and criminal activities in the neighborhood.
            }
        }

        $ps setdefault force.law.beta.NONE                0.0
        $ps setdefault force.law.beta.CHECKPOINT          0.5
        $ps setdefault force.law.beta.CMO_CONSTRUCTION    0.0
        $ps setdefault force.law.beta.CMO_DEVELOPMENT     0.0
        $ps setdefault force.law.beta.CMO_EDUCATION       0.0
        $ps setdefault force.law.beta.CMO_EMPLOYMENT      0.0
        $ps setdefault force.law.beta.CMO_HEALTHCARE      0.0
        $ps setdefault force.law.beta.CMO_INDUSTRY        0.0
        $ps setdefault force.law.beta.CMO_INFRASTRUCTURE  0.0
        $ps setdefault force.law.beta.CMO_LAW_ENFORCEMENT 1.0
        $ps setdefault force.law.beta.CMO_OTHER           0.3
        $ps setdefault force.law.beta.COERCION            0.3
        $ps setdefault force.law.beta.CRIMINAL_ACTIVITIES 0.0
        $ps setdefault force.law.beta.CURFEW              1.2
        $ps setdefault force.law.beta.GUARD               1.0
        $ps setdefault force.law.beta.PATROL              1.0
        $ps setdefault force.law.beta.PSYOP               0.3

        $ps subset force.law.coverage {
            These parameters are coverage functions for law enforcement
            activities, in terms of the neighborhood's urbanization
            level.  If coverage is 1.0, then background criminal activities
            are completely suppressed.  The input is a complex measure of
            personnel involved in activities that relate in some way to
            law enforcement or suppression of crime.
        }

        foreach {urb func} {
            ISOLATED {1.0 1000}
            RURAL    {1.0 1000}
            SUBURBAN {2.0 1000}
            URBAN    {3.0 1000}
        } {
            $ps define force.law.coverage.$urb ::simlib::coverage $func "
                Law enforcement coverage function for $urb neighborhoods.
            "
        }

        $ps subset force.law.efficiency {
            This is set of multipliers indicating the efficiency of a
            force group at law enforcement given its training level.
        }

        foreach {name val} {
            PROFICIENT 1.2
            FULL       0.9
            PARTIAL    0.7
            NONE       0.4
        } {
            $ps define force.law.efficiency.$name ::projectlib::rgain $val "
                Given a training level of $name, a non-negative
                multiplier indicating how efficient the force group
                will be at law enforcement.
            "
        }

        $ps subset force.law.suitability {
            A family of non-negative multipliers, by force type, indicating
            how suitable a force of the given type is for performing
            law enforcement activities.
        }

        foreach {name val} {
            REGULAR       0.8
            PARAMILITARY  0.6
            POLICE        1.0
            IRREGULAR     0.3
            CRIMINAL      0.6
        } {
            $ps define force.law.suitability.$name ::projectlib::rgain $val {
                A non-negative multiplier indicating how suitable a force
                group of a given type is to performing law enforcement
                activities.
            }
        }

        $ps subset force.law.crimfrac {
            A family of Z-curves indicating the fraction of a civilian
            group that will engage in criminal activities as a function
            of the group's unemployment per capita.
        }

        foreach {name zcurve} {
            AGGRESSIVE  {0.05 4.0 20.0 0.20}
            AVERAGE     {0.04 4.0 20.0 0.15}
            APATHETIC   {0.03 4.0 20.0 0.10}
        } {
            $ps define force.law.crimfrac.$name ::marsutil::zcurve $zcurve "
                A Z-curve, indicating the fraction of a civilian group
                with demeanor $name that will engage in criminal
                activities, as a function of group's unemployment per
                capita percentage.
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

        # NEXT, History parameters.
        $ps subset hist {
            Parameters which control the history data saved by Athena
            at each timestep.
        }

        $ps define hist.control ::snit::boolean on {
            If on, Athena will save, each week, the actor in control of each
            neighborhood to the hist_control table.
        }

        $ps define hist.coop ::snit::boolean on {
            If on, Athena will save, each week, the cooperation of
            each civilian group with each force group
            to the hist_coop table.
        }

        $ps define hist.hrel ::snit::boolean off {
            If on, Athena will save, each week, the horizontal
            relationship between each pair of groups to this
            hist_hrel table.  Horizontal relationships are only
            affected by magic inputs, and the amount of data can
            be quite large; hence, this flag is off by default.
        }

        $ps define hist.nbcoop ::snit::boolean on {
            If on, Athena will save, each week, the cooperation of
            each neighborhood with each force group
            to the hist_nbcoop table.
        }

        $ps define hist.nbmood ::snit::boolean on {
            If on, Athena will save, each week, the mood of
            each neighborhood to the hist_nbmood table.
        }

        $ps define hist.pop ::snit::boolean on {
            If on, Athena will save, each week, the population
            of each civilian group, and also all flows of population
            from one group to another.
        }

        $ps define hist.sat ::snit::boolean on {
            If on, Athena will save, each week, the satisfaction of
            each civilian group with each concern to the hist_sat table.
        }

        $ps define hist.security ::snit::boolean on {
            If on, Athena will save, each week, the security of each
            group in each neighborhood to the hist_security table.
        }

        $ps define hist.support ::snit::boolean on {
            If on, Athena will save, each week, the direct
            support, total support, and influence of each actor in
            each neighborhood to the hist_support table.
        }

        $ps define hist.volatility ::snit::boolean on {
            If on, Athena will save, each week, the volatility of each
            neighborhood to the hist_volatility table.
        }

        $ps define hist.vrel ::snit::boolean on {
            If on, Athena will save, each week, the vertical
            relationship of each civilian group with each actor
            to the hist_vrel table.
        }


        # NEXT, define rmf parameters
        $ps slave add [list ::simlib::rmf parm]

        # Service Model Parameters
        $ps subset service {
            Parameters which affect the Athena Service models.
        }

        $ps subset service.ENI {
            Parameters which affect the Essential Non-Infrastructure
            Services model.
        }

        $ps define service.ENI.alphaA ::simlib::rfraction 0.50 {
            Smoothing constant for computing the expected level of
            service <b>when the average amount of service has been
            higher than the expectation</b>.  If 1.0, the expected
            level of service will just be the current level of service
            (expectations change instantly); if 0.0, the expected
            level of service will never change at all.<p>

            The value can be thought of as 1 over the average age of
            the data in weeks.  Thus, the default value of 0.5 implies
            that the data used for smoothing has an average age of 2
            weeks.
        }

        $ps define service.ENI.alphaX ::simlib::rfraction 0.25 {
            Smoothing constant for computing the expected level of
            service <b>when the expectation of service has been higher
            than the average amount</b>.  If 1.0, the expected
            level of service will just be the current level of service
            (expectations change instantly); if 0.0, the expected
            level of service will never change at all.  <p>

            The value can be thought of as 1 over the average age of
            the data in weeks.  Thus, the default value of 0.25 implies
            that the data used for smoothing has an average age of 4
            weeks.
        }

        $ps subset service.ENI.beta {
            The shape parameter for the service vs. funding curve, by
            neighborhood urbanization level.  If 1.0, the curve is
            linear; for values less than 1.0, the curve exhibits
            economies of scale.
        }

        $ps define service.ENI.delta ::simlib::rfraction 0.1 {
            An actual service level A is presumed to be approximately
            equal to the expected service level X if
            abs(A-X) <= delta*X.
        }

        $ps define service.ENI.gainNeeds ::simlib::rmagnitude 2.0 {
            A "gain" multiplier applied to the ENI service "needs"
            factor.  When the gain is 0.0, the needs factor is 0.0.
            When the gain is 1.0, then -1.0 <= needs <= 1.0.  When
            the gain is 2.0 (the default), then -2.0 <= needs <= 2.0,
            and so on.  Setting the gain greater than 1.0 allows the
            magnitude applied to the needs factor in the ENI rule set
            to represent a median value rather than an extreme value.
        }

        $ps define service.ENI.gainExpect ::simlib::rmagnitude 2.0 {
            A "gain" multiplier applied to the ENI service "expectations"
            factor.  When the gain is 0.0, the expectations factor is 0.0.
            When the gain is 1.0, then -1.0 <= expectf <= 1.0.  When
            the gain is 2.0 (the default), then -2.0 <= expectf <= 2.0,
            and so on.  Setting the gain greater than 1.0 allows the
            magnitude applied to expectf in the ENI rule set
            to represent a median value rather than an extreme value.
        }

        $ps define service.ENI.minSupport ::simlib::rfraction 0.0 {
            The minimum direct support an actor requires in a neighborhood
            in order to fund ENI services in that neighborhood.
        }

        $ps subset service.ENI.required {
            The required level of service, by neighborhood
            urbanization level, expressed as a fraction of the
            saturation level of service.
        }

        $ps subset service.ENI.saturationCost {
            The per capita cost of providing the saturation level of
            service, by neighborhood urbanization level, in $/week.
        }

        foreach ul [::projectlib::eurbanization names] {
            $ps define service.ENI.beta.$ul ::simlib::rfraction 1.0     \
                "Value of service.ENI.beta for urbanization level $ul."

            $ps define service.ENI.required.$ul \
                ::simlib::rfraction 0.0 \
                "Value of service.ENI.required for urbanization level $ul."

            $ps define service.ENI.saturationCost.$ul \
                ::projectlib::money 0.0 \
             "Value of service.ENI.saturationCost for urbanization level $ul."
        }

        $ps setdefault service.ENI.required.ISOLATED       0.0
        $ps setdefault service.ENI.required.RURAL          0.2
        $ps setdefault service.ENI.required.SUBURBAN       0.4
        $ps setdefault service.ENI.required.URBAN          0.6

        $ps setdefault service.ENI.saturationCost.ISOLATED 0.01
        $ps setdefault service.ENI.saturationCost.RURAL    0.10
        $ps setdefault service.ENI.saturationCost.SUBURBAN 0.20
        $ps setdefault service.ENI.saturationCost.URBAN    0.40

        # Strategy Model parameters

        $ps subset strategy {
            Parameters which affect the Athena Strategy Model.
        }

        $ps define strategy.autoDemob snit::boolean yes {
            If yes, Athena will automatically demobilize all force
            and organization group personnel that remain undeployed
            at the end of the strategy tock.
        }

        # NEXT, define uram parameters
        $ps slave add [list ::simlib::uram parm]

        # NEXT, destroy tempdb
        $tempdb destroy
    }
}
