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
#    Insofar as possible, input validation and error-handling are
#    automated, so that all orders are trivially easy to make work the
#    same.  Orders are defined with sufficient information that order
#    dialogs can be generated automatically.
#
#    ::order is a singleton object implemented as a snit::type.  To
#    initialize it, call "::order init".
#
# ERROR HANDLING
#
#    order(sim) throws two kinds of errors when processing an order.
#
#    If the -errorcode is REJECT, the order was rejected due to errors
#    in the order parameters.  The error return is a dictionary of
#    parameter names and error messages.
#
#    Otherwise, the error is unexpected, i.e, the order handler, or
#    code called by it, threw an error unrelated to validation of the
#    order parms.  This usually indicates a bug in the code.
#
#    How errors are handled depends on the interface.
#
# ORDER INTERFACES:
#
#    Orders can be received from the simulation, the GUI (or, more 
#    generally, from the user) or from the test suite.  The interface
#    is specified on "order send" using one of the following interface
#    specifiers:
#
#    gui  -- Order originates from the GUI (i.e., the user)
#    test -- Order originates from the test suite
#    sim  -- Order originates elsewhere in the simulation
#
#    The chosen interface affects the outcome in the following ways:
#
#    * The order handler can modify its behavior depending on the interface.
#      For example, a *:DELETE order handler can pop up a warning dialog
#      if the interface is "gui", and "cancel" the order if need be.
#
#    * Ordinarily, all orders are added to the CIF and can be undone
#      and redone.  Orders received from the "sim", however, are really
#      fancy procedure calls, and so the CIF is bypassed.
#
#    * Ordinarily, the call to the order handler is wrapped in an
#      SQL transaction, so that unexpected failures do not corrupt the
#      RDB.  When the interface is "test", failed changes are not rolled
#      back, to make it easier to debug the failure.
#
#    * If the order handler throws an error, how it is handled depends on
#      the interface.
#
#      * When "sim" sends an order, it is a fancy procedure call; there 
#        should be no erroordersrs.  Therefore, any error is allowed to propagate 
#        back to the sender of the order, so that the error stack trace is 
#        maximally informative. 
#
#      * Otherwise, if the order is REJECTed the rejection is logged and
#        the error is rethrown.  The presumption is that the sender
#        will do something useful with the rejection dictionary.
#
#      * Otherwise, if the error is unexpected and the interface is "gui",
#        the stack trace is logged and a detailed error message is displayed
#        in a popup.  The scenario is then reconfigured.
#
#      * Otherwise, the error is simply rethrown.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# order

# Create the defscript namespace immediately.

namespace eval ::order::define:: {}


