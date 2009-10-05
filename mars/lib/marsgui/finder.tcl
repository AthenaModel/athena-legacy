#-----------------------------------------------------------------------
# TITLE:
#   finder.tcl
# 
# AUTHOR:
#   Dave Jaffe
#   Will Duquette
# 
# DESCRIPTION:
#   Mars marsgui(n) package: Finder widget.
# 
#   This widget provides a text search control for doing incremental, 
#   wildcard, and regular expression searches of a rotext(n) widget
#   (or any other widget which implements the compatible 
#   "find/-foundcmd" protocol.  It also provides navigation buttons.
#
#   TBD:
#
#   * Reorganize the methods properly in the file.
#   * I removed a number of incremental search optimizations during
#     the scrub; at some point I should reoptimize.
#   * The -loglist option should be replaced by a listfind/listfound
#     protocol. 
# 
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Export public commands

namespace eval ::marsgui:: {
    namespace export finder
}

#-----------------------------------------------------------------------
# Widget Definition

snit::widget ::marsgui::finder {
    #-------------------------------------------------------------------
    # Components

    component entry      ;# The commandentry(n)
    
    #-------------------------------------------------------------------
    # Options

    # -findcmd cmd
    # 
    # The command to call when it's time to find some text.
    option -findcmd
    
    # -loglist
    #
    # The loglist component to search.
    option -loglist -default ""
    
    # -targettype
    #
    # The default search type: incremental, exact, wildcard, or regexp.
    # Defaults to incremental.
    option -targettype -default "exact" -configuremethod ConfigureTargetType

    method ConfigureTargetType {option value} {
        # FIRST, save the value.
        set options($option) $value

        # NEXT, trigger a search
        $self TargetTypeChanged
    }

    # -msgcmd    
    #     
    # A command for reporting messages, usually to the application's
    # message line.  It should take one additional argument.
    option -msgcmd -default ""

    # -multicol
    #     
    # When enabled, indicates that the target of searchback spans multiple
    # columns.  This is used to control -loglist's -formattext option.
    # This option has no effect if -loglist is not specified.
    option -multicol -type snit::boolean -default 0 \
        -configuremethod MultiColChanged
    
    # Delegate all other options to the hull
    delegate option -width to entry
    delegate option * to hull
    
    #-------------------------------------------------------------------
    # Instance Variables

    # Status display string.
    variable status "0 of 0"
    
    #-------------------------------------------------------------------
    # Constructor
    
    constructor {args} {
        # FIRST, set the hull defaults
        $hull configure                 \
            -relief             sunken  \
            -borderwidth        1       \
            -highlightcolor     black   \
            -highlightthickness 1

        # NEXT, Create the entry, options are delegated to it.
        install entry using ::marsgui::commandentry $win.entry    \
            -clearbtn           yes                           \
            -changecmd          [mymethod TargetChanged]      \
            -returncmd          [mymethod DoSearch]           \
            -background         $::marsgui::defaultBackground     \
            -highlightthickness 0                             \
            -borderwidth        0

        # NEXT, Save the constructor options.
        $self configurelist $args
        
        # NEXT, create the magnifying glass menu.
        menubutton $win.type                            \
            -relief           flat                      \
            -borderwidth      0                         \
            -activebackground $::marsgui::defaultBackground \
            -image            ::marsgui::search_icon        \
            -menu             $win.type.menu
        
        menu $win.type.menu   \
            -tearoff        0 \
            -borderwidth    1
        
        $win.type.menu add radio                     \
            -label      "Incremental"                \
            -variable   [myvar options(-targettype)] \
            -value      "incremental"                \
            -command    [mymethod TargetTypeChanged]
            
        $win.type.menu add radio                     \
            -label      "Exact"                      \
            -variable   [myvar options(-targettype)] \
            -value      "exact"                      \
            -command    [mymethod TargetTypeChanged]
            
        $win.type.menu add radio                     \
            -label      "Wildcard"                   \
            -variable   [myvar options(-targettype)] \
            -value      "wildcard"                   \
            -command    [mymethod TargetTypeChanged]
            
        $win.type.menu add radio                     \
            -label      "Regexp"                     \
            -variable   [myvar options(-targettype)] \
            -value      "regexp"                     \
            -command    [mymethod TargetTypeChanged]

        # If searchback will be enabled, provide the multi-column option
        if {$options(-loglist) ne ""} {
            $win.type.menu add separator

            $win.type.menu add checkbutton             \
                -label      "Multi-column Searchback"  \
                -variable   [myvar options(-multicol)] \
                -command    [mymethod MultiColChanged] 
        }

        button $win.first                                       \
            -relief         flat                                \
            -borderwidth    0                                   \
            -bitmap         @$::marsgui::library/button_first.xbm   \
            -state          disabled                            \
            -command        [mymethod GoToFirst]

        button $win.prev                                        \
            -relief         flat                                \
            -borderwidth    0                                   \
            -bitmap         @$::marsgui::library/button_prev.xbm    \
            -state          disabled                            \
            -command        [mymethod GoToPrev]

        button $win.next                                        \
            -relief         flat                                \
            -borderwidth    0                                   \
            -bitmap         @$::marsgui::library/button_next.xbm    \
            -state          disabled                            \
            -command        [mymethod GoToNext]

        button $win.last                                        \
            -relief         flat                                \
            -borderwidth    0                                   \
            -bitmap         @$::marsgui::library/button_last.xbm    \
            -state          disabled                            \
            -command        [mymethod GoToLast]
                                    
        label $win.status                       \
            -textvariable   [varname status]    \
            -relief         flat                \
            -width          15                  \
            -state          disabled
        
        if {$options(-loglist) ne ""} {
        
            button $win.prevlog                                     \
                -relief         flat                                \
                -borderwidth    0                                   \
                -bitmap         @$::marsgui::library/button_2up.xbm     \
                -state          disabled                            \
                -command        [mymethod SearchLogs earlier]

            button $win.stop                                        \
                -relief         flat                                \
                -borderwidth    0                                   \
                -bitmap         @$::marsgui::library/button_stop.xbm    \
                -state          disabled                            \
                -command        [mymethod StopSearch]

            button $win.nextlog                                     \
                -relief         flat                                \
                -borderwidth    0                                   \
                -bitmap         @$::marsgui::library/button_2down.xbm   \
                -state          disabled                            \
                -command        [mymethod SearchLogs later]           
        }     
    
        # NEXT, Lay out the widgets.

        # Column layout variable.
        set c -1
        
        grid $win.type  -row 0 -column [incr c] 
        grid $entry     -row 0 -column [incr c] -padx 4
        
        # Add the loglist search controls if needed
        if {$options(-loglist) ne ""} {
            grid $win.prevlog    -row 0  -column [incr c]
            grid $win.stop       -row 0  -column [incr c]
            grid $win.nextlog    -row 0  -column [incr c]
        }
        
        grid $win.status   -row 0  -column [incr c]
        grid $win.first    -row 0  -column [incr c]
        grid $win.prev     -row 0  -column [incr c]
        grid $win.next     -row 0  -column [incr c]
        grid $win.last     -row 0  -column [incr c]
                        
        grid $win -sticky ew        
    }

    #-------------------------------------------------------------------
    # Private Methods

    # MultiColChanged
    #
    # Called when the -multicol is changed via the icon menu or via
    # configure.  Informs the -loglist of the change if -loglist is
    # defined.

    method MultiColChanged {} {
        if {$options(-loglist) ne ""} {
            $options(-loglist) configure -formattext $options(-multicol)
        }
    }

    # TargetTypeChanged
    #
    # Called when the -targettype is changed via the icon menu or via
    # configure.  Executes a new search.

    method TargetTypeChanged {} {
        $entry execute
    }

    # TargetChanged text
    #
    # text        Current content of the target entry
    #
    # Makes changes as the target string changes.

    method TargetChanged {text} {
        # FIRST, Check for emptiness.
        if {[string is space $text]} {
            $entry clear
            set text ""
        }

        # NEXT, Enable/disable the clear button and file search buttons.
        if {$options(-loglist) ne ""} {
            if {$text eq ""} {
                $win.prevlog  configure -state disabled
                $win.nextlog  configure -state disabled
            } else {
                $win.prevlog  configure -state normal
                $win.nextlog  configure -state normal
            }
        }

        # NEXT, If searching is incremental, or if the entry is now
        # clear, update the search state.
        if {$text eq "" || $options(-targettype) eq "incremental"} {
            $self DoSearch $text
        }
    }

    # DoSearch target
    #
    # target     A new target string
    #
    # Execute a search with the new target string.
    method DoSearch {target} {
        # FIRST, Ignore empty targets.
        if {[string is space $target]} {
            $entry clear

            set target ""
        }
                
        # NEXT, if the search type is regexp, check the target for
        # validity.
        if {$options(-targettype) eq "regexp"} {
            if {[catch {regexp -- $target dummy} result]} {
                $self Message "invalid regexp: \"[$entry get]\""
                bell
                return
            }
        }


        # NEXT, call the -findcmd.
        if {$options(-targettype) eq "incremental"} {
            set searchType "exact"
        } else {
            set searchType $options(-targettype)
        }

        callwith $options(-findcmd) target $searchType $target
    }

    # GoToFirst
    #
    # Highlight and center the first line matching the search target.
    method GoToFirst {} {
        callwith $options(-findcmd) show 0
    }
    
    # GoToLast
    #
    # Highlight and center the last line matching the search target.
    method GoToLast {} {
        callwith $options(-findcmd) show end
    }
    
    # GoToNext
    #
    # Highlight and center the next line matching the search target.
    method GoToNext {} {
        callwith $options(-findcmd) next
    }
    
    # GoToPrev
    #
    # Highlight and center the previous line matching the search target.
    method GoToPrev {} {
        callwith $options(-findcmd) prev
    }
    
    # SearchLogs direction
    #
    # direction "earlier" or "later"
    #
    # Executes the current search in the loglist in the specified direction.
    # If the search hits, execute the same search in the logdisplay.
    method SearchLogs {direction} {
        # Get the current target; return if it's empty.
        if {[set target [$entry get]] eq ""} {return}
        
        # Incremental searches are actually exact searches.
        if {$options(-targettype) eq "incremental"} {
    
            set searchType "exact"
        
        } else {
        
            set searchType $options(-targettype)
        }
        
        # If doing regexp check the target pattern validity first
        if {$options(-targettype) eq "regexp"} {
            if {[catch {regexp -- $target dummy} result]} {
                $self Message "invalid regexp: \"[$entry get]\""
                bell
                return
            }
        }

        # Enable the stop button; disable the search buttons.
        $win.stop     configure -state normal
        $win.prevlog  configure -state disabled
        $win.nextlog  configure -state disabled
        
        # Execute the search.
        if {[$options(-loglist) searchlogs $direction $target $searchType]} {
            $self DoSearch $target
        }
        
        # Disable the stop button; enable the search buttons.
        $win.stop     configure -state disabled 
        $win.prevlog  configure -state normal
        $win.nextlog  configure -state normal
    }
    
    # StopSearch
    #
    # Stop the current loglist search.
    method StopSearch {} {
        $options(-loglist) stopsearch
    }
    
    # SetNavButtons state
    #
    # state     normal or disabled
    #
    # Set the state of the navigation buttons.
    method SetNavButtons {state} {
        $win.first  configure -state $state
        $win.prev   configure -state $state
        $win.next   configure -state $state
        $win.last   configure -state $state
    }

    # Message msg
    #
    # msg   A message string
    #
    # Logs a message using the -msgcmd.
    method Message {msg} {
        callwith $options(-msgcmd) $msg
    }
    
    #-------------------------------------------------------------------
    # Public Methods
    
    # found count instance
    #
    # count     Number of lines found (or 0)
    # instance  Instances which is highlighted, 0 to count-1 (or -1)
    # 
    # Updates the display to reflect the results.  This is usually
    # called by a rotext(n) widget's -foundcmd.

    method found {count instance} {
        if {$count == 0} {
            set status "0 of 0"

            if {[$entry get] eq ""} {
                $win.status configure -state disabled

                if {$options(-loglist) ne ""} {
                    $win.prevlog configure -state disabled
                    $win.nextlog configure -state disabled
                }
            } else {
                $win.status configure -state normal
            }

            $self SetNavButtons disabled

        
        } else {
            let line {$instance + 1}
            set status "$line of $count"
            $win.status configure -state normal

            if {$count > 0} {
                $self SetNavButtons normal
            } else {
                $self SetNavButtons disabled
            }
        }
    }
}






