#-----------------------------------------------------------------------
# TITLE:
#   scriptbrowser.tcl
#
# AUTHORS:
#   Will Duquette
#
# DESCRIPTION:
#   scriptbrowser(sim) package: Executive Script Browser/Editor
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Widget Definition

snit::widget scriptbrowser {
    #-------------------------------------------------------------------
    # Type Constructor


    #-------------------------------------------------------------------
    # Options

    # Options delegated to the hull
    delegate option * to hull


    #-------------------------------------------------------------------
    # Components

    component reloader       ;# timeout(n) that reloads content

    # SList: Script List
    component slist          ;# Script List sqlbrowser(n)
    component sl_bar         ;# Toolbar
    component sl_addbtn      ;# Add Script
    component sl_impbtn      ;# Import Script button
    component sl_expbtn      ;# Export Script button
    component sl_togglebtn   ;# Toggle Auto button
    component sl_topbtn      ;# To Top button
    component sl_raisebtn    ;# Raise button
    component sl_lowerbtn    ;# Lower button
    component sl_bottombtn   ;# To Bottom button
    component sl_deletebtn   ;# Delete Script button

    # Editor: Script Editor Pane
    component editor         ;# Script editor widget
    component ed_bar         ;# Editor toolbar
    component ed_name        ;# Editor name
    component ed_renamebtn   ;# Rename button
    component ed_execbtn     ;# Eval button
    component ed_savebtn     ;# Save button
    component ed_revertbtn   ;# Revert button (X)
    component ed_resetbtn    ;# Executive reset button

    # Outlog: Script Outlog Pane
    component outlog         ;# Script outlog widget.
    component out_bar        ;# Script outlog toolbar.

    #-------------------------------------------------------------------
    # Instance Variables

    # info array
    #
    #   sname           - Name of currently displayed script, or ""
    #   reloadRequests  - Number of reload requests since the last reload.
    
    variable info -array {
        sname          ""
        reloadRequests 0
    }

    #--------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, create the timeout controlling reload requests.
        install reloader using timeout ${selfns}::reloader \
            -command    [mymethod ReloadContent]           \
            -interval   1                                  \
            -repetition no

        # NEXT, create the GUI components
        ttk::panedwindow $win.hpaner \
            -orient horizontal

        pack $win.hpaner -fill both -expand yes

        ttk::panedwindow $win.hpaner.vpaner \
            -orient vertical

        pack $win.hpaner.vpaner -fill both -expand yes

        $self SListCreate $win.hpaner.slist
        $self EditorCreate $win.hpaner.vpaner.editor
        $self OutlogCreate $win.hpaner.vpaner.outlog

        $win.hpaner        add $win.hpaner.slist 
        $win.hpaner        add $win.hpaner.vpaner        -weight 1
        $win.hpaner.vpaner add $win.hpaner.vpaner.editor -weight 2
        $win.hpaner.vpaner add $win.hpaner.vpaner.outlog -weight 1

        # NEXT, configure the command-line options
        $self configurelist $args

        # NEXT, Behavior

        # Reload the content when the window is mapped.
        bind $win <Map> [mymethod MapWindow]

        # Reload the content on various notifier events.
        notifier bind ::sim       <DbSyncB> $self [mymethod ReloadOnEvent]
        notifier bind ::sim       <State>   $self [mymethod ReloadOnEvent]
        notifier bind ::executive <Scripts> $self [mymethod MonScripts]

        # NEXT, schedule the first reload
        $self reload
    }

    destructor {
        notifier forget $self
    }

    # MapWindow
    #
    # Reload the browser when the window is mapped, if there have
    # been any reload requests.
    
    method MapWindow {} {
        # If a reload has been requested, but the reloader is no
        # longer scheduled (i.e., the reload was requested while
        # the window was unmapped) then reload it now.
        if {$info(reloadRequests) > 0 &&
            ![$reloader isScheduled]
        } {
            $self ReloadContent
        }
    }

    # ReloadOnEvent
    #
    # Reloads the widget when various notifier events are received.
    # The "args" parameter is so that any event can be handled.
    
    method ReloadOnEvent {args} {
        $self reload
    }
    
    # ReloadContent
    #
    # Reloads the current -view.  Has no effect if the window is
    # not mapped.
    
    method ReloadContent {} {
        # FIRST, we don't do anything until we're mapped.
        if {![winfo ismapped $win]} {
            return
        }

        # NEXT, clear the reload request counter.
        set info(reloadRequests) 0

        # NEXT, Reload each of the components
        $slist reload
        $self EditorReload
        $self OutlogClear
    }

    # MonScripts update|delete name
    #
    # op    - The 
    # name  - The script name
    #
    # The set of scripts has been modified in some way.  Update the script
    # list accordingly.

    method MonScripts {op name} {
        # FIRST, Update the SList.
        if {$name ne ""} {
            $slist uid $op $name
        } else {
            $slist reload
        }

        # NEXT, if the script was updated and it's the currently
        # selected script, refresh the entire browser; this will
        # reload the script changes in the editor.
        if {$op eq "update" && $name == $info(sname)} {
            $self reload
        }
    }

    # Show sname
    #
    # sname   - A script name
    #
    # Displays the script with the given name.

    method Show {sname} {
        $slist uid select [list $sname]
    }



    #-------------------------------------------------------------------
    # Script List Pane

    # SListCreate pane
    #
    # pane - The name of the script list's pane widget
    #
    # Creates the "slist" component, which lists all of the
    # available scripts.

    method SListCreate {pane} {
        # FIRST, create the pane
        ttk::frame $pane

        # NEXT, create the toolbar
        install sl_bar using ttk::frame $pane.sl_bar
        ttk::separator $pane.sep1 \
            -orient horizontal

        # NEXT, add the buttons
        install sl_addbtn using mktoolbutton $sl_bar.sl_addbtn    \
            ::marsgui::icon::plus22                               \
            "Add Script"                                          \
            -state   normal                                       \
            -command [mymethod SListScriptAdd]

        cond::predicate control $sl_addbtn                       \
            browser $win                                         \
            predicate editorSaved

        install sl_impbtn using mktoolbutton $sl_bar.sl_impbtn    \
            ::projectgui::icon::import22                          \
            "Import Script"                                       \
            -state   normal                                       \
            -command [mymethod SListScriptImport]

        cond::predicate control $sl_impbtn                       \
            browser $win                                         \
            predicate editorSaved

        install sl_expbtn using mktoolbutton $sl_bar.sl_expbtn    \
            ::projectgui::icon::export22                          \
            "Export Script"                                       \
            -state   normal                                       \
            -command [mymethod SListScriptExport]

        cond::predicate control $sl_expbtn                       \
            browser $win                                         \
            predicate singleSaved

        install sl_togglebtn using mktoolbutton $sl_bar.sl_toggle \
            ::marsgui::icon::onoff                                \
            "Toggle Auto Flag"                                    \
            -state   normal                                       \
            -command [mymethod SListScriptToggleAuto]

        cond::predicate control $sl_togglebtn                    \
            browser $win                                         \
            predicate singleSaved

        install sl_topbtn using mktoolbutton $sl_bar.top         \
            ::marsgui::icon::totop                               \
            "Execute First"                                      \
            -state   disabled                                    \
            -command [mymethod SListSequence top]

        cond::predicate control $sl_topbtn                       \
            browser $win                                         \
            predicate singleSelected

        install sl_raisebtn using mktoolbutton $sl_bar.raise     \
            ::marsgui::icon::raise                               \
            "Execute Earlier"                                    \
            -state   disabled                                    \
            -command [mymethod SListSequence raise]

        cond::predicate control $sl_raisebtn                     \
            browser $win                                         \
            predicate singleSelected

        install sl_lowerbtn using mktoolbutton $sl_bar.lower     \
            ::marsgui::icon::lower                               \
            "Execute Later"                                      \
            -state   disabled                                    \
            -command [mymethod SListSequence lower]

        cond::predicate control $sl_lowerbtn                     \
            browser $win                                         \
            predicate singleSelected

        install sl_bottombtn using mktoolbutton $sl_bar.bottom   \
            ::marsgui::icon::tobottom                            \
            "Execute Last"                                       \
            -state   disabled                                    \
            -command [mymethod SListSequence bottom]

        cond::predicate control $sl_bottombtn                    \
            browser $win                                         \
            predicate singleSelected

        install sl_deletebtn using mkdeletebutton $sl_bar.deletebtn \
            "Delete Script"                                         \
            -state   disabled                                       \
            -command [mymethod SListDelete]

        cond::predicate control $sl_deletebtn                    \
            browser $win                                         \
            predicate singleSelected

        pack $sl_addbtn    -side left
        pack $sl_impbtn    -side left
        pack $sl_expbtn    -side left
        pack $sl_togglebtn -side left
        pack $sl_topbtn    -side left
        pack $sl_raisebtn  -side left
        pack $sl_lowerbtn  -side left
        pack $sl_bottombtn -side left

        pack $sl_deletebtn  -side right


        # NEXT, create the list widget
        install slist using sqlbrowser $pane.slist      \
            -columnsorting off                          \
            -height        10                           \
            -width         20                           \
            -relief        flat                         \
            -borderwidth   1                            \
            -stripeheight  0                            \
            -db            ::rdb                        \
            -view          gui_scripts                  \
            -uid           name                         \
            -filterbox     off                          \
            -selectmode    browse                       \
            -selectioncmd  [mymethod SListScriptSelect] \
            -layout {
                {name "Script" -stretchable yes} 
                {auto "Auto"                   }
            } 

        # NEXT, grid them all in place
        grid $sl_bar       -row 0 -column 0 -sticky ew -columnspan 2
        grid $pane.sep1    -row 1 -column 0 -sticky ew -columnspan 2
        grid $slist        -row 2 -column 0 -sticky nsew

        grid rowconfigure    $pane 2 -weight 1
        grid columnconfigure $pane 0 -weight 1
    }


    # SListScriptSelect
    #
    # Called when an script is selected in the slist.  Updates the
    # rest of the browser to display that script's body.

    method SListScriptSelect {} {
        # FIRST, update the rest of the browser
        set sname [lindex [$slist uid curselection] 0]

        # NEXT, handle selection of other scripts
        if {$sname ne $info(sname)} {
            # FIRST, if the current script hasn't been saved, do nothing.
            if {[$self editorUnsaved]} {
               messagebox popup                \
                    -parent  $win              \
                    -buttons {ok "OK"}         \
                    -icon    error             \
                    -title   "Unsaved Changes" \
                    -message [outdent {
                        There are unsaved changes in the current script.
                        Please save them before proceeding.
                    }]

                $self Show $info(sname)
                return
            }

            # NEXT, select the new script.          
            set info(sname) $sname 
            $self EditorReload
            $self OutlogClear
        }

        # NEXT, update state controllers
        $self SetButtonState
    }

    # SListScriptAdd
    #
    # Prompts the user for the name of a new script, and adds it to the
    # list.

    method SListScriptAdd {} {
        # FIRST, ask for the script name.
        set sname [$self GetUnusedScriptName \
            "New Script" \
            "Enter a name for the new script:"]

        if {$sname eq ""} {
            return
        }

        executive script save $sname

        $self Show $sname
    }

    # GetUnusedScriptName title text
    #
    # title   - The message box tile
    # text    - The message box text
    #
    # Prompts the user to enter a new, unused script name;
    # and returns it.  On cancel, returns "".

    method GetUnusedScriptName {title text} {
        # FIRST, ask for the script name.
        set sname [messagebox gets \
            -message $text         \
            -title   $title        \
            -parent  $win]

        if {$sname eq ""} {
            return
        }

        if {[executive script exists $sname]} {
            messagebox popup \
                -parent  [winfo toplevel $win]   \
                -buttons {ok "OK"}               \
                -icon    error                   \
                -title   "Script Already Exists" \
                -message "That name is already in use."

            return ""
        }

        return $sname
    }

    # SListScriptImport
    #
    # Prompts the user to select a script file, and imports it into
    # the set of executive scripts

    method SListScriptImport {} {
        # FIRST, query for a map file.
        set filename [tk_getOpenFile                    \
                          -parent $win                  \
                          -title "Select a script file" \
                          -filetypes {
                              {{Executive Scripts} {.tcl} }
                              {{Any File}    *      }
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, Import the map
        if {[catch {
            set sname [executive script import $filename]
        } result]} {
            app error {
                |<--
                Import failed: $result

                $filename
            }
        }

        $self Show $sname
    }

    # SListScriptExport
    #
    # Prompts the user to enter a file name to save the currently
    # selected script to.

    method SListScriptExport {} {
        # FIRST, the default file name is the script name with ".tcl"
        set filename $info(sname)

        # NEXT, query for the file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                        \
                          -parent      $win                 \
                          -title       "Export Script As"   \
                          -initialfile $filename            \
                          -filetypes   {
                              {{Executive Script} {.tcl} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, make sure it has a .tcl extension.
        if {[file extension $filename] ne ".tcl"} {
            append filename ".tcl"
        }

        # NEXT, Save the script using this name
        if {[catch {
            try {
                set f [open $filename w]
                puts $f [executive script get $info(sname)]
            } finally {
                close $f
            }
        } result opts]} {
            log warning app "Could not export script: $result"
            log error app [dict get $opts -errorinfo]
            app error {
                |<--
                Could not export the script to
                
                    $filename

                $result
            }
            return
        }

        log normal scenario "Exported script \"$info(sname)\" to: $filename"

        app puts "Exported script to [file tail $filename]"

        return
    }

    # SListScriptToggleAuto
    #
    # Toggles the auto flag for the selected script.

    method SListScriptToggleAuto {} {
        set auto [executive script auto $info(sname)]
        executive script auto $info(sname) [expr {!$auto}]
    }

    # SListDelete
    #
    # Deletes the selected script.

    method SListDelete {} {
        set answer [messagebox popup \
            -parent  [winfo toplevel $win]          \
            -buttons {cancel "Cancel" ok "Delete"}  \
            -icon    question                       \
            -title   "Delete Script"                \
            -message "Delete the script called \"$info(sname)\"?"]

        if {$answer eq "ok"} {
            executive script delete $info(sname)
            $self reload
        }
    }

    # SListSequence op
    #
    # op   - The operation: top, raise, lower, bottom
    #
    # Changes the sequence of the scripts.

    method SListSequence {op} {
        executive script sequence $info(sname) $op
    }


    #-------------------------------------------------------------------
    # Editor: Script Editor Pane

    # EditorCreate pane
    # 
    # pane - The name of the pane widget
    #
    # Creates the Editor pane, where scripts
    # edited.

    method EditorCreate {pane} {
        # FIRST, create the pane
        ttk::frame $pane

        # NEXT, create the toolbar
        install ed_bar using ttk::frame $pane.ed_bar

        ttk::label $ed_bar.title \
            -text "Script:"

        # Name field
        install ed_name using ttk::label $ed_bar.ed_name \
            -width 20

        # Rename button
        install ed_renamebtn using ttk::button $ed_bar.ed_renamebtn \
            -style   Toolbutton                                     \
            -state   disabled                                       \
            -text    "Rename"                                       \
            -command [mymethod EditorRename]
 
        cond::predicate control $ed_renamebtn \
            browser   $win               \
            predicate singleSaved

        DynamicHelp::add $ed_renamebtn \
            -text "Rename the currently selected script."


        # Revert button
        install ed_revertbtn using ttk::button $ed_bar.ed_revertbtn \
            -style   Toolbutton                                     \
            -state   disabled                                       \
            -text    "Revert"                                       \
            -command [mymethod EditorReload]
 
        cond::predicate control $ed_revertbtn \
            browser   $win                    \
            predicate editorUnsaved

        DynamicHelp::add $ed_revertbtn \
            -text "Throws away unsaved script changes."

        # Reset button
        install ed_resetbtn using ttk::button $ed_bar.ed_resetbtn   \
            -style   Toolbutton                                     \
            -text    "Reset"                                        \
            -command [mymethod EditorReset]

        DynamicHelp::add $ed_resetbtn \
            -text "Resets the executive, reloading saved scripts."

        # Exec button
        install ed_execbtn using ttk::button $ed_bar.ed_execbtn \
            -style   Toolbutton                                 \
            -state   disabled                                   \
            -text    "Execute"                                  \
            -command [mymethod EditorExecute]

        cond::predicate control $ed_execbtn                     \
            browser $win                                        \
            predicate singleSelected

        DynamicHelp::add $ed_execbtn \
            -text "Executes the script in the editor without saving it."


        # Save button
        install ed_savebtn using ttk::button $ed_bar.ed_savebtn \
            -style   Toolbutton                                 \
            -state   disabled                                   \
            -text    "Save"                                     \
            -command [mymethod EditorSave]

        cond::predicate control $ed_savebtn                     \
            browser $win                                        \
            predicate editorUnsaved
        DynamicHelp::add $ed_savebtn \
            -text "Saves any changes to the script.  Note that the scenario as a whole must be saved as well."

        # Pack 'em in.
        pack $ed_bar.title  -side left
        pack $ed_name       -side left
        pack $ed_renamebtn  -side left
        pack $ed_revertbtn  -side left
        pack $ed_resetbtn   -side left

        pack $ed_savebtn    -side right
        pack $ed_execbtn    -side right

        ttk::separator $pane.sep1 \
            -orient horizontal

        # NEXT, create the editor proper
        install editor using ctexteditor $pane.editor \
            -state       disabled                     \
            -modifiedcmd [mymethod SetButtonState ctext]    \
            -messagecmd  {app puts}

        $editor mode executive

        # NEXT, grid them all in place
        grid $ed_bar       -row 0 -column 0 -sticky ew
        grid $pane.sep1    -row 1 -column 0 -sticky ew
        grid $editor       -row 2 -column 0 -sticky nsew

        grid rowconfigure    $pane 2 -weight 1
        grid columnconfigure $pane 0 -weight 1
    }

    # SetButtonState
    #
    # Sets the state of the editor buttons in response to various events.

    method SetButtonState {args} {
        cond::predicate update [list \
            $sl_addbtn    \
            $sl_impbtn    \
            $sl_expbtn    \
            $sl_togglebtn \
            $sl_topbtn    \
            $sl_raisebtn  \
            $sl_lowerbtn  \
            $sl_bottombtn \
            $sl_deletebtn \
            $ed_renamebtn \
            $ed_revertbtn \
            $ed_execbtn   \
            $ed_savebtn]
    }

    # EditorReload
    #
    # Loads the currently selected script into the editor.
    # Disables the editor if no script is selected.

    method EditorReload {} {
        $editor configure -state normal
        $editor delete 1.0 end
        $editor edit modified no

        if {$info(sname) eq ""} {
            $editor configure -state disabled
        } else {
            $editor insert 1.0 [executive script get $info(sname)]
            $editor see 1.0
            $editor mark set insert 1.0
            $editor edit modified no
            $editor highlight 1.0 end
        }

        $ed_name configure -text $info(sname)
    }

    # EditorRename
    #
    # Allows the user to rename the current script.

    method EditorRename {} {
        # FIRST, ask for the script name.
        set oldName $info(sname)

        set newName [$self GetUnusedScriptName \
            "Rename Script" \
            "Enter a new name for the script:"]

        if {$newName eq ""} {
            return
        }

        executive script rename $oldName $newName
    }

    # EditorReset
    #
    # Resets the executive.

    method EditorReset {} {
        $self OutlogShow [executive reset]
    }

    # EditorExecute
    #
    # Evaluates the text in the editor without saving.

    method EditorExecute {} {
        set text [$editor get 1.0 "end -1 char"]

        set output "Checking "

        if {[$self editorUnsaved]} {
            append output "Unsaved "
        }

        append output "Script: $info(sname)\n"

        if {[catch {
            executive eval $text
        } result eopts]} {
            append output "Error: $result\n\n"
            append output "Full Info:\n"
            append output [dict get $eopts -errorinfo]

            $self OutlogShow $output error
            return
        }

        append output "OK\n\n"
        append output $result
        $self OutlogShow $output
    }

    # EditorSave
    #
    # Saves the text in the editor.

    method EditorSave {} {
        set text [$editor get 1.0 "end -1 char"]
        executive script save $info(sname) $text -silent
        $editor edit modified no
        $self SetButtonState

        set output "Saved Script: $info(sname)\n"

        if {[executive script auto $info(sname)]} {
            append output "Checking Script: $info(sname)\n"

            if {[catch {
                executive script load $info(sname)
            } result eopts]} {
                append output "Error: $result\n\n"
                append output "Full Info:\n"
                append output [dict get $eopts -errorinfo]

                $self OutlogShow $output error
                return
            }

            append output "OK\n\n"
            append output $result
        } else {
            append output "No check done (auto flag not set).\n"
            append output "Press \"Execute\" to check manually.\n"
        }


        $self OutlogShow $output
    }


    #-------------------------------------------------------------------
    # Outlog: Script Outlog Pane

    # OutlogCreate pane
    # 
    # pane - The name of the pane widget
    #
    # Creates the outlog pane, where script outlog is displayed.

    method OutlogCreate {pane} {
        # FIRST, create the pane
        ttk::frame $pane

        # NEXT, create the toolbar
        install out_bar using ttk::frame $pane.out_bar

        # Temporary add button, just for looks
        ttk::label $out_bar.title \
            -text "Script Output:"

        # TBD: Add Clear button?
            
        pack $out_bar.title -side left

        ttk::separator $pane.sep1 \
            -orient horizontal

        # NEXT, create the tactics tree widget
        install outlog using rotext $pane.outlog \
            -height         5                    \
            -width          80                   \
            -foreground     forestgreen          \
            -yscrollcommand [list $pane.yscroll set]

        ttk::scrollbar $pane.yscroll                 \
            -orient         vertical                 \
            -command        [list $outlog yview]

        # NEXT, grid them all in place
        grid $out_bar      -row 0 -column 0 -sticky ew -columnspan 2
        grid $pane.sep1    -row 1 -column 0 -sticky ew -columnspan 2
        grid $outlog       -row 2 -column 0 -sticky nsew
        grid $pane.yscroll -row 2 -column 1 -sticky ns

        grid rowconfigure    $pane 2 -weight 1
        grid columnconfigure $pane 0 -weight 1

        # NEXT, configure the rotext.
        $outlog tag configure error -foreground red
    }

    # OutlogClear
    #
    # Clears the outlog pane

    method OutlogClear {} {
        $outlog del 1.0 end
    }

    # OutlogShow text ?tags?
    #
    # text    - The outlog to display
    # tags    - tags to use, i.e., "error".
    #
    # Displays the text in the outlog widget.

    method OutlogShow {text {tag ""}} {
        $outlog del 1.0 end
        $outlog ins 1.0 $text $tag
        $outlog see 1.0
    } 


    #-------------------------------------------------------------------
    # State Controller Predicates
    #
    # These methods are used in statecontroller -conditions to control
    # the state of toolbar buttons and such-like.

    # singleSelected
    #
    # Returns 1 if a single item is selected in the SList, and 0 
    # otherwise.
    
    method singleSelected {} {
        expr {[llength [$slist curselection]] == 1}
    }

    # editorUnsaved
    #
    # returns 1 if the editor text has been modified, and 0 otherwise.

    method editorUnsaved {} {
        return [$editor edit modified]
    }    

    # editorSaved
    #
    # returns 1 if the editor text is unmodified, and 0 otherwise.

    method editorSaved {} {
        return [expr {![$editor edit modified]}]
    }    

    # singleSaved
    #
    # returns 1 if a single script is selected, and the editor is
    # unmodified.

    method singleSaved {} {
        return [expr {[$self singleSelected] && [$self editorSaved]}]
    }

    #-------------------------------------------------------------------
    # Public Methods

    delegate method * to hull

    # reload
    #
    # Schedules a reload of the content.  Note that the reload will
    # be ignored if the window isn't mapped.
    
    method reload {} {
        incr info(reloadRequests)
        $reloader schedule -nocomplain
    }
}




