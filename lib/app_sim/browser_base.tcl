#-----------------------------------------------------------------------
# TITLE:
#    browser_base.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    browser_base(sim) package: Base Browser Code.
#
#    This module defines a snit widget that defines the basic 
#    entity browser behavior for the application.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget browser_base {
    #-------------------------------------------------------------------
    # Components

    component tb          ;# tablebrowser(n) used to browse groups
    component bar         ;# Tool bar
    component reloader    ;# timeout(n) to reload entities
    component changer     ;# timeout(n) to call -selectioncmd

    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull

    # Options delegated to the table browser
    delegate option -table        to tb
    delegate option -keycol       to tb
    delegate option -keycolnum    to tb
    delegate option -displaycmd   to tb
    delegate option -titlecolumns to tb
    delegate option -views        to tb

    # -selectioncmd cmd
    #
    # cmd is called when the selection changes
    
    option -selectioncmd \
        -default ""

    # -tickreload flag
    #
    # If yes, the contents will be reloaded on each <Tick>
    
    option -tickreload \
        -default  no   \
        -readonly yes
    
    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the table browser
        install tb using tablebrowser $win.tb   \
            -db          ::rdb                  \
            -width       100                    \
            -views       [from args -views]

        # NEXT, get the options.
        $self configure \
            -width  600 \
            -height 600 \
            {*}$args

        # NEXT, create the toolbar
        install bar using frame $tb.toolbar \
            -relief flat

        $tb toolbar $bar

        # NEXT, pack the tablebrowser and let it expand
        pack $tb -expand yes -fill both

        # NEXT, prepare to get tablelist events
        bind $tb <<TablebrowserSelect>> [mymethod SelectionChanged]

        # NEXT, create the reloader timeout
        install reloader using timeout ${selfns}::reloader \
            -command    [mymethod reload]                  \
            -interval   1                                  \
            -repetition no

        # NEXT, create the changer timeout
        install changer using timeout ${selfns}::changer \
            -command    [mymethod SelectionChanged]      \
            -interval   1                                \
            -repetition no

        # NEXT, Reconfigure the whole window when:
        #
        # * It becomes mapped
        # * An explicit reconfigure is requested
        # * The time advances
        #
        # Note that the reload is ignored if the window isn't mapped.
        bind $win               <Map>               [mymethod reload]
        notifier bind     ::sim <Reconfigure> $self [mymethod reload]

        if {$options(-tickreload)} {
            notifier bind ::sim <Tick>        $self [mymethod reload]
        }
    }

    destructor {
        notifier forget $self
    }

    #-------------------------------------------------------------------
    # Public Methods

    # Methods delegated to the tablebrowser
    delegate method * to tb


    # reload
    #
    # Called when the entire content of the browser needs to be
    # reloaded.

    method reload {} {
        # FIRST, if the window isn't mapped we can ignore this.
        if {![winfo ismapped $win]} {
            return
        }
        
        # FIRST, update the table browser
        $tb reload

        # NEXT, handle selection changes
        $self SelectionChanged
    }


    # select ids
    #
    # ids    A list of entity ids
    #
    # Programmatically selects the entities in the browser.

    method select {ids} {
        # FIRST, select them in the table browser.
        $tb select $ids

        # NEXT, handle the new selection (tablebrowser only reports
        # user changes, not programmatic changes).
        $self SelectionChanged
    }

    # create id
    #
    # id      The ID of a new entity
    #
    # A new entity has been created. For now, just reload the whole 
    # shebang.  Sometimes this happens many times in sequence, so 
    # schedule the reload to happen shortly.
    
    method create {id} {
        # FIRST, if the window isn't mapped we can ignore this.
        if {![winfo ismapped $win]} {
            return
        }

        $reloader schedule
    }

    # update id
    #
    # id        The {n g c} of the updated curve
    #
    # The curve has been updated.

    method update {id} {
        # FIRST, if the window isn't mapped we can ignore this.
        if {![winfo ismapped $win]} {
            return
        }

        # NEXT, update the table browser
        $tb update $id

        # NEXT, notify the client that the selection has changed--
        # after a moment.
        $changer schedule
    }

    # delete id
    #
    # id        The {n g c} of the updated curve
    #
    # When a curve is deleted, there might no longer be a selection.

    method delete {id} {
        # FIRST, if the window isn't mapped we can ignore this.
        if {![winfo ismapped $win]} {
            return
        }

        # NEXT, update the tablebrowser
        $tb delete $id

        # NEXT, notify the client that the selection has changed--
        # after a moment.
        $changer schedule
    }

    #-------------------------------------------------------------------
    # Private Methods

    # SelectionChanged
    #
    # Notifes the browser of the selection change.

    method SelectionChanged {} {
        callwith $options(-selectioncmd)
    }
}




