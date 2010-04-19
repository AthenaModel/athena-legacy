#-----------------------------------------------------------------------
# FILE: view.tcl
#
#   Athena View Manager
#
# PACKAGE:
#   app_sim(n) -- athena_sim(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Module: view
#
# This module is responsible for creating temporary SQLite3 views 
# corresponding to data variables.  There are two kinds:
#
#   - Neighborhood variables, each of which is a single value that
#     varies over the domain of neighborhoods
#
#   - Time series variables, each of which is a single value that
#     varies with time.
#
#   - Eventually there will be a number of other view types:
#     *g* for groups, *u* for units, etc.
#
# The application requests a view given a variable name, and receives
# a dictionary of information about variable, including the view name.
# Each created view has a name like "tv$count", has two columns,
# *x*, the data value, and either *n* or *t*.
#
# Views are defined in the <viewdef> array; data related to the
# type of the *x* column (the range variable) is found in the
# <rangeInfo> array.
#
# Variable Names and Indices:
#
#    Each domain defines a number of variable types; each variable name
#    is a period-delimited list of the variable type and its relevant
#    indices.  For example, "sat.<g>.<c>" is the pattern for the
#    neighborhood variable "satisfaction of a group with a concern".
#    The "g" and "c" represent the indices of the variable in the relevant
#    SQL table or view.
#
# Checkpoint/Restore:
#    This module is a saveable(i), and participates in the checkpoint/
#    restore protocol.  It has no checkpointed data; however, it must
#    flush its cache of views on restore.

