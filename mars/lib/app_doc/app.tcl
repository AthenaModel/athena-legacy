#-----------------------------------------------------------------------
# TITLE:
#    app.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    mars_doc(1) Application
#
#    This module defines app, the application ensemble.
#
#        package require app_doc
#        app init $argv
#
#    This program is a document processor for app_doc(5) document
#    format.  app_doc(5) documents are written in "Extended HTML", 
#    i.e., HTML extended with Tcl macros.  It automatically generates
#    tables of contents, etc., and provides easy linking to other
#    documents and man pages.
#
# DOCUMENT STRUCTURE:
#
#    A document consists of the following elements:
#
#    * A table of contents, which may be located anywhere in the 
#      document but conventionally goes at the beginning.
#
#    * Zero or more "preface" sections.  A preface section has a title 
#      but no section number, and cannot have children.
# 
#    * Zero or more numbered sections, each of which may have zero or 
#      more subsections, etc.
#
#    * Numbered sections may contain figures and tables.
#
#    Every preface, section, figure, and table has an xref ID, 
#    which has the following form:
#
#    Type     Form
#    -------  ---------------------------------------------------------
#    preface  <token>
#    section  <token>[.<token>[.<token>...]]    
#    table    tab.<token>
#    figure   fig.<token>
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# app ensemble

