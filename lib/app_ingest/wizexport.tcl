#-----------------------------------------------------------------------
# TITLE:
#    wizexport.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    wizexport(n): A wizard manager page for viewing and exporting the 
#    simevents script and HTML documentation.
#    
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# wizexport widget


snit::widget wizexport {
    #-------------------------------------------------------------------
    # Lookup table

    # The HTML help for this widget.
    typevariable helptext {
        <h1>Export Script and Documentation</h1>
        
        The lefthand pane shows an Athena executive script which
        will create the ingested simulation events in Athena.  Save it to
        disk by pressing the "Save Script" button, or copy-and-paste
        it into Athena's Scripts Editor.<p>

        The righthand pane shows documentation for each of the 
        ingested simulation events, relating them to the TIGR
        messages that drove their creation.  Press the 
        "Save Documentation" button to save this documentation to
        disk as an HTML file.<p>
    }

    
    #-------------------------------------------------------------------
    # Components

    component hframe    ;# htmlframe(n), for documentation at top.
    component script    ;# rotext(n), generated script.
    component detail    ;# htmlviewer(n) to display documentation

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Constructor
    #
    #   +----------------------+
    #   | hframe               |
    #   +----------------------+
    #   | separator1           |
    #   +-----------+----------+
    #   | script    | detail   |
    #   +-----------+----------+
    #   |  save     |  save    |
    #   +-----------+----------+


    constructor {args} {
        $self configurelist $args

        $self MakeHtmlFrame  $win.hframe  ;# hframe
        ttk::separator       $win.sep1
        $self MakeScriptPane $win.script  ;# script
        $self MakeDetailPane $win.detail  ;# detail
        ttk::separator       $win.sep2

        ttk::button $win.bscript \
            -text "Save Script"  \
            -command [mymethod SaveScriptAs]

        ttk::button $win.bdoc \
            -text "Save Documentation" \
            -command [mymethod SaveDocsAs]

        # NEXT, grid the major components.
        grid $hframe      -row 0 -column 0 -columnspan 2 -sticky ew
        grid $win.sep1    -row 1 -column 0 -columnspan 2 -sticky ew
        grid $win.script  -row 2 -column 0 -sticky nsew
        grid $win.detail  -row 2 -column 1 -sticky nsew
        grid $win.sep2    -row 3 -column 0 -columnspan 2 -sticky ew -pady {0 3}
        grid $win.bscript -row 4 -column 0
        grid $win.bdoc    -row 4 -column 1

        grid rowconfigure    $win 2 -weight 1
        grid columnconfigure $win 1 -weight 1
        grid columnconfigure $win 2 -weight 1
    }

    # MakeHtmlFrame w
    #
    # Creates an htmlframe to hold a page title and description.

    method MakeHtmlFrame {w} {
        install hframe using htmlframe $win.hframe \
            -shrink yes

        $hframe layout $helptext

    }

    # MakeScriptPane w
    #
    # Makes a rotext widget for displaying the generated script.

    method MakeScriptPane {w} {
        frame $w

        install script using rotext $w.rotext         \
            -highlightthickness 0                     \
            -height             24                    \
            -width              80                    \
            -xscrollcommand     [list $w.xscroll set] \
            -yscrollcommand     [list $w.yscroll set]

        ttk::scrollbar $w.xscroll \
            -orient horizontal \
            -command [list $script xview]

        ttk::scrollbar $w.yscroll \
            -orient vertical \
            -command [list $script yview]

        grid $w.rotext  -row 0 -column 0 -sticky nsew
        grid $w.yscroll -row 0 -column 1 -sticky ns
        grid $w.xscroll -row 1 -column 0 -sticky ew

        grid rowconfigure    $w 0 -weight 1
        grid columnconfigure $w 0 -weight 1
    }

    # MakeDetailPane w
    #
    # The name of the frame window.

    method MakeDetailPane {w} {
        frame $w

        install detail using htmlviewer $w.hv \
            -height         300                   \
            -width          300                   \
            -xscrollcommand [list $w.xscroll set] \
            -yscrollcommand [list $w.yscroll set]

        ttk::scrollbar $w.xscroll \
            -orient horizontal \
            -command [list $detail xview]

        ttk::scrollbar $w.yscroll \
            -orient vertical \
            -command [list $detail yview]

        grid $w.hv      -row 0 -column 0 -sticky nsew
        grid $w.yscroll -row 0 -column 1 -sticky ns
        grid $w.xscroll -row 1 -column 0 -sticky ew

        grid rowconfigure    $w 0 -weight 1
        grid columnconfigure $w 0 -weight 1
    }



    #-------------------------------------------------------------------
    # Event handlers

    # SaveScriptAs
    #
    # Prompts the user to save the ingestion script.

    method SaveScriptAs {} {
        set filename [tk_getSaveFile                        \
                          -parent $win                      \
                          -title "Save Ingestion Script As" \
                          -filetypes {
                              {{Athena Executive Script} {.tcl} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the scenario using this name
        try {
            ingester saveFile $filename [ingester script]
        } on error {errmsg} {
            app error "Could not save $filename:\n$errmsg"
            return
        } 

        app puts "Saved script as: $filename"
    }

    # SaveDocsAs
    #
    # Prompts the user to save the ingestion docs.

    method SaveDocsAs {} {
        set filename [tk_getSaveFile                        \
                          -parent $win                      \
                          -title "Save Ingestion Documentation As" \
                          -filetypes {
                              {{HTML Document} {.html} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the scenario using this name
        try {
            ingester saveFile $filename [ingester docs]
        } on error {errmsg} {
            app error "Could not save $filename:\n$errmsg"
            return
        } 

        app puts "Saved docs as: $filename"
    }

    #-------------------------------------------------------------------
    # Wizard Page Interface

    # enter
    #
    # This command is called when wizman selects this page for
    # display.  It should do any necessary set up (i.e., pull
    # data from the data model).

    method enter {} {
        $script ins 1.0 [ingester script]
        $script see 1.0

        $detail set [ingester docs]
        return
    }


    # finished
    #
    # This command is called to determine whether or not the user has
    # completed all necessary tasks on this page.  It returns 1
    # if we can go on to the next page, and 0 otherwise.

    method finished {} {
        # This is the last page.
        return 1
    }


    # leave
    #
    # This command is called when the user presses the wizman's
    # "Next" button to go on to the next page.  It should trigger
    # any processing that needs to be done as the result of the
    # choices made on this page, before the next page is entered.

    method leave {} {
        # Nothing to be done at the moment.
        return
    }
}