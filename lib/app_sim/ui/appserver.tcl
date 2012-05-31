#-----------------------------------------------------------------------
# TITLE:
#    appserver.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n): myserver(i) Server
#
#    This is an object that presents a unified view of the data resources
#    in the application, and consequently abstracts away the details of
#    the RDB.  The intent is to provide a RESTful interface to the 
#    application data to support browsing (and, possibly,
#    editing as well).
#
#    The content is provided by the appserver_*.tcl modules; this module
#    creates and configures the myserver(n) and provides tools to the
#    other modules.
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
    # Type Variables

    # minfo array: Module Info
    #
    # names  - List of the names of the defined appserver modules.

    typevariable minfo -array {
        names {}
    }

    # Image Cache
    # 
    # Image files loaded from disk are cached as Tk images in the 
    # imageCache array by [appfile:image].  The keys are image file URLs; 
    # the values are pairs, Tk image name and [file mtime].

    typevariable imageCache -array {}

    #-------------------------------------------------------------------
    # Submodule Interface

    # module name defscript
    # 
    # name      - Fully-qualified command name of an appserver module.
    # defscript - snit::type definition body.
    #
    # Defines the module as a snit::type in the appserver:: namespace,
    # and registers it so that it will get initialized at the right time.

    typemethod module {name defscript} {
        # FIRST, define the type.
        set header {
            # Make it a singleton
            pragma -hasinstances no

            # Allow module to use procs from ::appserver::
            typeconstructor {
                namespace path [list [namespace parent $type]]
            }
        }

        set fullname ${type}::${name}
        snit::type $fullname "$header\n$defscript"

        # NEXT, save the metadata
        ladd minfo(names) $fullname
    
        return
    }

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

        # NEXT, register resource types from submodules.
        foreach name [lsort $minfo(names)] {
            $name init
        }


        # NEXT, add test handler
        $type register /test {test/?} \
            text/html [myproc /test:html] { Test URL }
    
        $type register /hello {hello/?} \
            tk/widget [myproc /hello:widget] { Test widget }
    
        $type register /plot/{var} {plot/([[:alnum:].]+)}  \
            tk/widget [myproc /plot:widget] { Test Time Plot }
    }

    # /plot:widget

    proc /plot:widget {udict matchArray} {
        upvar 1 $matchArray ""
        set tsvar $(1)

        if {![view t exists $tsvar]} {
            throw NOTFOUND \
                "Unknown time series variable: [dict get $udict url]"
        }
        set tsvar [view t validate $tsvar]

        list ::timechart %W -varnames $tsvar
    }

    # /hello:widget
    proc /hello:widget {udict matchArray} {
        list ::label %W -text "Hello!" -background red
    }

    # /test:html
    #
    # Test routine; creates an HTML form, with widgets.

    proc /test:html {udict matchArray} {
        ht page "Test Page" {
            ht title "Test Page"

            ht subtitle "Time Series Plot"
            ht putln "<object width=100% height=2in data=\"my://app/plot/sat.peonu.qol\" standby=\"Time Series Plot\"></object>"
            ht para
            ht putln "Some more text."
            ht para
        }

        return [ht get]
    }

    #===================================================================
    # Content Routines
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

        if {[sim state] eq "PREP"} {
            ht put "Scenario is unlocked."
        } else {
            ht put [format "Simulation time: Week %04d, %s." \
                      [simclock now] [simclock asZulu]]
        }

        ht put [format " -- Wall Clock: %s" [clock format [clock seconds]]]

        ht put "</i></font>"
    }


    #-------------------------------------------------------------------
    # Handler API
    #
    # These commands are defined for use within URL handlers.

    # appfile:image path...
    #
    # path  - One or more path components, rooted at the appdir.
    #
    # Retrieves and caches the file, returning a tk/image.

    proc appfile:image {args} {
        # FIRST, get the full file path.
        set fullname [GetAppDirFile {*}$args]

        # NEXT, see if we have it cached.
        if {[info exists imageCache($fullname)]} {
            lassign $imageCache($fullname) img mtime

            # FIRST, If the file exists and is unchanged, 
            # return the cached value.
            if {![catch {file mtime $fullname} newMtime] &&
                $newMtime == $mtime
            } {
                return $img
            }
            
            # NEXT, Otherwise, clear the cache.
            unset imageCache($fullname)
        }


        if {[catch {
            set mtime [file mtime $fullname]
            set img   [image create photo -file $fullname]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "Image file could not be found: $(1)"
        }

        set imageCache($fullname) [list $img $mtime]

        return $img
    }

    # appfile:text path...
    #
    # path  - One or more path components, rooted at the appdir.
    #
    # Retrieves the content of the file, or throws NOTFOUND.

    proc appfile:text {args} {
        set fullname [GetAppDirFile {*}$args]

        if {[catch {
            set content [readfile $fullname]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "Page could not be found: $(1)"
        }

        return $content
    }


    # GetAppDirFile path...
    #
    # path  - One or more path components, rooted at the appdir.
    #
    # Gets the full, normalized file name, and verifies that it's
    # within the appdir.  If it is, returns the name; if not, it
    # throws NOTFOUND.

    proc GetAppDirFile {args} {
        set fullname [file normalize [appdir join {*}$args]]

        if {[string first [appdir join] $fullname] != 0} {
            return -code error -errorcode NOTFOUND \
                "Page could not be found: $file"
        }

        return $fullname
    }
    
    # locked ?-disclaimer?
    #
    # -disclaimer  - Put a disclaimer, if option is given
    #
    # Returns whether or not the simulation is locked; optionally,
    # adds a disclaimer to the output.

    proc locked {{option ""}} {
        if {[sim state] ne "PREP"} {
            return 1
        } else {
            if {$option ne ""} {
                ht putln ""
                ht tinyi {
                    More information will be available once the scenario has
                    been locked.
                }
                ht para
            }

            return 0
        }
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

    # restrict dict key vtype defval
    #
    # dict    A dictionary
    # key     A dictionary key 
    # vtype   A validation type
    # defval  A default value
    #
    # Restricts a parameter value to belong to the validation type.
    #
    # If the dict contains the key, and the key's value is not empty,
    # and the key's value is valid, returns the canonicalized 
    # value.  Otherwise, returns the default value.

    proc restrict {dict key vtype defval} {
        if {[dict exists $dict $key]} {
            set value [dict get $dict $key]

            if {$value ne "" &&
                ![catch {{*}$vtype validate $value} result]
            } {
                # Allow the validation type to canonicalize the
                # result.
                return $result
            }
        }

        return $defval
    }

    # sigevents ?options...?
    #
    # Options:
    #
    # -tags  - A list of sigevents tags
    # -mark  - A sigevent mark type
    # -desc  - List in descending order.
    #
    # Formats the sigevents as HTML, in order of occurrence.  If
    # If -tags is given, then only events with those tags are included.
    # If -mark is given, then only events since the most recent mark of
    # the given type are included.  If -desc is given, sigevents are
    # shown in reverse order.

    proc sigevents {args} {
        # FIRST, process the options.
        array set opts {
            -tags  ""
            -mark  "lock"
            -desc  0
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -tags -
                -mark {
                    set opts($opt) [lshift args]
                }

                -desc {
                    set opts($opt) 1
                }

                default {
                    error "Unknown sigevents option: \"$opt\""
                }
            }
        }

        # NEXT, get the earliest event ID to consider
        set mark [sigevent lastmark $opts(-mark)]

        ht push

        if {$opts(-tags) eq ""} {
            set query {
                SELECT level, t, zulu, component, narrative
                FROM gui_sigevents
                WHERE event_id >= $mark
            }
        } elseif {[llength $opts(-tags)] == 0} {
            set tag [lindex $opts(-tags) 0]

            set query {
                SELECT level, t, zulu, component, narrative
                FROM gui_sigevents_wtag
                WHERE event_id >= $mark
                AND tag = $tag
            }
        } else {
            set tags "('[join $opts(-tags) ',']')"

            set query "
                SELECT DISTINCT level, t, zulu, component, narrative
                FROM gui_sigevents_wtag
                WHERE event_id >= \$mark
                AND tag IN $tags
            "
        }

        if {$opts(-desc)} {
            append query "ORDER BY t DESC, event_id"
        } else {
            append query "ORDER BY event_id"
        }

        rdb eval $query {
            ht tr {
                ht td right {
                    ht put $t
                }

                ht td left {
                    ht put $zulu
                }

                ht td left {
                    ht put $component
                }

                if {$level == -1} {
                    ht putln "<td bgcolor=orange>"
                } elseif {$level == 0} {
                    ht putln "<td bgcolor=yellow>"
                } elseif {$level == 1} {
                    ht putln "<td>"
                } else {
                    ht putln "<td bgcolor=lightgray>"
                }

                ht put $narrative

                ht put "</td>"
            }
        }
        

        set text [ht pop]

        if {$text ne ""} {
            ht table {"Week" "Zulu Time" "Model" "Narrative"} {
                ht putln $text
            }
        } else {
            ht putln "No significant events occurred."
        }
            
        ht para
    }
}



