#-----------------------------------------------------------------------
# TITLE:
#    wfscap.tcl
#
# AUTHOR:
#    Dave Hanks
#
# DESCRIPTION:
#
#    Parses XML returned from a WFS server resulting from a
#    GetCapabilities call. A nested dictionary is returned with the
#    following structure. If data is not found for a particular tag,
#    the value for that key in the dictionary corresponding to that tag 
#    is the empty string.
#
#    Version -> The version of the WFS 
#    Operation => dictionary of WFS operations available
#              -> $operation => dictionary of metadata for the operation
#                               defined
#                            -> Xref => string, base URL for $operation
#    FeatureType => dictionary of WFS features available
#                -> $feature => dictionary of metadata for the feature
#                               defined
#                            -> Title => string, human readable description
#                            -> SRS => Default spatial reference system 
#                                      for the defined feature
#    Constraints => list of constraint name/value pairs, constraints are
#                   defined by the WFS
#
#-----------------------------------------------------------------------

namespace eval ::projectlib:: {
    namespace export wfscap
}

#-----------------------------------------------------------------------
# wscap

snit::type ::projectlib::wfscap {
    #-------------------------------------------------------------------
    # Type Constructor
    typeconstructor {
        namespace import ::marsutil::*
    }

    #-------------------------------------------------------------------
    # Type Variables

    # wfsdata - the Web Feature Service data returned
    typevariable wfsdata 

    # wfsversion - the WMS version this parser supports
    typevariable wfsversion "1.1.0"

    #-------------------------------------------------------------------
    # Type Methods

    # parse xml
    #
    # xml    - the XML to parse, it must comply with v1.1.0 of the open GIS
    #          WFS capabilities schema
    #
    # This method takes a chunk of XML and creates a DOM tree which is then
    # traversed and the WFS dictionary filled in.

    typemethod parse {xml} {
        # FIRST, default values for the WFS dictionary of data
        dict set wfsdata Version "unknown"
        dict set wfsdata Operation ""
        dict set wfsdata FeatureType ""
        dict set wfsdata Constraints ""

        # NEXT, create the DOM and get the top node
        set doc [dom parse $xml]
        set root [$doc documentElement]
        set topNode [$doc getElementsByTagName WFS_Capabilities]

        # NEXT check to see if this is the right format and version
        if {$topNode eq ""} {
            return -code error -errorcode INVALID \
                "Not WFS Capabilities data."
        }

        set vers [$type getAttribute $topNode "version"]

        if {$vers ne $wfsversion} {
            return -code error -errorcode VERSION \
                "Version mismatch: $vers"
        }

        # NEXT, set version
        dict set wfsdata Version $vers

        # NEXT, parse constraints
        foreach node [$root selectNodes /*] {
            foreach cons [$node getElementsByTagName ows:Constraint] {
                set name [$cons getAttribute name]
                set val [$type getElementText $cons "ows:Value"]
                dict lappend wfsdata Constraints $name $val
            }
        }

        # NEXT, parse available WFS operations
        foreach node [$root selectNodes /*] {
             foreach op [$node getElementsByTagName ows:Operation] {
                 set operation [$op getAttribute name]
                 set urlNode [$type getChildNodeByName $op "ows:Get"]
                 set url [$type getAttribute $urlNode xlink:href]

                 set d [dict create $operation [dict create Xref $url]]
                 set newd [dict merge $d [dict get $wfsdata Operation]]
                 dict set wfsdata Operation $newd
             }
        }
        
        # NEXT, parse available WFS feature types
        foreach node [$root selectNodes /*] {
            foreach feature [$node getElementsByTagName FeatureType] {
                set name [$type getElementText $feature Name]
                set title [$type getElementText $feature Title]
                set srs   [$type getElementText $feature DefaultSRS]

                set d [dict create $name [dict create Title $title SRS $srs]]
                set newd [dict merge $d [dict get $wfsdata FeatureType]]
                dict set wfsdata FeatureType $newd
            }
        }

        # NEXT, delete DOM and return data
        $doc delete

        return $wfsdata
    }

    # parsefile fname
    #
    # fname   - the name of an XML file that complies with v1.1.0 of the
    #           Open GIS Consortium WFS Capabilities schema
    #
    # The method opens the file extracts the XML and then calls the DOM
    # parse method.

    typemethod parsefile {fname} {
        set f [open $fname "r"]

        set xml [read $f]
        close $f

        $type parse $xml
    }

    # getChildNodeByName node tag
    #
    # node   - a DOM node
    # tag    - a tag to search for in the subtree below node
    #
    # This method expects to find one and only one child with the 
    # supplied tag as a name somewhere below node in the DOM if 
    # found, the node is returned otherwise the empty string is
    # returned.  Error if there is more than one child with the
    # supplied tag.

    typemethod getChildNodeByName {node tag} {
        set children [$node getElementsByTagName $tag]

        if {[llength $children] == 0} {
            return ""
        } elseif {[llength $children] > 1} {
            error "Too many $tag elements in [$node nodeName]"
        } 

        set child [lindex $children 0]
        return $child
    }

    # getElementText  node tag
    #
    # node   - a DOM node
    # tag    - a tag to search for in the subtree below node
    #
    # This method expects to find one and only one child with the
    # supplied tag as a name somewhere below node in the DOM. If
    # found, the text enclosed by the start and end tag is returned
    # otherwise the empty string is returned.  Error if there is 
    # more than one child with the supplied tag.

    typemethod getElementText {node tag} {
        set children [$node getElementsByTagName $tag]

        if {[llength $children] == 0} {
            return ""
        } elseif {[llength $children] > 1} {
            error "Too many $tag elements in [$node nodeName]"
        } else {
            set child [lindex $children 0]
            
            return [$child text]
        }
    }

    # getElementsAsList node tag ?caps?
    #
    # node  - a DOM node
    # tag   - a tag to search for in the subtree below node
    # caps  - if 1, return all caps otherwise return text as found
    #         default is 0
    #
    # This method searches the subtree below node for all children
    # with the supplied tag. If found, a list of the text enclosed
    # by the start and end tag is returned otherwise an empty string
    # is returned.

    typemethod getElementsAsList {node tag {caps 0}} {
        set children [$node getElementsByTagName $tag]

        if {[llength $children] == 0} {
            return ""
        } else {
            set clist [list]
            
            foreach child $children {
                if {$caps} {
                    lappend clist [string toupper [$child text]]
                } else {
                    lappend clist [$child text]
                }
            }

            return $clist
        }
    }


    # getAttribute node name
    #
    # node   - a DOM node
    # name   - the name of an attribute in node
    #
    # This method returns the value of an attribute found within
    # the supplied node. If not found, an error is generated.

    typemethod getAttribute {node name} {
        if {[$node hasAttribute $name]} {
            return [$node getAttribute $name]
        } else {
            error "[$node nodeName]: no attribute named $name"
        }
    }
}

