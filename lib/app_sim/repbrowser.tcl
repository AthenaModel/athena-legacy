#-----------------------------------------------------------------------
# TITLE:
#    repbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    repbrowser(sim) package: Report browser.
#
#    This widget is a simple wrapper around reportbrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widgetadaptor repbrowser {
    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the hull
        installhull using reportbrowser -db ::rdb

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, refresh the content
        $hull refresh

        # NEXT, update individual entities when they change.
        notifier bind ::report <Report> $self [mymethod ReportCB]
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Private Methods

    # ReportCB dict
    #
    # dict     A dictionary of report options
    #
    # Displays the report in the browser.

    method ReportCB {dict} {
        if {[dict get $dict -requested]} {
            $hull setbin requested
        } else {
            $hull update
        }
    }


    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull
}

