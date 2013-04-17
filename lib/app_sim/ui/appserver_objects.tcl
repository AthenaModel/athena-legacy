#-----------------------------------------------------------------------
# TITLE:
#    appserver_objects.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    app_sim(n), appserver(sim) module: Object Types
#
#    my://app/objects/...
#
#    The purpose of these URLs is to provide the top-level set of links
#    to navigate the tree of simulation objects in Athena (e.g., to 
#    populate the tree widgets in the detail browser).  At the
#    top-level are the object types, and subsets of these types.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# appserver module

appserver module OBJECTS {
    #-------------------------------------------------------------------
    # Type Variables

    # objectInfo: Nested dictionary of object data.
    #
    # key: object collection resource
    #
    # value: Dictionary of data about each object/object type
    #
    #   label     - A human readable label for this kind of object.
    #   listIcon  - A Tk icon to use in lists and trees next to the
    #               label

    typevariable objectInfo {
        /actors {
            label    "Actors"
            listIcon ::projectgui::icon::actor12
            table    gui_actors
            key      a
        }

        /caps   {
            label    "CAPs"
            listIcon ::projectgui::icon::cap12
            table    gui_caps
            key      k
        }

        /econ   {
            label    "Econ"
            listIcon ::projectgui::icon::dollar12
        }

        /ioms   {
            label    "IOMs"
            listIcon ::projectgui::icon::message12
            table    gui_ioms
            key      iom_id
        }

        /hooks {
            label    "Semantic Hooks"
            listIcon ::projectgui::icon::hook12
            table    gui_hooks
            key      hook_id
        }

        /groups {
            label    "Groups"
            listIcon ::projectgui::icon::group12
            table    gui_groups
            key      g
        }

        /groups/civ {
            label    "Civ. Groups"
            listIcon ::projectgui::icon::civgroup12
            table    gui_civgroups
            key      g
        }

        /groups/frc {
            label    "Force Groups"
            listIcon ::projectgui::icon::frcgroup12
            table    gui_frcgroups
            key      g
        }

        /groups/org {
            label    "Org. Groups"
            listIcon ::projectgui::icon::orggroup12
            table    gui_orggroups
            key      g
        }

        /nbhoods {
            label    "Neighborhoods"
            listIcon ::projectgui::icon::nbhood12
            table    gui_nbhoods
            key      n
        }

        /overview {
            label "Overview"
            listIcon ::projectgui::icon::eye12
        }

        /parmdb {
            label "Model Parameters"
            listIcon ::marsgui::icon::pencil12
        }

        /mads {
            label    "Magic Attitude Drivers"
            listIcon ::projectgui::icon::blueheart12
        }

        /drivers {
            label    "Drivers"
            listIcon ::projectgui::icon::blackheart12
        }

        /contribs {
            label    "Contributions"
            listIcon ::projectgui::icon::heart12
        }
    }

    #-------------------------------------------------------------------
    # Public methods

    # init
    #
    # Initializes the appserver module.

    typemethod init {} {
        # FIRST, register the resource types
        appserver register /objects {objects/?}           \
            tcl/linkdict [myproc /objects:linkdict]       \
            text/html    [myproc /objects:html "Objects"] \
            "Links to the main Athena simulation objects."

        appserver register /objects/bsystem {objects/(bsystem)/?}       \
            tcl/linkdict [myproc /objects:linkdict]                     \
            text/html    [myproc /objects:html "Belief System Objects"] {
                Links to the Athena objects for which belief 
                systems are defined.
            }

    }

    #-------------------------------------------------------------------
    # /objects                 - All object types
    # /objects/bsystem         - Belief system entities
    #
    # Match Parameters:
    # 
    # {subset} ==> $(1)   - bsystem or ""

    # /objects:linkdict udict matchArray
    #
    # Returns an objects[/*] resource as a tcl/linkdict 
    # where $(1) is the objects subset.

    proc /objects:linkdict {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, handle subsets
        switch -exact -- $(1) {
            "" { 
                set subset {
                    /overview
                    /actors 
                    /nbhoods 
                    /groups/civ 
                    /groups/frc 
                    /groups/org
                    /mads
                    /drivers
                    /contribs
                    /econ
                    /caps
                    /hooks
                    /ioms
                    /parmdb
                }
            }

            bsystem { 
                set subset {/actors /groups/civ}    
            }

            default { 
                # At present, the resource patterns should prevent
                # this case from occurring; otherwise we'd need to
                # throw NOTFOUND
                error "Unknown resource: \"$udict\"" 
            }
        }

        foreach otype $subset {
            dict with objectInfo $otype {
                dict set result $otype label $label
                dict set result $otype listIcon $listIcon
            }
        }

        return $result
    }

    # /objects:html title udict matchArray
    #
    # title      - The page title
    #
    # Returns an object/* resource as a text/html
    # where $(1) is the objects subset.

    proc /objects:html {title udict matchArray} {
        upvar 1 $matchArray ""

        set url [dict get $udict url]

        set types [/objects:linkdict $url ""]

        ht page $title
        ht h1 $title
        ht ul {
            foreach link [dict keys $types] {
                ht li { ht link $link [dict get $types $link label] }
            }
        }
        ht /page

        return [ht get]
    }
}



