#-----------------------------------------------------------------------
# FILE: wizard.tcl
#
#   Wizard Main Ensemble.
#
# PACKAGE:
#   wnbhood(n) -- package for athena(1) intel ingestion wizard.
#
# PROJECT:
#   Athena Regional Stability Simulation
#
# AUTHOR:
#   Dave Hanks
#
#-----------------------------------------------------------------------

 
#-----------------------------------------------------------------------
# wizard
#
# Intel Ingestion Wizard main module.

snit::type ::wnbhood::wizard {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Variables

    # Wizard Window Name
    typevariable win .wnbhoodwizard   

    # ndict
    #
    # ndict => dictionary of neighborhoods
    #       -> $name => list of refpoint/polygon pairs

    typevariable ndict

    #-------------------------------------------------------------------
    # Wizard Invocation

    # invoke
    #
    # Invokes the wizard.  This initializes the underlying modules, and
    # creates the wizard window.  We enter the WIZARD state when the
    # window is created, and remain in it until the wizard window
    # has completed or is destroyed.

    typemethod invoke {} {
        assert {[$type caninvoke]}

        # FIRST, check that there is a geo-referenced map already defined
        # in Athena
        if {![$type MapExists]} {
            messagebox popup   \
                -title "Unsuitable Map" \
                -icon  error            \
                -buttons {ok "Ok"}      \
                -default ok             \
                -parent [app topwin]    \
                -message [normalize "
                    This scenario does not yet have a suitable geo-referenced
                    map loaded.  Please go to the File menu and
                    either import a map from disk or retrieve one from a web
                    map service.
                "]

           return
        }

        # NEXT, init non-GUI modules
        wizdb ::wnbhood::wdb

        # NEXT, create the real main window.
        wizwin $win
    }

    # cleanup
    #
    # Cleans up all transient wizard data.

    typemethod cleanup {} {
        bgcatch {
            wdb destroy
        }

        # Reset the sim state, if necessary.
        sim wizard off
    }

    #-------------------------------------------------------------------
    # Queries

    # caninvoke
    #
    # Returns 1 if it's OK to invoke the wizard, and 0 otherwise.  We
    # can invoke the wizard if we are in the PREP state, and the wizard
    # window isn't already in existence.

    typemethod caninvoke {} {
        expr {[sim state] eq "PREP" && ![winfo exists $win]}
    }

    #-------------------------------------------------------------------
    # Predicates
    #
    # These subcommands indicate whether we've acquired needed information
    # or not.

    # MapExists
    #
    # Checks if a suitable map is available for placing neighborhoods
    # on.

    typemethod MapExists {} {
        set projtype [rdb onecolumn {SELECT projtype FROM maps WHERE id=1}]

        # Must be a rectangular projection
        if {$projtype ne "RECT"} {
            return 0
        }

        return 1
    }

    #-------------------------------------------------------------------
    # Mutators

    # retrieveTestPolygons
    #
    # Retrieves our canned test messages.

    typemethod retrieveTestPolygons {} {
        set filenames \
            [glob -nocomplain [file join $::wnbhood::library *.kml]]

        $type readfiles $filenames

        notifier send ::wnbhood::wizard <update>
    }

    # retrievePolygons filenames
    #
    # TBD

    typemethod retrievePolygons {filenames} {
        $type readfiles $filenames

        notifier send ::wnbhood::wizard <update>
    }
    
    # readfiles flist
    #
    # flist  - a list of file names
    #
    # This method goes through the list of filenames provided and parses out
    # KML polygons from them.

    typemethod readfiles {flist} {
        set info(errmsgs) [dict create]

        foreach fname $flist {
            $type ParseFile $fname
        }

        return [dict size $info(errmsgs)]
    }

    # ParseFile fname
    #
    # fname  - the name of a KML file that contains polygons
    #
    # This method extracts polygons and thier names from a KML file
    # and inserts the data into the wdb.

    typemethod ParseFile {fname} {
        # FIRST, use the kmlpoly object to parse the data
        if {[catch {
            set pdict [kmlpoly parsefile $fname]
        } result]} {
            dict set info(errmsgs) $fname $result
            return
        }

        # NEXT, extract the data from the returned dictionary and add it
        # it to the wdb.
        set names [dict get $pdict NAMES]
        set polys [dict get $pdict POLYGONS]

        if {[llength $names] ne [llength $polys]} {
            dict set info(errmsgs) $fname "Name/Polygon size mismatch."
            return
        }

        foreach name $names poly $polys {
            wdb eval {
                INSERT OR REPLACE INTO
                polygons(name, polygon)
                VALUES($name, $poly)
            }
        }
    }


    # errmsgs
    #
    # returns any error message found during KML parsing
    typemethod errmsgs {} {
        return [dict get $info(errmsgs)]
    }

    # docs
    #
    # Returns HTML documentation

    typemethod docs {} {
        # TBD
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

    #-------------------------------------------------------------------
    # Finish: Ingest the neighborhoods into the scenario

    # finish
    #
    # Ingests the selected neighborhoods into the scenario.

    typemethod finish {} {
        # FIRST, the wizard is done; we're about to make things happen.
        sim wizard off

        # NEXT, have the wizwin save the selected nbhoods
        $win save

        # NEXT, cleanup.
        destroy $win
    }
}



