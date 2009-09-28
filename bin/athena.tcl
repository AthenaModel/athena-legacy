#!/bin/sh
# -*-tcl-*-
# The next line restarts using tclsh \
exec tclsh8.5 "$0" "$@"

#-----------------------------------------------------------------------
# TITLE:
#    athena.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Athena: Simulation Launcher
#
#    This script serves as the main entry point for the Athena
#    simulation and related tools. Athena apps are invoked using 
#    the following syntax:
#
#        $ athena appname ?args....?
#
#    E.g., 
#
#        $ athena sim ...
#
#    Every tool is defined by a Tcl package called "app_<appname>", 
#    e.g., "app_sim"; the package is assumed to define an application 
#    ensemble, "app", which has at least an "init" subcommand.  Thus, 
#    an application is invoked as follows:
#
#        package require $applib
#        app init $argv
#
#    Some applications may require additional inputs.
#
# APPLICATION METADATA
#
#    This script defines an array called metadinfo existsata(), which contains
#    metadata about each application which this script can launch.
#    The key is the appname, e.g., "sim", etc.
#
#    applib      The application library name, e.g., app_sim
#
#    mode        gui, server, cmdline:
#                cmdline:  A non-GUI tool app which returns immediately.
#                gui:      A Tk GUI.
#                server:   A non-GUI server app using the Tcl event loop.
#                
#    If the mode is "gui" or "server", Tk will be loaded immediately;
#    in the latter case, the main window will be withdrawn, so that
#    no GUI is presented to the user; nevertheless the app will still
#    enter the event loop.  If the mode is cmdline,
#    Tk will not be loaded, and the event loop will not be entered.
#     
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Set up the auto_path, so that we can find the correct libraries.  
# In development, there might be directories loaded from TCLLIBPATH;
# strip them out.

# First, remove all TCLLIBPATH directories from the auto_path.

if {[info exists env(TCLLIBPATH)]} {
    set old_path $auto_path
    set auto_path [list]

    foreach dir $old_path {
        if {$dir ni $env(TCLLIBPATH)} {
            lappend auto_path $dir
        }
    }
}

# Next, get the Athena-specific directories.

set appdir  [file normalize [file dirname [info script]]]
set libdir  [file normalize [file join $appdir .. lib]]
set marsdir [file normalize [file join $appdir .. mars lib]]

# Add Athena libs to the new lib path.
lappend auto_path $marsdir $libdir

#-------------------------------------------------------------------
# Next, require Tcl

package require Tcl 8.5

#-----------------------------------------------------------------------
# Application Metadata

set metadata {
    sim {
        text     "Simulation"
        applib   app_sim
        mode     gui
    }

    version {
        text     "Version Switcher"
        applib   app_version
        mode     cmdline
    }

    export {
        text     "XML Export"
        applib   app_export
        mode     cmdline
    }
}

#-----------------------------------------------------------------------
# Main Program 

# main argv
#
# argv       Command line arguments
#
# This is the main program; it is invoked at the bottom of the file.
# It determines the application to invoke, and does so.

proc main {argv} {
    global metadata
    global appname

    #-------------------------------------------------------------------
    # Get the Metadata

    array set meta $metadata

    #-------------------------------------------------------------------
    # Application Mode.

    # FIRST, assume the mode is "cmdline": Tk is not needed, nor is the
    # Tcl event loop.

    set appname ""
    set mode cmdline

    # NEXT, Extract the appname, if any, from the command line arguments
    if {[llength $argv] >= 1} {
        set appname [lindex $argv 0]
        set argv [lrange $argv 1 end]

        # If we know it, then we know the mode; otherwise, cmdline is right.
        if {[info exists meta($appname)]} {
            set mode [dict get $meta($appname) mode]
        }
    }

    #-------------------------------------------------------------------
    # Require Packages

    # FIRST, Require Tk if this is a GUI.
    #
    # NOTE: There's a bug in the current basekit such that if sqlite3
    # is loaded before Tk things get horribly confused.  In particular,
    # when loading Tk we get an error:
    #
    #    version conflict for package "Tcl": have 8.5.3, need exactly 8.5
    #
    # This logic works around the bug. We're not currently building
    # a starpack based on this script, but it's best to be prepared.

    if {$mode eq "gui" || $mode eq "server"} {
        # FIRST, get all Non-TK arguments from argv, leaving the Tk-specific
        # stuff in place for processing by Tk.
        set argv [nonTkArgs $argv]

        # NEXT, load Tk.
        package require Tk 8.5

        if {$mode eq "server"} {
            # Withdraw the main window, so it can't be closed accidentally.
            wm withdraw .
        }
    }

    # NEXT, go ahead and load marsutil(n).  Don't import it;
    # leave that for the applications.

    package require marsutil

    # NEXT, if no app was requested, show usage.
    if {$appname eq ""} {
        ShowUsage
        exit
    }

    # NEXT, if the appname is unknown, show error and usage
    if {![info exists meta($appname)]} {
        puts "Error, no such application: \"athena $appname\"\n"

        ShowUsage
        exit 1
    }

    # NEXT, make sure the current state meets the requirements for
    # this application.

    # NEXT, we have the desired application.  Load its package.
    package require [dict get $meta($appname) applib]

    # NEXT, get the application directory in the host
    # file system.
    appdir init
    
    # NEXT, load the mods from the mods directory, if any.
    ::athena_mods::load

    # NEXT, apply any applicable mods
    ::athena_mods::apply

    # NEXT, Invoke the app.
    app init $argv

    # NEXT, return the mode, so that server apps can enter
    # the event loop.
    return $mode
}

