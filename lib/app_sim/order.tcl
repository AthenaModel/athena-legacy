#-----------------------------------------------------------------------
# TITLE:
#    order.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    minerva_sim(n) Order Processing Module
#
#    This is the module responsible for processing simulation orders.
#    Orders can be received from the simulation, "sim", or
#    from a simulation client (e.g., the GUI, "client". 
#
#    Orders are defined with sufficient information that order
#    dialogs can be defined mostly automatically.
#
# ERROR HANDLING
#
#    There are two kinds of error, of increasing severity:
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

# Create the parmdef namespace ASAP
namespace eval ::order::parmdef {}


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
    # Order Definition Variables

    # Array of parm definition dictionaries by order name
    
    typevariable meta -array {}

    # Used while defining an order
    typevariable currentOrder

    #-------------------------------------------------------------------
    # Transient Variables
    #
    # The following variables are used while processing an error; they
    # are cleared before every new order.

    typevariable currentInterface  ;# The current interface
    typevariable parms             ;# Array of order parameters
    typevariable errors            ;# List of error message components.
    typevariable errorLevel        ;# Nature of error messages.

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
    # interface       sim|client
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

        # NEXT, save the interface.
        set currentInterface $interface

        # NEXT, save the order parameters in the parms array
        array unset parms
        array set parms $parmdict

        # NEXT, set up the error messages and call the order handler.
        set errors [dict create]
        set errorLevel NONE

        # NEXT, do the automated parameter processing; this might
        # set the errorLevel.
        CheckParameters $name

        # NEXT, save the order name.
        set parms(_order) $name

        # NEXT, in null mode we're done.
        if {$nullMode} {
            if {$errorLevel ne "NONE"} {
                return -code error -errorcode REJECT $errors
            }

            return
        }

        # NEXT, call the order handler.
        if {$interface eq "client"} {
            if {[catch $name result opts]} {
                if {[dict get $opts -errorcode] eq "REJECT"} {
                    log warning order $result                    
                    return {*}$opts $result
                } else {
                    log error order \
           "Unexpected error in $displayName:\n[dict get $opts -errorinfo]"
                    error \
                        "Unexpected error in $displayName:\n$result" \
                        [dict get $opts -errorinfo]
                }
            }
        } elseif {$interface eq "sim"} {
            if {[catch $name result]} {
                log error order \
           "Unexpected error in $displayName:\n[dict get $opts -errorinfo]"
 
                error \
                    "Unexpected error in $displayName:\n$result" \
                    $::errorInfo
            }
        } else {
            error "Invalid interface type: \"$interface\""
        }

        # TBD: Add order to CIF

        # NEXT, return the result, if any.
        return $result
    }

    # CheckParameters
    #
    # Checks each of the parameters, and transforms them as indicated
    # in the parameter definition.

    proc CheckParameters {order} {
        set parmlist [dict keys $meta($order)]

        dict for {parm attrs} $meta($order) {
            dict with attrs {
                # Make sure that all parameters exist.
                if {![info exists parms($parm)]} {
                    set parms($parm) ""
                }

                # Next, transform the value, as required
                if {$trim} {
                    set parms($parm) [string trim $parms($parm)]
                }

                if {$toupper} {
                    set parms($parm) [string toupper $parms($parm)]
                }

                if {$tolower} {
                    set parms($parm) [string tolower $parms($parm)]
                }

                if {$normalize} {
                    set parms($parm) [normalize $parms($parm)]
                }

                # required
                if {$required && 
                    $parms($parm) eq ""
                } {
                    reject $parm "required value"
                }
            }
        }
    }

    # normalize text
    #
    # text    A block of text
    #
    # Strips leading and trailing whitespace, converts newlines to spaces,
    # and replaces all multiple internal spaces with single spaces.
    #
    # TBD: Add this to a text processing module in marsutil(n).

    proc normalize {text} {
        set text [string trim $text]
        regsub -all "\n" $text " " text
        regsub -all { +} $text " " text
        
        return $text
    }


    # define name parms body
    #
    # name        The name of the order
    # parmdef     Parameter definition script
    # body        The body of the order
    #
    # Defines a proc within the ::order namespace in which all
    # type variables appear.  This allows orders to be defined
    # outside the order.tcl file.

    typemethod define {name parmdef body} {
        # FIRST, save the parameter definition
        set currentOrder $name

        if {[catch {
            namespace eval ::order::parmdef:: $parmdef
        } result]} {
            error "Error in $name parameter definition: $result"
        }

        # NEXT, get the variables
        set vars [list namespace upvar $type]
        
        foreach tv [$type info typevars] {
            lappend vars $tv [namespace tail $tv]
        }

        # NEXT, define the handler
        proc ${type}::$name {} "$vars\n$body"

    }

    # parmdef::parm name options...
    #
    # Defines the named parameter

    proc parmdef::parm {name args} {
        # FIRST, set defaults
        set pdict {
            required  0
            normalize 0
            trim      0
            toupper   0
            tolower   0
        }

        # NEXT, get the options
        while {[llength $args] > 0} {
            set opt [lshift args]
            switch -exact -- $opt {
                -required  { dict set pdict required  1}
                -normalize { dict set pdict normalize 1}
                -trim      { dict set pdict trim      1}
                -toupper   { dict set pdict toupper   1}
                -tolower   { dict set pdict tolower   1}
                default    { error "unknown parm option: \"$opt\"" }
            }
        }

        # NEXT, save this parameter for the order
        dict set meta($currentOrder) $name $pdict
    }

    #-------------------------------------------------------------------
    # Procs for use in order handlers

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

    # invalid parm
    #
    # parm    Parameter name
    #
    # Returns 1 if parm has already been flagged as invalid, and 0 
    # otherwise.

    proc invalid {parm} {
        dict exists $errors $parm
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

    proc validate {parm script} {
        if {[invalid $parm]} {
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
}


