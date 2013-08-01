#-----------------------------------------------------------------------
# TITLE:
#    appwin.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    Main application window
#
#    This window is implemented as snit::widget; however, it's set up
#    to exit the program when it's closed, just like ".".  It's expected
#    that "." will be withdrawn at start-up.
#
#    Because this is an application window, it can make use of
#    application-wide resources, such as the RDB.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appwin

snit::widget appwin {
    hulltype toplevel

    #-------------------------------------------------------------------
    # Components

    component filemenu              ;# The File menu
    component datagrid              ;# The datagrid(n) 
    component toolbar               ;# Application tool bar
    component content               ;# Tabbed notebook for content
    component detail                ;# Detail browser
    component jobdisp               ;# Job display, a rotext(n) widget
    component msgline               ;# The message line

    component master                ;# The experimentdb(n) for all results

    #-------------------------------------------------------------------
    # Variables

    variable timeoutId     ""

    variable info -array {
        adbfile "None"
        adbshort "None"
        axdbfile "None"
        axdbshort "None"
        weeks 26
        outdir ~
        rundir ~
        jobname "NONE"
        jobnum  0
        jobstate "IDLE"
        nnodes 0
        ntests 0
        queue  "shortq"
    }

    variable qsize -array {
        shortq    128
        mediumq   128
        longq     64
        verylongq 64
    }

    #-------------------------------------------------------------------
    # Options

    delegate option * to hull

    #-------------------------------------------------------------------
    # Instance variables

    # TBD

    #-------------------------------------------------------------------
    # Constructor

    constructor {args} {
        # FIRST, withdraw the hull widget, until it's populated.
        wm withdraw $win

        # NEXT, get the options
        $self configurelist $args

        # NEXT, create the menu bar
        $self CreateMenuBar

        # NEXT, create components.
        $self CreateComponents
        
        # NEXT, define dynaforms used
        $self DefineForms

        # NEXT, Allow the created widget sizes to propagate to
        # $win, so the window gets its default size; then turn off 
        # propagation.  From here on out, the user is in control of the 
        # size of the window.

        update idletasks
        grid propagate $win off

        # NEXT, Exit the app when this window is closed.
        wm protocol $win WM_DELETE_WINDOW [mymethod FileExit]

        # NEXT, restore the window
        wm title $win "Athena PBS [version]"
        wm deiconify $win
        raise $win

        # NEXT, initialize output and run directories
        set info(outdir) $::env(HOME)
        set info(rundir) $::env(HOME)
    }

    destructor {
        notifier forget $self
    }

    # CreateMenuBar
    #
    # Creates the application menus

    method CreateMenuBar {} {
        # FIRST, create the menu bar
        set menubar [menu $win.menubar -borderwidth 0]
        $win configure -menu $menubar

        # NEXT, create the File menu
        set menu [menu $menubar.file]
        $menubar add cascade -label "File" -underline 0 -menu $menu

        $menu add command \
            -label    "Set Output Directory..." \
            -underline 4 \
            -accelerator "Ctrl+W" \
            -command [mymethod SetOutputdir]

        $menu add command \
            -label       "Quit"   \
            -underline   0        \
            -accelerator "Ctrl+Q" \
            -command     [mymethod FileExit]
        bind $win <Control-q> [mymethod FileExit]
        bind $win <Control-Q> [mymethod FileExit]
    }

    #-------------------------------------------------------------------
    # Components

    # CreateComponents
    #
    # Creates the main window's components.

    method CreateComponents {} {
        # FIRST, prepare the grid.
        grid rowconfigure $win 0 -weight 0 ;# Separator
        grid rowconfigure $win 1 -weight 0 ;# Data grid
        grid rowconfigure $win 2 -weight 0 ;# Tool Bar
        grid rowconfigure $win 3 -weight 0 ;# Separator
        grid rowconfigure $win 4 -weight 1 ;# Content
        grid rowconfigure $win 5 -weight 0 ;# Separator
        grid rowconfigure $win 6 -weight 0 ;# Status Line

        grid columnconfigure $win 0 -weight 1

        # NEXT, put in the row widgets

        # ROW 0, add a separator between the menu bar and the rest of the
        # window.
        ttk::separator $win.sep0

        # ROW 1, add a toolbar
        install toolbar using ttk::frame $win.toolbar

        # Select input files
        ttk::button $toolbar.selectfiles \
            -style   Toolbutton                 \
            -image   ::marsgui::icon::openfile \
            -command [mymethod SelectFiles]
        DynamicHelp::add $toolbar.selectfiles -text "Select Files"

        # Run Experiment
        ttk::button $toolbar.run \
            -style   Toolbutton            \
            -image   ::marsgui::icon::step \
            -command [mymethod RunExperiment] 
        DynamicHelp::add $toolbar.run -text "Run Experiment"

        ::sc::notrunning control $toolbar.run

        ttk::button $toolbar.stop \
            -style Toolbutton             \
            -image ::marsgui::icon::x22   \
            -command [mymethod StopExperiment]
        DynamicHelp::add $toolbar.stop -text "Stop Experiment"

        pack $toolbar.selectfiles -side left
        pack $toolbar.run         -side left
        pack $toolbar.stop        -side left

        # ROW 2, add a separator between the tool bar and the content
        # window.
        ttk::separator $win.sep2

        # ROW 3, create the data grid
        install datagrid using datagrid $win.datagrid
        $datagrid label 0 0 -text "ADB:"
        $datagrid value 0 1 -width 30 -textvariable [myvar info(adbshort)]
        $datagrid label 0 2 -text "AXDB:"
        $datagrid value 0 3 -width 30 -textvariable [myvar info(axdbshort)]
        $datagrid label 1 0 -text "PBS job number:"
        $datagrid value 1 1 -width 9  -textvariable [myvar info(jobnum)]
        $datagrid label 1 2 -text "Job State:"
        $datagrid value 1 3 -width 10 -textvariable [myvar info(jobstate)]
        $datagrid label 2 0 -text "Nodes:"
        $datagrid value 2 1 -width 5  -textvariable [myvar info(nnodes)]
        $datagrid label 2 2 -text "Test Cases:"
        $datagrid value 2 3 -width 5  -textvariable [myvar info(ntests)]

        # ROW 4, create the content widgets.
        ttk::panedwindow $win.paner -orient vertical

        install content using ttk::notebook $win.paner.content \
            -padding 2 

        # Frame to hold the status display
        ttk::frame $content.dispw

        $win.paner add $content \
            -weight 1

        # ROW 5, add a separator
        ttk::separator $win.sep4

        # ROW 6, Create the Status Line frame.
        ttk::frame $win.status    \
            -borderwidth        2 

        # Message line
        install msgline using messageline $win.status.msgline

        pack $win.status.msgline -fill both -expand yes

        # Job display window
        install jobdisp using rotext $content.dispw.jobdisp    \
            -height    24                \
            -width     80                \
            -yscrollcommand [list $content.dispw.yscroll set] 
 

        ttk::scrollbar $content.dispw.yscroll \
            -command [list $content.dispw.jobdisp yview]

        $content add $content.dispw \
            -sticky nsew \
            -padding 2   \
            -text "Status"

        # Layout the scroll bar and job display window
        grid columnconfigure $content.dispw 0 -weight 1
        grid rowconfigure    $content.dispw 0 -weight 1
        grid $content.dispw.jobdisp -row 0 -column 0 -sticky nsew
        grid $content.dispw.yscroll -row 0 -column 1 -sticky ns

        # NEXT, manage all of the components.
        grid $win.sep0     -sticky ew
        grid $toolbar      -sticky ew
        grid $win.sep2     -sticky ew
        grid $win.datagrid -sticky ew
        grid $win.paner    -sticky nsew
        grid $win.sep4     -sticky ew
        grid $win.status   -sticky ew

        $self DisplayJobs ""
    }

    # DefineForms
    #
    # This method defines dynaform(n)s used by the Athena PBS applications
    
    method DefineForms {} {

        # FIRST, the runner form that pops up when the user selects to run
        # the experiment
        dynaform define runner {
            rcc "Number of nodes:" -for nnodes
            text nnodes

            rcc "Number of tests:" -for ntests
            text ntests

            rcc "Weeks to run:" -for nweeks
            text nweeks

            rcc "Est. run time:" -for queue
            enumlong queue -dictcmd {eqnames deflist} -defvalue shortq
        }
    }

    #-------------------------------------------------------------------
    # Menu Item Handlers

    # SelectFiles
    #
    # This method allows the user to select the baseline .adb and the
    # experiment .axdb file that contains the test cases to run

    method SelectFiles {} {
        set filename [tk_getOpenFile           \
                          -parent $win         \
                          -title  "Choose Files" \
                          -filetypes {
                              {{Baseline Scenario File} {.adb}}
                              {{Experiment File} {.axdb}}
                          }]

        # Nothing selected or "Cancel"
        if {$filename eq ""} {
            return
        }
    
        # Extract file extension and set appropriate variables
        if {[file extension $filename] eq ".adb"} {
            set info(adbfile) $filename
            set info(adbshort) [file tail $filename] 
        } elseif {[file extension $filename] eq ".axdb"} {
            set info(axdbfile) $filename
            set info(axdbshort) [file tail $filename]
            set info(jobname) [file rootname $info(axdbshort)]
            set axdb [experimentdb axdb_%AUTO%]
            $axdb open $info(axdbfile)
            set info(ntests) [$axdb eval {SELECT count(*) FROM cases}]
            set info(nnodes) $info(ntests)
            $axdb close
            $axdb destroy
        } else {
            error "Unrecognized file type: $filename"
        }
    }

    # RunExperiment 
    #
    # This method is called when the user selects the "Run" button or the
    # run command from the menu.

    method RunExperiment {} {
        # FIRST, there must be an .adb file selected
        if {![file exists $info(adbfile)]} {
            messagebox popup  \
                -parent $win  \
                -message "Select ADB file before running."

            return
        }

        # NEXT, there must be an .axdb file selected
        if {![file exists $info(axdbfile)]} {
            messagebox popup \
                -parent $win \
                -message "Select AXDB file before running."
            return
        }

        # NEXT, popup the dynabox with defaulted selections made
        set pdict [dynabox popup -formtype runner                    \
                            -parent $win                             \
                            -oktext "Run"                            \
                            -initvalue [list                         \
                                        nnodes $info(nnodes)         \
                                        ntests $info(ntests)         \
                                        nweeks $info(weeks)]   \
                            -validatecmd [mymethod ValidateRun]]

       if {$pdict eq ""} {
           return
       }

       # NEXT, compute the bounds of the tests to run based on the users
       # selections
       $self ComputeTestBounds $pdict

       # NEXT, generate the test scripts that will be run on each node
       $self GenerateTestScripts 

       # NEXT, run the job array
       $self RunJobArray
    }

    # StopExperiment 
    #
    # This method prompts the user to confirm that the experiment should
    # be stopped. If it is stopped, the PBS qdel command is executed with
    # job number that is currently running.

    method StopExperiment {} {
        set answer [messagebox popup \
                       -parent $win  \
                       -icon warning \
                       -message "Are you sure you want to stop?" \
                       -title "Stop Experiment" \
                       -onclose cancel          \
                       -buttons {
                           yes  "Yes"
                           cancel "Cancel"
                       }]

        if {$answer eq "cancel"} {
            return
        }

        # NEXT, get jobnum and append brackets (PBS wants them) and set
        # job state.
        set job "$info(jobnum)\[\]"
        set info(jobstate) "STOPPING"

        # NEXT, wrap the qdel in a catch. This will fail only if the job
        # terminates on its own just prior to the user confirming that
        # it should be deleted. In which case, the user already got what
        # was wanted.
        catch {
           exec qdel $job
        }

        notifier send ::main <State>
    }

    # ValidateRun pdict
    #
    # Validates the content of the dynabox of user inputs for a run
    #
    # pdict contains the following:
    #    nnodes  - the number of nodes to run on
    #    ntests  - the number of test cases to run
    #    nweeks  - the number of weeks to run

    method ValidateRun {pdict} {
       dict with pdict {} 

       # FIRST, the number of nodes must be at least 2. This is because
       # we are using a job array
       if {![string is integer -strict $nnodes] || $nnodes < 1} {
           return -code error -errorcode INVALID \
               "Number of nodes must be integer > 1"
       }

       # NEXT, the number of weeks should be at least 1.
       if {![string is integer -strict $nweeks] || $nweeks < 1} {
           return -code error -errorcode INVALID \
                "Number of weeks must be integer > 0"
       }

       # NEXT, you cannot request more nodes than can be supported
       # by the selected queue
       if {$nnodes > $qsize($queue)} {
           return -code error -errorcode INVALID \
               "Number of nodes must be <= $qsize($queue)"
       }

       return
    }

    # ComputeTestBounds pdict
    #
    # This method computes the bounds of test cases to be run on each
    # node. The data includes the starting and ending indices of each
    # set of tests and the number of weeks to run.
    #
    # pdict contains these variables:
    #    nnodes   - the number of nodes to run on
    #    ntests   - the total number of test cases to run
    #    nweeks   - the number of weeks to run Athena for each test case

    method ComputeTestBounds {pdict} {
        # FIRST, bring variables into scope
        dict with pdict {}
        
        if {$nnodes > $ntests} {
            set nnodes $ntests
        }

        # NEXT, fill in some info in the info array
        set info(nnodes) $nnodes
        set info(ntests) $ntests

        # NEXT, compute the minumum number of tests per node
        set minTestsPerNode [expr int($info(ntests)/$info(nnodes))]

        # NEXT, if the modulus of the number of tests to number of
        # nodes is not zero we will need to increase the number of tests 
        # on some nodes by one.
        set mod [expr {$info(ntests) % $info(nnodes)}]

        # NEXT, set the number of weeks to run, this is the same for all
        # test cases
        set info(weeks) $nweeks

        # NEXT, compute starting and ending tests based on user inputs
        set startTest 1
        set endTest   0

        for {set i 1} {$i <= $info(nnodes)} {incr i} {
            # Start is last end + 1
            set info(start-$i) $startTest

            # End is start + min tests per node 
            set endTest [expr {$startTest+$minTestsPerNode-1}]
            
            # Bump the end by one if the node number is less than
            # the modulus of number of tests to number of nodes
            if {$i <= $mod} {
                incr endTest
            }

            set info(end-$i) $endTest

            # Set the next start test for the next node
            set startTest [expr {$endTest + 1}]
        }
    }

    # GenerateTestScripts
    #
    # This method generates the axdb scripts that get passed to each instance
    # of Athena in the -script command line option. Each script sets the
    # bounds for each test case.

    method GenerateTestScripts {} {
        set rundir $info(rundir)
        for {set i 1} {$i <= $info(nnodes)} {incr i} {
            set f [open [file join $rundir test_case$i.tcl] "w"]

            puts $f "axdb open db_in$i.axdb"
            puts $f "axdb run -start $info(start-$i) -end $info(end-$i) -weeks $info(weeks)"
            puts $f "axdb close"

            close $f
        }
    }

    # RunJobArray
    #
    # This method creates the script that is actually passed to the
    # PBS queue execution command called "qsub". It includes any user
    # defined PBS directives. For now, only one user defined directive is
    # available: the number of nodes to run. This will likely expand to
    # other directives.

    method RunJobArray {} {
        # FIRST, create the script to run 
        set rundir $info(rundir)

        set f [open [file join $info(rundir) job.tcl] "w"]

        # NEXT, move .adb and .axdb into the run directory 
        file copy -force $info(adbfile) $rundir
        file copy -force $info(axdbfile) $rundir

        # NEXT, generate the script
        puts $f "#!/usr/bin/tclsh"
        puts $f "#PBS -N [string range $info(jobname) 0 14]"
        puts $f "#PBS -j oe"
        puts $f "#PBS -l ncpus=1"
        puts $f "#PBS -q shortq"

        # Number of nodes directive
        puts $f "#PBS -J 1-$info(nnodes)"

        puts $f "#PBS -W stagein=db_in^array_index^.axdb@kelvin:$rundir/$info(axdbshort),adb_in^array_index^.adb@kelvin:$rundir/$info(adbshort)"
        puts $f "#PBS -W stageout=db_in^array_index^.axdb@kelvin:$rundir/db_out^array_index^.axdb"
        puts $f "set jobidx \$::env(PBS_ARRAY_INDEX)"
        puts $f "set scriptfile \"test_case\$jobidx.tcl\""
        puts $f "cd \$::env(PBS_JOBDIR)"
        #puts $f "exec athena.tcl -batch -script \$scriptfile $rundir/$info(adbshort)"
        puts $f "exec athena.tcl -batch -script \$scriptfile adb_in\$jobidx.adb"
        close $f

        # NEXT, submit the job array saving the jobId
        cd $info(rundir)
        file delete -force [file join $info(rundir) error.log]

        set jobId [exec qsub ./job.tcl]

        # NEXT, if we are running after the first time, cancel any timeout
        if {$timeoutId ne ""} {
            after cancel $timeoutId
        }

        # NEXT, display the status of the just submitted job
        $self DisplayJobs $jobId
    }

    # DisplayJobs ?jobId?
    #
    # This method displays the PBS systems status of all jobs in the job
    # array associated with jobId. If jobId is passed in, then that means
    # a new job has been submitted, otherwise this method displays whatever
    # information is available about the last job submitted. There may be
    # nothing available for display.

    method DisplayJobs {{jobId {}}} {
        # FIRST, if a jobId is passed in then a new job was just submitted
        if {$jobId ne ""} {
            
            # NEXT, parse out the job number, which is everything up to, but
            # not including the first left brace
            set lbidx [string first {[} $jobId]
            incr lbidx -1
            set info(jobnum) [string range $jobId 0 $lbidx]

            # NEXT, set the job state as started and schedule the next
            # timeout and return
            set info(jobstate) "STARTED"
            notifier send ::main <State>
            after 1000 [mymethod DisplayJobs ""]
            return
        }

        # NEXT, if we are waiting for a job, nothing to display
        if {$info(jobnum) == 0} {
            return
        }

        # NEXT, this is an existing job, update job status by using
        # the PBS qstat command
        set status [exec qstat -t]
        set alljobs [split $status "\n"]

        # NEXT, qstat returns *all* jobs, grab just those that have the
        # right job number embedded 
        set myjobs [list]

        foreach job $alljobs {
            if {[string first $info(jobnum) $job] > -1} {
                lappend myjobs $job
            }
        }

        # NEXT, grab the yscroll location
        set yscr [$content.dispw.yscroll get]

        # NEXT clear job display widget
        $jobdisp del 1.0 end

        # NEXT, update job display depending on qstat return
        if {[llength $myjobs] == 0} {
            $jobdisp ins 1.0 "No jobs active."

            # NEXT, if we were in the RUNNING state, then we are finished
            # Set status and coalesce the results. Otherwise we are IDLE
            if {$info(jobstate) eq "RUNNING"} {
                set info(jobstate) "RESULTS"
                after 500 [mymethod CoalesceResults]

                # NEXT, done. Cancel the timeout and return
                after cancel $timeoutId
                notifier send ::main <State>
                return
            }
        } else {
            # NEXT, we have jobs active in the job array, if we are in
            # the STARTED state, go to the RUNNING state otherwise we
            # just stay in the RUNNING state
            if {$info(jobstate) eq "STARTED" || $info(jobstate) eq "RUNNING"} {
                set info(jobstate) "RUNNING"
            } else {
                # This shouldn't happen, needed? Maybe, qstat may provide
                # information that results in this state.
                set info(jobstate) "IDLE"
            }

            # NEXT, update the job displays widget with our jobs
            $jobdisp ins 1.0 "[lindex $alljobs 0]\n"
            $jobdisp ins 2.0 "[lindex $alljobs 1]\n"

            set line 3
            foreach job $myjobs {
                $jobdisp ins $line.0 "$job\n"
                incr line
            }

            # NEXT, put the scrollbar back and notify state change
            $content.dispw.jobdisp yview moveto [lindex $yscr 0]
            notifier send ::main <State>
        }

        # NEXT, schedule the next timeout to update the jobs display
        set timeoutId [after 5000 [mymethod DisplayJobs ""]]
    }

    # CoalesceResults
    #
    # This method is called when the job state goes from RUNNING to FINISHED
    # It is responsible for opening up all the staged out .axdb files from
    # each test case and combining them into a single .axdb that contains
    # all results and all the history for the entire experiment.

    method CoalesceResults {} {
        # FIRST, grab the axdb output files that were staged out
        set fouts [lsort -dictionary \
            [glob -nocomplain [file join $info(rundir) db_out*.axdb]]]

        $jobdisp del 1.0 end

        # NEXT, if no axdb files were found, then there's a serious problem
        if {[llength $fouts] == 0} {
            $jobdisp ins 1.0 "No output AXDB files found, no results written"

            # NEXT, perform any clean up
            set info(jobstate) "IDLE"
            $self CleanUp

            return
        }

        # NEXT, create the master experimentdb object to hold all the
        # results
        set master [experimentdb master]
        set ofile "$info(jobname)_$info(jobnum).axdb"
        $jobdisp ins 1.0 "Writing results to [file join $info(outdir) $ofile]"

        update 

        $master open [file join $info(rundir) $ofile]

        $master clear

        # NEXT, get the names of the history tables that will be filled
        set destTables [$master eval {
            SELECT name FROM sqlite_master
            WHERE type='table'
            AND name GLOB 'hist_*'
        }]

        # NEXT, open each source axdb and write results into the master
        set node 1
        set nodelen [llength $fouts]

        foreach fout $fouts {
            $jobdisp ins end "\nWriting results from node $node of $nodelen"
            update

            $master eval "
                ATTACH DATABASE '$fout' AS source;
            "

            # FIRST, test cases. We only want the ones from the source
            # axdb that have outcomes
            $master transaction {
                $master eval {
                    INSERT OR REPLACE INTO cases 
                    SELECT * FROM source.cases
                    WHERE source.cases.outcome IS NOT NULL;
                }
            }

            # NEXT, all the history. Just grab everything, there won't be
            # any history for tests not run
            set sourceTables [$master eval {
                SELECT NAME FROM source.sqlite_master
                WHERE type='table'
                AND name GLOB 'hist_*'
            }]

            $master transaction {
                foreach table $destTables {
                    if {$table ni $sourceTables} {
                        continue
                    }
             
                    $master eval \
                        "INSERT INTO main.$table SELECT * FROM source.$table"
                }
            }

            $master eval {DETACH DATABASE source;}
            $jobdisp del 2.0 end
            incr node
        }

        $jobdisp del 1.0 end
        $jobdisp ins 1.0 "Wrote results to [file join $info(outdir) $ofile]"

        $master close

        if {$info(rundir) ne $info(outdir)} {
            file copy -force  [file join $info(rundir) $ofile] $info(outdir)
            if {[file exists [file join $info(rundir) error.log]]} {
                file copy -force [file join $info(rundir) error.log] \
                                 $info(outdir)
            }
        } 

        if {[file exists [file join $info(outdir) error.log]]} {
            messagebox popup \
                -parent $win \
                -icon error  \
                -title "Error" \
                -message [normalize "
                There was an error encountered during the run. See
                [file join $info(outdir) error.log] for more 
                information."]
        } 

        $master destroy
        set master ""

        # NEXT, perform any clean up
        set info(jobstate) "IDLE"

        #$self CleanUp
    }

    # CleanUp
    #
    # There are a lot of intermediate files that are generated that are
    # discarded by this method. The files all follow a particular pattern.
   
    method CleanUp {} {
        
        set filesToDelete [list]

        # FIRST, PBS job output files
        foreach f [glob -nocomplain \
            [file join $info(rundir) "*.o$info(jobnum)*"]] {
                file delete -force $f
        }

        # NEXT, individual Athena test case scripts
        foreach f [glob -nocomplain \
            [file join $info(rundir) "test_case*.tcl"]] {
                file delete -force $f
        }

        # NEXT, individual Athena AXDB output files. These were coalesced into
        # a single AXDB
        foreach f [glob -nocomplain [file join $info(rundir) "db_out*.axdb"]] {
            file delete -force $f
        }

        return
    }

    # FileOpen
    #
    # Prompts the user to open a script file.

    method FileOpen {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, query for the script file name.
        set filename [tk_getOpenFile                      \
                          -parent $win                    \
                          -title "Open Cell Model"        \
                          -filetypes {
                              {{cellmodel(5) script}     {.cm} }
                          }]

        # NEXT, If none, they cancelled
        if {$filename eq ""} {
            return
        }

        # NEXT, Open the requested script.
        cmscript open $filename
    }

    # FileSaveAs
    #
    # Prompts the user to save the script as a particular file.

    method FileSaveAs {} {
        # FIRST, query for the script file name.  If the file already
        # exists, the dialog will automatically query whether to 
        # overwrite it or not. Returns 1 on success and 0 on failure.

        set filename [tk_getSaveFile                       \
                          -parent $win                     \
                          -title "Save Cell Model As"        \
                          -filetypes {
                              {{cellmodel(5) script} {.cm} }
                          }]

        # NEXT, If none, they cancelled.
        if {$filename eq ""} {
            return 0
        }

        # NEXT, Save the script using this name
        return [cmscript save $filename]
    }

    # FileSave
    #
    # Saves the script to the current file, making a backup
    # copy.  Returns 1 on success and 0 on failure.

    method FileSave {} {
        # FIRST, if no file name is known, do a SaveAs.
        if {[cmscript cmfile] eq ""} {
            return [$self FileSaveAs]
        }

        # NEXT, Save the script to the current file.
        return [cmscript save]
    }

    # SaveUnsavedData
    #
    # Allows the user to save unsaved changes.  Returns 1 if the user
    # is ready to proceed, and 0 if the current activity should be
    # cancelled.

    method SaveUnsavedData {} {
        return 1

        # TBD need experiment module
        if {[experiment unsaved]} {
            # FIRST, deiconify the window, this gives the message box
            # a parent to popup over.
            wm deiconify $win

            # NEXT, popup the message box for the user
            set name [file tail [cmscript cmfile]]

            set message [tsubst {
                |<--
                The experiment [tif {$name ne ""} {"$name" }]has not been saved.
                Do you want to save your changes?
            }]

            set answer [messagebox popup                     \
                            -icon    warning                 \
                            -message $message                \
                            -parent  $win                    \
                            -title   "Athena PBS [version]" \
                            -buttons {
                                save    "Save"
                                discard "Discard"
                                cancel  "Cancel"
                            }]

            if {$answer eq "cancel"} {
                return 0
            } elseif {$answer eq "save"} {
                # Stop exiting if the save failed
                if {![$self FileSave]} {
                    return 0
                }
            }
        }

        return 1
    }


    # SetOutputdir
    #
    # Sets the working directory
    
    method SetOutputdir {} {
        set outdir [tk_chooseDirectory \
                        -initialdir $info(outdir) \
                        -parent $win \
                        -title "Choose Output Directory"]
        if {$outdir eq ""} {
            return
        }

        set info(outdir) $outdir
    }

    # FileExit
    #
    # Verifies that the user has saved data before exiting.

    method FileExit {} {
        # FIRST, Allow the user to save unsaved data.
        if {![$self SaveUnsavedData]} {
            return
        }

        # NEXT, the data has been saved if it's going to be; so exit.
        app exit
    }

    # CliPrompt
    #
    # Returns a prompt string for the CLI

    method CliPrompt {} {
        return ">"
    }
    
    # error text
    #
    # text       A tsubst'd text string
    #
    # Displays the error in a message box

    method error {text} {
        set text [uplevel 1 [list tsubst $text]]

        messagebox popup   \
            -message $text \
            -icon    error \
            -parent  $win
    }

    # puts text
    #
    # text     A text string
    #
    # Writes the text to the message line

    method puts {text} {
        $msgline puts $text
    }

    method jobstate {} {
        return $info(jobstate)
    }
}
