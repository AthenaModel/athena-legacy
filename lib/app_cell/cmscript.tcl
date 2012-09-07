#-----------------------------------------------------------------------
# TITLE:
#    cmscript.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n) cmscript Ensemble
#
#    This module manages the cellmodel(5) script for the application.
#    It knows whether the current script has been saved or not, and owns
#    the cellmodel(n) object.  It is responsible for the 
#    open/save/save as/new functionality.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# cmscript ensemble

snit::type cmscript {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent cm     ;# The cellmodel(n) object
    typecomponent editor ;# The cmscripteditor object

    #-------------------------------------------------------------------
    # Type Variables

    # Info Array: most scalars are stored here
    #
    # cmfile  - Name of the current cellmodel(5) file

    typevariable info -array {
        cmfile  ""
    }

    #-------------------------------------------------------------------
    # Initializer

    # init
    #
    # Initializes the module.

    typemethod init {} {
        # FIRST, create a clean cellmodel(n) object
        cellmodel ::cm 
    }

    # register ed
    #
    # ed   - A cmscripteditor widget
    #
    # Registers the script editor with this module.
    
    typemethod register {ed} {
        set editor $ed
    }

    #-------------------------------------------------------------------
    # Script Management Methods

    # new
    #
    # Creates a new, blank cellmodel(5) script

    typemethod new {} {
        # NEXT, Create a blank cmscript
        $type MakeNew

        app puts "New cell model created"
    }

    # MakeNew
    #
    # Creates a new, blank, script.  This is used on 
    # "cmscript new", and when "cmscript open" tries and fails.

    typemethod MakeNew {} {
        set info(cmfile)  ""

        $editor new

        notifier send ::cmscript <Update>
    }

    # open filename
    #
    # filename - A .cm file
    #
    # Opens the specified file name, replacing the existing file.

    typemethod open {filename} {
        # FIRST, load the file.
        if {[catch {
            $editor new [readfile $filename]
        } result]} {
            $type MakeNew

            app error {
                |<--
                Could not open cellmodel(5) file
                
                    $filename

                $result
            }

            return
        }

        set info(cmfile) $filename

        notifier send ::cmscript <Update>

        app puts "Opened file [file tail $filename]"

        return
    }

    # save ?filename?
    #
    # filename - Name for the new save file
    #
    # Saves the file, notify the application on success.  If no
    # file name is specified, the cmfile is used.  Returns 1 if
    # the save is successful and 0 otherwise.

    typemethod save {{filename ""}} {
        # FIRST, if filename is not specified, get the cmfile
        if {$filename eq ""} {
            if {$info(cmfile) eq ""} {
                error "Cannot save: no file name"
            }

            set cmfile $info(cmfile)
        } else {
            set cmfile $filename
        }

        # NEXT, make sure it has a .cm extension.
        if {[file extension $cmfile] ne ".cm"} {
            append cmfile ".cm"
        }

        # NEXT, notify the application that we're saving, so other 
        # modules can prepare.
        notifier send ::cmscript <Saving>

        # NEXT, Save, and check for errors.
        if {[catch {
            if {[file exists $cmfile]} {
                file rename -force $cmfile [file rootname $cmfile].bak
            }

            set f [open $cmfile w]
            puts $f [$editor getall]
            close $f
        } result opts]} {
            app error {
                |<--
                Could not save as
                
                    $cmfile

                $result
            }
            return 0
        }

        # NEXT, mark it saved, and save the file name
        set info(unsaved) 0
        set info(cmfile) $cmfile

        app puts "Saved file [file tail $info(cmfile)]"

        # NEXT, set the current working directory to the cmscript
        # file location.
        catch {cd [file dirname [file normalize $filename]]}

        # NEXT, notify the application
        notifier send ::cmscript <Update>
        notifier send ::cmscript <Saved>

        return 1
    }


    # cmfile
    #
    # Returns the name of the current cmscript file

    typemethod cmfile {} {
        return $info(cmfile)
    }

    # cmtext
    #
    # Returns the text of the current cmscript file

    typemethod cmtext {} {
        return [$editor getall]
    }

    # unsaved
    #
    # Returns 1 if there are unsaved changes, and 0 otherwise.

    typemethod unsaved {} {
        return [$editor edit modified]  
    }

    # check
    #
    # Checks the content of the current model.  Returns one of the
    # following:
    #
    # SANE
    #     The model appears to be sane.
    #
    # INSANE
    #     The model appears to be insane: e.g., missing cell
    #
    # SYNTAX <line> <errmsg>
    #     There's a syntax error at <line>

    typemethod check {} {
        # FIRST, check the syntax.
        if {[catch {cm load [$editor getall]} result eopts]} {
            set ecode [dict get $eopts -errorcode]

            if {[lindex $ecode 0] eq "SYNTAX"} {
                return [list SYNTAX [lindex $ecode 1] $result]
            }

            # It's an unexpected error; rethrow
            return {*}$eopts $result
        }

        # NEXT, if there were other problems, let them know about
        # that.
        if {$result == 0} {
            return INSANE
        }

        # FINALLY, all is good.
        return SANE
    }
}











