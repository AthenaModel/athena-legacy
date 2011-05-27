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
        $compiler alias include   $self Compiler_include
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

    # include object ?options...?
    #
    # object  - An object name
    # options - One or more options/values
    #
    #    -attrs names - Attribute names to include.
    #    -tags tags   - Tags to apply to the object's attributes.
    #
    # Includes the attributes of the named object into this object.

    method Compiler_include {object args} {
        set opts(-attrs) [::objects::$object attr names]
        set opts(-tags)  [list]

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -attrs -
                -tags  { 
                    set opts($opt) [lshift args]
                }
                default "Unknown option: \"$opt\""
            }
        }

        foreach attr $opts(-attrs) {
            lassign [::objects::$object attr data $attr] label text
            $self Compiler_attribute $attr $label $text -tags $opts(-tags)
        }
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

    # attr data name
    #
    # name - An attribute name
    #
    # Returns the raw attribute data for the named attributes as a
    # list: label text

    method {attr data} {name} {
        return [list $info(label-$name) $info(text-$name)]
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
    #    -display     - The attributes are marked as Display Only.
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
                -required { set data(mode)  "Required"       }
                -optional { set data(mode)  "Optional"       }
                -display  { set data(mode)  "Display Only"   }
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

            if {$data(mode) eq "Display Only"} {
                append text {
                    This parameter is displayed to provide
                    context to the user; it is not an input.
                }
            }
            append text "\n<</parm>>\n\n"
        }

        return [ehtml expand $text]
    }

    # parm attr ?options?
    #
    # Options:
    #    -label       - Alternative label text.
    #    -required    - The attribute is marked as Required.
    #    -optional    - The attribute is marked as Optional.
    #    -display     - The attribute is marked as Display Only.
    #
    # Returns expanded <<parm>>...<</parm>> text for the attribute.

    method parm {attr args} {
        # FIRST, get the options
        set data(label) $info(label-$attr)
        set data(mode)  ""

        while {[llength $args] > 0} {
            set opt [lshift args]

            switch -exact -- $opt {
                -label    { set data(label) [lshift args]    }
                -required { set data(mode)  "Required"       }
                -optional { set data(mode)  "Optional"       }
                -display  { set data(mode)  "Display Only"   }
                default   { error "Invalid option: \"$opt\"" }
            }
        }

        set text "<<parm $attr [list $data(label)]>>\n"

        if {$data(mode) ne ""} {
                append text "<b>$data(mode).</b>"
        }

        append text $info(text-$attr)
        append text "\n<</parm>>\n\n"

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


