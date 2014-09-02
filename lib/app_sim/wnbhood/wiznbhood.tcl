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
          Nangarhar {
              Achin {}
              Bati_Kot {}
              Chaparhar {}
              Dara_I_Nur {}
              Dih_Bala {}
              Dur_Baba {}
              Goshta {}
              Hisarak {}
              Jalalabad {}
              Kama {}
              Khogyani {}
              Kuz_Kunar {}
              Lal_Pur {}
              Muhmand_Dara {}
              Nazyan {}
              Pachir_Wa_Agam {}
              Rodat {}
              Sherzad {}
              Shiwar {}
              Surkh_Rod {}
          }
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
        # FIRST, grab polygons from the WDB
        set pdict [dict create]
        wdb eval {
            SELECT name, polygon FROM polygons
        } {
            dict set pdict $name $polygon
        }

        # NEXT, clear the nb chooser and set the polygons
        # in it. If no neighborhoods can be displayed, pop up
        # a message box with the information.
        $nbchooser clear

        if {[$nbchooser setpolys $pdict] == 0} {
            lassign [$nbchooser bbox] minlat minlon maxlat maxlon
            set minlat [format "%.3f" $minlat]
            set minlon [format "%.3f" $minlon] 
            set maxlat [format "%.3f" $maxlat]
            set maxlon [format "%.3f" $maxlon]

            messagebox popup \
                -title "No Neighborhoods" \
                -icon  info               \
                -buttons {ok "Ok"}        \
                -default ok               \
                -parent [app topwin]      \
                -message [normalize "
                    The map selected is outside the bounds of all available
                    neighborhoods.  Neighborhoods available are contained 
                    within the box bounded on the lower left by 
                    $minlat deg. latitude and $minlon deg. longitude and 
                    the upper right by $maxlat deg. latitude and $maxlon deg.
                    longitude.
                "]
        }
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
