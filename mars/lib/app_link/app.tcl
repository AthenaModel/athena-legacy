#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mars_link(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_link
#        app init $argv
#
#    This program is a CM tool that links versions of Mars into
#    a client project's work area.
#
# TERMINOLOGY:
#    Mars is linked to a client tag, branch, or trunk if checking out
#    the client project's tag, branch, or trunk will also check out
#    some version of Mars.
#
#    Mars is linked locally if a version of Mars has been "svn copy"'d 
#    into the client's code base.
#
#    Mars is linked externally if svn:externals is set on client 
#    directory to checkout Mars as a subdirectory.
#
#    A client working copy is said to be linked with a
#    version of Mars if that version of Mars is checked out within it
#    as an external working copy.
#
#    * The working copy is temporarily linked if svn:externals has not
#      been set, or is set to a different version of Mars.
#
#    * The link has been saved if svn:externals is set to the linked
#      version of Mars.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Constructor

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # Info array
    #
    # action     Desired action: Query, Link, Save, Copy, Help
    # linkver    Version to link: trunk, or a version number

    typevariable info -array {
        action  ""
        linkver ""
    }

    # client array
    #
    # Array of information about the client working copy.

    typevariable client

    # mars array
    #
    # Array of information about the mars working copy
    
    typevariable mars

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv         Command line arguments
    #
    # This the main program.

    typemethod init {argv} {
        # FIRST, parse the arguments.  The results will be stored
        # in the info() array.  On error, the program will halt.
        ParseArgs $argv

        # NEXT, print out the current working directory:
        putf "In Directory" [file normalize .]

        # NEXT, execute the desired option
        $info(action)
    }

    # ParseArgs argv
    #
    # argv       List of command line arguments
    #
    # Parses and validates the arguments, putting the result in
    # the info() array.

    proc ParseArgs {argv} {
        # FIRST, If no arguments, this is a query.
        if {[llength $argv] == 0} {
            set info(action) Query
            return
        }

        # NEXT, there's at least one argument; determine the desired
        # action.
        set cmd [lshift argv]

        switch -exact -- $cmd {
            help {
                set info(action) Help
            }
                
            save {
                set opt [lshift argv]

                if {$opt eq ""} {
                    set info(action) Save
                } elseif {$opt eq "-ascopy"} {
                    set info(action) Copy
                } else {
                    puts "Error, invalid option: \"$opt\""
                    exit 1
                }
            }

            trunk {
                set info(action)  Link
                set info(linkver) trunk
            }

            default {
                set info(action) Link
                set info(linkver) $cmd
            }
        }

        if {[llength $argv] > 0} {
            puts "Error, excess arguments: \"$argv\""
            exit 1
        }
    }

    #-------------------------------------------------------------------
    # Subcommands

    # Help
    #
    # Display command line syntax.

    proc Help {} {
        puts [tsubst {
            |<--
            Usage: mars link <command> <args...>

                help            Show this text.

                trunk           Temporarily link this client working copy 
                                with the Mars trunk.

                <version>       Temporarily link this client working copy 
                                with the specified Mars version, e.g., 1.3.

                save            Make the current link permanent as an
                                external link.

                save -ascopy    Permanently copy the linked version of
                                Mars into the the client's code base.
        }]
    }

    # Query
    #
    # Queries the current link, and populates the client() and mars()
    # arrays.

    proc Query {} {
        # FIRST, Verify that this is an OK place to be.
        EnsureInClientWorkingCopy

        # NEXT, get info about the client working copy.  We know it
        # exists.
        svninfo . client

        putf "Repository" $client(Repository_Root)
        putf "Client URL" $client(relURL)
        
        # NEXT, get info about Mars
        GetMarsInfo

        if {$mars(link) eq "external"} {
            putf "Current Link" $mars(relURL)
        } else {
            putf "Current Link" $mars(link)
        }
    }

    # Link
    #
    # Switches the linked Mars to the desired version

    proc Link {} {
        # FIRST, Query and display the current working copy, the 
        # current link, and so forth.  This will also load the client()
        # and mars() arrays.
        Query

        # NEXT, see if there's already a copy here; in that case,
        # we can't link anything.
        
        if {$mars(link) eq "copy"} {
            puts [tsubst {
                |<--

                Mars cannot be linked; a copy of Mars has already been
                explicitly copied into the client's code base using
                "svn copy".
            }]

            exit 1
        }

        # NEXT, ensure that the requested version of Mars is available
        # in the same repository as the client.

        set rep $client(Repository_Root)

        if {$info(linkver) eq "trunk"} {
            set newRelURL mars/trunk
        } else {
            set newRelURL mars/tags/mars_$info(linkver)
        }

        set newURL $rep/$newRelURL


        # NEXT, add ".jpl.nasa.gov", if need be.
        set newURL [AddDomain $newURL jpl.nasa.gov]

        putf "New Mars Link" $newRelURL
        putf "New Mars URL"  $newURL

        # NEXT, make sure that we aren't already linked to this
        # version.

        if {$newURL eq [AddDomain $mars(URL) jpl.nasa.gov]} {
            puts [tsubst {
                |<--

                Mars is already linked to the desired version.
            }]

            exit
        }
       
        # NEXT, make sure that this version exists
        if {[catch {exec svn ls $newURL} result]} {
            puts [tsubst {
                |<--

                Mars cannot be linked; no such version of Mars is
                available in this repository.
            }]

            exit 1
        }

        # NEXT, If there is already a version of Mars checked out,
        # switch it to this version; otherwise, check out a new one.
        
        set marsDir [file join . mars]

        puts ""
        
        if {$mars(link) eq "external"} {
            svn switch $newURL $marsDir
        } elseif {$mars(link) eq "none"} {
            svn checkout $newURL $marsDir
        } else {
            puts [tsubst {
                |<--

                Mars cannot be linked; $marsDir has unexpected link
                type: "$mars(link)".
            }]

            exit 1
        }

        puts ""

        puts "$marsDir is temporarily linked to $newRelURL."
    }

    # Save
    #
    # Saves the linked copy permanently, using svn:external.

    proc Save {} {
        # FIRST, Query and display the current working copy, the 
        # current link, and so forth.  This will also load the client()
        # and mars() arrays.
        Query

        # NEXT, see if there's already a copy here; in that case,
        # we can't save anything.
        
        if {$mars(link) eq "copy"} {
            puts [tsubst {
                |<--

                Cannot save; a copy of Mars has already been explicitly 
                copied into the client's code base using "svn copy".
            }]

            exit 1
        }

        # NEXT, make sure there's a link.
        set marsDir [file join . mars]

        if {$mars(link) eq "none"} {
            puts [tsubst {
                |<--

                Cannot save; there is no linked copy of Mars at
                "$marsDir".
            }]

            exit 1
        }

        # NEXT, if this is the client trunk, only the Mars trunk can
        # be saved.

        if {[string match "*/trunk" $client(URL)]
            && ![string match "*/trunk" $mars(URL)]
        } {
            puts [tsubst {
                |<--

                Cannot save anything but the Mars trunk to the
                client trunk.
            }]

            exit 1
        }

        puts ""

        svn propset svn:externals "mars $mars(URL)\n" .
        svn update
        svn commit -m "Permanent link to $mars(relURL)." .

        puts ""
        puts "$marsDir is permanently linked to $mars(relURL)."
    }

    # Copy
    #
    # Saves the linked copy permanently, by "svn copy"ing it into
    # the client code base.

    proc Copy {} {
        # FIRST, Query and display the current working copy, the 
        # current link, and so forth.  This will also load the client()
        # and mars() arrays.
        Query

        # NEXT, can't save a local copy to the client trunk.

        if {[string match "*/trunk" $client(URL)]} {
            puts [tsubst {
                |<--

                Cannot save a local copy to the client's trunk.
            }]

            exit 1
        }

        # NEXT, see if there's already a copy here; in that case,
        # we can't save anything.
        
        if {$mars(link) eq "copy"} {
            puts [tsubst {
                |<--

                Cannot save; a copy of Mars has already been explicitly 
                copied into the client's code base using "svn copy".
            }]

            exit 1
        }

        # NEXT, make sure there's a link.
        set marsDir [file join . mars]

        if {$mars(link) eq "none"} {
            puts [tsubst {
                |<--

                Cannot save; there is no linked copy of Mars at
                "$marsDir".
            }]

            exit 1
        }

        puts ""

        # NEXT, delete any svn:externals

        svn propdel svn:externals .
        svn commit -m "Deleted external link to Mars." .

        # NEXT, copy the version of Mars into the code base
        set clientMars [AddDomain $client(URL)/mars jpl.nasa.gov]
        set msg "Copying $mars(relURL) into $client(relURL)"
        svn copy -m$msg \
            $mars(URL) $clientMars

        # NEXT, switch the ./mars directory to the client's
        # code base.

        svn switch $clientMars $marsDir

        puts ""
        puts "$mars(relURL) has been copied into the client at"
        puts "the URL $clientMars."
    }

    #-------------------------------------------------------------------
    # Mars Link Utilities


    # EnsureInClientWorkingCopy
    #
    # Ensures that the current working directory is in a Subversion
    # working copy; and that it is a client project, not a Mars
    # working copy.

    proc EnsureInClientWorkingCopy {} {
        # FIRST, are we in a working copy at all?
        if {[catch {svninfo . temp}]} {
            puts [tsubst {
                |<--

                Mars cannot be linked here; this directory is not part
                of a Subversion working copy.
            }]

            exit 1
        }

        # NEXT, make sure it isn't a Mars working copy.
        if {[string match "*/mars/*" $temp(URL)]} {
            puts [tsubst {
                |<--

                Mars cannot be linked here; this directory is part of
                a Mars working copy.  Linking Mars here could cause
                Mars to check itself out recursively, which would be
                a *bad* thing.
            }]

            exit 1
        }
    }

    # GetMarsInfo
    #
    # Retrieves svninfo for ./mars into mars() as well as the following:
    #
    #    link     If "none", no linked mars
    #             If "copy", Mars has been "svn copy"'d into this
    #             client.
    #             If "external", it's an external working copy.
    #             See relURL for the version.

    proc GetMarsInfo {} {
        set marsDir [file join . mars]

        if {![file exists $marsDir]} {
            set mars(link) none
        } elseif {[catch {svninfo ./mars mars} result]} {
            set mars(link) none
        } elseif {$mars(relURL) eq [file join $client(relURL) mars]} {
            set mars(link) copy
        } else {
            set mars(link) external
        }
    }

    #-------------------------------------------------------------------
    # Subversion Utilities

    # svninfo path infoVar
    #
    # path     A file or directory path
    # infoVar  Name of an array to receive the info
    #
    # Retrieves "svn info" for the path and returns it in the array.
    
    proc svninfo {path infoVar} {
        upvar 1 $infoVar info

        # FIRST, get and save the info
        set result [exec svn info $path]

        foreach line [split $result "\n"] {
            set colonIndex [string first ":" $line]
            
            set key [string map {" " _} [string range $line 0 $colonIndex-1]]
            set value [string range $line $colonIndex+2 end]
            
            if {$key ne ""} {
                set info($key) $value
            }
        }

        # NEXT, determine the relURL
        set len [string length $info(Repository_Root)]
        set info(relURL) [string range $info(URL) $len+1 end]
    }

    # svn cmd args...
    #
    # Logs and executes the Subversion cmd, and returns the result
    
    proc svn {cmd args} {
        puts "svn $cmd $args"
        puts [exec svn $cmd {*}$args]
    }

    #-------------------------------------------------------------------
    # Other Utilities

    # AddDomain url domain
    #
    # url     An SVN URL
    # domain  A DNS domain
    #
    # Adds the domain to the server in the url, if it's not already
    # there.

    proc AddDomain {url domain} {
        set domainRE {^(https?://([^:/]+))([:/].*)$}

        # FIRST, get the server
        regexp $domainRE $url dummy root server tail

        # NEXT, if the domain is there don't add it.
        if {[string match "*$domain" $server]} {
            return $url
        }

        # NEXT, insert the domain into the URL
        return "$root.$domain$tail"
    }

    # putf label value
    #
    # label    A text label
    # value    A value
    #
    # Outputs labels and values in columns

    proc putf {label value} {
        puts [format "%-18s %s" "$label:" $value]
    }


}





