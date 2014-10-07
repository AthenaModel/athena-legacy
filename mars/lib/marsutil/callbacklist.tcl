#-----------------------------------------------------------------------
# TITLE:
#    callbacklist.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    marsutil(n) callbacklist manager
#
#    This object encapsulates the logic associated with managing
#    a list of callbacks.  Clients can register and cancel their callbacks
#    independently of one another.
#
#-----------------------------------------------------------------------

namespace eval ::marsutil:: {
    namespace export callbacklist
}

snit::type ::marsutil::callbacklist {
    #-------------------------------------------------------------------
    # Instance Variables

    variable counter   0 ;# Counter; used to generate callback IDs.
    variable callbacks   ;# Array of callbacks by callback ID.

    #-------------------------------------------------------------------
    # Constructor and Destructor

    # Default constructor is fine.

    # Default destructor is fine.

    #-------------------------------------------------------------------
    # Public methods

    # register callback
    #
    # callback        A command to be called later.
    #
    # Registers the callback for later use.  Returns the callback ID.
    
    method register {callback} {
        set id [incr counter]

        set callbacks($id) $callback

        return $id
    }

    # cancel id
    #
    # id         Cancels the callback with the specified ID
    #
    # Cancels any scheduled callbacklist.

    method cancel {id} {
        if {[catch {unset callbacks($id)} result]} {
            error "cannot cancel id '$id': no such callback"
        }

        return
    }

    # call ?args....?
    #
    # args...     Arguments; they will vary according to the callback
    #             list.
    #
    # Calls each command on the callbacklist, in no particular order,
    # appending the specified arguments.

    method call {args} {
        foreach id [array names callbacks] {
            uplevel \#0 [concat $callbacks($id) $args]
        }

        return
    }
}




