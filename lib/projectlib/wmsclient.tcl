#-----------------------------------------------------------------------
# TITLE:
#   wmsclient.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Client type for accessing WMS servers.  Uses httpagent(n); 
#   one request can be active at a time.
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export wmsclient
}


#-----------------------------------------------------------------------
# wmsclient

snit::type ::projectlib::wmsclient {
    #-------------------------------------------------------------------
    # Type Variables

    typevariable wmsVersion 1.3.0

    #-------------------------------------------------------------------
    # Components

    component agent -public agent ;# The httpagent(n) object.
    

    #-------------------------------------------------------------------
    # Options

    delegate option -timeout to agent

    # -servercmd cmd
    #
    # A command to call when the [$o server state] changes.

    option -servercmd

    #-------------------------------------------------------------------
    # Instance Variables

    # info - Array of state data
    #
    # server-url     - Base server URL.
    # server-state   - Server state: UNKNOWN, WAITING, ERROR, OK
    # server-status  - Human-readable text for server-state
    # server-error   - Detailed debugging info for connection errors 

    variable info -array {
        server-url     ""
        server-state   IDLE
        server-status  "No connection attempted"
    }


    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the HTTP agent.
        install agent using httpagent ${selfns}::agent

        # NEXT, configure the options
        $self configurelist $args
    }

    #-------------------------------------------------------------------
    # server API

    # server connect url
    #
    # url  - The server's base URL
    #
    # Attempts to connect to the given WMS server.  The connection
    # is done asynchronously, and can time out.

    method {server connect} {url} {
        set info(server-url)    $url
        set info(server-state)  WAITING
        set info(server-status) "Waiting for server"
        set info(server-error)  ""

        set query [dict create      \
            SERVICE WMS             \
            VERSION $wmsVersion     \
            REQUEST GetCapabilities]


        $agent get $url \
            -command [mymethod CapabilitiesCmd] \
            -query   $query
    }

    # CapabilitiesCmd
    #
    # This command is called when Capabilities 
    # data is returned from the WMS server (or when the request fails).

    method CapabilitiesCmd {} {
        # FIRST, handle errors.
        set info(server-state) [$agent state]

        if {$info(server-state) ne "OK"} {
            set info(server-status) [$agent status]
            set info(server-error)  [$agent error]
            callwith $options(-servercmd)
            return
        }

        # NEXT, The request returned an HTTP status.  Handle all of the
        # cases.

        if {0} {
            # Result isn't a WMS_Capabilities document?
            set info(server-state)  ERROR
            set info(server-status) "Could not retrieve capabilities"
            set info(server-error)  \
                "Server returned something other than WMS_Capabilities"
        } elseif {0} {
            # WMS Version isn't 1.3.0?
            set info(server-state)  ERROR
            set info(server-status) "WMS version mismatch"
            set info(server-error)  \
                "Server does not support WMS 1.3.0"
        } else {
            # Success!
            set info(server-state)  OK
            set info(server-status) "Connection is Ready"
            set info(server-error)  ""

            # TBD: Save all of the retrieved data.
        }

        callwith $options(-servercmd)
    }

    # server url
    #
    # Returns the server's base URL

    method {server url} {} {
        return $info(server-url)
    }

    # server state
    #
    # Returns the current server state code.    

    method {server state} {} {
        return $info(server-state)
    }

    # server status
    #
    # Returns the current server status text.    

    method {server status} {} {
        return $info(server-status)
    }

    # server error
    #
    # Returns the current server status text.    

    method {server error} {} {
        return $info(server-error)
    }
}
