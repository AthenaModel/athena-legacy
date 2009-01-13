#-----------------------------------------------------------------------
# TITLE:
#    order.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(n) Order Processing Module
#
#    This is the module responsible for processing simulation orders.
#    Orders can be received from the simulation, "sim", or
#    from the GUI, "gui", or from the test suite, "test".
#
#    Orders are defined with sufficient information that order
#    dialogs can be defined mostly automatically.
#
# ERROR HANDLING
#
#    There are three kinds of error, of increasing severity:
#
#    * REJECT: the order parameters contain an out-and-out error which
#      prevents the order from being processed.
#
#    * Unexpected: the order handler, or code called by it, throws an
#      error unexpectedly (i.e., there's a bug in the code).
#
#    How these are handled varies depending on the interface.
#
#    Insofar as possible, input validation and error-handling are
#    automated, so that all orders are trivially easy to make work the
#    same.
#
#    ::order is a singleton object implemented as a snit::type.  To
#    initialize it, call "::order init".
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# order

snit::type order {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Constructor
    
    typeconstructor {
        # TBD
    }

    #-------------------------------------------------------------------
    # Checkpointed Variables

    # None

    #-------------------------------------------------------------------
    # Non-Checkpointed Variables

    # Order handler name by order name
    
    typevariable handler -array {}

    # Array of meta dicts by order name.
    typevariable meta -array {}

    #-------------------------------------------------------------------
    # Transient Variables
    #
    # The following variables are used while processing an error; they
    # are cleared before every new order.

    typevariable currentInterface  ;# The current interface
    typevariable parms             ;# Array of order parameters
    typevariable oldparms          ;# For UPDATE orders, previous parms.
    typevariable errors            ;# List of error message components.
    typevariable errorLevel        ;# Nature of error messages.
    typevariable undoCmd           ;# Undo command for this order.

    # nullMode: While in null mode, the orders don't actually get
    # executed; send returns after saving the parms.
    typevariable nullMode 0

    #-------------------------------------------------------------------
    # Initialization method

    typemethod init {} {
        # NEXT, Order processing is up.
        log normal order "Initialized"
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # nullmode flag
    #
    # flag      A boolean flag
    #
    # Turns nullmode on and off.  This is used for testing commands
    # that send orders.

    typemethod nullmode {flag} {
        set nullMode $flag
    }

    # parms
    #
    # Returns a dictionary of the most recent order parms, with one
    # additional parm, _order.

    typemethod parms {} {
        array get parms
    }

    # send alias interface name parmdict
    #
    # alias           Alternate order name to use in error messages; leave
    #                 as "" to use real order name.
    # interface       sim|gui
    # name            The order's name
    # parmdict        The order's parameter dictionary
    #
    # Processes the order, handling errors in the appropriate way for the
    # interface.

    typemethod send {alias interface name parmdict} {
        # FIRST, log the order
        if {$alias ne ""} {
            set displayName '$alias'
        } else {
            set displayName $name
        }

        log normal order [list $displayName from '$interface': $parmdict]

        # NEXT, do we have an order handler?
        require {[info exists handler($name)]} "Undefined order: $name"

        # NEXT, save the interface.
        set currentInterface $interface

        # NEXT, save the order parameters in the parms array, saving
        # the order name.
        set validParms [dict keys [$type meta $name parms]]

        array unset parms

        dict for {parm value} $parmdict {
            require {$parm in $validParms} "Unknown parameter: \"$parm\""

            set parms($parm) $value
        }

        set parms(_order) $name

        # NEXT, in null mode we're done.
        if {$nullMode} {
            if {$errorLevel ne "NONE"} {
                return -code error -errorcode REJECT $errors
            }

            return
        }

        # NEXT, set up the error messages and call the order handler.
        set errors     [dict create]
        set errorLevel NONE
        set undoCmd    {}

        if {$interface in {"gui" "test"}} {
            if {[catch $handler($name) result opts]} {
                if {[dict get $opts -errorcode] in "REJECT"} {
                    log warning order $result                    
                    return {*}$opts $result
                } elseif {[dict get $opts -errorcode] eq "CANCEL"} {
                    log warning order $result                    
                    return
                } else {
                    log error order \
           "Unexpected error in $displayName:\n[dict get $opts -errorinfo]"
                    error \
                        "Unexpected error in $displayName:\n$result" \
                        [dict get $opts -errorinfo]
                }
            }
        } elseif {$interface eq "sim"} {
            if {[catch $handler($name) result opts]} {
                set einfo [dict get $opts -errorinfo]

                log error order \
           "Unexpected error in $displayName:\n$einfo"
 
                error \
                    "Unexpected error in $displayName:\n$result" \
                    $einfo
            }
        } else {
            error "Invalid interface type: \"$interface\""
        }

        # NEXT: Add order to CIF, unless it was generated by the
        # simulation.
        if {$interface ne "sim"} {
            cif add $name $parmdict $undoCmd
        }

        # NEXT, return the result, if any.
        return $result
    }

    # define module name metadata body
    #
    # module      The name of a module (a snit::type)
    # name        The name of the order
    # metadata    The order's metadata
    # body        The body of the order
    #
    # Defines a proc within the module::orders namespace in which all
    # type variables appear.  This allows orders to be defined
    # outside the order.tcl file.

    typemethod define {module name metadata body} {
        # FIRST, save the metadata, setting default values.
        set meta($name) [dict merge             \
                             {table "" keys ""} \
                             $metadata]

        # Add the "defvalue" key to each parm's defdict.
        set parmdefs [dict get $meta($name) parms]

        dict for {parm defdict} $parmdefs {
            dict set parmdefs $parm [dict merge {
                ptype  text
                defval ""
            } $defdict]
        }

        dict set meta($name) parms $parmdefs


        # NEXT, get the module variables
        set modvars [list namespace upvar $module]

        foreach tv [$module info typevars] {
            lappend modvars $tv [namespace tail $tv]
        }

        # NEXT, define the namespace and set up the namespace path
        namespace eval ${module}::orders:: \
            [list namespace path [list ${module} ::order::]]

        # NEXT, save the handler name
        set handler($name) ${module}::orders::$name

        # NEXT, define the handler
        proc $handler($name) {} [tsubst {
        |<--
            namespace upvar $type ${type}::parms parms
            $modvars
            set type $module

            $body
        }]
    }

    # meta order key ?key...?
    #
    # order     The name of an order
    # key...    Keys into the meta dictionary
    #
    # Returns the result of "dict get" on the meta dictionary

    typemethod meta {order args} {
        return [dict get $meta($order) {*}$args]
    }

    # exists name
    #
    # name     An order name
    #
    # Returns 1 if there's an order with this name, and 0 otherwise

    typemethod exists {name} {
        return [info exists handler($name)]
    }


    #-------------------------------------------------------------------
    # Procs for use in order handlers

    # interface
    #
    # Returns the name of the current interface

    proc interface {} {
        return $currentInterface
    }

    # prepare parm options...
    #
    # Prepares the parameter for processing, as determined by the
    # options.

    proc prepare {parm args} {
        # FIRST, make sure that the parameter exists.
        if {![info exists parms($parm)]} {
            set parms($parm) ""
        }

        # NEXT, process the options, so long as there's no explicit
        # error.

        while {![dict exists $errors $parm] && [llength $args] > 0} {
            set opt [lshift args]
            switch -exact -- $opt {
                -trim {
                    set parms($parm) [string trim $parms($parm)]
                }
                -toupper {
                    set parms($parm) [string toupper $parms($parm)]
                }
                -tolower {
                    set parms($parm) [string tolower $parms($parm)]
                }
                -normalize {
                    set parms($parm) [normalize $parms($parm)]
                }
                -required { 
                    if {$parms($parm) eq ""} {
                        reject $parm "required value"
                    }
                }
                -oldvalue {
                    set oldvalue [lshift args]

                    if {$parms($parm) eq $oldvalue} {
                        set parms($parm) ""
                    }
                }
                -unused {
                    if {$parms($parm) eq ""} {
                        continue
                    }

                    set name $parms($parm)

                    if {[rdb exists {
                        SELECT id FROM entities 
                        WHERE id=$name
                    }]} {
                        reject $parm "An entity with this ID already exists"
                    }

                    if {[rdb exists {
                        SELECT longname FROM entities 
                        WHERE longname=$name
                    }]} {
                        reject $parm "An entity with this name already exists"
                    }
                }
                -type {
                    set parmtype [lshift args]

                    validate $parm { 
                        set parms($parm) [{*}$parmtype validate $parms($parm)]
                    }
                }
                default { 
                    error "unknown option: \"$opt\"" 
                }
            }
        }

    }

    # reject parm msg
    #
    # parm   A parameter name, or "*"
    # msg    An error message
    #
    # There's an out-and-out error in the order.  Add the message to
    # the error dictionary, and set the errorLevel to REJECT.

    proc reject {parm msg} {
        dict set errors $parm $msg
        set errorLevel REJECT
    }

    # valid parm
    #
    # parm    Parameter name
    #
    # Returns 1 if parm's value is not known to be invalid, and
    # 0 otherwise.  A parm's value is invalid if it's the 
    # empty string (a missing value) or if it's been explicitly
    # flagged as invalid.

    proc valid {parm} {
        if {$parms($parm) eq "" || [dict exists $errors $parm]} {
            return 0
        }

        return 1
    }

    # validate parm script
    #
    # parm    A parameter to validate
    # script  A script to validate it.
    #
    # Executes the script in the caller's context.  If the script
    # throws an error, and the error code is INVALID, the value
    # is rejected.  Any other error is rethrown as an unexpected
    # error.
    #
    # If the parameter is already known to be invalid, the code is skipped.
    # Further, if the parameter is the empty string, the code is skipped,
    # as presumably it's an optional parameter.

    proc validate {parm script} {
        if {![valid $parm]} {
            return
        }

        if {[catch {
            uplevel 1 $script
        } result opts]} {
            if {[lindex [dict get $opts -errorcode] 0] eq "INVALID"} {
                reject $parm $result
            } else {
                return {*}$opts $result
            }
        }
    }

    # returnOnError
    #
    # Handles accumulated errors.

    proc returnOnError {} {
        # FIRST, If there are no errors, do nothing
        if {[dict size $errors] == 0} {
            return
        }

        # FINALLY, throw the accumulated errors at the specified
        # error level; this will terminate order processing.
        
        return -code error -errorcode REJECT $errors
    }

    # cancel
    #
    # Use this in the rare case where the user can interactively 
    # cancel an order that's in progress.

    proc cancel {} {
        return -code error -errorcode CANCEL \
            "The order was cancelled by the user."
    }

    # setundo cmd
    #
    # cmd    An undo command
    #
    # Sets the undo command for the current order.

    proc setundo {cmd} {
        set undoCmd $cmd
    }
}



