#-----------------------------------------------------------------------
# TITLE:
#    wiztigr.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    wiztigr(n): A wizard manager page for retrieving TIGR messages. 
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# wiztigr widget


snit::widget wiztigr {
    #-------------------------------------------------------------------
    # Layout

    # The HTML layout for this widget.
    typevariable layout {
        <h1>Retrieve TIGR Messages</h1>
        
        Ideally, this page would contain controls for selecting a
        a time interval and possibly other search terms, to be used
        in retrieving some set of TIGR messages.  For the present,
        however, we can retrieve canned TIGR messages from disk.
        To browse for TIGR .xml files on disk, press the "Browse"
        button; to load our canned set of test .xml messages, 
        press the "Test Data" button.<p>

        <input name="bbrowse"> <input name="btest"><p>
    }
    
    #-------------------------------------------------------------------
    # Components

    component hframe     ;# htmlframe(n) widget to contain the content.
    component btest      ;# test data button
    component browse     ;# browse button
    component status     ;# Status message
    
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Variables


    #-------------------------------------------------------------------
    # Constructor
    #

    constructor {args} {
        # FIRST, set the default size of this page.
        $hull configure \
            -height 300 \
            -width  600

        pack propagate $win off

        # NEXT, create the HTML frame.
        install hframe using htmlframe $win.hframe

        pack $hframe -fill both -expand yes

        # NEXT, create the widgets
        install bbrowse using ttk::button $hframe.bbrowse \
            -text    "Browse"                             \
            -command [mymethod BrowseForData]

        install btest using ttk::button $hframe.btest \
            -text    "Test Data"                      \
            -command [mymethod RetrieveTestData]

        # NEXT, lay it out.
        $self layout
    }

    #-------------------------------------------------------------------
    # Layout Management

    # layout
    #
    # Lays out the current content of the widget, starting with the
    # boilerplate, and adding status information.

    method layout {} {
        set msgCount [llength [tigr ids]]
        set errCount [dict size [tigr errmsgs]]

        set status "Retrieved $msgCount messages so far.<p>\n"

        if {$errCount > 0} {
            append status "Errors in these files:<p>\n
            "
            append status "<ul>\n"

            dict for {name msg} [tigr errmsgs] {
                append status "<li> $name: $msg\n"
            }

            append status "</ul>\n"
        }

        $hframe layout "$layout<p>\n\n$status"
    }
    

    #-------------------------------------------------------------------
    # Event handlers

    # RetrieveTestData
    #
    # Tells ingester to retrieve the test messages.

    method RetrieveTestData {} {
        ingester retrieveTestMessages

        $self layout
    }

    # BrowseForData
    #
    # Browses for .xml files and passes them along.

    method BrowseForData {} {
        # FIRST, get the filenames to parse
        set filenames [tk_getOpenFile \
                       -initialdir [pwd]                  \
                       -title      "Select TIGR Messages" \
                       -parent     [app topwin]           \
                       -multiple   1                      \
                       -filetypes {
                           {{TIGR messages} {.xml}}
                       }]

        if {[llength $filenames] == 0} {
            return
        }

        ingester retrieveMessages $filenames
        set number [llength [tigr ids]]

        $self layout
    }

    #-------------------------------------------------------------------
    # Wizard Page Interface

    # enter
    #
    # This command is called when wizman selects this page for
    # display.  It should do any necessary set up (i.e., pull
    # data from the data model).

    method enter {} {
        $self layout
        return
    }


    # finished
    #
    # This command is called to determine whether or not the user has
    # completed all necessary tasks on this page.  It returns 1
    # if we can go on to the next page, and 0 otherwise.

    method finished {} {
        return [ingester gotMessages]
    }


    # leave
    #
    # This command is called when the user presses the wizman's
    # "Next" button to go on to the next page.  It should trigger
    # any processing that needs to be done as the result of the
    # choices made on this page, before the next page is entered.

    method leave {} {
        # Nothing to do
        return
    }
}