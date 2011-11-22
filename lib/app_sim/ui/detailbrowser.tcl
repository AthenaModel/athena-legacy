#-----------------------------------------------------------------------
# TITLE:
#    detailbrowser.tcl
#
# AUTHORS:
#    Will Duquette
#
# DESCRIPTION:
#    detailbrowser(sim) package: Detail browser.
#
#    This widget displays a web-like browser for examining
#    model entities in detail.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget detailbrowser {
    #-------------------------------------------------------------------
    # Type Methods

    # new
    #
    # Creates a new detailbrowser in its own window.

    typemethod new {} {
        # FIRST, get a new toplevel
        set count 1
        while {[winfo exists .detail$count]} {
            incr count
        }

        set w .detail$count

        toplevel $w

        wm title $w "Athena [version]: Detail Browser #$count"

        # NEXT, create the widgets
        detailbrowser $w.browser \
            -messagecmd [list $w.status.msgline puts]

        ttk::separator $w.sep

        ttk::frame $w.status \
            -borderwidth 2 
        messageline $w.status.msgline

        pack $w.status.msgline -fill x

        pack $w.status  -side bottom -fill x
        pack $w.sep     -side bottom -fill x
        pack $w.browser -fill both -expand yes
    }


    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to browser

    #-------------------------------------------------------------------
    # Components

    component browser ;# The mybrowser(n)
    component otree   ;# The object linktree(n)
    component htree   ;# The help linktree(n)
    component lazy    ;# The lazyupdater(n)
    component context ;# The context menu

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, Install the browser
        install browser using mybrowser $win.browser \
            -home         my://app/                  \
            -hyperlinkcmd [mymethod GuiLinkCmd]      \
            -searchcmd    [mymethod FormatSearchURL] \
            -messagecmd   {app puts}

        # NEXT, create the sidebar.
        set sidebar [$browser sidebar]

        ttk::notebook $sidebar.tabs \
            -takefocus 0            \
            -padding   2

        # Object Tree
        install otree using linktree $sidebar.tabs.otree \
            -url       my://app/objects                  \
            -width     150                               \
            -height    400                               \
            -changecmd [mymethod ShowLink]               \
            -errorcmd  [list log warning detailb]

        $sidebar.tabs add $sidebar.tabs.otree    \
            -sticky  nsew                        \
            -padding 2                           \
            -text "Objects"

        $browser configure \
            -reloadcmd [mymethod RefreshLinks]

        # Help Tree
        install htree using linktree $sidebar.tabs.htree \
            -url       my://help                         \
            -lazy      yes                               \
            -width     150                               \
            -height    400                               \
            -changecmd [mymethod ShowLink]               \
            -errorcmd  [list log warning detailb]

        $sidebar.tabs add $sidebar.tabs.htree   \
            -sticky  nsew                       \
            -padding 2                          \
            -image   ::projectgui::icon::help12


        pack $sidebar.tabs -fill both -expand yes

        # NEXT, create the lazy updater
        install lazy using lazyupdater ${selfns}::lazy \
            -window   $win \
            -command  [list $browser reload]

        pack $browser -fill both -expand yes

        # NEXT, get the options.
        $self configurelist $args

        # NEXT, bind to events that are likely to cause reloads.
        notifier bind ::sim <DbSyncB> $win [mymethod reload]
        notifier bind ::sim <Tick>    $win [mymethod reload]
        notifier bind ::rdb <Monitor> $win [mymethod reload]
        notifier bind ::parm <Update> $win [mymethod reload]

        # NEXT, create the browser context menu
        bind $win.browser <3>         [mymethod MainContextMenu %X %Y]
        bind $win.browser <Control-1> [mymethod MainContextMenu %X %Y]

        set context [menu $win.context]

        # NEXT, schedule the first reload
        $self reload
        $htree refresh
    }

    destructor {
        notifier forget $win
    }

    # MainContextMenu rx ry
    #
    # rx,ry   - Root window coordinates.
    #
    # Populates and pops up the context menu.
    
    method MainContextMenu {rx ry} {
        # FIRST, get the current content data
        set data [$browser data]

        # NEXT, delete any existing menu items.
        $context delete 0 end

        # NEXT, we can only deal with text/*
        dict with data {
            if {[string match "text/*" $contentType]} {
                set state normal
            } else {
                set state disabled
            }
        }

        # NEXT, add the relevant menu items.
        $context add command \
            -label "Save to Disk..."       \
            -state $state                  \
            -command [mymethod SaveToDisk]

        $context add command \
            -label "View in System Web Browser..." \
            -state $state                                  \
            -command [mymethod ToSystemBrowser]

        $context add command \
            -label    "View Source..."            \
            -state    $state                      \
            -command  [mymethod ViewSource]

        # NEXT, pop it up.
        tk_popup $win.context $rx $ry 
    }

    # ViewSource
    #
    # Loads the current page's HTML source into a viewer window.

    method ViewSource {} {
        # FIRST, get the data
        set data [$browser data]

        dict with data {
            textwin .tw_%AUTO%        \
                -title "Source: $url" \
                -text  $content
        }
    }

    # SaveToDisk
    #
    # Saves the current page to disk.

    method SaveToDisk {} {
        # FIRST, get the data.
        set data [$browser data]

        dict with data {
            # FIRST, get the file type.
            if {$contentType eq "text/html"} {
                set initfile  save.html
                set filetypes { {{HTML File} {.html}} }
            } else {
                set initfile  save.txt
                set filetypes { {{Text File} {.txt}} }
            }

            # NEXT, ask for the file name.
            set filename [tk_getSaveFile                  \
                              -parent      [app topwin]   \
                              -title       "Save Page As" \
                              -initialfile $initfile      \
                              -filetypes   $filetypes]

            # NEXT, if none they cancelled.
            if {$filename eq ""} {
                return 0
            }

            # NEXT, Save the file
            if {[catch {
                $self WriteFile $filename $content
            } result]} {
                messagebox popup \
                    -title    "Could Not Save Page" \
                    -icon     error                 \
                    -buttons  {cancel "Cancel"}     \
                    -parent   [app topwin]          \
                    -message  [normalize "
                        Athena was unable to save the page to the
                        requested file:  $result
                    "]
            } else {
                app puts "Page saved to $filename"
            }
        }
    }

    # WriteFile filename text
    #
    # filename  - The filename
    # text      - The text file
    #
    # Writes the text to the file.

    method WriteFile {filename text} {
        set f [open $filename w]

        try {
            puts $f $text
        } finally {
            close $f
        }
    }

    # ToSystemBrowser
    #
    # Saves the current page to a temporary file, and hands it off to 
    # the system web browser.

    method ToSystemBrowser {} {
        # FIRST, get the data
        set data [$browser data]

        dict with data {
            # FIRST, get a temporary file name, and the browser name.
            set filename [fileutil::tempfile].html
            set helper  [prefs get helper.[os type].browser]

            # NEXT, Save and browse the file

            if {[catch {
                $self WriteFile $filename $content
                exec {*}$helper $filename &
            } result]} {
                messagebox popup \
                    -title    "Could Not View Page" \
                    -icon     error                 \
                    -buttons  {cancel "Cancel"}     \
                    -parent   [app topwin]          \
                    -message  [normalize "
                        Athena was unable to view the page in the
                        system web browser using the command
                        '$helper': $result
                    "]
                return
            }

        }
    }

    # GuiLinkCmd url
    #
    # url - A URL with a scheme other than "my:".
    #
    # Checks the URL scheme; if it's known, passes it to 
    # "app show".  Otherwise, lets mybrowser handle it.

    method GuiLinkCmd {url} {
        # FIRST, get its scheme
        if {[catch {
            array set parts [uri::split $url]
        } result]} {
            return 0
        }

        if {$parts(scheme) ne "gui"} {
            return 0
        }

        app show $url
        return 1
    }

    # FormatSearchURL text
    #
    # text      - Text from the search box
    #
    # Given the search string, returns the search URL.

    method FormatSearchURL {text} {
        return "my://help/?$text"
    }

    # RefreshLinks
    #
    # Called on browser reload; refreshes the links tree
    
    method RefreshLinks {} {
        $otree refresh
    }

    # ShowLink url
    #
    # Shows whatever is selected in the tree, if it's different than
    # what we already have.

    method ShowLink {url} {
        if {$url ne ""} {
            $browser show $url
        }
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to browser

    # reload
    #
    # Causes the widget to reload itself.  In particular,
    #
    # * This call triggers the lazy updater.
    # * The lazy updater will ask the mybrowser to reload itself after
    #   1 millisecond, or when the window is next mapped.
    # * The mybrowser will reload the currently displayed resource and
    #   ask the tree to refresh itself via its -reloadcmd.

    method reload {} {
        $lazy update
    }
}

