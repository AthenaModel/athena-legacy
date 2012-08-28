#-----------------------------------------------------------------------
# TITLE:
#    appserver.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_cell(n): myserver(i) Server
#
#    This is an object that presents a unified view of the data resources
#    in the application, and consequently abstracts away the details of
#    the RDB.  The intent is to provide a RESTful interface to the 
#    application data to support browsing (and, possibly,
#    editing as well).
#
# URLs:
#
#    Resources are identified by URLs, as in a web server, using the
#    "my://" scheme.  This server is registered as "app", so that it
#    can be queried using "my://app/...".  However, it is also the
#    default server, so "//app" can be omitted.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# server singleton

snit::type appserver {
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    typecomponent server   ;# The myserver(n) instance.

    #-------------------------------------------------------------------
    # Public methods

    delegate typemethod * to server

    # init
    #
    # Creates the myserver, and registers all of the resource types.

    typemethod init {} {
        # FIRST, create the server
        set server [myserver ${type}::server]

        # NEXT, create the buffer for generating HTML.
        htools ${type}::ht \
            -rdb       ::rdb              \
            -footercmd [myproc FooterCmd]


        # NEXT, register the resource types
        appserver register / {/?} \
            text/html [myproc /:html] \
            "Model Overview"
        
        appserver register /page/{p} {page/(\w+)/?} \
            text/html [myproc /page:html]           \
            "Detail page for cell model page {p}."
    }

    #-------------------------------------------------------------------
    # /:    Model overview page
    #
    # No match parameters

    # /:html udict matchArray
    #
    # Formats and displays the overview page.

    proc /:html {udict matchArray} {
        ht page "Model Overview"
        ht title "Model Overview"

        # FIRST, Check the current model.
        lassign [cmscript check] code line errmsg

        # NEXT, handle syntax errors
        if {$code eq "SYNTAX"} {
            ht putln "The cell model has a syntax error at line $line:"
            ht para
            ht putln "<b>$errmsg</b>"
            ht para
            ht putln "The error must be fixed before further analysis"
            ht putln "is possible."
            ht para
            ht /page

            return [ht get]
        }
        
        if {$code eq "SANE"} {
            ht putln "The cell model is sane, and contains the following pages:"
            ht para

            ht table {"Line" "Page" "# of Cells" "Cyclic?"} {
                foreach page [cm pages] {
                    set pcount [llength [cm cells $page]]

                    ht tr {
                        ht td right {
                            set line [cm pageinfo pline $page]
                            ht link gui://editor/$line $line
                        }
                        ht td left { 
                            ht put <b>
                            ht link page/$page $page
                            ht put </b>
                        }
                        ht td right { ht put $pcount }
                        ht td left  {
                            if {[cm pageinfo cyclic $page]} {
                                ht put "Yes"
                            } else {
                                ht put "No"
                            }
                        }
                    }
                }
            }
        } else {
            ht putln "The cell model is insane."
            ht para
        }


        # Referenced but not defined.
        if {[llength [cm cells unknown]] > 0} {
            ht subtitle "Missing Cells"

            ht putln "The following cells are referenced but not defined:"
            ht para

            ht ul {
                foreach cell [cm cells unknown] {
                    set refcount [llength [cm cellinfo usedby $cell]]
                    
                    ht li {
                        ht putln [format "%03d times: <b>%s</b>" $refcount $cell]
                    }
                }
            }
        }

        # Cells with serious errors
        # TBD: add dl/dd/dt to htools


        if {[llength [cm cells invalid]] > 0} {
            ht subtitle "Invalid Cells"

            ht putln "The following cells have serious errors:"
            ht para

            ht putln "<dl>"

            foreach cell [cm cells invalid] {
                ht putln "<dt>"
                ht put "<b>$cell</b> = [normalize [cm formula $cell]]"

                set out [list]

                if {[cm cellinfo error $cell] ne ""} {
                    lappend out "=> [normalize [cm cellinfo error $cell]"
                }

                foreach rcell [cm cellinfo unknown $cell] {
                    lappend out "=> References undefined cell: $rcell"
                }

                foreach rcell [cm cellinfo badpage $cell] {
                    lappend out "=> References cell on later page: $rcell"
                }

                ht putln "<dd>"
                ht put [join $out "<br>\n"]
                ht para
            }

            ht putln "</dl>"
        }

        # FINALLY, complete the page
        ht /page

        return [ht get]
    }

    # OverviewSane:html
    #
    # Outputs an overview of a sane cell model

    proc OverviewSane:html {} {
        ht putln "The model contains the following pages:"
        ht para

    }

    #-------------------------------------------------------------------
    # /page/{p}:    Model page details
    #
    # {p} => $(1)  - The page name

    # /page:html udict matchArray
    #
    # Formats and displays the details for a particular model page.

    proc /page:html {udict matchArray} {
        upvar 1 $matchArray ""

        set page $(1)

        if {$page ni [cm pages]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        ht page "Model Page: $page"
        ht title "Model Page: $page"

        ht putln "<b>$page</b> is a "
        if {[cm pageinfo cyclic $page]} {
            ht put "Cyclic"
        } else {
            ht put "Acyclic"
        }

        set pline [cm pageinfo pline $page]
        ht put " page containing [llength [cm cells $page]] cells."
        ht putln "It is defined starting at line "
        ht link gui://editor/$pline $pline
        ht putln "in the cell model file."
        ht para

        ht table {"Line#" "Cell" "Value" "Formula"} {
            foreach cell [cm cells $page] {
                ht tr valign top {
                    ht td right {
                        set line [cm cellinfo line $cell]
                        ht link gui://editor/$line $line
                    }
                    ht td left { ht put [namespace tail $cell] }
                    ht td left { ht put [cm value $cell] }
                    ht td left {
                        ht put <code>
                        ht put [cm cellinfo formula $cell] 
                        ht put </code>
                    }
                }
            }
        }

        # FINALLY, complete the page
        ht /page

        return [ht get]
    }


    #===================================================================
    # Other Content Routines
    #
    # The following code relates to particular resources or kinds
    # of content.

    # FooterCmd
    #
    # Standard Page Footer

    proc FooterCmd {} {
        ht putln <p>
        ht putln <hr>
        ht putln "<font size=2><i>"
        ht put [format " -- Wall Clock: %s" [clock format [clock seconds]]]

        ht put "</i></font>"
    }


    #-------------------------------------------------------------------
    # Content Handlers
    #
    # The following routines are full-fledged content handlers.  
    # Server modules may register them as content handlers using the
    # [asproc] call.
    
    # enum:enumlist enum udict matchArray
    #
    # enum  - An enum(n), or any command with a "names" subcommand.
    # 
    # Returns the "names" for an enum type (or equivalent).

    proc enum:enumlist {enum udict matchArray} {
        return [{*}$enum names]
    }

    # enum:enumdict enum udict matchArray
    #
    # enum  - An enum(n), or any command with "names" and "longnames"
    #         subcommands.
    # 
    # Returns the names/longnames dictionary for an enum type (or equivalent).

    proc enum:enumdict {enum udict matchArray} {
        foreach short [{*}$enum names] long [{*}$enum longnames] {
            lappend result $short $long
        }

        return $result
    }

    # type:html title command udict matchArray
    # 
    # Returns the HTML documentation for any type command with an
    # "html" subtype, adding a title.

    proc type:html {title command udict matchArray} {
        ht page $title {
            ht title $title
            ht putln [{*}$command html]
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # Handler API
    #
    # These commands are defined for use within URL handlers.

    # asproc command....
    # 
    # command   - A command or command prefix, optionally with arguments
    #
    # Returns the command and its arguments with the command name fully
    # qualified as being defined in this type.  This makes it easy for
    # appserver modules to use handlers defined herein.
    
    proc asproc {args} {
        return [myproc {*}$args]
    }
    
    # objects:linkdict odict
    # 
    # odict - Object type dictionary
    #
    # Returns a tcl/linkdict for a collection resource, based on an RDB 
    # table and other data from the object type dictionary, which must
    # have the following fields:
    #
    # label    - Human-readable label for this kind of object
    # listIcon - A Tk icon to use in lists and trees next to the label
    # table    - The table or view containing the objects
    #
    # The table or view must define columns "url" and "fancy".

    proc objects:linkdict {odict} {
        set result [dict create]

        dict with odict {
            rdb eval "
                SELECT url, fancy
                FROM $table 
                ORDER BY fancy
            " {
                dict set result $url \
                    [dict create label $fancy listIcon $listIcon]
            }
        }

        return $result
    }

    # querydict udict parms
    #
    # udict  - A URL dictionary, as passed to a handler
    # parms  - A list of parameter names
    #
    # Uses urlquery2dict to parse the udict's query, and returns
    # the resulting dictionary.  Only the listed parms will be
    # included; and listed parms which do not appear in the query
    # will have empty values.

    proc querydict {udict parms} {
        # FIRST, parse the query.
        set in [urlquery2dict [dict get $udict query]]

        # NEXT, build the output.
        set out [dict create]

        foreach p $parms {
            if {[dict exists $in $p]} {
                dict set out $p [dict get $in $p]
            } else {
                dict set out $p ""
            }
        }

        return $out
    }
}



