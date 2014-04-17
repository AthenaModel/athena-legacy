#-----------------------------------------------------------------------
# TITLE:
#    wmscap.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#
#    Parses XML returned from a WMS server resulting from a
#    GetCapabilities call. A nested dictionary is returned with the
#    following structure. If data is not found for a particular tag,
#    the value for that key in the dictionary corresponding to that tag 
#    is the empty string.
#
#    Version -> The version of the WMS 
#    Service => dictionary of service metadata
#            -> Title => string, short description of the service
#            -> Abstract => string, long description of the service
#            -> MaxWidth => integer, the maximum width in pixels
#            -> MaxHeight => integer, the maximum height in pixels
#            -> LayerLimit => integer, the maximum number of requestable layers
#            -> BoundingBox => list of double (lat1, lon1, lat2, lon2) that
#                              sets the bounds of data supported by the WMS
#            -> CRS => The coordinate reference system of the bounding box
#    Layer => dictionary of layer metadata available
#            -> Name => string, the name of the layer to be included in
#               map requests
#            -> Title => string, human readable name of the layer for
#                        display
#    Request => dictionary of capabilities that can be requested
#            -> $request => dictionary of metadata for the capability 
#                           defined
#                        -> Format => list of strings, the formats available 
#                                     for the type of capability
#                        -> Xref => string, base URL of capability
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export wmscap
}

#-----------------------------------------------------------------------
# wscap

