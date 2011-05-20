#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_helptool(1) Application
#
#    Compiler for help(5) files.
#
#        package require app_help
#        app init $argv
#
#    This is a prototype for a new help compiler that can build
#    .helpdb files that can be read by helpserver(n) and browsed
#    in a mybrowser(n).
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        snit::stringtype ::app::slug \
            -regexp {^[-A-Za-z0-9_:=]+$}
    }



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

        # NEXT, create the help db in the global namespace so that
        # the macro code can see it.
        sqldocument ::hdb   \
            -autotrans off  \
            -rollback  off

        hdb open $outfile
        hdb clear
        hdb eval [readfile [file join $::app_help::library help.sql]]

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
            Usage: helptool \[options...\] file.help \[file.helpdb\]

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
        $compiler alias object  $type Compiler_object

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
                WHERE path=$pageInfo(path);

                INSERT INTO helpdb_search(path,title,text)
                VALUES($pageInfo(path),$pageInfo(title),$searchText);
            }
        }
    }


    # Compiler_page parent slug title text
    #
    # parent      Path of parent page, or "" for root
    # slug        The page's name, or "" for the root
    # title       The page title
    # text        The raw text of the page.
    #
    # Defines a help page.

    typemethod Compiler_page {parent slug title text} {
        # FIRST, get the path.
        if {$parent eq "" && $slug eq ""} {
            set path "/"
        } elseif {$parent eq "/"} {
            set path "/$slug"
        } else {
            set path "$parent/$slug"
        }

        # NEXT, validate the input
        require {
            ($parent eq "" && $slug eq "") || 
            ($parent ne "" && $slug ne "")
        } "Only the root page can have an empty slug."

        if {$slug ne "" && [catch {slug validate $slug} result]} {
            error "Misformed slug for page \"$path\""
        }
        require {$title ne ""} "Page \"$path\" has no title"
        require {$text  ne ""} "Page \"$path\" has no text"

        if {[hdb exists {
            SELECT path FROM helpdb_reserved WHERE path=$path}]
        } {
            error "Duplicate entity path: \"$path\""
        }

        if {$parent ne ""} {
            if {![hdb exists {
                SELECT path FROM helpdb_pages WHERE path=$parent
            }]} {
                error "Page \"$path\"'s parent does not exist: \"$parent\""
            }

            hdb eval {
                UPDATE helpdb_pages
                SET leaf=0
                WHERE path=$parent;
            }
        }

        # NEXT, add the page footer.
        append text "<p>\n\n<hr>\n"
        append text "<i><font size=2>Help compiled "
        append text "<<clock format [clock seconds]>></font></i>\n"

        # NEXT, save the page.
        hdb eval {
            INSERT INTO 
            helpdb_pages(path,parent,slug,title,text)
            VALUES($path,$parent,$slug,$title,$text);
        }
    }

    # Compiler_image slug title filename
    #
    # slug       The image slug; path is /image/$slug
    # title      A short title
    # filename   The image file on disk
    #
    # Loads an image into the helpdb so that it can be referenced
    # in help pages.

    typemethod Compiler_image {slug title filename} {
        # FIRST, get the path
        set path /image/$slug

        # NEXT, is the path unused?
        if {[hdb exists {
            SELECT path FROM helpdb_reserved WHERE path=$path}]
        } {
            error "Duplicate entity path: \"$path\""
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
            INTO helpdb_images(path,slug,title,data)
            VALUES($path,$slug,$title,$data)
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

    # Compiler_object name script
    #
    # name       The object's command name.
    # script     The object definition script.
    #
    # Creates an object type that can later be queried.

    typemethod Compiler_object {name script} {
        namespace eval ::objects:: { }

        if {[catch {
            set obj [object ::objects::$name $script]
        } result opts]} {
            error "Error in object definition \"$name\",\n$result"
        }

        # Make the object available for use as a macro
        namespace eval ::objects:: [list namespace export $name]
        ehtml import ::objects::$name

        # Make the object available for use in procs
        $compiler alias $name ::objects::$name
    } 


    #-------------------------------------------------------------------
    # Utility Typemethods for use in macros and so forth.

    # image exists path
    #
    # path - An image path
    #
    # Returns 1 if the image exists, and 0 otherwise.

    typemethod {image exists} {path} {
        hdb exists {SELECT * FROM helpdb_images WHERE path=$path}
    }

    # page exists path
    #
    # path - A page path
    #
    # Returns 1 if the page exists, and 0 otherwise.

    typemethod {page exists} {path} {
        hdb exists {SELECT * FROM helpdb_pages WHERE path=$path}
    }

    # page title path
    #
    # path - A page path
    #
    # Returns the page's title

    typemethod {page title} {path} {
        hdb onecolumn {SELECT title FROM helpdb_pages WHERE path=$path}
    }

}


