#-----------------------------------------------------------------------
# FILE: ingester.tcl
#
#   Data ingester.
#
# PACKAGE:
#   wintel(sim) -- Athena Intel Ingestion Wizard
#
# PROJECT:
#   Athena Regional Stability Simulation
#
# AUTHOR:
#    Will Duquette
#
# TODO: Merge into wizard.tcl.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# ingester
#
# wintel(n) Data Ingester
#
# This module is responsible for accumulating ingested data and preparing
# the final ingestion script to be given to athena_sim(1).

snit::type ::wintel::ingester {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Variables

    # info array: data structure for the ingested data.
    #
    # events => dictionary of simevents by event type
    #        -> $eventType => list of ::simevent::$eventType objects

    typevariable info -array {
        sorting      {}
        events       {}
    }
    

    #-------------------------------------------------------------------
    # Application Initialization


    #-------------------------------------------------------------------
    # Predicates
    #
    # These subcommands indicate whether we've acquired needed information
    # or not.

    # gotMessages
    #
    # Returns 1 if we've got some messages, and 0 otherwise.

    typemethod gotMessages {} {
        return [wdb exists {SELECT cid FROM messages}]
    }

    # gotSorting
    #
    # Returns 1 if we've sorted the messages by event, and 0 otherwise.

    typemethod gotSorting {} {
        return [wdb exists {SELECT cid FROM cid2etype}]
    }

    #-------------------------------------------------------------------
    # Mutators

    # retrieveTestMessages
    #
    # Retrieves our canned test messages.

    typemethod retrieveTestMessages {} {
        tigr readTestData

        notifier send ::wizard <update>
    }

    # retrieveMessages filenames
    #
    # Ideally, this should have search arguments to pass along to
    # TIGR; or perhaps the wiztigr widget should talk directly to
    # tigr.

    typemethod retrieveMessages {filenames} {
        tigr readfiles $filenames

        notifier send ::wizard <update>
    }
    
    # saveSorting sorting
    #
    # sorting   - A sorting of message IDs into event bins, or ""
    #
    # Gives the current sorting to the ingestor.  If "", there is no
    # current sorting.

    typemethod saveSorting {sorting} {
        wdb eval {DELETE FROM cid2etype}
        
        dict for {bin idlist} $sorting {
            if {$bin in {unsorted ignored}} {
                continue
            }

            foreach id $idlist {
                wdb eval {
                    INSERT INTO cid2etype(cid,etype)
                    VALUES($id,$bin)
                }
            }
        }

        notifier send ::ingester <update>
    }

    # ingestEvents 
    #
    # Creates candidate events based on the message sorting.

    typemethod ingestEvents {} {
        simevent ingest
    }

    # script
    #
    # Returns an ingestion script for the ingested events.

    typemethod script {} {
        set supportFile [file join $::wintel::library ingest_support.tcl]

        set ts [clock format [clock seconds]]

        set script [enscript {
            #-------------------------------------------------------
            # athena_ingest(1) Ingestion Script
            #
            # Generated at %timestamp

        } %timestamp $ts]


        append script "\n[readfile $supportFile]\n\n"

        append script [enscript {
            #-------------------------------------------------------
            # Ingested Events

        }]

        foreach id [simevent normals] {
            set e [simevent get $id]

            append script "\n"
            append script [$e export] "\n"
        }

        append script [enscript {

            # End of script
            #-------------------------------------------------------
        }]

        return $script
    }

    # docs
    #
    # Returns HTML documentation for the ingested messages.

    typemethod docs {} {
        set ht [htools %AUTO%]

        $ht page "Ingestion Report"

        $ht title "Ingestion Report"

        set nEvents [llength [simevent normals]]
        set nTigr   [llength [tigr ids]]

        $ht putln "<b>At:</b> [clock format [clock seconds]]<br>"
        $ht putln "<b>Ingested:</b> $nEvents Athena events<br>"
        $ht putln "<b>From:</b> $nTigr TIGR messages<br>"

        $ht para

        foreach id [simevent normals] {
            set e [simevent get $id]

            $ht putln [$e htmltext]
        }

        $ht /page

        return [$ht get]
    }

    # saveFile filename text
    #
    # filename   - A user selected file name
    # text       - The text to save
    #
    # Attempts to save the text to disk.
    # Errors are handled by caller.

    typemethod saveFile {filename text} {
        set f [open $filename w]
        puts $f $text
        close $f
        return
    }

}






