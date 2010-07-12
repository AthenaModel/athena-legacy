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
#    cli  -- Order originates from the CLI (i.e., the user)
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
#        should be no errors.  Therefore, any error is allowed to propagate 
#        back to the sender of the order, so that the error stack trace is 
#        maximally informative. 
#
#      * Otherwise, if the order is REJECTed the rejection is logged and
#        the error is rethrown.  The presumption is that the sender
#        will do something useful with the rejection dictionary.
#
#      * Otherwise, if the error is unexpected and the interface is "gui",
#        the stack trace is logged and a detailed error message is displayed
#        in a popup.  The scenario is then resync'd with the RDB.
#  
#      * "cli" is handled in all cases just like "gui", except that
#        REJECT messages are formatted for display at the CLI.
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
    # opts-$name          Option definition dictionary
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
    # state           Application's current order state.
    #
    # nullMode:       0 or 1.  While in null mode, the orders don't 
    #                 actually get executed; "order send" returns after 
    #                 saving the parms.

    typevariable info -array {
        initialized 0
        state       ""
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
    # checking            1 if in "order check" and 0 otherwise.

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
        log detail order "init"

        foreach name $orders(names) {
            DefineOrder $name
        }

        # NEXT, save components
        set orderdialog ::orderdialog

        # NEXT, Order processing is up.
        set info(initialized) 1
        log detail order "init complete"
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
        set orders(opts-$name) {
            -alwaysunsaved  0
            -narrativecmd   {}
            -schedulestates {}
            -sendstates     {}
            -table          ""
            -tags           {}
        }
        set orders(parms-$name) ""
        array unset orders pdict-$name-*

        # NEXT, set the current order name
        set deftrans(order) $name

        # NEXT, execute the defscript
        namespace eval ::order::define $orders(defscript-$name)

        # NEXT, check constraints
        require {$orders(title-$name) ne ""} \
            "Order $name has no title"
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
    

    # options option...
    #
    # -alwaysunsaved             
    #     If set, the dialog "Send" buttons will not be disabled when 
    #     there is no "unsaved" data.
    #
    # -narrativecmd cmd
    #     Specifies a command that should return a human-readable
    #     description of the order's effect.  The command will be
    #     called with two additional arguments, the order name and
    #     the parm dict.  If no -narrativecmd is given, the order's
    #     narrative is simply its title.
    #
    # -schedulestates states     
    #     States in which the order can be scheduled.  If clear, the 
    #     order cannot be scheduled.  (Note: controls the act of 
    #     scheduling the order, not the states in which the scheduled
    #     order will execute--all scheduled orders execute in the RUNNING
    #     state.)
    #
    # -sendstates states     
    #     States in which the order can be sent.  If clear, the order 
    #     cannot be sent.
    #
    # -table tableName  
    #     Name of an RDB table or view associated with this order.
    #
    # -tags taglist
    #     Entity tags (requires -table)
    #
    # Sets the order's options.

    proc define::options {args} {
        # FIRST, get the option dictionary
        set odict $orders(opts-$deftrans(order))

        # FIRST, validate and save the options
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -alwaysunsaved {
                    dict set odict $opt 1
                }

                -narrativecmd   -
                -schedulestates -
                -sendstates     -
                -table          -
                -tags           { 
                    dict set odict $opt [lshift args] 
                }

                default {
                    error "Unknown option: $opt"
                }
            }
        }

        # NEXT, check constraints

        # -tags requires -table.
        if {[dict get $odict -tags]  ne "" &&
            [dict get $odict -table] eq ""} {
            error "order option -tags requires -table"
        }

        # NEXT, save the accumulated options
        set orders(opts-$deftrans(order)) $odict
    }


    # parm name fieldType label ?option...?
    #
    # name        The parameter's name
    # fieldType   The field type, e.g., color, enum, key, multi, text, zulu
    # label       The parameter's label string
    # 
    # -defval value      Default value
    # -tags taglist      <SelectionChanged> tags
    # -type enumtype     fieldType enum only, the enum(n) type.
    # -displaylong       enum only, with -type, display long names
    # -display column    key only, display $column rather than $name
    # -schedwheninvalid  Order can be scheduled even if this field is 
    #                    invalid.
    # -refreshcmd cmd    Command to update the field when refreshed.
    #
    # Defines the parameter.  Most of the data feeds the generic
    # order dialog code.

    proc define::parm {name fieldType label args} {
        # FIRST, remember this parameter
        set order $deftrans(order)

        lappend orders(parms-$order) $name

        # NEXT, initialize the pdict
        set pdict [dict create \
                       -fieldtype        $fieldType \
                       -label            $label     \
                       -defval           {}         \
                       -tags             {}         \
                       -type             {}         \
                       -displaylong      0          \
                       -display          ""         \
                       -schedwheninvalid 0          \
                       -refreshcmd       {}]

        # NEXT, accumulate the pdict
        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -defval      -
                -tags        -
                -type        -
                -refreshcmd  -
                -display     {
                    dict set pdict $opt [lshift args] 
                }

                -displaylong      -
                -schedwheninvalid {
                    dict set pdict $opt 1
                }
                default {
                    error "Unknown option: $opt"
                }
            }
        }

        # NEXT, check constraints

        # -type requires "enum"
        if {[dict get $pdict -type] ne "" &&
            $fieldType ne "enum"
        } {
            error "-type is invalid for this field type: \"$name\""
        }

        # An enum parameter must have a -type or a -refreshcmd.
        if {$fieldType eq "enum" &&
            [dict get $pdict -type]       eq "" &&
            [dict get $pdict -refreshcmd] eq ""
        } {
            error \
                "field type \"enum\" requires -type, or -refreshcmd: \"$name\""
        }

        # -displaylong requires -type
        if {[dict get $pdict -displaylong] &&
            [dict get $pdict -type] eq ""
        } {
            error "-displaylong requires enum with -type: \"$name\""
        }

        # -display requires key
        if {[dict get $pdict -display] ne "" &&
            $fieldType ne "key"
        } {
            error "-display requires key field: \"$name\""
        }

        # key and multi parameters requires a "table".
        if {$fieldType in {key multi} && 
            [dict get $orders(opts-$order) -table] eq ""
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

    # validate name
    #
    # name    An order name
    #
    # Validates the name as an order name

    typemethod validate {name} {
        if {![order exists $name]} {
            return -code error -errorcode INVALID \
                "order does not exist: \"$name\""
        }

        return $name
    }


    # exists name
    #
    # name     An order name
    #
    # Returns 1 if there's an order with this name, and 0 otherwise

    typemethod exists {name} {
        return [info exists handler($name)]
    }

    
    # cansend name
    #
    # name    An order name
    #
    # Returns 1 if the order can be sent in the current state,
    # and 0 otherwise.

    typemethod cansend {name} {
        expr {$info(state) in [$type cget $name -sendstates]}
    }

    # canschedule name
    #
    # name    An order name
    #
    # Returns 1 if the order can be scheduled in the current state,
    # and 0 otherwise.

    typemethod canschedule {name} {
        expr {$info(state) in [$type cget $name -schedulestates]}
    }


    # isvalid name
    #
    # name    An order name
    #
    # Returns 1 if the order can either be sent or scheduled in
    # the current state.

    typemethod isvalid {name} {
        expr {[order canschedule $name] || [order cansend $name]}
    }

    # title name
    #
    # name     The name of an order
    #
    # Returns the order's title

    typemethod title {name} {
        return $orders(title-$name)
    }

    # narrative name pdict
    #
    # name     The name of an order
    # pdict    The parameter dictionary for the order
    #
    # Returns the order's narrative.

    typemethod narrative {name pdict} {
        set cmd [order cget $name -narrativecmd]

        if {$cmd eq ""} {
            return [order title $name]
        } else {
            return [{*}$cmd $name $pdict]
        }
    }
    
    # cget name ?opt?
    # 
    # name     The name of an order
    # opt      The name of an order option
    #
    # Returns the order's option dictionary, or the value of the
    # specified option.

    typemethod cget {name {opt ""}} {
        if {$opt eq ""} {
            return $orders(opts-$name)
        } else {
            return [dict get $orders(opts-$name) $opt]
        }
    }

    
    # parms name
    #
    # name     The name of an order
    #
    # Returns a list of the parameter names

    typemethod parms {name} {
        return $orders(parms-$name)
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

    # state ?state?
    #
    # state    A new order state
    #
    # Sets/queries the current order state, which determines which
    # orders are valid/invalid.  Each order is associated with a list
    # of states in which is valid, or is valid in all states.  This
    # module doesn't care what the states are, particularly; it has no
    # logic associated with specific states.  Thus, the application
    # can pick whatever states make sense.

    typemethod state {{state ""}} {
        if {$state ne ""} {
            set info(state) $state
            notifier send $type <State> $state
        }

        return $info(state)
    }


    # send interface name parmdict
    # send interface name parm value ?parm value...?
    #
    # interface       gui|cli|test|sim
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
        if {$interface ni {gui cli test sim}} {
            error \
     "Unexpected error in $name, invalid interface spec: \"$interface\""
        }

        # NEXT, save the interface.
        set trans(interface) $interface

        # NEXT, we're not just checking.
        set trans(checking) 0

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
            # FIRST, check the state.  Note that if the interface is
            # "sim", this doesn't matter; the sim is in control
            
            if {$interface ne "sim"} {
                set states [$type cget $name -sendstates]

                if {$info(state) ni $states} {
                    
                    reject * "
                        Simulation state is $info(state), but order is valid
                        only in these states: [join $states {, }]
                    "

                    returnOnError
                }
            }
            
            # NEXT, call the handler
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
            if {$ecode eq "REJECT"} {
                if {$interface eq "cli"} {
                    set result [FormatRejectionForCLI $result]
                }

                log warning order $result                    
                return {*}$opts $result
            }

            if {$ecode eq "CANCEL"} {
                log warning order $result                    
                return "Order was cancelled."
            }

            if {$interface in {gui cli sim}} {
                log error order "Unexpected error in $name:\n$result"
                log error order "Stack Trace:\n$einfo"

                [app topwin] tab view slog

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

                if {[sim state] eq "RUNNING"} {
                    # TBD: might need to send order?
                    sim mutate pause
                }

                sim dbsync
                
                return "Unexpected error while handling order."
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

        # NEXT, notify the app that the order has been accepted.
        notifier send $type <Accepted> $name $parmdict

        # NEXT, return the result, if any.
        return $result
    }

    # FormatRejectionForCLI errdict
    #
    # errdict     A REJECT error dictionary
    #
    # Formats the rejection error dictionary for display at the console.
    
    proc FormatRejectionForCLI {errdict} {
        if {[dict exists $errdict *]} {
            lappend out [dict get $errdict *]
        }

        dict for {parm msg} $errdict {
            if {$parm ne "*"} {
                lappend out "$parm: $msg"
            }
        }

        return [join $out \n]
    }



    # check name parmdict
    # check name parm value ?parm value...?
    #
    # name            The order's name
    # parmdict        The order's parameter dictionary
    # parm,value...   The parameter dictionary passed as separate args.
    #
    # Checks the order, throwing a REJECT error if invalid.

    typemethod check {name args} {
        # FIRST, get the parmdict.
        if {[llength $args] > 1} {
            set parmdict $args
        } else {
            set parmdict [lindex $args 0]
        }

        # NEXT, do we have an order handler?
        require {[info exists handler($name)]} "Undefined order: $name"

        # NEXT, save the interface.
        set trans(interface) sim

        # NEXT, we're checking.
        set trans(checking) 1

        # NEXT, save the order parameters in the parms array, saving
        # the order name.
        set validParms [order parms $name]

        array unset parms

        dict for {parm value} $parmdict {
            require {$parm in $validParms} "Unknown parameter: \"$parm\""

            set parms($parm) $value
        }

        set parms(_order) $name

        # NEXT, set up the error messages and call the order handler,
        # rolling back the database automatically on error.
        set trans(errors) [dict create]
        set trans(level)  NONE
        set trans(undo)   {}

        # NEXT, call the handler
        set code [catch { $handler($name) } result opts]

        if {$code == 0} {
            return -code error \
                "order $name responds improperly on validity check"
        } else {
            set ecode [dict get $opts -errorcode]

            if {$ecode ne "CHECKED"} {
                return {*}$opts $result
            }
        }

        return
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
                -oldnum {
                    set oldvalue [lshift args]

                    if {$parms($parm) == $oldvalue} {
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
        dict set trans(errors) $parm [normalize $msg]
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

    # returnOnError ?-final?
    #
    # Handles accumulated errors.

    proc returnOnError {{flag ""}} {
        # FIRST, Were there any errors?
        if {[dict size $trans(errors)] == 0} {
            # If this is the -final check, and we're just checking,
            # escape out of the order.
            if {$flag eq "-final" && $trans(checking)} {
                return -code error -errorcode CHECKED
            } else {
                # Just return normally.
                return
            }
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
        return
    }

    #---------------------------------------------------------------
    # Order Scheduling

    # schedule interface timespec name parmdict
    #
    # interface    gui, cli, test, sim
    # timespec     A time specification string
    # name         The name of the order
    # parmdict     The parmdict for the order.
    # 
    # Validates the order, taking -schedwheninvalid into account,
    # and schedules it if valid.

    typemethod schedule {interface timespec name parmdict} {
        # FIRST, check the order.
        set code [catch {order check $name $parmdict} result opts]

        if {$code} {
            set ecode [dict get $opts -errorcode]

            # FIRST, if the error code isn't REJECT, just rethrow
            if {$ecode ne "REJECT"} {
                return {*}$opts $result
            }

            # NEXT, if any invalid parameter isn't escaped, rethrow.
            foreach {parm msg} $result {
                if {![order parm $name $parm -schedwheninvalid]} {
                    return {*}$opts $result
                }
            }
        }

        order send $interface ORDER:SCHEDULE \
            [list timespec $timespec name $name parmdict $parmdict]
    }

    # scheduled names
    #
    # Returns a list of the IDs of the scheduled orders

    typemethod {scheduled names} {} {
        rdb eval {SELECT id FROM eventq_queue_orderExecute}
    }


    # scheduled validate id
    #
    # id      A scheduled order ID
    #
    # Validates and returns the order ID

    typemethod {scheduled validate} {id} {
        if {$id ni [order scheduled names]} {
            return -code error -errorcode INVALID \
                "order not scheduled: \"$id\""
        }

        return $id
    }
    

    # mutate schedule dict
    #
    # dict        A dictionary of order parameters
    #
    #    timespec     The time in ticks at which the order should
    #                 execute, > now.
    #    name         The name of the order
    #    parmdict     The parmdict for the order.
    #
    # Schedules the order to occur at the specified time, and 
    # returns the undo script.

    typemethod {mutate schedule} {dict} {
        dict with dict {
            set narrative [order narrative $name $parmdict]

            log normal order "at $timespec, schedule $narrative\n[list $name: $parmdict]"
            set id [eventq schedule orderExecute \
                        $timespec $name $narrative $parmdict]

            notifier send ::order <Queue>
            
            # NEXT, return the undo script
            return [list order UndoSchedule]
        }
    }

    # UndoSchedule
    #
    # Undo script for mutate schedule

    typemethod UndoSchedule {} {
        eventq undo schedule
        notifier send ::order <Queue>
    }


    # mutate cancel id
    #
    # id      The eventq id of the order to cancel
    #
    # Cancels the order, but returns an undo script.

    typemethod {mutate cancel} {id} {
        # FIRST, get undo data
        rdb eval {
            SELECT t, name, parmdict FROM eventq_queue_orderExecute
            WHERE id=$id
        } {}


        # NEXT, cancel the order
        log normal order "cancel order $id at $t: [list $name: $parmdict]"

        set undoToken [eventq cancel $id]

        notifier send ::order <Queue>
        
        # NEXT, return the undo script
        return [list order UndoCancel $undoToken]
    }

    # UndoCancel undoToken
    #
    # Undo script for mutate cancel

    typemethod UndoCancel {undoToken} {
        eventq undo cancel $undoToken
        notifier send ::order <Queue>
    }
}


#-------------------------------------------------------------------
# orderExecute event

eventq define orderExecute {name narrative parmdict} {
    if {[catch {
        order send sim $name $parmdict
    } result]} {
        # Unexpected errors are handled by order send; this is
        # a rejection.

        if {[app topwin] ne ""} {
            [app topwin] tab view slog

            app error {
                |<--
                $name

                This scheduled order was rejected.  Please
                see the log for the reason why.  You may
                rewind to the previous snapshot to replace
                or delete the order, or you may continue
                running from here.
            }
        }

        sim mutate pause
    }
} 


#-------------------------------------------------------------------
# Order-related Orders

# ORDER:SCHEDULE
#
# Schedules an order to be executed in the future.

order define ::order ORDER:SCHEDULE {
    title "Schedule Order"
    options -sendstates {PREP PAUSED}

    # Note: we're defining the parameters here, but the dialog will
    # never be used.
    parm timespec  text "Time Spec"
    parm name      enum "Order Name"  -type order
    parm parmdict  text "Parm Dict"
} {
    # FIRST, prepare the parameters
    prepare timespec -required -toupper -type {simclock future}
    prepare name     -required -toupper -type order
    prepare parmdict

    returnOnError

    # NEXT, time must be later than now.
    validate timespec {
        if {$parms(timespec) < [simclock now]} {
            reject timespec "The scheduled time must not be in the past."
        }

        if {[order state] ne "PREP" && $parms(timespec) == [simclock now]} {
            reject timespec \
                "The scheduled time must be strictly in the future."
        }
    }

    # NEXT, the order must be schedulable
    validate name {
        if {![order canschedule $parms(name)]} {
            reject name "The named order cannot be scheduled in advance."
        }
    }

    returnOnError -final

    # NEXT, schedule the order and return the undo script
    setundo [order mutate schedule [array get parms]]
}


# ORDER:CANCEL
#
# Cancels a scheduled order.

order define ::order ORDER:CANCEL {
    title "Cancel Scheduled Order"
    options -sendstates {PREP PAUSED}

    # Note: we're defining the parameters here, but the dialog will
    # never be used.
    parm id enum "Order ID" -type {order scheduled}
} {
    # FIRST, prepare the parameters
    prepare id -required -type {order scheduled}

    returnOnError -final

    # NEXT, schedule the order and return the undo script
    setundo [order mutate cancel $parms(id)]
}

