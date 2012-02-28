#-----------------------------------------------------------------------
# TITLE:
#    smartinterp.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsutil(n) module: smartinterp(n), Smart Interps
#
#    A smart interp is a standard Tcl interp wrapped in a Snit object,
#    with added features for defining aliases.  The biggest of these
#    is the "smartalias" feature, which provides much better error
#    messages when a command is called with too many or too few 
#    arguments.
#
#-----------------------------------------------------------------------

namespace eval ::marsutil:: {
    namespace export smartinterp
}

#-----------------------------------------------------------------------
# smartinterp

snit::type ::marsutil::smartinterp {
    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        namespace import ::marsutil::* 
        namespace import ::marsutil::*
    }


    #-------------------------------------------------------------------
    # Components

    component interp   ;# The Tcl interp we're wrapping

    #-------------------------------------------------------------------
    # Options

    # -trusted flag
    #
    # The flag indicates whether the interpreter is trusted or not.  
    # Interps are untrusted (i.e., interp create -safe) by default.

    option -trusted \
        -default  no            \
        -readonly yes           \
        -type     snit::boolean

    # -cli flag
    #
    # The flag indicates whether the interpreter is attached to a CLI
    # or not.  If it's attached to the CLI, the error messages become
    # more readable.  By default the flag is "no", and the error messages
    # are similar to those produced by Tcl.

    option -cli \
        -default no            \
        -type    snit::boolean

    #-------------------------------------------------------------------
    # Instance Variables

    # aliases    Array of alias data
    #
    #   min-$alias       The minimum number of arguments
    #   max-$alias       The maximum number of arguments, or "-"
    #   argsyn-$alias    The argument syntax string
    #   prefix-$alias    The command prefix for which $alias is an alias.

    variable aliases -array {}

    # ensembles   Array of ensemble data
    #
    #   subs-$alias      List of known subcommands

    variable ensembles -array {}

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, get the options
        $self configurelist $args

        # NEXT, create and configure the interpreter
        if {$options(-trusted)} {
            set interp [interp create]
        } else {
            set interp [interp create -safe]
        }

        # NEXT, define a private namespace to work in
        $interp eval {
            namespace eval ::_smart_:: { }
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    # Delegated methods
    delegate method alias        to interp
    delegate method eval         to interp
    delegate method expose       to interp
    delegate method hide         to interp
    delegate method hidden       to interp
    delegate method invokehidden to interp

    # proc name arglist body
    #
    # name      A proc name
    # arglist   A proc arglist
    # body      A proc body
    #
    # Defines a proc in the context of the interp, just as if a
    # proc command were passed to eval.

    method proc {name arglist body} {
        $interp eval [list proc $name $arglist $body]
    }

    # ensemble alias
    #
    # alias       An ensemble alias of one or more tokens.
    #
    # Defines an ensemble to which aliases can be added.

    method ensemble {alias} {
        require {![info exists aliases(prefix-$alias)]} \
            "can't redefine smartalias as an ensemble: \"$alias\""

        if {[llength $alias] > 1} {
            set parent [lrange $alias 0 end-1]
            require {[info exists ensembles(subs-$parent)]} \
       "can't define ensemble \"$alias\", no parent ensemble \"$parent\""
            lappend ensembles(subs-$parent) [lindex $alias end]
        }

        set ensembles(subs-$alias) {}

        if {[llength $alias] == 1} {
            $interp alias $alias   $self EnsembleHandler $alias
        }
    }
    
    
    # smartalias alias min max argsyn prefix
    #
    # alias     The command to define in the interp.
    # min       min number of arguments, >= 0
    # max       max number of arguments >= min, or "-" for unlimited.
    # argsyn    Argument syntax
    # prefix    The command prefix to which the alias's arguments will be
    #           lappended.
    #
    # Defines a new command called $alias in the interp.  The alias
    # must be called with at least min arguments and no more than
    # max (if max isn't "-").  If the number of arguments is wrong,
    # the error "wrong # args: $alias $argsyn" is thrown.
    #
    # The $prefix is the command prefix in the parent interpreter which
    # corresponds to $alias in the slave, and to which the args of $alias
    # will be appended.

    method smartalias {alias min max argsyn prefix} {
        require {![info exists ensembles(subs-$alias)]} \
            "can't redefine ensemble as a smartalias: \"$alias\""

        if {[llength $alias] > 1} {
            set parent [lrange $alias 0 end-1]

            require {[info exists ensembles(subs-$parent)]} \
               "can't define alias \"$alias\", no parent ensemble \"$parent\""

            lappend ensembles(subs-$parent) [lindex $alias end]
        }

        # FIRST, save the values.
        set aliases(min-$alias)    $min
        set aliases(max-$alias)    $max
        set aliases(argsyn-$alias) $argsyn
        set aliases(prefix-$alias) $prefix

        # NEXT, alias it into the interp.
        if {[llength $alias] == 1} {
            $interp alias $alias   $self SmartAliasHandler $alias
        }
    }

    # SmartAliasHandler alias args...
    #
    # alias    The alias to handle
    # args     The args it was called with
    #
    # Validates the number of args and calls the target command.

    method SmartAliasHandler {alias args} {
        set len [llength $args]

        if {$len < $aliases(min-$alias) ||
            ($aliases(max-$alias) ne "-" &&
             $len > $aliases(max-$alias))
        } {
            set syntax $alias
            
            if {$aliases(argsyn-$alias) ne ""} {
                append syntax " "
                append syntax $aliases(argsyn-$alias)
            }

            if {$options(-cli)} {
                error [tsubst {
                    |<--
                    Wrong number of arguments.

                    [$self help $alias]}]
            } else {
                error "wrong \# args: should be \"$syntax\""
            }
        }

        return [uplevel \#0 $aliases(prefix-$alias) $args]
    }

    # EnsembleHandler alias args...
    #
    # alias     The aliased ensemble name
    # args      The arguments to the ensemble.
    #
    # Calls the correct alias in this ensemble

    method EnsembleHandler {alias args} {
        # FIRST, there must be a subcommand.
        while {[llength $args] > 0} {
            # FIRST, get the subcommand.
            set sub [lindex $args 0]
            set args [lrange $args 1 end]

            # NEXT, either we have an alias, another ensemble, or 
            # it's an error.
            set subalias [concat $alias $sub]

            if {[info exists aliases(prefix-$subalias)]} {
                return [eval [list $self SmartAliasHandler $subalias] $args]
            }

            if {![info exists ensembles(subs-$subalias)]} {
                if {$options(-cli)} {
                    error [tsubst {
                        |<--
                        Invalid subcommand: "$sub"

                        [$self help $alias]}]
                } else {
                    set subs [join $ensembles(subs-$alias) ", "]

                    error "bad subcommand \"$sub\", should be one of: $subs"
                }
            }

            # NEXT, go round again.
            set alias $subalias
        }

        if {$options(-cli)} {
            error [tsubst {
                |<--
                Missing subcommand.
                
                [$self help $alias]}]
        } else {
            set subs [join $ensembles(subs-$alias) ", "]

            error "wrong \# args: should be \"$alias subcommand ?args...?\", valid subcommands: $subs"
        }
    }

    # help alias
    #
    # alias         A smart alias
    #
    # Returns help text for the alias, if any.

    method help {alias} {
        # FIRST, what kind of alias is it?
        if {[info exists ensembles(subs-$alias)]} {
            # It's an ensemble
            set subs [join $ensembles(subs-$alias) ", "]

            return [tsubst {
                |<--
                Usage: $alias subcommand ?args...?
                Valid subcommands: $subs}]
        } elseif {[info exists aliases(prefix-$alias)]} {
            # It's a normal smart alias
            return "Usage: $alias $aliases(argsyn-$alias)"
        } else {
            # It's neither.
            error "No help found: \"$alias\""
        }
    }

    # cmdinfo alias
    #
    # alias         A smart alias
    #
    # Returns implementation details for the alias.

    method cmdinfo {alias} {
        return [$self InfoWithLeader $alias ""]
    }

    # InfoWithLeader alias leader
    #
    # leader    Leading whitespace for each line.

    method InfoWithLeader {alias leader} {
        # FIRST, what kind of alias is it?
        if {[info exists ensembles(subs-$alias)]} {
            lappend out [list ensemble $alias of:]
            foreach sub $ensembles(subs-$alias) {
                lappend out [$self InfoWithLeader "$alias $sub" "    "]
            }
        } elseif {[info exists aliases(prefix-$alias)]} {
            # It's a normal smart alias
            lappend out [list alias $alias \
                        $aliases(min-$alias) \
                        $aliases(max-$alias) \
                        $aliases(prefix-$alias)]
        } else {
            error "No info found: \"$alias\""
        }

        return "$leader[join $out \n$leader]"
    }

}




