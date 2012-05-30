#-----------------------------------------------------------------------
# TITLE:
#    appserver_parmdb.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: parmdb(5)
#
#    my://app/parmdb/...
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module PARMDB {
    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /parmdb {parmdb/?} \
            tcl/linkdict [myproc /parmdb:linkdict] \
            text/html [myproc /parmdb:html] {
                An editable table displaying the contents of the
                model parameter database.  This resource can take a parameter,
                a wildcard pattern; the table will contain only
                parameters that match the pattern.
            }

        appserver register /parmdb/{subset} {parmdb/(\w+)/?} \
            text/html [myproc /parmdb:html] {
                An editable table displaying the contents of the given
                subset of the model parameter database.  The subsets
                are the top-level divisions of the database, e.g.,
                "sim", "aam", "force", etc.  In addition, the subset
                "changed" will return all parameters with non-default
                values.
                This resource can take a parameter,
                a wildcard pattern; the table will contain only
                parameters that match the pattern.
            }

        
    }

    #-------------------------------------------------------------------
    # /parmdb
    # /parmdb/{subset}
    #
    # Match Parameters:
    #
    # {subset} => $(1)   - The subset, or "" for all, or "changed".
    
    # /parmdb:linkdict udict matcharray
    #
    # Returns a parmdb resource as a tcl/linkdict.  Does not handle
    # subsets or queries.

    proc /parmdb:linkdict {udict matchArray} {
        dict set result /parmdb/changed label "Changed"
        dict set result /parmdb/changed listIcon ::marsgui::icon::pencil12

        foreach subset {
            sim
            aam
            activity
            attitude
            control
            dam
            demsit
            demog
            econ
            ensit
            force
            hist
            uram
            rmf
            service
            strategy
        } {
            set url /parmdb/$subset

            dict set result $url label "$subset.*"
            dict set result $url listIcon ::marsgui::icon::pencil12
        }

        return $result
    }

    # /parmdb:html udict matchArray
    #
    # Matches:
    #   $(1) - The major subset, or "changed".
    #
    # Returns a page that documents the current parmdb(5) values.
    # There can be a query; if so, it is treated as a glob-pattern,
    # and only parameters that match are included.

    proc /parmdb:html {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, are we looking at all parms or only changed parms?
        if {$(1) eq "changed"} {
            set initialSet nondefaults
        } else {
            set initialSet names
        }

        # NEXT, get the pattern, if any.
        set pattern [dict get $udict query]

        # NEXT, get the base set of parms.
        if {$pattern eq ""} {
            set parms [parm $initialSet]
        } else {
            set parms [parm $initialSet $pattern]
        }

        # NEXT, if some subset other than "changed" was given, find
        # only those that match.

        if {$(1) ne "" && $(1) ne "changed"} {
            set subset "$(1).*"
            
            set allParms $parms
            set parms [list]

            foreach parm $allParms {
                if {[string match $subset $parm]} {
                    lappend parms $parm
                }
            }
        }

        # NEXT, get the title

        set parts ""

        if {$(1) eq "changed"} {
            lappend parts "Changed"
        } elseif {$(1) ne ""} {
            lappend parts "$(1).*"
        }

        if {$pattern ne ""} {
            lappend parts [htools escape $pattern]
        }

        set title "Model Parameters: "

        if {[llength $parts] == 0} {
            append title "All"
        } else {
            append title [join $parts ", "]
        }

        ht page $title
        ht title $title

        # NEXT, if no parameters are found, note it and return.
        if {[llength $parms] == 0} {
            ht putln "No parameters match the query."
            ht para
            
            ht /page
            return [ht get]
        }

        ht table {"Parameter" "Default Value" "Current Value" ""} {
            foreach parm $parms {
                ht tr {
                    ht td left {
                        set path [string tolower [join [split $parm .] /]]
                        ht link my://help/parmdb/$path $parm 
                    }
                    
                    ht td left {
                        set defval [htools escape [parm getdefault $parm]]
                        ht putln <tt>$defval</tt>
                    }

                    ht td left {
                        set value [htools escape [parm get $parm]]

                        if {$value eq $defval} {
                            set color black
                        } else {
                            set color "#990000"
                        }

                        ht putln "<font color=$color><tt>$value</tt></font>"
                    }

                    ht td left {
                        if {[parm islocked $parm]} {
                            ht image ::marsgui::icon::locked
                        } elseif {![order cansend PARM:SET]} {
                            ht image ::marsgui::icon::pencil22d
                        } else {
                            ht putln "<a href=\"gui:/order/PARM:SET?parm=$parm\">"
                            ht image ::marsgui::icon::pencil22
                            ht putln "</a>"
                        }
                    }
                }
            }
        }

        return [ht get]
    }
}



