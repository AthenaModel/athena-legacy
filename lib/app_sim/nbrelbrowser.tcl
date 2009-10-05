#-----------------------------------------------------------------------
# TITLE:
#    nbrelbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    nbrelbrowser(sim) package: Nbhood Relationship browser.
#
#    This widget displays a formatted list of nbrel_mn records.
#    It is a variation of browser_base(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor nbrelbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #-------------------------------------------------------------------
    # Components

    component editbtn     ;# The "Edit" button

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using browser_base                \
            -table        "gui_nbrel_mn"              \
            -keycol       "id"                        \
            -keycolnum    0                           \
            -titlecolumns 3                           \
            -displaycmd   [mymethod DisplayData]      \
            -selectioncmd [mymethod SelectionChanged]

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, create the toolbar buttons
        set bar [$hull toolbar]

        install editbtn using button $bar.edit   \
            -image      ::projectgui::icon::pencil22 \
            -relief     flat                     \
            -overrelief raised                   \
            -state      disabled                 \
            -command    [mymethod EditSelected]

        DynamicHelp::add $editbtn -text "Edit Selected Relationship"

        cond::orderIsValidCanUpdate control $editbtn \
            order   NBHOOD:RELATIONSHIP:UPDATE   \
            browser $win


        pack $editbtn   -side left

        # NEXT, create the columns and labels.  Create and hide the
        # ID column; it will be used to reference rows as "$n $g", but
        # we don't want to display it.

        $hull insertcolumn end 0 {ID}
        $hull columnconfigure end -hide yes
        $hull insertcolumn end 0 {Of Nbhood}
        $hull insertcolumn end 0 {With Nbhood}
        $hull insertcolumn end 0 {Proximity}
        $hull insertcolumn end 0 {Effects Delay}
        $hull columnconfigure end -sortmode real

        # NEXT, sort on column 1 by default
        $hull sortbycolumn 1 -increasing

        # NEXT, update individual entities when they change.
        notifier bind ::nbrel <Entity> $self $self
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # canupdate
    #
    # Returns 1 if the current selection can be "updated" and 0 otherwise.
    #
    # The current selection can be updated if it is a single or multiple
    # selection and none of the selected entries has f=g.

    method canupdate {} {
        # FIRST, there must be something selected
        if {[llength [$self curselection]] > 0} {
            foreach id [$self curselection] {
                lassign $id m n

                if {$m eq $n} {
                    return 0
                }
            }

            return 1
        } else {
            return 0
        }
    }

    #-------------------------------------------------------------------
    # Private Methods

    # DisplayData dict
    # 
    # dict   the data dictionary that contains the entity information
    #
    # This method converts the entity data dictionary to a list
    # that contains just the information to be displayed in the table browser.

    method DisplayData {dict} {
        # FIRST, extract each field
        dict with dict {
            set id [list $m $n]

            $hull setdata $id \
                [list $id $m $n $proximity $effects_delay]
        }
    }


    # SelectionChanged
    #
    # Enables/disables toolbar controls based on the current selection,
    # and notifies the app of the selection change.

    method SelectionChanged {} {
        # FIRST, update buttons
        cond::orderIsValidCanUpdate update $editbtn

        # NEXT, notify the app of the selection.
        if {[llength [$hull curselection]] == 1} {
            set id [lindex [$hull curselection] 0]
            lassign $id m n

            notifier send ::app <ObjectSelect> \
                [list mn $id  nbhood $m]
        }
    }


    # EditSelected
    #
    # Called when the user wants to edit the selected entities

    method EditSelected {} {
        set ids [$hull curselection]

        if {[llength $ids] == 1} {
            lassign [lindex $ids 0] m n

            order enter NBHOOD:RELATIONSHIP:UPDATE m $m n $n
        } else {
            order enter NBHOOD:RELATIONSHIP:UPDATE:MULTI ids $ids
        }
    }
}


