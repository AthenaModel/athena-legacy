#-----------------------------------------------------------------------
# TITLE:
#    prefs.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena user preferences
#
#    The module delegates most of its function to parmset(n).
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export prefs
}

#-------------------------------------------------------------------
# parm

snit::type ::projectlib::prefs {
    # Make it a singleton
    pragma -hasinstances 0

    #-------------------------------------------------------------------
    # Typecomponents

    typecomponent ps ;# The parmset(n) object

    #-------------------------------------------------------------------
    # Type Variables

    # Name of the user preferences file.
    typevariable prefsFile ~/.athena/user.prefs

    #-------------------------------------------------------------------
    # Public typemethods

    delegate typemethod cget       to ps
    delegate typemethod configure  to ps
    delegate typemethod docstring  to ps
    delegate typemethod get        to ps
    delegate typemethod getdefault to ps
    delegate typemethod items      to ps
    delegate typemethod names      to ps
    delegate typemethod manlinks   to ps
    delegate typemethod manpage    to ps


    # init
    #
    # Initializes the module

    typemethod init {} {
        # Don't initialize twice.
        if {$ps ne ""} {
            return
        }

        # FIRST, create the parm set
        set ps [parmset %AUTO%]

        # NEXT, define parameters

        $ps subset cli {
            Parameters which affect the Command Line Interface (CLI).
        }

        $ps define cli.maxlines ::projectlib::iminlines 500 {
            The maximum number of lines of text to be retained in the
            main window's command line interface scrollback buffer:
            an integer number no less than 100.
        }

        $ps subset helper {
            Names of helper applications.
        }

        $ps define helper.browser snit::stringtype "firefox" {
            Name of web browser application, for opening pages
            from the Detail browser.
        }

        $ps subset session {
            Parameters which affect session management.
        }

        $ps define session.purgeHours ::projectlib::iquantity 4 {
            The duration in hours for which session working directories
            are retained.  At startup, athena_sim(1) automatically 
            purges all working directories older than this amount.
        }
    }

    # help parm
    #
    # parm   A parameter name
    #
    # Returns the docstring.

    typemethod help {parm} {
        return [$ps docstring $parm]
    }

    # set parm value
    #
    # parm     A parameter name
    # value    A value
    # 
    # Sets the parameter's value, and saves the preferences.

    typemethod set {parm value} {
        $ps set $parm $value
        $ps save $prefsFile
    }
    
    # prefs reset
    #
    # Resets all parameters to their defaults, and saves the result.
    
    typemethod reset {} {
        $ps reset
        $ps save $prefsFile
    }

    # list ?pattern?
    #
    # pattern    A glob pattern
    #
    # Lists all parameters with their values, or those matching the
    # pattern.  If none are found, throws an error.

    typemethod list {{pattern *}} {
        set result [$ps list $pattern]

        if {$result eq ""} {
            error "No matching parameters"
        }

        return $result
    }

    # load
    #
    # Loads the parameters safely from the prefsFile, if it exists.

    typemethod load {} {
        if {[file exists $prefsFile]} {
            $ps load $prefsFile -safe
        }
    }
}