snit::type app {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Constructor

    typeconstructor {
        # Export macros
        namespace export    \
            banner          \
            changelog       \
            /changelog      \
            change          \
            /change         \
            contents        \
            figure          \
            figures         \
            longproject     \
            preface         \
            project         \
            section         \
            sectioncontents \
            sequence        \
            standardstyle   \
            table           \
            /table          \
            tables          \
            version
    }

    #-------------------------------------------------------------------
    # Data Tables

    # HTML header levels by section header live.  Note that section 
    # level 0 is for unnumbered sections.

    typevariable hn -array {
        0 h2
        1 h2
        2 h3
        3 h4
        4 h4
        5 h4
        6 h4
    }

    # Default style sheet

    typevariable css {
        a {
            text-decoration: none;
        }
        body {
            color: black;
            background: white;
            margin-left: 1%;
            margin-right: 1%;
        }
        pre.box {
            background:     #FFFF99 ;
            border:         1px solid blue;
            padding-top:    2px;
            padding-bottom: 2px;
            padding-left:   4px;
        }
        table {
            margin-top:    4px;
            margin-bottom: 4px;
            width:         100%;
        }
        th {
            padding-left: 4px;
        }
        td {
            padding-left: 4px;
        }
    }


    #-------------------------------------------------------------------
    # Type Variables

    # Info array: scalars
    #
    #  version      The version of the software being documented
    #  project      The project name
    #  longproject  The project title
    #  dumpAnchors  If 1, dump a list of sections, tables, and figures,
    #               with xref IDs, for each document.
    #  debugFlag    If 1, dump additional debugging info
    #  fileroot     Root of the current input file's name
    
    typevariable info -array {
        version     "1.x"
        project     "Mars"
        longproject "Simulation Infrastructure Library"
        dumpAnchors 0
        debugFlag   0
        fileroot    ""
    }

    #-------------------------------------------------------------------
    # Document Data
    #
    # Every location in the document that can be linked to has an
    # xref ID: a single token which can be used in <<xref...>> calls.
    # By convention, section IDs use dot notation.  For example, a
    # toplevel section called "Introduction" might have an ID like
    # "intro". Subsections of this section would have IDs like
    # "intro.this" and "intro.that", and so on.
    #
    # Every section has a level, 0 through 5.  Level 0 sections lack
    # section numbers, and are necessarily toplevel.  Level 1 sections
    # have a section number like "1."; level 2 sections a number like
    # "1.1", and so on.
    #
    # All of the section indexing data is stored in the following
    # variable.  The schema is as follows, where $id is an xref ID.
    #
    # Index                Description
    # -------------------  ---------------------------------------------
    # anchors              A list of valid xref IDs, in the order of
    #                      appearance in the document.
    #
    # topsections          A list of valid xref IDs for toplevel sections.
    # tables               A list of valid xref IDs for tables.
    # figures              A list of valid xref IDs for figures.
    #
    # levels               This is a list of the current section numbers
    #                      at each level.  For example, if we just saw
    #                      section 1.2.3, this will be the list
    #                  
    #                          dummy 1 2 3 0 0 0
    #
    # current-$n           This list contains the xref ID of the current
    #                      section at each section level.  Thus, when
    #                      we've just seen section a.b.c, the array will 
    #                      contain these entries:
    #
    #                         current-1 a
    #                         current-2 a.b
    #                         current-3 a.b.c
    #
    # tablecounter         Number of last table in this major section
    # figurecounter        Number of last figure in this major section
    #
    # imagecounter         Number of last generated image in this document
    #                      Used for creating file names.
    #
    # children-$id         A list of the xref IDs of the children of
    #                      section $id.
    #
    # title-$id            Complete title for anchor $id, e.g.,
    #                      "1.1 References".
    # link-$id             Link text for anchor $id e.g., "Section 1.1"

    typevariable doc

    #-------------------------------------------------------------------
    # Application Initializer

    # init argv
    #
    # argv         Command line arguments
    #
    # This the main program.

    typemethod init {argv} {
        # FIRST, initialize the ehtml processor.
        ehtml init

        # NEXT, import the macros
        ehtml import ::app::*
        
        while {[string match "-*" [lindex $argv 0]]} {
            set opt [lshift argv]
            
            switch -exact -- $opt {
                -version {
                    set info(version) [lshift argv]
                }

                -project {
                    set info(project) [lshift argv]
                }

                -longproject {
                    set info(longproject) [lshift argv]
                }
                
                -manroots {
                    set val [lshift argv]

                    if {[catch {ehtml manroots $val} result]} {
                        puts "Invalid -manroots: \"$val\"\n   $result"
                        exit 1
                    }
                }

                -anchors {
                    set info(dumpAnchors) 1
                }

                -debug {
                    set info(debugFlag) 1
                }

                default {
                    puts stderr "Unknown option: '$opt'."

                    ShowUsage
                    exit 1
                }
            }
        }

        if {[llength $argv] < 1} {
            ShowUsage
            exit 1
        }

        foreach infile $argv {
            ResetForNextDocument

            set info(fileroot) [file rootname $infile]
            set outfile $info(fileroot).html
            
            if {[catch {ehtml expandFile $infile} output]} {
                puts stderr $output

                if {$info(debugFlag)} {
                    puts stderr $::errorInfo
                }
                exit 1
            }
            
            set f [open $outfile w]
            puts $f $output

            if {$info(dumpAnchors)} {
                puts "<!-- List of Anchors"
                puts [DumpAnchors]
                puts "-->"
            }

            close $f
            
            puts "Wrote $outfile"
        }
    }

    # ShowUsage
    #
    # Display command line syntax.

    proc ShowUsage {} {
        puts "Usage: mars_doc \[options\] file.ehtml..."
        puts ""
        puts "Options:"
        puts "    -manroots <roots>   Man page directories; see mars_docs(1)."
        puts "    -version <version>  Version of documented software"
        puts "    -anchors            Appends list of anchors as HTML comment."
        puts ""
        puts "Given file.ehtml, produces file.html in the same directory."
    }

    #-------------------------------------------------------------------
    # Document Management

    # ResetForNextDocument
    #
    # Initialize the documentation indices.

    proc ResetForNextDocument {} {
        set doc(anchors) {}
        set doc(levels) [list dummy 0 0 0 0 0 0]
        set doc(topsections) {}
        set doc(tables) {}
        set doc(figures) {}
    }

    # AddSectionId stype id title
    #
    # stype   type of the section header: preface or numbered.
    # id      xref ID
    # title   section title
    #
    # Use in pass 1 to save section ID.

    proc AddSectionId {stype id title} {
        # FIRST, validate the ID.
        if {[lsearch -exact $doc(anchors) $id] != -1} {
            error "Duplicate section id: '$id'"
        }

        if {![regexp {\w+(\.\w+)*} $id]} {
            error \
                "Invalid section id: '$id', should be '<token>\[.<token>...\]'"
        }

        # NEXT, determine the level.  For preface, it's 0; for 
        # normal sections, it's 1 plus the number of periods.
        set numPeriods [CountPeriods $id]

        if {$stype eq "preface"} {
            if {$numPeriods > 0} {
                error "Invalid preface id: '$id', should be '<token>'"
            }

            set level 0
            set doc(level-$id) $level
            set doc(current-1) $id
            lappend doc(topsections) $id
        } else {
            set level [expr {$numPeriods + 1}]

            set doc(level-$id) $level

            if {$level == 1} {
                set doc(current-1) $id
                lappend doc(topsections) $id
            } else {
                set doc(current-$level) $id
                set plevel [expr {$level - 1}]
                set parent $doc(current-$plevel)

                if {![string match "$parent.*" $id]} {
                    set goodparent [file rootname $id]
                    error \
      "Invalid section ID: '$id'; parent is '$parent', should be '$goodparent'"
                }

                lappend doc(children-$parent) $id
            }
        }

        lappend doc(anchors) $id
        set doc(children-$id) {}

        if {$level == 0 || $level == 1} {
            set doc(tablecounter) 0
            set doc(figurecounter) 0
        }

        if {$level == 0} {
            set doc(title-$id) $title
            set doc(link-$id) $title
            return
        }

        # Increment the section number at this level and 0 the lower levels.
        set max [llength $doc(levels)]

        for {set i $level} {$i < $max} {incr i} {
            if {$i == $level} {
                set secnum [lindex $doc(levels) $i]
                incr secnum
                lset doc(levels) $i $secnum
            } else {
                lset doc(levels) $i 0
            }
        }

        # Next format link and title for the section.
        if {$level == 1} {
            set number "[lindex $doc(levels) 1]"
            set doc(title-$id) "$number. $title"
            set doc(link-$id) "Section $number"
        } else {
            set number "[lindex $doc(levels) 1]"
            for {set i 2} {$i <= $level} {incr i} {
                append number ".[lindex $doc(levels) $i]"
            }
            set doc(title-$id) "$number $title"
            set doc(link-$id) "Section $number"
        }

        # NEXT, save the cross-reference
        ehtml xrefset $id $doc(link-$id) "#$id"
    }

    # CountPeriod id
    #
    # id    An xref ID
    #
    # Counts the number of periods in an xref ID; this determines
    # the level of the section.

    proc CountPeriods {id} {
        set count 0

        foreach c [split $id ""] {
            if {$c eq "."} {
                incr count
            }
        }

        return $count
    }

    # AddTableId id title
    #
    # id      The table's xref ID
    # title   The table's title
    #
    # Use in pass 1 to save the table ID.

    proc AddTableId {id title} {
        if {[lsearch -exact $doc(anchors) $id] != -1} {
            error "Duplicate table id: '$id'"
        }

        if {![regexp {tab\.\w+} $id]} {
            error "Invalid table id: '$id'; should be 'tab.<token>'"
        }

        lappend doc(anchors) $id
        lappend doc(tables) $id


        # Get the section number of the parent toplevel section.
        set secnum [lindex $doc(levels) 1]

        if {$secnum == 0} {
            error "Table appears outside of numbered section: $id"
        }

        # Get the number of this table
        set tabnum [incr doc(tablecounter)]

        set doc(title-$id) "Table $secnum-$tabnum: $title"
        set doc(link-$id) "Table $secnum-$tabnum"

        # NEXT, save the cross-reference
        ehtml xrefset $id $doc(link-$id) "#$id"
    }

    # AddFigureId id title
    # 
    # id      The figure's xref ID
    # title   The figure's title
    #
    # Use in pass 1 to save the figure ID.

    proc AddFigureId {id title} {
        if {[lsearch -exact $doc(anchors) $id] != -1} {
            error "Duplicate figure id: '$id'"
        }

        if {![regexp {fig\.\w+} $id]} {
            error "Invalid figure id: '$id'; should be 'fig.<token>'"
        }

        lappend doc(anchors) $id
        lappend doc(figures) $id

        # Get the section number of the parent toplevel section.
        set secnum [lindex $doc(levels) 1]

        if {$secnum == 0} {
            error "Figure appears outside of numbered section: $id"
        }

        # Get the number of this table
        set fignum [incr doc(figurecounter)]

        set doc(title-$id) "Figure $secnum-$fignum: $title"
        set doc(link-$id) "Figure $secnum-$fignum"

        # NEXT, save the cross-reference
        ehtml xrefset $id $doc(link-$id) "#$id"
    }

    # DumpAnchors
    #
    # Returns a list of sections, tables, and figures, with their 
    # xref IDs, to stdout.  This can be useful while writing
    # document.

    proc DumpAnchors {} {
        # FIRST, determine the maximum anchor length
        set len 0

        foreach id $doc(anchors) {
            set alen [string length $id]

            # Figures and tables are indented by four spaces; allow for it.
            if {[string match "fig.*" $id] ||
                [string match "tab.*" $id]} {
                incr alen 4
            }
            if {$alen > $len} {
                set len $alen
            }
        }

        # NEXT, format the format string.
        set fmt "%-${len}s  %s\n"

        # NEXT, output the list anchors
        set out ""

        foreach id $doc(anchors) {
            # If it's a figure or table, indent by four spaces.
            if {[string match "fig.*" $id] ||
                [string match "tab.*" $id]} {
                set displayId "    $id"
            } else {
                set displayId $id
            }

            append out [format $fmt $displayId $doc(title-$id)]
        }

        return $out
    }
    
    #-------------------------------------------------------------------
    # Section Header Macros

    # preface id title
    #
    # id       Xref ID
    # title    Section title
    #
    # Begins a preface section

    proc preface {id title} {
        return [SectionDef preface $id $title]
    }

    # section id title
    #
    # id       Xref ID
    # title    Section title
    #
    # Begins a numbered section or subsection

    proc section {id title} {
        return [SectionDef numbered $id $title]
    }

    # SectionDef stype id title
    #
    # stype    numbered | preface
    # id       Xref ID
    # title    Section title
    #
    # Formats a section header, and saves the index info.

    template proc SectionDef {stype id title} {
        if {[ehtml pass] == 1} {
            AddSectionId $stype $id $title
            return
        }

        set level $doc(level-$id)
        set title $doc(title-$id)
    } {
        |<--

        <$hn($level)><a name="$id" href="#toc.$id">$title</a></$hn($level)>
    }

    #-------------------------------------------------------------------
    # Tables

    # table id title
    #
    # id       Xref ID
    # title    Section title
    #
    # Begins a titled table

    template proc table {id title} {
        if {[ehtml pass] == 1} {
            AddTableId $id $title
            return
        }
    } {
        |<--
        <center><table border="1" cellpadding="2" cellspacing="0">
        <caption><b><a name="$id" href="#toc.$id">$doc(title-$id)</a><b></caption>
    }

    # /table
    #
    # Ends a titled table

    template proc /table {} {
        |<--
        </table></center><p>
    }

    #-------------------------------------------------------------------
    # Figures

    # figure id title filename
    # 
    # id        Xref ID
    # title     Figure title
    # filename  Image file (e.g., .gif, .png, .jpg)
    #
    # Includes a titled figure in the document.

    template proc figure {id title filename} {
        if {[ehtml pass] == 1} {
            AddFigureId $id $title
            return
        }
    } {
        <p><a name="$id" href="#toc.$id"><center><img src="./$filename"><br/>
        <b>$doc(title-$id)</b></center></a></p>
    }

    # sequence id title ?options? sequence
    #
    # id        Xref ID
    # title     Figure title
    # sequence     sequence(5) sequence diagram text
    #
    # -narration
    #    Include narrative text in the output, following the diagram.

    proc sequence {id title args} {
        # FIRST, get the options
        if {[llength $args] < 1} {
            error "wrong \# args: should be \"sequence id title ?options...? sequence\""
        }

        set sequence [lindex $args end]
        set args [lrange $args 0 end-1]

        set opts(-narration) 0

        while {[llength $args] > 0} {
            set opt [lshift args]
            
            switch -exact -- $opt {
                -narration { set opts(-narration) 1 }
                default    { error "Unknown option: \"$opt\""}
            }
        }

        # NEXT, get the image file name
        set filename "$info(fileroot)_img[incr doc(imagecount)].gif"

        # NEXT, begin to build up the output
        set output [figure $id $title $filename]

        # NEXT, if this is pass 1 there's nothing more to do.
        if {[ehtml pass] == 1} {
            return
        }

        # NEXT, render the sequence to a file
        ::marsutil::sequence renderas $filename $sequence

        # NEXT, output the narration if required.
        if {$opts(-narration)} {
            array set nar [::marsutil::sequence narration]

            if {[info exists nar(diagram)]} {
                append output "$nar(diagram)<p>\n\n"
                unset nar(diagram)
            }

            foreach index [lsort -integer [array names nar]] {
                append output "<b>Step $index</b>: $nar($index)<p>\n\n"
            }
        }

        # NEXT, return the output
        return $output
    }


    #-------------------------------------------------------------------
    # Tables of Contents, Tables, and Figures

    # contents
    #
    # Returns a formatted table of contents, including any tables of 
    # tables and figures.

    template proc contents {} {
        if {[ehtml pass] == 1} {
            return
        }
    } {
        |<--
        <h2>Table of Contents</h2>

        [tforeach id $doc(topsections) {
            |<--
            <p><b><a href="#$id" name="toc.$id">$doc(title-$id)</a></b></p>

            [sectioncontents $id]
        }]

        [tables]
        [figures]
    }

    # sectioncontents id
    #
    # id      A section xref ID
    #
    # Returns a table of contents listing for the subsections of
    # the specified section.

    template proc sectioncontents {id} {
        if {[llength $doc(children-$id)] == 0} {
            return ""
        }
    } {
        |<--
        <ul>
        [tforeach cid $doc(children-$id) {
            <li><a href="#$cid" name="toc.$cid">$doc(title-$cid)</a></li>

            [sectioncontents $cid]
        }]
        </ul>
    }

    # tables
    #
    # Returns a List of Tables

    template proc tables {} {
        if {[ehtml pass] == 1} {
            return
        }

        if {[llength $doc(tables)] == 0} {
            return ""
        }
    } {
        |<--
        <h2>List of Tables</h2>
        <ul>
        [tforeach id $doc(tables) {
            <li><a href="#$id" name="toc.$id">$doc(title-$id)</a></li>
        }]
        </ul>
    }

    # figures
    #
    # Returns a List of Figures

    template proc figures {} {
        if {[ehtml pass] == 1} {
            return
        }

        if {[llength $doc(figures)] == 0} {
            return ""
        }
    } {
        |<--
        <h2>List of Figures</h2>
        <ul>
        [tforeach id $doc(figures) {
            <li><a href="#$id" name="toc.$id">$doc(title-$id)</a></li>
        }]
        </ul>
    }

    #-------------------------------------------------------------------
    # Miscellaneous Macros

    # version
    #
    # Returns the current project version.

    proc version {} {
        return $info(version)
    }

    # project
    #
    # Returns the current project name

    proc project {} {
        return $info(project)
    }

    # longproject
    #
    # Returns the long project name

    proc longproject {} {
        return $info(longproject)
    }

    # banner
    #
    # Returns the current project banner.
    #
    # TBD: Should be settable by the caller

    template proc banner {} {
        |<--
        <h1 style="background: red;">
        &nbsp;[project] [version]: [longproject]
        </h1>
    }

    # standardstyle
    #
    # Returns the standard CSS styles.

    proc standardstyle {} {
        return $css
    }

}
