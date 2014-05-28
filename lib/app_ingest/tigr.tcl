#-----------------------------------------------------------------------
# FILE: tigr.tcl
#
#   TIGR message retriever.
#
# PACKAGE:
#   app_ingest(n) -- athena_ingest(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# tigr
#
# app_ingest(n) TIGR I/F
#
# This module is responsible for retrieving TIGR messages from the 
# disk or a server, and making them available to the application.

snit::type tigr {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent ht ;# HTools object, for details.

    #-------------------------------------------------------------------
    # Type Variables

    # info array: data structure for the ingested data.
    #
    # errmsgs     - Dictionary of error messages by TIGR file name.
    # numskipped  - Number of messages skipped because they were
    #               outside the neighborhoods.

    typevariable info -array {
        errmsgs  {}
        skipped  0
    }
    

    #-------------------------------------------------------------------
    # Application Initialization

    # init
    #
    # Initializes the module, which prepares the data structures.
    
    typemethod init {} {
        set ht [htools ${type}::ht]
    }

    # retrieveMessages
    #
    # For now, allows the user to pick and choose which files to parse

    typemethod retrieveMessages {} {
        # FIRST, get the filenames to parse
        set filenames [tk_getOpenFile \
                       -initialdir [appdir join] \
                       -title "Select TIGR Messages" \
                       -parent [app topwin] \
                       -multiple 1 \
                       -filetypes {
                           {{TIGR messages} {.xml}}
                       }]

        # NEXT, extract data from the files accumulating errors
        # along the way, the number of errors is returned
        return [$type readfiles $filenames]
    }

    # readTestData
    #
    # Reads the test files included with the software.

    typemethod readTestData {} {
        set filenames \
            [glob -nocomplain [file join $::app_ingest::library messages *.xml]]
        $type readfiles $filenames
    }

    # readfiles flist
    #
    # flist   - a list of files containing TIGR data
    #
    # This method uses the tigrmsg parser to extract the data from
    # TIGR messages and store them in a dictionary.
    #
    # If any files contained errors, the [errmsgs] call will return
    # a dictionary of file names and error messages.

    typemethod readfiles {flist} {
        # FIRST, clear the error list.
        set info(errmsgs) [dict create]

        # NEXT, process each of the files.
        foreach filename $flist {
            $type ParseFile $filename
        }

        # NEXT, assign numeric week numbers
        $type AssignWeekNumbers

        # NEXT, return the size of the error dictionary
        return [dict size $info(errmsgs)]
    }

    # ParseFile filename
    #
    # filename - a list of file containing a TIGR message
    #
    # This method uses the tigrmsg parser to extract the data from
    # a TIGR message and store it in the messages table..

    typemethod ParseFile {filename} {
        # FIRST, parse the file
        if {[catch {
            set tdict [tigrmsg parsefile $filename]
        } result]} {
            # Append offending files/problems to the dictionary
            # of errors.
            dict set info(errmsgs) $filename $result
            return
        }

        # NEXT, extract TIGR data
        set cid       [dict get $tdict CID]
        set start     [dict get $tdict TIMEPERIOD START ZULUSEC]
        set start_str [dict get $tdict TIMEPERIOD START STRING]
        set end       [dict get $tdict TIMEPERIOD END ZULUSEC]
        set end_str   [dict get $tdict TIMEPERIOD END STRING]
        set tz        [dict get $tdict TIMEPERIOD END TIMEZONE]
        set locs      [dict get $tdict LOCATIONLIST]
        set title     [dict get $tdict TITLE]
        set desc      [dict get $tdict DESCRIPTION]

        # NEXT, get the neighborhood.  There might be in theory
        # be multiple locations; in practice, there is only ever one.
        # For now, take the first location that maps to a neighborhood.
        set n ""
        foreach loc $locs {
            lassign $loc lat lon
            set n [nbhood find $lat $lon]
            if {$n ne ""} {
                break
            }
        }

        # NEXT, if no neighborhood was found, we're done.
        if {$n eq ""} {
            return
        }

        # NEXT, get the julian week string.
        set week [week toString [week toWeek $start]]

        # NEXT, insert data into the rdb
        rdb eval {
            INSERT OR REPLACE INTO 
            messages(cid,
                     title,
                     desc,
                     start_str,
                     end_str,
                     start,
                     end,
                     tz,
                     locs,
                     week,
                     n)
            VALUES($cid,
                   $title,
                   $desc,
                   $start_str,
                   $end_str,
                   $start,
                   $end,
                   $tz,
                   $locs,
                   $week,
                   $n)
        }
    }

    # AssignWeekNumbers
    #
    # Assigns a week number (an integer) to each message, based
    # on the week strings.  The first week is week 1.

    typemethod AssignWeekNumbers {} {
        set weeks [rdb eval {
            SELECT DISTINCT week FROM messages ORDER BY week ASC
        }]

        set t 0
        foreach week $weeks {
            incr t

            rdb eval {
                UPDATE messages
                SET t = $t
                WHERE week = $week
            }
        }
    }



    # errmsgs
    #
    # Returns a dict of filename/error message pairs, which is
    # empty if there are no errors.

    typemethod errmsgs {} {
        return [dict get $info(errmsgs)]
    }

    # ids
    #
    # Returns the retrieved message IDs

    typemethod ids {} {
        return [rdb eval {SELECT cid FROM messages}]
    }

    # view id
    #
    # Gets a "view" dictionary for the given message.

    typemethod view {id} {
        rdb eval {
            SELECT * FROM messages WHERE cid=$id
        } row {
            unset -nocomplain row(*)

            return [array get row]
        }

        return [dict create]
    }

    # detail id
    #
    # Returns detail about the message and its contents in the 
    # form of an HTML string.
    # 
    # TBD: Pull the data from the RDB, and include everything
    # known to date.

    typemethod detail {id} {
        # FIRST, retrieve the data.
        rdb eval {SELECT * FROM messages WHERE cid=$id} row {}

        set loclist [list]
        foreach loc $row(locs) {
            lappend loclist [latlong tomgrs $loc]
        }


        # NEXT, format the details.
        $ht clear

        $ht title $row(title) "Message $id"

        $ht putln "<table>"
        $type VarItem "Week"      $row(week)
        $type VarItem "Nbhood"    $row(n)
        $type VarItem "Start/End" "$row(start_str) -- $row(end_str)"
        $type VarItem "Location"  [join $loclist ", "]
        $ht putln "</table>" 
        $ht para

        if {$row(desc) ne ""} {
            $ht putln $row(desc)
        } else {
            $ht putln "No more information available."
        }

        $ht para

        return [$ht get]
    }

    # VarItem name value
    #
    # Outputs a table row with a name and value.
    typemethod VarItem {name value} {
        $ht putln "<tr><td><b>$name:</b></td> <td>$value</td></tr>"
    }

}



