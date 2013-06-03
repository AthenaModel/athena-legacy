#-----------------------------------------------------------------------
# TITLE:
#    gofer.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    projectlib(n): Gofer Types
#    
#    A gofer is a data validation type whose values represent different
#    ways of retrieving a data value of interest, so called because
#    on demand the gofer type can go retrieve the desired data.
#    For example, there are many ways to select a list of civilian groups: 
#    an explicit list, all groups resident in a particular neighborhood or 
#    neighborhoods, all groups who support a particular actor, and so forth.
#
#    The value of a gofer is a gofer dictionary, or gdict.  It will 
#    always have a field called "_rule", whose value indicates the algorithm
#    to use to find the data value or values of interest.  Other fields
#    will vary from gofer to gofer.
#
#    See gofer(i) for the methods that a gofer object must 
#    implement.
#
#    In addition to the gofer type, this file also defines the "gofer"
#    dynaform_field(i) type.

namespace eval ::projectlib:: {
    namespace export gofer
}

snit::type ::projectlib::gofer {
    #-------------------------------------------------------------------
    # Helper Procs

    delegate typemethod * using {%t UnknownTypemethod %m}

    typemethod UnknownTypemethod {subcmd args} {
        error "Unknown subcommand: \"$subcmd\" (use \"create\" to create types)"
    }

    # check
    #
    # Does a sanity check of all defined gofers.  This command is
    # intended for use by the Athena test suite.  An error is thrown
    # if a problem is found; otherwise it returns "OK".

    typemethod check {} {
        foreach instance [$type info instances] {
            if {[catch {$instance SanityCheck} result]} {
                error "Error in gofer $instance, $result"
            }
        }

        return "OK"
    }

    # join list ?maxlen? ?delim?
    #
    # list   - A list
    # maxlen - If given, the maximum number of list items to show.
    #          If "", the default, there is no maximum.
    # delim  - If given, the delimiter to insert between items.
    #          Defaults to ", "
    #
    # Joins the elements of the list using the delimiter, 
    # replacing excess elements with "..." if maxlen is given.

    typemethod join {list {maxlen ""} {delim ", "}} {
        if {$maxlen ne "" && [llength $list] > $maxlen} {
            set list [lrange $list 0 $maxlen-1]
            lappend list ...
        }

        return [join $list $delim]
    }

    # listval noun vcmd list
    #
    # noun   - A plural noun for use in error messages
    # vcmd   - The validation command for the list members
    # list   - The list to validate
    #
    # Attempts to validate the list, returning it in canonical
    # form for the validation type.  Throws an error if any
    # list member is invalid, or if the list is empty.

    typemethod listval {noun vcmd list} {
        set out [list]
        foreach elem $list {
            lappend out [{*}$vcmd $elem]
        }

        if {[llength $out] == 0} {
            throw INVALID "No $noun selected"
        }

        return $out
    }

    # listnar snoun pnoun list ?-brief?
    #
    # snoun   - A singular noun, or ""
    # pnoun   - A plural noun
    # list    - A list of items
    # -brief  - If given, truncate list
    #
    # Returns a standard list narrative string.

    typemethod listnar {snoun pnoun list {opt ""}} {
        if {$opt eq "-brief"} {
            set maxlen 8
        } else {
            set maxlen ""
        }

        if {[llength $list] == 1} {
            if {$snoun ne ""} {
                set text "$snoun [lindex $list 0]"
            } else {
                set text [lindex $list 0]
            }
        } else {
            set text "$pnoun ([gofer join $list $maxlen])" 
        }

        return $text
    }

    #-------------------------------------------------------------------
    # Instance Variables
    
    # Array mapping rule symbols to rule objects
    variable rules -array {}

    # Name of the type's dynaform
    variable form ""

    #-------------------------------------------------------------------
    # Constructor

    # constructor ruledict formspec
    #
    # ruledict - A dict mapping rule symbols to rule object command names.
    # formspec - A dynaform spec

    constructor {ruledict formspec} {
        # FIRST, get the rules.
        array set rules $ruledict

        # NEXT, create the form
        set form $self.form
        dynaform define $form $formspec
    }

    #-------------------------------------------------------------------
    # Public Methods

    # dynaform 
    #
    # Returns the name of the type's dynaform.

    method dynaform {} {
        return $form
    }
    
    # validate gdict
    #
    # gdict   - Possibly, a valid gdict
    #
    # Validates the gdict and returns it in canonical form.  Only
    # keys relevant to the rule are checked or included in the result.
    # Throws INVALID if the gdict is invalid.

    method validate {gdict} {
        # FIRST, if it doesn't begin with _rule, assume it's a raw value.
        if {[lindex $gdict 0] ne "_rule"} {
            set gdict [dict create _rule by_value raw_value $gdict]
        }

        # NEXT, get the rule and put it in canonical form.
        set rule [string tolower [dict get $gdict _rule]]
        set out [dict create _rule $rule]

        # NEXT, if we don't know it, that's an error.
        if {![info exists rules($rule)]} {
            throw INVALID "Unknown rule: \"$rule\""
        }

        # NEXT, make sure it's got all needed keys for the rule
        foreach key [$rules($rule) keys] {
            dict set stub $key ""
        }
        set gdict [dict merge $stub $gdict]

        # NEXT, validate the remainder of the gdict according to the
        # rule.
        return [dict merge $out [$rules($rule) validate $gdict]]
    }

    # narrative gdict ?-brief?
    #
    # gdict   - A valid gdict
    # -brief  - If given, constrains lists to the first few members.
    #
    # Returns a narrative string for the gdict as a phrase to be inserted
    # in a sentence, i.e., "all non-empty groups resident in $n".

    method narrative {gdict {opt ""}} {
        # FIRST, if it doesn't begin with _rule, assume it's a raw value.
        if {[lindex $gdict 0] ne "_rule"} {
            set gdict [dict create _rule by_value raw_value $gdict]
        }

        set rule [dict get $gdict _rule]

        # NEXT, if we don't know it, that's an error.
        if {![info exists rules($rule)]} {
            return "Unknown rule: \"$rule\""
        }

        # NEXT, call the rule
        return [$rules($rule) narrative $gdict $opt]
    }

    # eval gdict
    #
    # gdict   - A valid gdict
    #
    # Evaluates the gdict and returns a list of civilian groups.

    method eval {gdict} {
        # FIRST, if it doesn't begin with _rule, assume it's a raw value.
        if {[lindex $gdict 0] ne "_rule"} {
            set gdict [dict create _rule by_value raw_value $gdict]
        }

        set rule [dict get $gdict _rule]

        # NEXT, if we don't know it, that's an error.
        if {![info exists rules($rule)]} {
            error "Unknown rule: \"$rule\""
        }

        # NEXT, evaluate by rule.
        return [$rules($rule) eval $gdict]
    }


    #-------------------------------------------------------------------
    # Rule constructors
    
    delegate method * using {%s UnknownSubcommand %m}

    # UnknownSubcommand rule args..
    #
    # rule    - An unknown subcommand; presumably a rule name
    #
    # Calls the constructor for the rule type.

    method UnknownSubcommand {rule args} {
        if {![info exists rules($rule)]} {
            error "Unknown rule: \"$rule\""
        }

        return [dict merge \
            [dict create _rule $rule] \
            [$rules($rule) construct {*}$args]]
    }

    #-------------------------------------------------------------------
    # Other Private Methods

    # SanityCheck
    #
    # Does a sanity check of this gofer, verifying that the 
    # gofer(i) requirements are met, and that the ruledict and
    # formspec are consistent.
    #
    # This check is usually called by [gofer check], which is 
    # intended to be used by the Athena test suite.
    #
    # NOTE: We could do all of these checks on creation, but don't
    # mostly because it would require that the rule objects are
    # loaded before the gofers, whereas the modules are
    # easier to read if it's the other way around.

    method SanityCheck {} {
        # FIRST, verify that there is a by_value rule, and that its only
        # parm is "raw_value"
        require {[info exists rules(by_value)]} \
            "gofer has no \"by_value\" rule"

        set keys [$rules(by_value) keys]
        require {$keys eq "raw_value"} \
            "gofer's by_value rule has key(s) \"$keys\", should be \"raw_value\""

        # NEXT, verify that the dynaform begins with a _rule selector.
        set first [lindex [dynaform fields $form] 0]

        require {$first eq "_rule"} \
            "gofer's first field is \"$first\", expected \"_rule\""

        if {[catch {
            set cases [dynaform cases $form _rule {}] 
        } result]} {
            error "gofer's _rule field isn't a selector"
        }

        # NEXT, verify that every rule has a case and vice versa.
        foreach rule [array names rules] {
            require {$rule in $cases} \
                "gofer's form has no case for rule \"$rule\""
        }

        foreach case $cases {
            require {[info exists rules($case)]} \
                "gofer has no rule matching form case \"$case\""
        }

        # NEXT, for each rule verify that the case fields match the 
        # rule keys.
        foreach rule [array names rules] {
            set fields [GetCaseFields $form $rule]

            foreach key [$rules($rule) keys] {
                require {$key in $fields} \
                    "rule $rule's key \"$key\" has no form field"
            }

            foreach field $fields {
                require {$field in [$rules($rule) keys]} \
                    "rule $rule's field $field matches no rule key"
            }
        }
    }    
    
    # GetCaseFields ftype case
    #
    # ftype - A form type
    # case  - A _rule case
    #
    # Returns the names of the fields defined for the given case, walking
    # down the tree as needed.

    proc GetCaseFields {ftype case} {
        # FIRST, get the ID of the _rule field
        set ri [GetRuleItem $ftype]

        # NEXT, get the case items
        set items [dict get [dynaform item $ri cases] $case]

        set fields [list]

        foreach id $items {
            GetFieldNames fields $id
        }

        return $fields
    }

    # GetRuleItem ftype
    #
    # ftype  - A form type
    #
    # Retrieves the ID of the rule item for that form type.

    proc GetRuleItem {ftype} {
        foreach id [dynaform allitems $ftype] {
            set dict [dynaform item $id]

            if {[dict get $dict itype] eq "selector" &&
                [dict get $dict field] eq "_rule"
            } {
                return $id 
            }
        }

        # This should already have been checked.
        error "No _rule selector"
    }

    # GetFieldNames listvar id
    #
    # listvar   - Name of a list to receive the field names
    # id        - An item ID
    #
    # If the ID is a field, adds its name to the list.
    # If it is a selector field, recurses.

    proc GetFieldNames {listvar id} {
        upvar 1 $listvar fields

        set dict [dynaform item $id]

        if {[dict exists $dict field]} {
            lappend fields [dict get $dict field]
        }

        if {[dict get $dict itype] eq "selector"} {
            foreach case [dict get $dict cases] {
                foreach cid [dict get $dict cases $case] {
                    GetFieldNames fields $cid
                }
            }
        }
    }
}

#-----------------------------------------------------------------------
# gofer field type
#
# This is a dynaform field type to use with gofer types.

::marsutil::dynaform fieldtype define gofer {
    typemethod attributes {} {
        return {
            typename wraplength width
        }
    }

    typemethod validate {idict} {
        dict with idict {}
        require {$typename ne ""} \
            "No gofer type name command given"
    }

    typemethod create {w idict} {
        set context [dict get $idict context]

        set wid [dict get $idict width]

        # This widget works better if the width is negative, setting a
        # minimum size.  Then it can widen to the wraplength.
        if {$wid ne "" && $wid > 0} {
            dict set idict width [expr {-$wid}]
        }

        goferfield $w \
            -state [expr {$context ? "disabled" : "normal"}] \
            {*}[asoptions $idict typename wraplength width]
    }
}

