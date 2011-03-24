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
#    At present, it is all application-layer code; ultimately,
#    the main logic and some of the content handlers will be abstracted
#    out into an infrastructure module.
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
    # URL Schema
    #
    # For each resource type, we save the following data:
    #
    # pattern - A regexp that recognizes the resource.  It is matched
    #           against the "path" component, and so does not begin
    #           with a "/".
    # ctypes  - A dictionary of content types and handlers.  The
    #           first content type is the preferred type used when no
    #           type is requested.  The handler is a command that takes
    #           two additional arguments, the URL given to the server,
    #           and an array to received pattern matches from the
    #           regexp into values "1", "2", and "3".
    # doc     - A documentation string for the resource type.  Note
    #           that "{" and "}" in resource types and doc strings
    #           are converted to "<i>" and "</i>" when displayed as
    #           HTML.

    typevariable rinfo {
        /actor {
            doc     {Links to the currently defined actors.}
            pattern {^actor/?$}
            ctypes  {
                tcl/linkdict {DictLinks actors a ::projectgui::icon::actor12}
                text/html  {HtmlLinks "Actors" actors a}
            }
        }

        /actor/{a} {
            doc     {Detail page for actor {a}.}
            pattern {^actor/(\w+)/?$}
            ctypes  {
                text/html {HtmlActor}
            }
        }

        /civgroup {
            doc     {Links to the currently defined civilian groups.}
            pattern {^civgroup/?$}
            ctypes  {
                tcl/linkdict {DictLinks civgroups g ::projectgui::icon::civgroup12}
                text/html  {HtmlLinks "Civ. Groups" civgroups g}
            }
        }

        /civgroup/{g} {
            doc     {Detail page for civilian group {g}.}
            pattern {^civgroup/(\w+)/?$}
            ctypes  {
                text/html {HtmlEntity "Civ. Group" civgroups g}
            }
        }

        /docs/{path}.html {
            doc     {An HTML file in the Athena docs/ tree.}
            pattern {^(docs/[^.]+\.html)$}
            ctypes  {
                text/html {HtmlFile ""}
            }
        }

        /docs/{imageFile} {
            doc     {
                A .gif, .jpg, or .png file in the Athena /docs/ tree.
            }
            pattern {^(docs/.+\.(gif|jpg|png))$}
            ctypes  {
                tk/image {ImageFile ""}
            }
        }

        /entitytype {
            doc     {Links to the main Athena entity types.}
            pattern {^entitytype/?$}
            ctypes  {
                tcl/linkdict {DictEntityTypes}
                text/html  {HtmlEntityTypes "Entity Types"}
            }
        }

        /entitytype/bsystem {
            doc     {
                Links to the Athena entity types for which belief
                systems are defined.
            }
            pattern {^entitytype/(bsystem)/?$}
            ctypes  {
                tcl/linkdict {DictEntityTypes}
                text/html  {HtmlEntityTypes "Belief System Entity Types"}
            }
        }

        /frcgroup {
            doc     {Links to the currently defined force groups.}
            pattern {^frcgroup/?$}
            ctypes  {
                tcl/linkdict {DictLinks frcgroups g ::projectgui::icon::frcgroup12}
                text/html  {HtmlLinks "Force Groups" frcgroups g}
            }
        }

        /frcgroup/{g} {
            doc     {Detail page for force group {g}.}
            pattern {^frcgroup/(\w+)/?$}
            ctypes  {
                text/html {HtmlEntity "Force Group" frcgroups g}
            }
        }

        /group {
            doc     {Links to the currently defined groups of all types.}
            pattern {^group/?$}
            ctypes  {
                tcl/linkdict {DictLinks groups g ::projectgui::icon::group12}
                text/html  {HtmlLinks "Groups" groups g}
            }
        }

        /group/{g} {
            doc     {Detail page for group {g}.}
            pattern {^group/(\w+)/?$}
            ctypes  {
                text/html {HtmlEntity "Group" groups g}
            }
        }

        /image/{name} {
            doc     {Any Tk image, by its {name}.}
            pattern {^image/(.+)$}
            ctypes  {
                tk/image {TkImage}
            }
        }

        /lib/{file}.html {
            doc     {An HTML file in the Athena library.}
            pattern {^lib/([^./]+\.html)$}
            ctypes  {
                text/html {HtmlFile lib/app_sim}
            }
        }

        /lib/{imageFile} {
            doc     {
                A .gif, .jpg, or .png file in the Athena library.
            }
            pattern {^lib/(.+\.(gif|jpg|png))$}
            ctypes  {
                tk/image {ImageFile lib/app_sim}
            }
        }


        /mars/docs/path.html {
            doc     {An HTML file in the Athena mars/docs/ tree.}
            pattern {^(mars/docs/.+\.html)$}
            ctypes  {
                text/html {HtmlFile ""}
            }
        }

        /mars/docs/{imageFile} {
            doc     {
                A .gif, .jpg, or .png file in the Athena mars/docs/ tree.
            }
            pattern {^(mars/docs/.+\.(gif|jpg|png))$}
            ctypes  {
                tk/image {ImageFile ""}
            }
        }

        /nbhood {
            doc     {Links to the currently defined neighborhoods.}
            pattern {^nbhood/?$}
            ctypes  {
                tcl/linkdict {DictLinks nbhoods n ::projectgui::icon::nbhood12}
                text/html  {HtmlLinks "Neighborhoods" nbhoods n}
            }
        }

        /nbhood/{n} {
            doc     {Detail page for neighborhood {n}.}
            pattern {^nbhood/(\w+)/?$}
            ctypes  {
                text/html {HtmlEntity "Neighborhood" nbhoods n}
            }
        }

        /orggroup {
            doc     {Links to the currently defined organization groups.}
            pattern {^orggroup/?$}
            ctypes  {
                tcl/linkdict {DictLinks orggroups g ::projectgui::icon::orggroup12}
                text/html  {HtmlLinks "Org. Groups" orggroups g}
            }
        }

        /orggroup/{g} {
            doc     {Detail page for organization group {g}.}
            pattern {^orggroup/(\w+)/?$}
            ctypes  {
                text/html {HtmlEntity "Org. Group" orggroups g}
            }
        }

        /urlhelp {
            doc     {Complete URL schema for this server.}
            pattern {^urlhelp/?$}
            ctypes  {
                text/html {HtmlUrlHelp}
            }
        }

        /urlhelp/{url} {
            doc     {Help for URL {url}.}
            pattern {^urlhelp/(.+)$}
            ctypes  {
                text/html {HtmlUrlHelp}
            }
        }
    }

    #-------------------------------------------------------------------
    # Type Variables

    # Resource Type Cache
    #
    # Looking up a URL requires matching it against a variety of 
    # resource types.  In general, the resource type matched by 
    # a URL will never change; and many we'll look up over and over
    # again.  So cache the results of the lookup in an array.
    #
    # This might be an unnecessary optimization (I dunno) but it will
    # make me feel better.
    #
    # The key is a URL; the value is a pair, resourceType/matchDict

    typevariable rtypeCache -array {}

    # Image Cache
    # 
    # Image files loaded from disk are cached as Tk images in the 
    # imageCache array.  The keys are image file URLs; the 
    # values are pairs, Tk image name and [file mtime].

    typevariable imageCache -array {}

    #-------------------------------------------------------------------
    # get

    # get url ?contentTypes?
    #
    # url         - The URL of the resource to get.
    # contentType - The list of accepted content types.  Wildcards are
    #               allowed, e.g., text/*, */*
    #
    # Retrieves the given resource, or throws an error.  If the 
    # contentTypes list is omitted, returns the resource's 
    # preferred content type (usually text/html); otherwise it returns
    # the first content type in contentTypes that matches an available
    # content type.  If there is none, throws NOTFOUND.
    #
    # Returns a dictionary:
    #
    #    url          - The URL
    #    contentType  - The returned content type
    #    content      - The returned content
    #
    # If the requested resource is not found, throws NOTFOUND.

    typemethod get {url {contentTypes ""}} {
        # FIRST, parse the URL.  We will ignore the scheme and host.
        array set u [uri::split $url]

        # NEXT, determine the resource type
        set rtype [GetResourceType $u(path) match]

        # NEXT, strip any trailing "/" from the URL
        set url [string trimright $url "/"]

        # NEXT, get the content
        set contentType ""

        dict with rinfo $rtype {
            if {[llength $contentTypes] == 0} {
                set contentType [lindex [dict keys $ctypes] 0]
                set handler [dict get $ctypes $contentType]
            } else {
                foreach cpat $contentTypes {
                    dict for {ctype handler} $ctypes {
                        if {[string match $cpat $ctype]} {
                            set contentType $ctype
                            break
                        }
                    }
                }
            }
        }

        if {$contentType eq ""} {
            return -code error -errorcode NOTFOUND \
                "No acceptable content-type available: $contentTypes"
        }

        return [dict create \
                    url         $url                     \
                    content     [{*}$handler $url match] \
                    contentType $contentType]
    }

    # GetResourceType url matchArray
    #
    # url         - A resource URL
    # matchArray  - An array of matches from the pattern.  Up to 3
    #               substrings can be matched.
    #
    # Returns the resource type key from $rinfo, or throws NOTFOUND.

    proc GetResourceType {url matchArray} {
        upvar $matchArray match

        # FIRST, is it cached?
        if {[info exists rtypeCache($url)]} {
            lassign $rtypeCache($url) rtype matchDict
            array set match $matchDict
            return $rtype
        }

        # NEXT, look it up and cache it.
        dict for {rtype rdict} $rinfo {
            # FIRST, does it match?
            set pattern [dict get $rdict pattern]

            if {[regexp $pattern $url dummy match(1) match(2) match(3)]} {
                set rtypeCache($url) [list $rtype [array get match]]

                return $rtype
            }
        }

        return -code error -errorcode NOTFOUND \
            "Resource not found or not compatible with this application."
    }


    
    #-------------------------------------------------------------------
    # Content Routines

    # DictEntityTypes url matchArray
    #
    # url        - The URL of the entitytype resource
    # matchArray - Array of pattern matches
    #
    # Returns an entitytype[/*] resource as a tcl/linkdict 
    # where $(1) is the entity type subset.

    proc DictEntityTypes {url matchArray} {
        upvar 1 $matchArray ""

        set result {
            /actor {
                label    "Actors"
                listIcon ::projectgui::icon::folder12
            }

            /nbhood {
                label    "Neighborhoods"
                listIcon ::projectgui::icon::folder12
            }

            /civgroup {
                label    "Civ. Groups"
                listIcon ::projectgui::icon::folder12
            }

            /frcgroup {
                label    "Force Groups"
                listIcon ::projectgui::icon::folder12
            }

            /orggroup {
                label    "Org. Groups"
                listIcon ::projectgui::icon::folder12
            }
        }

        if {$(1) eq "bsystem"} {
            dict set bsystem /actor    [dict get $result /actor]
            dict set bsystem /civgroup [dict get $result /civgroup]

            return $bsystem
        }

        return $result
    }
    
    # HtmlEntityTypes url matchArray
    #
    # title      - The page title
    # url        - The URL of the entitytype resource
    # matchArray - Array of pattern matches
    #
    # Returns an entitytype/* resource as a tcl/linkdict 
    # where $(1) is the entity type subset.

    proc HtmlEntityTypes {title url matchArray} {
        upvar 1 $matchArray ""

        set types [DictEntityTypes $url ""]

        return [Page $title [tsubst {
            |<--
            <h1>$title</h1>

            <ul>
            [tforeach link [dict keys $types] {
                |<--
                <li> <a href="$link">[dict get $types $link label]</a> </li>
            }]
            </ul>
        }]]
    }


    # DictLinks table key url matchArray
    #
    # table      - The RDB table
    # key        - The key column in the RDB table
    # listIcon   - The list icon
    # url        - The URL of the collection resource
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns tcl/linkdict for a collection resource, based on an RDB 
    # table.

    proc DictLinks {table key listIcon url matchArray} {
        set result [dict create]

        rdb eval "SELECT $key AS id FROM $table ORDER BY $key" {
            dict set result "$url/$id" \
                [dict create label $id listIcon $listIcon]
        }

        return $result
    }


    # HtmlLinks title table key url matchArray
    #
    # title      - A title string for the list of links
    # table      - The RDB table
    # key        - The key column in the RDB table
    # url        - The URL of the collection resource
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns a text/html of links for a collection resource, based on 
    # an RDB table.

    proc HtmlLinks {title table key url matchArray} {
        set ids [rdb eval "SELECT $key AS id FROM $table ORDER BY $key"]

        return [Page $title [tsubst {
            |<--
            <h1>$title</h1>

            <ul>
            [tforeach id $ids {
                |<--
                <li> <a href="$url/$id">$id</a> </li>
            }]
            </ul>
        }]]
    }

    # HtmlEntity title url matchArray
    #
    # title      - A title string for the kind of entity
    # table      - The RDB table
    # key        - The key column in the RDB table
    # url        - The URL of the entity
    # matchArray - Array of pattern matches
    #
    # Returns a stub text/html page for an entity.  Used as a stopgap
    # when no detailed content exists.

    proc HtmlEntity {title table key url matchArray} {
        upvar $matchArray ""

        set id $(1)

        if {![rdb exists "SELECT * FROM $table WHERE $key = \$id"]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: $url."
        }


        return [Page "$title: $(1)" [tsubst {
            |<--
            <h1>$title: $(1)</h1>

            No additional information has been provided for this entity.<p>
        }]]
    }

    # TkImage url matchArray
    #
    # url        - The URL that was requested
    # matchArray - Array of matches from the URL
    #
    # Validates $(1) as a Tk image, and returns it as the tk/image
    # content.

    proc TkImage {url matchArray} {
        upvar $matchArray ""

        if {[catch {image type $(1)} result]} {
            return -code error -errorcode NOTFOUND \
                "Image not found: $url"
        }

        return $(1)
    }


    #-------------------------------------------------------------------
    # Actor-specific handlers

    # HtmlActor url matchArray
    #
    # url        - The URL that was requested
    # matchArray - Array of matches from the URL

    proc HtmlActor {url matchArray} {
        upvar $matchArray ""

        # Accumulate data
        set a $(1)

        if {![rdb exists {SELECT * FROM actors WHERE a=$a}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: $url."
        }

        # Build the page
        set out "<h1>Actor: $a</h1>\n\n"

        append out "<h2>Personnel Assets</h2>\n\n"

        set body ""
        rdb eval {
            SELECT P.n         AS n, 
                   P.g         AS g,
                   P.personnel AS personnel, 
                   G.gtype     AS gtype, 
                   G.longname  AS longname, 
                   AG.subtype  AS subtype
            FROM personnel_ng AS P
            JOIN groups       AS G  USING (g)
            JOIN gui_agroups  AS AG USING (g)
            WHERE AG.a=$a
            AND   personnel > 0
        } {
            append body [tsubst {
                |<--
                <tr valign=top>
                <td>[Link /nbhood/$n $n]</td>
                <td align=right>$personnel</td>
                <td>[Link /group/$g "$g: $longname"]</td>
                <td>$gtype/$subtype</td>
                </tr>
            }]
        }

        if {$body eq ""} {
            append out "None.\n\n"
        } else {
            append out [tsubst {
                |<--
                [Table {Nbhood Personnel Group Type}]

                $body

                </table>
            }]
        }

        return [Page "Actor: $a" $out]
    }

    # HtmlFile base url matchArray
    #
    # base       - A directory within the appdir tree, or ""
    # url        - The URL of the entity
    # matchArray - Array of pattern matches
    #
    #     (1) - *.html
    #
    # Retrieves the file.

    proc HtmlFile {base url matchArray} {
        upvar 1 $matchArray ""

        set fullname [appdir join $base $(1)]

        if {[catch {
            set content [readfile $fullname]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "Documentation page could not be found: $(1)"
        }

        return $content
    }

    # ImageFile base url matchArray
    #
    # base       - A directory within the appdir tree, or ""
    # url        - The URL of the entity
    # matchArray - Array of pattern matches
    #
    #     (1) - image file name, relative to appdir.
    #
    # Retrieves and caches the file, returning a tk/image.

    proc ImageFile {base url matchArray} {
        upvar 1 $matchArray ""

        set fullname [appdir join $base $(1)]

        # FIRST, see if we have it cached.
        if {[info exists imageCache($url)]} {
            lassign $imageCache($url) img mtime

            # FIRST, If the file exists and is unchanged, 
            # return the cached value.
            if {![catch {file mtime $fullname} newMtime] &&
                $newMtime == $mtime
            } {
                return $img
            }
            
            # NEXT, Otherwise, clear the cache.
            unset imageCache($url)
        }


        if {[catch {
            set mtime [file mtime $(1)]
            set img   [image create photo -file $(1)]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "Image file could not be found: $(1)"
        }

        set imageCache($url) [list $img $mtime]

        return $img
    }

    # HtmlUrlHelp url matchArray
    #
    # url        - The /urlhelp URL
    # matchArray - Array of pattern matches
    # 
    # Produces an HTML page detailing one or all of the URLs
    # understood by this server.  Match parm (1) is either empty
    # or a URL for which help is requested.

    proc HtmlUrlHelp {url matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the list of rtypes to document.
        if {$(1) eq ""} {
            set rtypes [dict keys $rinfo]
            set title "URL Schema Help"
        } else {
            set rtypes [list [GetResourceType $(1) dummy]]
            set title "URL Schema Help: /$(1)"
        }

        # NEXT, format the output.
        set trans [list \{ <i> \} </i>]

        set body [tsubst {
            |<--
            <h1>$title</h1>

            <dl>
            [tforeach rtype $rtypes {
                set doc [string map $trans [dict get $rinfo $rtype doc]]
                set ctypes [dict keys [dict get $rinfo $rtype ctypes]]
                set rtype [string map $trans $rtype]
            } {
                |<--
                <dt><b>$rtype</b></td> 
                <dd>$doc ([join $ctypes ", "])<p></dd>
            }]
            </dl>
        }]

        return [Page $title $body]
        
    }


    #-------------------------------------------------------------------
    # HTML Convenience routines

    # Page title body
    #
    # title - Title of HTML page
    # body  - Body text
    #
    # Wraps the body text with the relevant HTML boilerplate.

    proc Page {title body} {
        return \
        "<html><head><title>$title</title></head>\n<body>$body</body></html>"
    }

    # Link url label
    #
    # url    - A resource URL
    # label  - A text label
    #
    # Formats and returns an HTML link.

    proc Link {url label} {
        return "<a href=\"$url\">$label</a>"
    }

    # Table headers
    #
    # headers - A list of column headers
    #
    # Begins a standard table with the specified column headers

    proc Table {headers} {
        set out "<table border=1 cellpadding=2 cellspacing=0>\n"
        append out "<tr align=left>\n"

        foreach header $headers {
            append out "<td>$header</td>\n"
        }
        append out "</tr>\n"

        return $out
    }
}

