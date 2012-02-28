#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mars_helptool(1) Application
#
#    Compiler for help(5) files.
#
#        package require app_helptool
#        app init $argv
#
#    This tool compiles help(5) input into .helpdb files which can be
#    browsed using helpbrowser(n) and queried using helpdb(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent compiler ;# Slave interpreter used to parse the input

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv         Command line arguments
    #
    # This the main program.

    typemethod init {argv} {
        # FIRST, get command-line options
        array set ::macro::docInfo {
            version  x.y.z
        }

        while {[string match "-*" [lindex $argv 0]]} {
            set opt [lshift argv]

            switch -exact -- $opt {
                -- {
                    break
                }

                -libdir {
                    lappend ::auto_path [lshift argv]
                }

                -lib {
                    package require {*}[lshift argv]
                }

                -version {
                    set ::macro::docInfo(version) [lshift argv]
                }

                default {
                    puts "Error, unrecognized option: $opt\n"
                    app usage
                    exit 1
                }
            }
        }

        # NEXT, validate the remaining arguments.
        set infile ""
        set outfile ""

        set argc [llength $argv]

        if {$argc == 1} {
            set infile  [lindex $argv 0]
            set outfile [file rootname $infile].helpdb
        } elseif {$argc == 2} {
            set infile  [lindex $argv 0]
            set outfile [lindex $argv 1]
        } else {
            app usage
            exit 1
        }

        # NEXT, if the outfile exists, delete it.
        file delete $outfile

        if {[file exists $outfile]} {
            puts "Error, output file already exists and cannot be deleted."
            exit 1
        }

        # NEXT, initialize the compiler
        $type CompilerInit

        # NEXT, create the helpdb in the global namespace so that
        # the macro code can see it.
        helpdb ::hdb
        hdb open $outfile
        hdb clear

        # NEXT, process the input file.
        set code [catch {$type CompileInputFile $infile} result]

        if {$code} {
            puts $::errorInfo
        }

        # NEXT, close the database.
        hdb close

        # NEXT, if there was a problem, notify the user and
        # delete the outfile.
        if {$code} {
            puts "Could not compile input file $infile:\n$result"
            file delete $outfile
        }

        # NEXT, exit explicitly, since we're running Tk
        exit
    }

    # usage
    # 
    # Displays the application usage.

    typemethod usage {} {
        puts [outdent {
            Usage: mars helptool \[options...\] file.help \[file.helpdb\]

            -version ver          Application version number
            -libdir  dir          Additional library directory
            -lib     "pkg ?ver?"  Package name and version
        }]
    }

    #-------------------------------------------------------------------
    # Compiler

    # CompilerInit
    #
    # Initializes the compiler.

    typemethod CompilerInit {} {
        # FIRST, create the slave interpreter used to parse the input
        # files.
        set compiler [interp create -safe]

        $compiler alias page    $type Compiler_page
        $compiler alias include $type Compiler_include
        $compiler alias image   $type Compiler_image
        $compiler alias macro   $type Compiler_macro
        $compiler alias super   $type Compiler_super

        # NEXT, initialize the ehtml(5) processor used to transform
        # the page bodies.
        ehtml init
        ehtml import ::macro::*
    }


    # CompileInputFile infile
    #
    # infile     The main input file.
    #
    # Compiles the input file into the help db.

    typemethod CompileInputFile {infile} {
        upvar 0 ::macro::pageInfo pageInfo

        # FIRST, compile the input
        $compiler invokehidden -global source $infile

        # NEXT, translate the pages from ehtml(5) to html.
        hdb eval {
            SELECT * FROM helpdb_pages
        } pageInfo {
            # FIRST, get the expanded text
            set newText [ehtml expand $pageInfo(text)]

            # NEXT, strip out the HTML, for searching
            regsub -all -- {<[^>]+>} $newText "" searchText

            # NEXT, save it in the database.
            hdb eval {
                UPDATE helpdb_pages
                SET text = $newText
                WHERE name=$pageInfo(name);

                INSERT INTO helpdb_search(name,title,text)
                VALUES($pageInfo(name),$pageInfo(title),$searchText);
            }
        }
    }


    # Compiler_page name title parent text
    #
    # name        The page's name
    # title       The page title
    # parent      Name of parent page, or ""
    # text        The raw text of the page.
    #
    # Defines a help page.

    typemethod Compiler_page {name title parent text} {
        # FIRST, validate the input
        require {$name ne ""} "Page name is empty"
        require {$title ne ""} "Page \"$name\" has no title"
        require {$text ne ""} "Page \"$name\" has no text"

        if {[hdb entity exists $name]} {
            error "Duplicate entity name: \"$name\""
        }

        if {$parent ne "" && ![hdb page exists $parent]} {
            error "Page \"$name\"'s parent does not exist: \"$parent\""
        }


        # NEXT, save the page.
        hdb eval {
            INSERT INTO 
            helpdb_pages(name,title,parent,text)
            VALUES($name,$title,$parent,$text);
        }
    }

    # Compiler_image name title filename
    #
    # name       The name used in links
    # title      A short title
    # filename   The image file on disk
    #
    # Loads an image into the helpdb so that it can be referenced
    # in help pages.

    typemethod Compiler_image {name title filename} {
        # FIRST, is the name unused?
        if {[hdb entity exists $name]} {
            error "Duplicate entity name: \"$name\""
        }

        # NEXT, is it a real image?
        if {[catch {
            set img [image create photo -file $filename]
        } result]} {
            error "Could not open the specified file as an image: $filename"
        }

        # NEXT, get the image data, and save it in the helpdb in PNG
        # format.
        set data [$img data -format png]

        hdb eval {
            INSERT OR REPLACE
            INTO helpdb_images(name,title,data)
            VALUES($name,$title,$data)
        }

        image delete $img
    } 


    # Compiler_include filename
    #
    # filename   Another .help file
    #
    # Includes the filename into the current file name

    typemethod Compiler_include {filename} {
        $compiler invokehidden -global source $filename
    }

    # Compiler_macro name arglist ?initbody? template
    #
    # name      A name for this fragment
    # arglist   Macro arguments
    # initbody  Initialization body
    # template  tsubst(n) template.
    #
    # Defines a macro that can be used in page bodies.

    typemethod Compiler_macro {name args} {
        ehtml macro $name {*}$args
    }

    # Compiler_super args
    #
    # args    A command to execute in the main interpreter
    #
    # This command allows the help input to access information from
    # project libraries by accessing the main interpreter in a controlled
    # way.

    typemethod Compiler_super {args} {
        namespace eval :: $args
    }
}

