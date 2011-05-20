#-----------------------------------------------------------------------
# TITLE:
#    object.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    helptool(1) Object Type definition
#
#    Implements the object command for help(5) files.  An object is an
#    entity that can have many attributes, each of which requires its
#    own documentation.  In essence, a help(5) object is a way of 
#    collecting related pieces of documentation so that they can be
#    entered once and re-used on multiple pages.
#
#    For example, consider an entity that the user can create using
#    orders, and then browse in the GUI.  Documentation is needed for
#    the entity's attributes, and it must appear in the help pages for
#    both the orders and the browser.
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# object ensemble

snit::type object {
    #-------------------------------------------------------------------
    # Instance Variables

    variable compiler ;# interp for compiling object definition scripts.

    # info: array of compiled data
    #
    # noun         - The object's printed name
    # overview     - The object's overview documentation
    # attrs        - List of the object's attribute IDs
    # label-$attr  - The attribute's label
    # text-$attr   - The attribute's documentation string
    # tags-$attr   - The attribute's tags

    variable info -array {
        noun       ""
        overview   ""
        attrs      {}
    }

    #-------------------------------------------------------------------
    # Constructor

    constructor {script} {
        set compiler [interp create -safe]
        
        $compiler alias noun      $self Compiler_noun
        $compiler alias overview  $self Compiler_overview
        $compiler alias attribute $self Compiler_attribute

        $compiler eval $script

        require {$info(noun) ne ""}     "Missing noun"
        require {$info(overview) ne ""} "Missing overview"
    }

    #-------------------------------------------------------------------
    # Compilation Commands
    #
    # The header comments are for the command as it appears in
    # object definition scripts.


    # noun noun
    #
    # noun - The English noun for this object.
    #
    # Defines the object's noun.

    method Compiler_noun {noun} {
        set info(noun) $noun
    }

    # overview text
    #
    # text - HTML text, with <<macros>>.
    #
    # Defines the overall description of this object type.

    method Compiler_overview {text} {
        set info(overview) $text
    }

    # attribute name label text ?options...?
    #
    # name      - The attribute name, i.e., usually an RDB column name.
    # label     - The human-readable name
    # text      - HTML text, with <<macros>>.
    # options   - As below.
    #
    # Options:
    #    -tags tags      - List of tags, e.g., "create update"
    #
    # Defines the overall description of this object type.

    method Compiler_attribute {name label text args} {
        ladd info(attrs) $name
        set info(label-$name) $label
        set info(text-$name) $text
        set info(tags-$name) [list]

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -tags { 
                    set info(tags-$name) [lshift args] 
                }

                default {
                    error "Unknown option: \"$opt\""
                }
            }
        }
    }

    #-------------------------------------------------------------------
    # Queries

    # noun
    #
    # Return the object's noun.

    method noun {} {
        return $info(noun)
    }

    # overview
    #
    # Return object's overview, expanding any macros.

    method overview {} {
        return [ehtml expand $info(overview)]
    }

    # attr names
    #
    # Return the attribute names in order of definition.

    method {attr names} {} {
        return $info(attrs)
    }

    # attr label name
    #
    # name - An attribute name
    #
    # Return the attribute's label.

    method {attr label} {name} {
        return $info(label-$name)
    }

    # attr text name
    #
    # name - An attribute name
    #
    # Return the attribute's documentation text, expanding any
    # macros.

    method {attr text} {name} {
        return [ehtml expand $info(text-$name)]
    }

    # parms ?options?
    #
    # Options:
    #    -tags tags   - A list of tags; only attributes with at least
    #                   one of the tags are included.
    #    -attrs attrs - A list of the attrs to include; overrides -tags.
    #    -required    - The attributes are marked as Required.
    #    -optional    - The attributes are marked as Optional.
    #
    # Returns <<parm>>...<</parm>> text for the attributes selected
    # by the options, or all attributes by default.

    method parms {args} {
        # FIRST, get the options
        array set data {
            tags {}
            attrs {}
            mode ""
        }

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -tags     { set data(tags)  [lshift args]    }
                -attrs    { set data(attrs) [lshift args]    }
                -required { set data(mode)  "Required"         }
                -optional { set data(mode)  "Optional"         }
                default   { error "Invalid option: \"$opt\"" }
            }
        }

        # NEXT, get the attrs
        if {[llength $data(attrs)] == 0} {
            if {[llength $data(tags)] == 0} {
                set data(attrs) $info(attrs)
            } else {
                # Match tags
                foreach name $info(attrs) {
                    foreach tag $info(tags-$name) {
                        if {$tag in $data(tags)} {
                            lappend data(attrs) $name
                            break
                        }
                    }
                }
            }
        }

        foreach name $data(attrs) {
            append text "<<parm $name [list $info(label-$name)]>>\n"
            if {$data(mode) ne ""} {
                append text "<b>$data(mode).</b>"
            }

            append text $info(text-$name)
            append text "\n<</parm>>\n\n"
        }

        return [ehtml expand $text]
    }

    # parmlist ?options...?
    #
    # The options are as for method parms, above.
    #
    # Returns a <<parmlist>> of all of the object's attributes.

    method parmlist {args} {
        set text [ehtml expand "<<parmlist Attribute Description>>\n"]

        append text [$self parms {*}$args]

        append text [ehtml expand "<</parmlist>>\n\n"]

        return $text
    }

}


