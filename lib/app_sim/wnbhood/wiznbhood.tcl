#-----------------------------------------------------------------------
# TITLE:
#    wiznbhood.tcl
#
# AUTHOR:
#    Dave Hanks
#
# PACKAGE:
#   wnbhood(n) -- package for athena(1) intel ingestion wizard.
#
# PROJECT:
#   Athena Regional Stability Simulation
#
# DESCRIPTION:
#    wiznbhood(n): A wizard manager page for choosing an
#    athena scenario.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# wiznbhood widget


snit::widget ::wnbhood::wiznbhood {
    #-------------------------------------------------------------------
    # Layout

    # The HTML layout for this widget.
    typevariable layout {
        <h1>Retrieve Neighborhood Polygons</h1>

        This wizard allows for the retrieval of neighborhood polygons
        to be used in an Athena scenario.  For now, polygons can only
        be retrieved from disk  by using canned test data.  Press the
        "Test Data" button to ingest polygons from test KML files.<p>
    }
    
    # Tree specification. This is stop gap for the prototype. Ideally,
    # this data would be acquired automatically through some other means.
    typevariable treespec {
        Afghanistan {
          Badakhshan {}
          Badghis {}
          Baghlan {}
          Balkh {}
          Bamyan {}
          Farah {}
          Faryab {}
          Ghazni {}
          Ghor {}
          Hilmand {}
          Hirat {}
          Jawzjan {}
          Kabul {}
          Kandahar {}
          Kapisa {}
          Khost {}
          Kunar {}
          Kunduz {}
          Laghman {}
          Logar {}
          Wardak {}
          Nangarhar {}
          Nimroz {}
          Nuristan {}
          Paktya {}
          Paktika {}
          Parwan {}
          Samangan {}
          Sari_Pul {}
          Takhar {}
          Uruzgan {}
          Zabul {}
        }
        Pakistan {}
        Tajikistan {}
    }

    #-------------------------------------------------------------------
    # Components

    component hframe     ;# htmlframe(n) widget to contain the content.
    component btest      ;# test data button
    component nbchooser  ;# nbchooser(n) widget
    
    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Variables

    # Info array: wizard data
    #

    variable info -array {
    }

    #-------------------------------------------------------------------
    # Constructor
    #

    constructor {args} {
        # FIRST, set the default size of this page.
        $hull configure \
            -height 600 \
            -width  800

        # NEXT, create the HTML frame.
        install hframe using htmlframe $win.hframe

        # NEXT, lay it out.
        $hframe layout $layout

        # NEXT, create the other widgets
        install btest using ttk::button $win.btest \
            -text "Test Data"                         \
            -command [mymethod RetrieveTestData]

        $self CreateNbChooser $win.nbchooser

        grid columnconfigure $win 0 -weight 1
        grid rowconfigure    $win 2 -weight 1

        grid $win.hframe    -row 0 -column 0 -sticky ew
        grid $win.btest     -row 1 -column 0 -sticky w
        grid $win.nbchooser -row 2 -column 0 -sticky nsew

        notifier bind ::wnbhood::wizard <update> $win [mymethod Refresh]
    }

    # CreateNbChooser w
    #
    # w   - the window to create
    #
    # This method creates an nbchooser widget that is used to select
    # which neighborhoods should be ingested into Athena.  The 
    # widget is configured with the map image and projection currently
    # loaded into the scenario.

    method CreateNbChooser {w} {
        # FIRST, grab the map image and projection object from
        # the scenario.
        rdb eval {
            SELECT width,height,projtype,proj_opts,data
            FROM maps WHERE id=1

        } {
            set mapimage [image create photo -format jpeg -data $data]

            set proj [[eprojtype as proj $projtype] %AUTO% \
                                       -width $width       \
                                       -height $height     \
                                       {*}$proj_opts]
        }

        install nbchooser using nbchooser $w \
            -treespec   $treespec            \
            -projection $proj                \
            -map        $mapimage
    }

    #-------------------------------------------------------------------
    # Event handlers

    method RetrieveTestData {} {
        wizard retrieveTestPolygons
    }


    method Refresh {args} {
        set pdict [dict create]
        wdb eval {
            SELECT name, polygon FROM polygons
        } {
            dict set pdict $name $polygon
        }

        $nbchooser clear
        $nbchooser setpolys $pdict
    }

    # getnbhoods
    #
    # Returns a dictionary of selected polygons in the nbchooser 

    method getnbhoods {} {
        return [$nbchooser getpolys]
    }

    #-------------------------------------------------------------------
    # Wizard Page Interface

    # enter
    #
    # This command is called when wizman selects this page for
    # display.  It should do any necessary set up (i.e., pull
    # data from the data model).

    method enter {} {
        # Nothing to do
    }


    # finished
    #
    # This command is called to determine whether or not the user has
    # completed all necessary tasks on this page.  It returns 1
    # if we can go on to the next page, and 0 otherwise.

    method finished {} {
        return 1
    }

    # leave
    #
    # This command is called when the user presses the wizman's
    # "Next" button to go on to the next page.  It should trigger
    # any processing that needs to be done as the result of the
    # choices made on this page, before the next page is entered.

    method leave {} {
        # Nothing to do
    }
}
