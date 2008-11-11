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

    typevariable meta -array {}    ;# Array of meta dicts by order name

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

        # NEXT, save the order name.
        set parms(_order) $name

        # NEXT, in null mode we're done.
        if {$nullMode} {
            return
        }

        # NEXT, set up the error messages and call the order handler.
        set errors [dict create]
        set errorLevel NONE

        if {$interface eq "client"} {
            if {[catch $name result opts]} {
                if {[dict get $opts -errorcode] eq "REJECT"} {
                    return {*}$opts $result
                } else {
                    error \
                        "Unexpected error in $displayName:\n$result" \
                        [dict get $opts -errorinfo]
                }
            }
        } elseif {$interface eq "sim"} {
            if {[catch $name result]} {
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

    # define name metadata body
    #
    # name        The name of the order
    # metadata    A dictionary of meta-data about the order.
    # body        The body of the order
    #
    # Defines a proc within the ::order namespace in which all
    # type variables appear.  This allows orders to be defined
    # outside the order.tcl file.

    typemethod define {name metadata body} {
        # FIRST, get the variables
        set vars [list namespace upvar $type]
        
        foreach tv [$type info typevars] {
            lappend vars $tv [namespace tail $tv]
        }

        # NEXT, define the handler
        proc ${type}::$name {} "$vars\n$body"

        # NEXT, save the metadata
        set meta($name) $metadata
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