snit::type view {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Group: Look-up Tables

    # Type Variable: domains
    #
    # Array of human-readable domain names, by domain code.

    typevariable domains -array {
        n "neighborhood"
        t "time series"
    }

    # Type Variable: rangeInfo
    #
    # This variable is an array of dictionaries of information about
    # various range types, e.g., satisfaction.  It's used when building
    # the view dictionaries.  The values that should be defined for
    # each range type are as follows.
    #
    #   rmin     - The lower bound for the range type, or "" if none.
    #   rmax     - The upper bound for the range type, or "" if none.
    #   gradient - A gradient(n) appropriate for visualizing this
    #              range type, or "" if none.

    typevariable rangeInfo -array {
        qcoop {
            rmin     0.0
            rmax     100.0
            gradient coopgradient
            units    Cooperation
            decimals 1
        }

        qsat {
            rmin     -100.0
            rmax     100.0
            gradient satgradient
            units    Satisfaction
            decimals 1
        }

        rcap {
            rmin     0
            rmax     ""
            gradient ""
            units    goodsBKT
            decimals 1
        }

        rpcf {
            rmin     0
            rmax     ""
            gradient pcfgradient
            units    PCF
            decimals 2
        }
    }

    # Type Variable: viewdef
    #
    # View definition dictionaries.  For each _domain,vartype_,
    # we have the following keys.
    #
    #   indices - A list of the names of the indices, e.g., {g c}
    #
    #   rtype   - The range type, used to key into the rangeInfo
    #             array.  It might or might not be a genuine data type.
    #
    #   query   - The SELECT statement used to define the view, with
    #             with variables $1, $2, etc., for the parameters.
    #             It must have a column with the same name as the _domain_,
    #             and an "x0" column for the range.

    typevariable viewdef -array {
        n,cap {
            indices {}
            rtype rcap
            query {
                SELECT n, cap AS x0
                FROM econ_n
            }
        }

        n,coop {
            indices {f g}
            rtype qcoop
            query {
                SELECT n, coop AS x0
                FROM gram_coop
                WHERE f='$1' AND g='$2'
            }
        }

        n,mood {
            indices {g}
            rtype qsat
            query {
                SELECT n, mood AS x0
                FROM gui_nbgroups
                WHERE g='$1'
            }
        }

        n,nbcoop {
            indices {g}
            rtype qcoop
            query {
                SELECT n, coop AS x0
                FROM gram_frc_ng
                WHERE g='$1'
            }
        }

        n,nbmood {
            indices {}
            rtype qsat
            query {
                SELECT n, sat AS x0 
                FROM gram_n
            }
        }

        n,none {
            indices {}
            rtype qsat
            query {
                SELECT n, 0.0 AS x0
                FROM nbhoods
            }
        }

        n,pcf {
            indices {}
            rtype rpcf
            query {
                SELECT n, pcf AS x0
                FROM econ_n
            }
        }

        n,sat {
            indices {g c}
            rtype qsat
            query {
                SELECT n, sat AS x0
                FROM gui_sat_ngc
                WHERE g='$1' AND c='$2'
            }
        }
    }


    #-------------------------------------------------------------------
    # Group: Uncheckpointed Variables

    # Type Variable: views
    #
    # Array of view dicts by "$domain,$varname".  This variable isn't
    # checkpointed, but it should be flushed on restore.

    typevariable views -array {}

    # Type Variable: data
    #
    # Array of scalar variables.
    #
    # viewCounter - View counter; used to name created views.
    
    typevariable data -array {
        viewCounter 0
    }

    #-------------------------------------------------------------------
    # Group: Initialization

    # Type Method: init
    #
    # Initializes the module, registering it as a saveable.

    typemethod init {} {
        log detail view "init"

        # FIRST, register this module as a saveable, so that the
        # cache is flushed as appropriate.
        scenario register $type

        # NEXT, the module is up.
        log detail view "init complete"
    }

    #-------------------------------------------------------------------
    # Group: View Queries
    #
    # Each of the commands in this section returns a view dictionary
    # given one or more variable names.  Applications should always 
    # request a new view dictionary prior to using the view; created views
    # are cached for speed.
    #
    # View Dictionary:
    #
    #  view     - SQLite view name
    #  domain   - Domain, *t* or *n*.
    #  count    - Number of variables included
    #  varnames - List of variable names.
    #  meta     - Variable metadata; key is a variable name, value is a 
    #             dictionary of variable info.
    #
    # Variable Dictionary:
    #
    #  varname  - Name of the variable 
    #  rtype    - Variable range type
    #  units    - Units: human readable text
    #  decimals - Number of decimal places for this kind of data
    #  rmin     - Range min, or "" if none.
    #  rmax     - Range max, or "" if none.
    #  gradient - Gradient(n) for this range type.

    # Type Method: n get
    #
    # Returns a view dictionary for the given neighborhood _varnames_.
    #
    # Syntax:
    #   n get _varnames_
    #
    #   varnames - A list of one or more variable names for the 
    #              neighborhood domain.

    typemethod "n get" {varnames} {
        if {[llength $varnames] == 1} {
            return [$type GetView n [lindex $varnames 0]]
        } else {
            return [$type GetCompositeView n $varnames]
        }
    }

    # Type Method: t get
    #
    # Returns a view dictionary for the time series variable(s)
    # with the given _varnames_.
    #
    # Syntax:
    #   t get _varnames_
    #
    #   varnames - A list of one or more variable names for the 
    #              time series domain.

    typemethod "t get" {varnames} {
        if {[llength $varnames] == 1} {
            return [$type GetView t [lindex $varnames 0]]
        } else {
            return [$type GetCompositeView t $varnames]
        }
    }

    # Type Method: GetView
    #
    # Returns a view dictionary for the _domain_ variable
    # with the given _varname_.
    #
    # Syntax:
    #   GetView _domain varname_
    #
    #   domain  - *n* (neighborhood) or *t* (time in ticks)
    #   varname - A variable name for the specified domain.

    typemethod GetView {domain varname} {
        # FIRST, if the view already exists, return it.
        if {[info exists views($domain,$varname)]} {
            return $views($domain,$varname)
        }

        # NEXT, validate the inputs
        $type ValidateVarname $domain $varname

        # NEXT, generate a view ID
        set vid "tv[incr data(viewCounter)]"

        # NEXT, split the variable name into its components
        set varlist [split $varname .]
        lassign $varlist vartype 1 2 3 4 5 6 7 8 9

        # NEXT, create the view
        set query [dict get $viewdef($domain,$vartype) query]
        set rtype [dict get $viewdef($domain,$vartype) rtype]

        rdb eval "CREATE TEMPORARY VIEW $vid AS [subst $query]"

        set vdict [dict create]
        dict set vdict view     $vid
        dict set vdict domain   $domain
        dict set vdict count    1

        dict set vdict meta $varname $rangeInfo($rtype)
        dict set vdict meta $varname rtype $rtype

        set views($domain,$varname) $vdict

        # NEXT, return the ID
        return $views($domain,$varname)
    }

    # Type Method: GetCompositeView
    #
    # Returns a view dictionary for the _domain_ variables
    # with the given _varnames_.  The created view will 
    # have columns x0, x1, etc.
    #
    # Syntax:
    #   GetCompositeView _domain varnames_
    #
    #   domain   - *n* (neighborhood) or *t* (time in ticks)
    #   varnames - A list of variable names for the specified domain.

    typemethod GetCompositeView {domain varnames} {
        # FIRST, get the composite variable name.
        set composite [join $varnames ,]

        # FIRST, if the view already exists, return it.
        if {[info exists views($domain,$composite)]} {
            return $views($domain,$composite)
        }

        # NEXT, create a new view ID and begin to fill in the
        # view dictionary.
        set vid "tv[incr data(viewCounter)]"
        
        set vdict [dict create \
                       view   $vid                \
                       domain $domain             \
                       count  [llength $varnames]]
                       

        # NEXT, get a view for each variable.
        set vids [list]

        foreach varname $varnames {
            set tdict [$type GetView $domain $varname]

            lappend vids [dict get $tdict view]
            
            dict set vdict meta $varname \
                [dict get $tdict meta $varname]
        }

        # NEXT, create the new view
        set i 0
        set columns [list]
        set joins ""

        foreach v $vids {
            # FIRST, get the column name
            lappend columns "$v.x0 AS x$i"
            incr i

            # NEXT, set up the joins.
            if {$joins eq ""} {
                set joins "$v"
            } else {
                append joins " JOIN $v USING ($domain)"
            }
        }

        set sql "
            CREATE TEMPORARY VIEW $vid AS
            SELECT [lindex $vids 0].$domain,[join $columns ,]
            FROM $joins
        "

        rdb eval $sql

        # NEXT, save the view dict.
        set views($domain,$composite) $vdict

        # NEXT, return the view dict
        return $views($domain,$composite)
    }

    # Type Method: n validate
    #
    # Validates a _varname_ for the neighborhood domain.
    # Returns the validated varname, which is in canonical form.
    #
    # Syntax:
    #   n validate _varname_
    #
    #   varname - The neighborhood variable name.

    typemethod "n validate" {varname} {
        return [$type ValidateVarname n $varname]
    }

    # Type Method: t validate
    #
    # Validates a _varname_ for the time series domain.
    # Returns the validated varname, which is in canonical form.
    #
    # Syntax:
    #   t validate _varname_
    #
    #   varname - The time series variable name.

    typemethod "t validate" {varname} {
        return [$type ValidateVarname t $varname]
    }

    # Type Method: ValidateVarname
    #
    # Validates a _varname_ for the particular _domain_.
    # Returns the validated varname, which is in canonical form.
    #
    # Specs have the syntax "<vartype>?.<indexValue>...?".  The _domain_
    # and _vartype_ must be known.  The index values may not contain 
    # characters that would allow injection attacks: "':,
    #
    # Canonical Form:
    #   At present, all variables have the same canonical form:
    #   the vartype is lower case and the index values are upper case.
    #   At some point in the future the latter condition might be
    #   relaxed in favor of vartype-specific validation; at present,
    #   though, it works in all cases.
    #
    # Syntax:
    #   ValidateVarname _domain varname_
    #
    #   domain  - *n* or *t*
    #   varname - The variable name.

    typemethod ValidateVarname {domain varname} {
        # FIRST, split the varname into tokens.
        set varlist [split $varname .]
        lassign $varlist vartype 1 2 3 4 5 6 7 8 9
        set vartype [string tolower $vartype]

        # NEXT, verify the domain and var type.
        if {![info exists viewdef($domain,$vartype)]} {
            return -code error -errorcode INVALID \
            "Invalid $domains($domain) variable type: \"$vartype\""
        }

        # NEXT, validate the number of arguments.
        set def $viewdef($domain,$vartype)
        set indices [dict get $def indices]

        if {[llength $varlist] - 1 != [llength $indices]} {
            set pattern [VartypePattern $vartype $indices]

            return -code error -errorcode INVALID \
 "Invalid $domains($domain) variable: expected \"$pattern\", got \"$varname\""
        }

        # NEXT, validate the syntax of the index values.
        set outlist [list $vartype]

        foreach value [lrange $varlist 1 end] {
            if {[regexp {['\";,]} $value]} {
                return -code error -errorcode INVALID \
   "Invalid $domains($domain) variable index value: \"$value\" in \"$varname\""
            }

            lappend outlist [string toupper $value]
        }

        return [join $outlist .]
    }

    # Proc: VartypePattern
    #
    # Returns the pattern given the var type and indices, for use
    # in error messages.
    #
    # Syntax:
    #   VartypePattern _spectype indices_
    #
    #   vartype  - The variable type, e.g., "sat"
    #   indices  - The variable's indices, e.g., {g c}

    proc VartypePattern {vartype indices} {
        set pattern $vartype

        foreach arg $indices {
            append pattern ".<$arg>"
        }

        return $pattern
    }

    #-------------------------------------------------------------------
    # Checkpoint/Restore

    # checkpoint ?-saved?
    #
    # Returns the component's checkpoint information as a string.

    typemethod checkpoint {{flag ""}} {
        # No checkpointed data
        return ""
    }

    # restore checkpoint ?-saved?
    #
    # checkpoint      A checkpoint string returned by "checkpoint"
    #
    # Restores the component's state to the checkpoint.  In this case,
    # the persistent situation state is stored wholly in the RDB...but we 
    # need to flush the cache of existing situation objects.

    typemethod restore {checkpoint {flag ""}} {
        array unset views
    }

    # changed
    #
    # Indicates that the nothing needs to be saved.

    typemethod changed {} {
        return 0
    }
}