snit::type ::projectlib::wmscap {
    #-------------------------------------------------------------------
    # Type Constructor
    typeconstructor {
        namespace import ::marsutil::*
    }

    #-------------------------------------------------------------------
    # Type Variables

    # wmsdata - the Web Map Service data returned
    typevariable wmsdata 

    # wmsversion - the WMS version this parser supports
    typevariable wmsversion "1.3.0"

    # info array
    #
    # root       - The root element of the XML file
    # currkey    - The current dictionary key that we are parsing data for
    # currcap    - The current capability
    # name       - The XML tag name
    # parent     - The parent name of the XML tag
    # stack      - The current stack of tags 
    # path       - The current stack of tags joined with "." between tags.

    typevariable info -array {
        root    {}
        currkey {}
        currcap {}
        name    {}
        parent  {}
        stack   {}
        path    {}
    }

    # qlayerflag  - flag indicating if a layer is queryable, we only care about
    #               those
    typevariable qlayerflag

    # rkeys   - The list of keys that correspond to XML tags that are of
    #           special interest
    typevariable rkeys [list WMS_Capabilities Service Layer Request]

    #-------------------------------------------------------------------
    # Type Methods

    # parse xml
    #
    # xml    - the XML to parse, it must comply with v1.3.0 of the open GIS
    #          WMS capabilities schema

    typemethod parse {xml} {
        # FIRST, initialize the dictionary and the info array
        set wmsdata [dict create]

        foreach val [array names info] {
            set info($val) ""
        }

        dict set wmsdata Version "unknown"

        dict set wmsdata Service [dict create \
                         Title {}             \
                         Abstract {}          \
                         MaxWidth {}          \
                         MaxHeight {}         \
                         LayerLimit {}        \
                         BoundingBox {}       \
                         CRS {}] 

        dict set wmsdata Layer [dict create \
                             Name {}        \
                             Title {}]

        dict set wmsdata Request {}

        # NEXT, initialize the queryable layer flag
        set qlayerflag 0

        # NEXT create the parser and parse the XML, the actual handling
        # of the XML data is done in the callbacks defined here
        set parser [expat -elementstartcommand [mytypemethod HandleStart] \
                          -characterdatacommand [mytypemethod HandleData] \
                          -elementendcommand [mytypemethod HandleEnd]]

        # NEXT, any  errors encountered while parsing will propagate up
        $parser parse $xml

        # NEXT, parsing is done, free it and return the collected data
        $parser free

        return [dict get $wmsdata]
    }

    # parsefile fname
    #
    # fname  - a name of an XML file that complies with v1.3.0 of the open
    #          GIS WMS capabilities schema.
    #
    # This method opens the file provided and stores the XML data as a 
    # string and passes it into the parse method.

    typemethod parsefile {fname} {
        # FIRST, open the file and get the contents
        set f [open $fname "r"]
        set xml [read $f]
        close $f

        # NEXT, parse the data
        return [$type parse $xml]
    }

    #-------------------------------------------------------------------
    # Parser Callbacks

    # HandleStart name atts
    #
    # name   - The name of the start tag
    # atts   - Any attributes that may be part of the start tag
    #
    # This typemethod handles any parsing that must be done due to
    # encountering a start tag that is interesting.

    typemethod HandleStart {name atts} {
        # FIRST, if we are just starting check the root tag
        if {$info(root) eq ""} {
            set info(root) $name
            if {$info(root) ne "WMS_Capabilities"} {
                return -code error -errorcode INVALID \
                    "Not WMS capabilities data."
            }
        }

        # NEXT, push the tag on the stack and set the path, name and parent
        lappend info(stack) $name
        set info(path) [join $info(stack) "."]
        set info(name) $name
        set info(parent) [lindex $info(stack) end-1]

        # NEXT, see if this is a top key in the dictionary
        if {$name in $rkeys} {
            set info(currkey) $name
        }

        # NEXT, operations performed based on the value of the
        # parent
        switch -exact -- $info(parent) {
            Request {
                # The parent is the <Request> tag, this is a capability to
                # add to the dictionary
                set info(currcap) $name
                set d [dict create $info(currcap) \
                    [dict create Format {} Xref {}]]

                set newd [dict merge $d [dict get $wmsdata Request]]
                dict set wmsdata Request $newd
            }

            Get {
                # The parent is the <Get> tag, we may have a base URL for a
                # capability in the tag attributes
                set tags [list $info(currcap) DCPType HTTP]
                if {[$type StackContains {*}$tags]} {
                    set idx [lsearch $atts "xlink:href"]
                    if {$idx > -1} {
                        set url [lindex $atts [expr {$idx+1}]]
                        dict set wmsdata Request $info(currcap) Xref $url
                    }
                }
            }

            default {}
        }

        # NEXT, operations performed based on the value of the current tag
        switch -exact -- $info(name) {
            Layer {
                # The Layer tag indicates a map layer, but only if it is
                # queryable
                set qlayerflag 0
                set idx [lsearch $atts "queryable"]
                if {$idx > -1} {
                    set val [lindex $atts [expr {$idx+1}]]
                    set qlayerflag [snit::boolean validate $val]
                }
            }

            BoundingBox {
                if {[$type StackIs "Capability.Layer.BoundingBox"]} {
                    set minx ""
                    set miny ""
                    set maxx ""
                    set maxy ""

                    set idx [lsearch $atts "CRS"]
                    if {$idx > -1} {
                        set val [lindex $atts [expr {$idx+1}]]
                        dict set wmsdata Service CRS $val
                    } else {
                        return -code error -errorcode INVALID \
                            "Bounding Box with no CRS encountered."
                    }

                    set idx [lsearch $atts "minx"]
                    if {$idx > -1} {
                        set val [lindex $atts [expr {$idx+1}]]
                        set minx $val
                    }

                    set idx [lsearch $atts "miny"]
                    if {$idx > -1} {
                        set val [lindex $atts [expr {$idx+1}]]
                        set miny $val
                    }

                    set idx [lsearch $atts "maxx"]
                    if {$idx > -1} {
                        set val [lindex $atts [expr {$idx+1}]]
                        set maxx $val
                    }

                    set idx [lsearch $atts "maxy"]
                    if {$idx > -1} {
                        set val [lindex $atts [expr {$idx+1}]]
                        set maxy $val
                    }

                    if {$minx eq "" || $miny eq "" ||
                        $maxx eq "" || $maxy eq ""} {
                            return -code error -errorcode INVALID \
                                "Invalid Bounding Box limits encountered."
                    }

                    dict set wmsdata Service BoundingBox \
                        [list $minx $miny $maxx $maxy]
                }

            }

            WMS_Capabilities {
                # Extract version number from the attributes
                set idx [lsearch $atts "version"]
                if {$idx > -1} {
                    set val [lindex $atts [expr {$idx+1}]]
                    if {$val ne $wmsversion} {
                        return -code error -errorcode VERSION \
                            "Version mismatch: $val"
                    }

                    dict set wmsdata Version $val
                }
            }

            default {}
        }
    }

    # HandleData s
    #
    # s  - XML data between a start and end tag
    #
    # This method operates on data found between a start and end tag. The
    # stack is queried to see which tag we are currently parsing and then
    # acts accordingly

    typemethod HandleData {s} {
        # FIRST, extract the tag from the stack and normalize data.
        set tag [lindex $info(stack) end]
        set data [normalize $s]

        switch -exact -- $info(currkey) {
            Service -
            Request - 
            Layer {
                # Parsing is in part of the XML file that contains data for
                # keys we are interested in
                switch -exact -- $tag {
                    Format {
                        # Handle the Format tag
                        $type Handle_$tag $tag $data
                    }

                    default {
                        # Default behavior is to handle data for the current
                        # dictionary key
                        $type Handle_$info(currkey) $tag $data
                    }
                }
            }

            default {}
        }
    }

    # HandleEnd name
    #
    # name  -   the name of the end tag
    #
    # This method handles any processing that must be done based on
    # encountering an end tag

    typemethod HandleEnd {name} {
        # FIRST, pop the tag off the stack and update path
        set info(stack) [lrange $info(stack) 0 end-1]
        set info(path) [join $info(stack) "."]

        # NEXT, processing based on the current dictionary key 
        if {$name eq $info(currkey)} {
            # Set current key to the empty string we are done processing
            # data for this key
            set info(currkey) ""

            # Reset the qlayerflag if the end tag is a Layer
            if {$name eq "Layer"} {
                set qlayerflag 0
            }
        }

        if {$name eq $info(currcap)} {
            set info(currcap) ""
        }
    }

    # Handle_Name tag data
    #
    # tag    - The name of an XML tag
    # data   - The data associated with the tag
    #
    # The name could be the name of a queryable layer. If it is we
    # store the name in the output dictionary being careful to add it
    # to a growing list of layers.

    typemethod Handle_Name {tag data} {
        if {$qlayerflag} {
            set keys [list Layer Name]
            set flist [dict get $wmsdata {*}$keys]
            lappend flist $data
            dict set wmsdata {*}$keys $flist
        }
    }
    
    # Handle_Layer tag data
    # 
    # tag   - The name of an XML tag
    # data  - The data associated with the tag
    #
    # A layer contains both a title and a name. The title is human
    # readable suitable for output. The name is what the WMS expects
    # to get in requests for maps.  There is a one-to-one correspondence
    # between titles and names.
    #
    # The stack must contain the Style tag in order for this to be
    # a layer of interest

    typemethod Handle_Layer {tag data} {
        if {$qlayerflag} {
            set keys [list Layer $tag]
            switch -exact -- $tag {
                Title -
                Name {
                    if {![$type StackContains Style]} {
                        set flist [dict get $wmsdata {*}$keys]
                        lappend flist $data
                        dict set wmsdata {*}$keys $flist
                    }
                }
                default {}
            }
        }
    }

    # Handle_Format tag data
    #
    # tag   - the name of an XML tag
    # data  - the data associated with the tag.
    #
    # If the current key is for a Request then this format is
    # a format supported by the WMS for this request.

    typemethod Handle_Format {tag data} {
        switch -exact -- $info(currkey) {
            Request {
                # If the current key is a Request store the format
                # in the output dictionary
                set keys [list $info(currkey) $info(currcap) $tag]
                set flist [dict get $wmsdata {*}$keys]
                lappend flist $data
                dict set wmsdata {*}$keys $flist
            }

            default {}
        }
    }

    # Handle_Service tag data
    #
    # tag  - the name of an XML tag
    # data - the data associated with the tag
    #
    # This method stores single values in the output dictionary for
    # specific tags corresponding to the WMS itself. The tags are:
    #
    # Title      - the title of the WMS
    # Name       - the name of the WMS
    # Abstract   - a short description of the WMS
    # MaxWidth   - The maximum width in pixels supported by the WMS
    # MaxHeight  - The maximum height in pixels supported by the WMS
    # LayerLimit - The maximum number of map layers supported by the WMS 
    #

    typemethod Handle_Service {tag data} {
        # FIRST, set the keys for storage in the dict
        set keys [list Service $tag]

        switch -exact -- $tag {
            Title -
            Name  -
            Abstract -
            MaxWidth -
            MaxHeight -
            LayerLimit {
                # Store data
                dict set wmsdata {*}$keys $data
            }

            default {}
        }
    }

    #------------------------------------------------------------------
    # Helper Methods 

    # StackIs path
    #
    # path   - a path of tags
    #
    # The method prepends the WMS_Capabilities tag to the supplied path
    # and compares it to the current path of the parser. If the
    # paths match, 1 is returned otherwise 0.
    
    typemethod StackIs {path} {
        set ipath "WMS_Capabilities.$path"
        return [expr {$ipath eq $info(path)}]
    }

    # StackContains args
    #
    # args   - A list of XML tags
    #
    # Given an arbitrary list of XML tags, return 1 if ALL of the tags
    # are in the stack, 0 otherwise

    typemethod StackContains {args} {
        set flag 1

        foreach e $args {
            set flag [expr {$e in $info(stack) & $flag}]
        }
        
        return $flag
    }
}