snit::type order {
    # Make it an ensemble
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Constructor
    
    typeconstructor {
        # TBD
    }

    #-------------------------------------------------------------------
    # Type Components

    typecomponent orderdialog     ;# orderdialog(sim)



    #-------------------------------------------------------------------
    # Checkpointed Variables

    # None

    #-------------------------------------------------------------------
    # Order Definition metadata

    # Order handler name by order name
    
    typevariable handler -array {}

    # orders: array of order definition data.
    #
    # names               List of order names
    # defscript-$name     Definition script for the named order.
    # title-$name         The order's title
    # table-$name         The order's associated RDB table, or ""
    # parms-$name         List of the names of the order's parameters
    # pdict-$name-$parm   Parameter definition dictionary
   
    typevariable orders -array {
        names {}
    }

    #-------------------------------------------------------------------
    # Non-checkpointed variables

    # info -- array of scalars
    #
    # initialized:    0 or 1.  Indicates whether "order init" has been
    #                 called or not.
    #
    # nullMode:       0 or 1.  While in null mode, the orders don't 
    #                 actually get executed; "order send" returns after 
    #                 saving the parms.

    typevariable info -array {
        initialized 0
        nullMode    0
    }

    #-------------------------------------------------------------------
    # Transient Variables

    # The following variables are used while defining an order:

    # deftrans: Array of transient order definition data
    #
    # order     The name of the order currently being defined.
    
    typevariable deftrans -array {}
    
    # The following variables are used while processing an order, and
    # are cleared before every new order.

    # trans: Array of transient data
    # interface           The current interface
    # errors              Dictionary of parameter names and error messages
    # level               Error level: NONE or REJECT
    # undo                Undo script for this order

    typevariable trans -array {}

    # Parms: array of order parameter values, by parameter name.
    # This array is aliased into every order handler.
    typevariable parms             ;# Array of order parameters


    #-------------------------------------------------------------------
    # Delegated Typemethods

    delegate typemethod enter to orderdialog

    #-------------------------------------------------------------------
    # Initialization

    # init
    #
    # Initializes the module, executing the definition scripts for
    # each order.

    typemethod init {} {
        # FIRST, evaluate all of the existing definition scripts.
        log detail order "Initializing"

        foreach name $orders(names) {
            DefineOrder $name
        }

        # NEXT, save components
        set orderdialog ::orderdialog

        # NEXT, Order processing is up.
        set info(initialized) 1
        log detail order "Initialized"
    }

    # initialized
    #
    # Returns 1 if the module has been initialized, and 0 otherwise.

    typemethod initialized {} {
        return $info(initialized)
    }

    #-------------------------------------------------------------------
    # Order Definition

    # define module name metadata body
    #
    # module      The name of a module (a snit::type)
    # name        The name of the order
    # defscript   The order's definition script 
    # body        The body of the order
    #
    # Defines a proc within the module::orders namespace in which all
    # type variables appear.  This allows orders to be defined
    # outside the order.tcl file.

    typemethod define {module name defscript body} {
        # FIRST, save the defscript
        order DefMeta $name $defscript

        # NEXT, get the module variables
        set modVarList [$module info typevars]

        if {[llength $modVarList] > 0} {
            set modvars [list namespace upvar $module]

            foreach tv [$module info typevars] {
                lappend modvars $tv [namespace tail $tv]
            }
        } else {
            set modvars [list]
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

    # DefMeta name script
    #
    # name     An order name
    # script   A definition script
    #
    # Specifies the metadata definition script for the existing orders.
    # The script is saved, to be executed at "order init"; if the
    # module is already initialized, then the script is executed
    # immediately.

    typemethod DefMeta {name script} {
        # FIRST, save the script
        if {$name ni $orders(names)} {
            lappend orders(names) $name
        }

        set orders(defscript-$name) $script

        # NEXT, execute it if the module is already initialized.
        if {[$type initialized]} {
            DefineOrder $name
        }
    }

    # DefineOrder name
    #
    # name      Order name
    #
    # Executes the definition script for this order

    proc DefineOrder {name} {
        log detail order "define $name"

        # FIRST, initialize the data values
        set orders(title-$name) ""
        set orders(table-$name) ""
        set orders(parms-$name) ""
        array unset orders pdict-$name-*

        # NEXT, set the current order name
        set deftrans(order) $name

        # NEXT, execute the defscript
        namespace eval ::order::define $orders(defscript-$name)

        # NEXT, check constraints
        require {$orders(title-$name) ne ""} \
            "Order $name has no title"

        require {[llength $orders(parms-$name)] > 0} \
            "Order $name has no parameters"
    }

    #-------------------------------------------------------------------
    # Definition Script Procs
    #
    # These procs are defined in the ::order::define:: namespace, which
    # is where definition scripts are evaluated.

    # title titleText
    #
    # titleText    Human-readable order title
    #
    # Sets the order's title text

    proc define::title {titleText} {
        set orders(title-$deftrans(order)) $titleText
    }
    
    # table tableName
    #
    # tableName     name of an RDB table or view associated with 
    #               this order.
    #
    # Saves the table name.
    
    proc define::table {tableName} {
        set orders(table-$deftrans(order)) $tableName
    }

    # parm name fieldType label ?option...?
    #
    # name        The parameter's name
    # fieldType   The field type, e.g., key, text, enum
    # label       The parameter's label string
    # 
    # -defval value    Default value
    # -tags taglist    <EntitySelect> tags
    # -type enumtype   fieldType enum only, the enum(n) type.
    # -refresh         Setting this parm triggers a refresh.
    # -refreshcmd      Command to update the field when refreshed.
    #
    # Defines the parameter.  Most of the data feeds the generic
    # order dialog code.

    proc define::parm {name fieldType label args} {
        # FIRST, remember this parameter
        set order $deftrans(order)

        lappend orders(parms-$order) $name

        # NEXT, initialize the pdict
        set pdict [dict create \
                       -fieldtype  $fieldType \
                       -label      $label     \
                       -defval     {}         \
                       -tags       {}         \
                       -type       {}         \
                       -refresh    0          \
                       -refreshcmd {}]

        # NEXT, accumulate the pdict
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -defval     -
                -tags       -
                -type       -
                -refreshcmd { 
                    dict set pdict $opt [lshift args] 
                }

                -refresh {
                    dict set pdict -refresh 1
                }

                default {
                    error "Unknown option: $opt"
                }
            }
        }

        # NEXT, check constraints

        # An enum parameter must have a -type or a -refreshcmd.
        if {$fieldType eq "enum" &&
            [dict get $pdict -type]       eq "" &&
            [dict get $pdict -refreshcmd] eq ""
        } {
            error \
                "field type \"enum\" requires -type, or -refreshcmd: \"$name\""
        }

        # key and multi parameters requires a "table".
        if {$fieldType in {key multi} && 
            $orders(table-$order) eq ""
        } {
            error \
                "missing table, field type $fieldType requires it: \"$name\""
        } 

        # A multi parameter must be the first parameter.
        if {$fieldType eq "multi"} {
            if {[llength $orders(parms-$order)] > 1} {
                error "misplaced multi parameter, must be first: \"$name\""
            }
        }

        # A key parameter can only be preceded by key parameters.
        if {$fieldType eq "key"} {
            foreach p $orders(parms-$order) {
                if {$p eq $name} {
                    break
                }

                if {[dict get $orders(pdict-$order-$p) -fieldtype] ne "key"} {
                    error \
    "misplaced key parameter, must precede all non-key parameters: \"$name\""
                }
            }
        }

        # Only enum can have -refresh.
        if {$fieldType ne "enum" && 
            [dict get $pdict -refresh]
        } {
            error \
                "field type \"$fieldType\" does not allow -refresh: \"$name\""
        }

        # Key and multi parameters cannot have -refreshcmd.
        if {$fieldType in {key multi} && 
            [dict get $pdict -refreshcmd] ne ""
        } {
            error "field type \"$fieldType\" does not allow -refreshcmd"
        }

        # NEXT, save the accumulated pdict
        set orders(pdict-$order-$name) $pdict
    }


    #-------------------------------------------------------------------
    # Order Queries
    #
    # These commands are used to query the existing orders and their
    # metadata.

    # names
    #
    # Returns the names of the currently defined orders
    
    typemethod names {} {
        return $orders(names)
    }

    # title name
    #
    # name     The name of an order
    #
    # Returns the order's title

    typemethod title {name} {
        return $orders(title-$name)
    }


    # table name
    #
    # name     The name of an order
    #
    # Returns the order's RDB table, or ""

    typemethod table {name} {
        return $orders(table-$name)
    }


    # parms name
    #
    # name     The name of an order
    #
    # Returns a list of the parameter names

    typemethod parms {name} {
        return $orders(parms-$name)
    }


    # exists name
    #
    # name     An order name
    #
    # Returns 1 if there's an order with this name, and 0 otherwise

    typemethod exists {name} {
        return [info exists handler($name)]
    }

    # parm order parm ?opt?
    #
    # order     The name of an order
    # parm      The name of a parameter
    # opt       The name of an option parameter
    #
    # If opt is omitted, returns the parm's parameter definition 
    # dictionary (pdict).  Otherwise, returns the value of the particular
    # option.

    typemethod parm {order parm {opt ""}} {
        if {$opt eq ""} {
            return $orders(pdict-$order-$parm)
        } else {
            return [dict get $orders(pdict-$order-$parm) $opt]
        }
    }


    #-------------------------------------------------------------------
    # Sending Orders

    # send interface name parmdict
    # send interface name parm value ?parm value...?
    #
    # interface       sim|gui
    # name            The order's name
    # parmdict        The order's parameter dictionary
    # parm,value...   The parameter dictionary passed as separate args.
    #
    # Processes the order, handling errors in the appropriate way for the
    # interface.

    typemethod send {interface name args} {
        # FIRST, get the parmdict.
        if {[llength $args] > 1} {
            set parmdict $args
        } else {
            set parmdict [lindex $args 0]
        }

        # NEXT, log the order
        log normal order [list $name from '$interface': $parmdict]

        # NEXT, do we have an order handler?
        require {[info exists handler($name)]} "Undefined order: $name"

        # NEXT, is the interface valid?
        if {$interface ni {gui test sim}} {
            error \
     "Unexpected error in $name, invalid interface spec: \"$interface\""
        }

        # NEXT, save the interface.
        set trans(interface) $interface

        # NEXT, save the order parameters in the parms array, saving
        # the order name.
        set validParms [order parms $name]

        array unset parms

        dict for {parm value} $parmdict {
            require {$parm in $validParms} "Unknown parameter: \"$parm\""

            set parms($parm) $value
        }

        set parms(_order) $name

        # NEXT, in null mode we're done.
        if {$info(nullMode)} {
            return
        }

        # NEXT, set up the error messages and call the order handler,
        # rolling back the database automatically on error.
        set trans(errors) [dict create]
        set trans(level)  NONE
        set trans(undo)   {}

        if {[catch {
            if {$interface ne "test"} {
                rdb transaction {
                    $handler($name)
                }
            } else {
                # On "test", don't rollback automatically, to make
                # debugging easier.
                $handler($name)
            }
        } result opts]} {
            # FIRST, get the error info
            set einfo [dict get $opts -errorinfo]
            set ecode [dict get $opts -errorcode]

            # NEXT, handle the result 
            if {$interface eq "sim"} {
                error "Unexpected error in $name:\n$result" $einfo
            }

            if {$ecode eq "REJECT"} {
                log warning order $result                    
                return {*}$opts $result
            }

            if {$ecode eq "CANCEL"} {
                log warning order $result                    
                return
            }

            if {$interface eq "gui"} {
                log error order "Unexpected error in $name:\n$result"
                log error order "Stack Trace:\n$einfo"

                app error {
                    |<--
                    $name

                    There was an unexpected error during the 
                    handling of this order.  The scenario has 
                    been rolled back to its previous state, so 
                    the application data  should not be 
                    corrupted.  However:

                    * You should probably save the scenario under
                      a new name, just in case.

                    * The error has been logged in detail.  Please
                      contact JPL to get the problem fixed.
                }

                scenario reconfigure
                
                return
            }

            # Non-GUI error return.
            error \
                "Unexpected error in $name:\n$result" $einfo
        }

        # NEXT: Add order to CIF, unless it was generated by the
        # simulation.
        if {$interface ne "sim"} {
            cif add $name $parmdict $trans(undo)
        }

        # NEXT, return the result, if any.
        return $result
    }


    # nullmode flag
    #
    # flag      A boolean flag
    #
    # Turns nullmode on and off.  This is used for testing commands
    # that send orders.

    typemethod nullmode {flag} {
        set info(nullMode) $flag
    }


    # lastparms
    #
    # Returns a dictionary of the most recent order parms, with one
    # additional parm, _order.

    typemethod lastparms {} {
        array get parms
    }


    #-------------------------------------------------------------------
    # Procs for use in order handlers

    # interface
    #
    # Returns the name of the current interface

    proc interface {} {
        return $trans(interface)
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

        # NEXT, trim the data.
        set parms($parm) [string trim $parms($parm)]


        # NEXT, process the options, so long as there's no explicit
        # error.

        while {![dict exists $trans(errors) $parm] && [llength $args] > 0} {
            set opt [lshift args]
            switch -exact -- $opt {
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
                -listof {
                    set parmtype [lshift args]

                    validate $parm {
                        set newvalue [list]

                        foreach val $parms($parm) {
                            lappend newvalue [{*}$parmtype validate $val]
                        }

                        set parms($parm) $newvalue
                    }
                }
                -xform {
                    set cmd [lshift args]

                    validate $parm {
                        set parms($parm) [{*}$cmd $parms($parm)]
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
    # the error dictionary, and set the trans(level) to REJECT.

    proc reject {parm msg} {
        dict set trans(errors) $parm $msg
        set trans(level) REJECT
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
        if {$parms($parm) eq "" || [dict exists $trans(errors) $parm]} {
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
        if {[dict size $trans(errors)] == 0} {
            return
        }

        # FINALLY, throw the accumulated errors at the specified
        # error level; this will terminate order processing.
        
        return -code error -errorcode $trans(level) $trans(errors)
    }

    # cancel
    #
    # Use this in the rare case where the user can interactively 
    # cancel an order that's in progress.

    proc cancel {} {
        return -code error -errorcode CANCEL \
            "The order was cancelled by the user."
    }

    # setundo script
    #
    # script    An undo script
    #
    # Sets the undo script for the current order.

    proc setundo {script} {
        set trans(undo) $script
    }
}