# from argvar option ?defvalue?
#
# Looks for the named option in the named variable.  If found,
# it and its value are removed from the list, and the value
# is returned.  Otherwise, the default value is returned.
#
# TBD: When the misc utils are ported, use optval (it's available).

proc from {argvar option {defvalue ""}} {
    upvar $argvar argv

    set ioption [lsearch -exact $argv $option]

    if {$ioption == -1} {
        return $defvalue
    }

    set ivalue [expr {$ioption + 1}]
    set value [lindex $argv $ivalue]
    
    set argv [lreplace $argv $ioption $ivalue] 

    return $value
}


# nonTkArgs arglist
#
# arglist        An argument list
#
# Removes non-Tk arguments from arglist, leaving only Tk options like
# -display and -geometry (with their values, of course); these are
# assigned to ::argv.  Returns the non-Tk arguments.

proc nonTkArgs {arglist} {
    set ::argv {}

    foreach opt {-colormap -display -geometry -name -sync -visual -use} {
        set val [from arglist $opt]

        if {$val ne ""} {
            lappend ::argv $opt $val
        }
    }

    return $arglist
}

# ShowUsage
#
# Displays the command-line syntax.

proc ShowUsage {} {
    global metadata

    # Get the list of apps in the order defined in the metadata
    set apps [dict keys $metadata]

    # TBD: It would be nice to associate a version with this
    puts "=== athena(1) ===\n"

    puts {Usage: athena appname [args...]}
    puts ""

    puts ""
    puts "The following applications are available:"
    puts ""

    puts "Application        Man Page            Description"
    puts "-----------------  ------------------  ------------------------------------"

    foreach app [dict keys $metadata] {
        puts [format "athena %-10s  %-18s  %s" \
                  $app                          \
                  athena_${app}(1)             \
                  [dict get $metadata $app text]]
    }
}

#-------------------------------------------------------------------
# Mod code

namespace eval ::athena_mods:: {
    # Mods for the app.
    #
    # ids          List of mod IDs
    # version-$id  Athena version
    # modfile-$id  Mod file it was loaded from.
    # title-$id    Mod title
    # body-$id     Body of the mod
    
    variable mods

    array set mods { 
        ids {}
    }

    # Current mod file
    variable modfile {}

}


# load
#
# Loads the mod files from disk, if any.

proc ::athena_mods::load {} {
    variable modfile

    # FIRST, create the mod interp
    set interp [interp create -safe]
    
    $interp alias mod ::athena_mods::ModCmd

    # NEXT, get the mods directory
    set moddir [appdir join mods]

    # NEXT, get a list of all of the mods in the directory
    foreach modfile [glob -nocomplain [file join $moddir *.tcl]] {
        if {[catch {
            $interp invokehidden source $modfile
        } result]} {
            puts "Error loading mod [file tail $modfile]: $result"
            exit 1
        }
    }

    # NEXT, destroy the interp
    rename $interp ""
}

# ModCmd app ver num title body 
#
# app    The application name, e.g., "sim"
# ver    The Athena version, e.g., "1.0.x"
# num    The number of the mod
# title  The title of the mod
# body   The body of the mod
#
# Loads the mod into memory.  Mods for other apps are ignored, and
# the version must match.  It's an error to have two mods with the
# same number.

proc ::athena_mods::ModCmd {app ver num title body} {
    variable modfile
    variable mods

    # FIRST, skip it if the app name doesn't match.
    if {$app ne $::appname} {
        return
    }

    # NEXT, it's an error if we already have a mod with this number
    if {$num in $mods(ids)} {
        puts "Duplicate mod:"
        puts "  Mod #$num is defined in [file tail $modfile]"
        puts "  Mod #$num is redefined in $mods(modfile-$num)"
        exit 1
    }

    # NEXT, save the data
    lappend mods(ids)      $num
    set mods(version-$num) $ver
    set mods(modfile-$num) [file tail $modfile]
    set mods(title-$num)   $title
    set mods(body-$num)    $body
}

# apply
#
# Applies any mods loaded for this app, in numerical order

proc ::athena_mods::apply {} {
    variable mods

    foreach num [lsort -integer $mods(ids)] {
        # FIRST, it's an error if the version doesn't match
        if {[llength [info commands ::version]] != 0 &&
            $mods(version-$num) ne [version]
        } {
            puts "Version mismatch:"
            puts "  Mod file $mods(modfile-$num) is for Athena $mods(version-$num)."
            puts "  This is Athena [version]."
            puts ""
            puts "Remove $mods(modfile-$num) from [file join $::appdir mods]."
            exit 1
        }

        if {[catch {
            namespace eval :: $mods(body-$num)
        } result]} {
            puts "Could not load mod $num from $mods(modfile-$num)\n  $result"
            puts ""
            puts "Remove $mods(modfile-$num) from [file join $::appdir mods]."
            exit 1
        }

        # It's the application's responsible to log mods in an appropriate
        # way.
        # puts "Mod loaded: $num ($mods(title-$num)) from $mods(modfile-$num)"
    }
}

# logmods
#
# Logs the mods for the application

proc ::athena_mods::logmods {} {
    variable mods

    foreach num [lsort -integer $mods(ids)] {
        log normal app "mod loaded: $num, \"$mods(title-$num)\", from $mods(modfile-$num)"
    }
}

# putsmods
#
# Outputs the loaded mods to stdout for the application

proc ::athena_mods::putsmods {} {
    variable mods

    foreach num [lsort -integer $mods(ids)] {
        puts "mod loaded: $num, \"$mods(title-$num)\", from $mods(modfile-$num)"
    }
}

#-----------------------------------------------------------------------
# Run the program

# FIRST, run the main routine, to set everything up.
main $argv



