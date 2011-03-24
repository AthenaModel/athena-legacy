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
                tcl/linkdict {linkdict_EntityLinks /actor}
                text/html  {html_EntityLinks /actor}
            }
        }

        /actor/{a} {
            doc     {Detail page for actor {a}.}
            pattern {^actor/(\w+)/?$}
            ctypes  {
                text/html {html_Actor}
            }
        }

        /civgroup {
            doc     {Links to the currently defined civilian groups.}
            pattern {^civgroup/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityLinks /civgroup}
                text/html  {html_EntityLinks /civgroup}
            }
        }

        /civgroup/{g} {
            doc     {Detail page for civilian group {g}.}
            pattern {^civgroup/(\w+)/?$}
            ctypes  {
                text/html {html_GenericEntity "Civ. Group" civgroups g}
            }
        }

        /docs/{path}.html {
            doc     {An HTML file in the Athena docs/ tree.}
            pattern {^(docs/[^.]+\.html)$}
            ctypes  {
                text/html {text_File ""}
            }
        }

        /docs/{path}.txt {
            doc     {A .txt file in the Athena docs/ tree.}
            pattern {^(docs/[^.]+\.txt)$}
            ctypes  {
                text/plain {text_File ""}
            }
        }

        /docs/{imageFile} {
            doc     {
                A .gif, .jpg, or .png file in the Athena /docs/ tree.
            }
            pattern {^(docs/.+\.(gif|jpg|png))$}
            ctypes  {
                tk/image {image_File ""}
            }
        }

        /entitytype {
            doc     {Links to the main Athena entity types.}
            pattern {^entitytype/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityType}
                text/html  {html_EntityType "Entity Types"}
            }
        }

        /entitytype/bsystem {
            doc     {
                Links to the Athena entity types for which belief
                systems are defined.
            }
            pattern {^entitytype/(bsystem)/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityType}
                text/html  {html_EntityType "Belief System Entity Types"}
            }
        }

        /frcgroup {
            doc     {Links to the currently defined force groups.}
            pattern {^frcgroup/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityLinks /frcgroup}
                text/html  {html_EntityLinks /frcgroup}
            }
        }

        /frcgroup/{g} {
            doc     {Detail page for force group {g}.}
            pattern {^frcgroup/(\w+)/?$}
            ctypes  {
                text/html {html_GenericEntity "Force Group" frcgroups g}
            }
        }

        /group {
            doc     {Links to the currently defined groups of all types.}
            pattern {^group/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityLinks /group}
                text/html  {html_EntityLinks /group}
            }
        }

        /group/{g} {
            doc     {Detail page for group {g}.}
            pattern {^group/(\w+)/?$}
            ctypes  {
                text/html {html_GenericEntity "Group" groups g}
            }
        }

        /image/{name} {
            doc     {Any Tk image, by its {name}.}
            pattern {^image/(.+)$}
            ctypes  {
                tk/image {image_TkImage}
            }
        }

        /lib/{file}.html {
            doc     {An HTML file in the Athena library.}
            pattern {^lib/([^./]+\.html)$}
            ctypes  {
                text/html {text_File lib/app_sim}
            }
        }

        /lib/{imageFile} {
            doc     {
                A .gif, .jpg, or .png file in the Athena library.
            }
            pattern {^lib/(.+\.(gif|jpg|png))$}
            ctypes  {
                tk/image {image_File lib/app_sim}
            }
        }


        /mars/docs/{path}.html {
            doc     {An HTML file in the Athena mars/docs/ tree.}
            pattern {^(mars/docs/.+\.html)$}
            ctypes  {
                text/html {text_File ""}
            }
        }

        /mars/docs/{path}.txt {
            doc     {A .txt file in the Athena mars/docs/ tree.}
            pattern {^(mars/docs/.+\.txt)$}
            ctypes  {
                text/plain {text_File ""}
            }
        }

        /mars/docs/{imageFile} {
            doc     {
                A .gif, .jpg, or .png file in the Athena mars/docs/ tree.
            }
            pattern {^(mars/docs/.+\.(gif|jpg|png))$}
            ctypes  {
                tk/image {image_File ""}
            }
        }

        /nbhood {
            doc     {Links to the currently defined neighborhoods.}
            pattern {^nbhood/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityLinks /nbhood}
                text/html  {html_EntityLinks /nbhood}
            }
        }

        /nbhood/{n} {
            doc     {Detail page for neighborhood {n}.}
            pattern {^nbhood/(\w+)/?$}
            ctypes  {
                text/html {html_GenericEntity "Neighborhood" nbhoods n}
            }
        }

        /orggroup {
            doc     {Links to the currently defined organization groups.}
            pattern {^orggroup/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityLinks /orggroup}
                text/html  {html_EntityLinks /orggroup}
            }
        }

        /orggroup/{g} {
            doc     {Detail page for organization group {g}.}
            pattern {^orggroup/(\w+)/?$}
            ctypes  {
                text/html {html_GenericEntity "Org. Group" orggroups g}
            }
        }

        /urlhelp {
            doc     {Complete URL schema for this server.}
            pattern {^urlhelp/?$}
            ctypes  {
                text/html {html_UrlHelp}
            }
        }

        /urlhelp/{url} {
            doc     {Help for URL {url}.}
            pattern {^urlhelp/(.+)$}
            ctypes  {
                text/html {html_UrlHelp}
            }
        }
    }

    #-------------------------------------------------------------------
    # Entity Types
    #
    # This data is used to handle the entity type URLs.

    # entityTypes: Nested dictionary of entity type data.
    #
    # key: entity type collection resource
    #
    # value: Dictionary of data about each entity
    #
    #   label     - A human readable label for this kind of entity.
    #   listIcon  - A Tk icon to use in lists and trees next to the
    #               label

    typevariable entityTypes {
        /actor {
            label    "Actors"
            listIcon ::projectgui::icon::actor12
            table    actors
            key      a
        }

        /nbhood {
            label    "Neighborhoods"
            listIcon ::projectgui::icon::nbhood12
            table    nbhoods
            key      n
        }

        /civgroup {
            label    "Civ. Groups"
            listIcon ::projectgui::icon::civgroup12
            table    civgroups
            key      g
        }

        /frcgroup {
            label    "Force Groups"
            listIcon ::projectgui::icon::frcgroup12
            table    frcgroups
            key      g
        }

        /group {
            label    "Groups"
            listIcon ::projectgui::icon::group12
            table    groups
            key      g
        }

        /orggroup {
            label    "Org. Groups"
            listIcon ::projectgui::icon::orggroup12
            table    orggroups
            key      g
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


    #===================================================================
    # Content Routines
    #
    # The following code relates to particular resources or kinds
    # of content.

    #-------------------------------------------------------------------
    # Server Introspection

    # html_UrlHelp url matchArray
    #
    # url        - The /urlhelp URL
    # matchArray - Array of pattern matches
    # 
    # Produces an HTML page detailing one or all of the URLs
    # understood by this server.  Match parm (1) is either empty
    # or a URL for which help is requested.

    proc html_UrlHelp {url matchArray} {
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

        ht::page $title
        ht::h1 $title
        ht::put <dl>

        foreach rtype $rtypes {
            set doc [string map $trans [dict get $rinfo $rtype doc]]
            set ctypes [dict keys [dict get $rinfo $rtype ctypes]]
            set rtype [string map $trans $rtype]

            ht::put <dt><b>$rtype</b>
            ht::put <dd>$doc ([join $ctypes {, }])<p>
        }

        ht::put </dl>
        ht::/page

        return [ht::get]
    }

    #-------------------------------------------------------------------
    # Pre-loaded Tk Images

    # image_TkImage url matchArray
    #
    # url        - The URL that was requested
    # matchArray - Array of matches from the URL
    #
    # Validates $(1) as a Tk image, and returns it as the tk/image
    # content.

    proc image_TkImage {url matchArray} {
        upvar $matchArray ""

        if {[catch {image type $(1)} result]} {
            return -code error -errorcode NOTFOUND \
                "Image not found: $url"
        }

        return $(1)
    }

    #-------------------------------------------------------------------
    # App Files
    #
    # These routines serve files in the appdir tree.

    # text_File base url matchArray
    #
    # base       - A directory within the appdir tree, or ""
    # url        - The URL of the entity
    # matchArray - Array of pattern matches
    #
    #     (1) - *.html or *.txt
    #
    # Retrieves the file.

    proc text_File {base url matchArray} {
        upvar 1 $matchArray ""

        set fullname [appdir join $base $(1)]

        if {[catch {
            set content [readfile $fullname]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "Page could not be found: $(1)"
        }

        return $content
    }

    # image_File base url matchArray
    #
    # base       - A directory within the appdir tree, or ""
    # url        - The URL of the entity
    # matchArray - Array of pattern matches
    #
    #     (1) - image file name, relative to appdir.
    #
    # Retrieves and caches the file, returning a tk/image.

    proc image_File {base url matchArray} {
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
            set mtime [file mtime $fullname]
            set img   [image create photo -file $fullname]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "Image file could not be found: $(1)"
        }

        set imageCache($url) [list $img $mtime]

        return $img
    }

    #-------------------------------------------------------------------
    # Generic Entity Type Code

    # linkdict_EntityType url matchArray
    #
    # url        - The URL of the entitytype resource
    # matchArray - Array of pattern matches
    #
    # Returns an entitytype[/*] resource as a tcl/linkdict 
    # where $(1) is the entity type subset.

    proc linkdict_EntityType {url matchArray} {
        upvar 1 $matchArray ""

        # FIRST, handle subsets
        switch -exact -- $(1) {
            "" { 
                set subset {/actor /nbhood /civgroup /frcgroup /orggroup}
            }

            bsystem { 
                set subset {/actor /civgroup}    
            }

            default { error "Unexpected URL: \"$url\"" }
        }

        foreach etype $subset {
            dict set result $etype [dict get $entityTypes $etype]
        }

        return $result
    }
    
    # html_EntityType url matchArray
    #
    # title      - The page title
    # url        - The URL of the entitytype resource
    # matchArray - Array of pattern matches
    #
    # Returns an entitytype/* resource as a tcl/linkdict 
    # where $(1) is the entity type subset.

    proc html_EntityType {title url matchArray} {
        upvar 1 $matchArray ""

        set types [linkdict_EntityType $url ""]

        ht::page $title
        ht::h1 $title
        ht::ul {
            foreach link [dict keys $types] {
                ht::li { ht::link $link [dict get $types $link label] }
            }
        }
        ht::/page

        return [ht::get]
    }


    # linkdict_EntityLinks table key url matchArray
    #
    # etype      - entityTypes key
    # url        - The URL of the collection resource
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns tcl/linkdict for a collection resource, based on an RDB 
    # table.

    proc linkdict_EntityLinks {etype url matchArray} {
        set result [dict create]

        dict with entityTypes $etype {
            rdb eval "SELECT $key AS id FROM $table ORDER BY $key" {
                dict set result "$url/$id" \
                    [dict create label $id listIcon $listIcon]
            }
        }

        return $result
    }


    # html_EntityLinks etype url matchArray
    #
    # etype      - entityTypes key
    # url        - The URL of the collection resource
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns a text/html of links for a collection resource, based on 
    # an RDB table.

    proc html_EntityLinks {etype url matchArray} {
        dict with entityTypes $etype {
            set ids [rdb eval "SELECT $key AS id FROM $table ORDER BY $key"]

            ht::page $label
            ht::h1 $label

            if {[llength $ids] == 0} {
                ht::put "No entities of this type have been defined."
                ht::para
            } else {
                ht::ul {
                    foreach id $ids {
                        ht::li { ht::link $url/$id $id }
                    }
                }
            }

            ht::/page
            
            return [ht::get]
        }
    }

    # html_GenericEntity title url matchArray
    #
    # title      - A title string for the kind of entity
    # table      - The RDB table
    # key        - The key column in the RDB table
    # url        - The URL of the entity
    # matchArray - Array of pattern matches
    #
    # Returns a stub text/html page for an entity.  Used as a stopgap
    # when no detailed content exists.

    proc html_GenericEntity {title table key url matchArray} {
        upvar $matchArray ""

        set id $(1)

        if {![rdb exists "SELECT * FROM $table WHERE $key = \$id"]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: $url."
        }

        ht::page "$title: $(1)" {
            ht::h1 "$title: $(1)"
            ht::put \
              "No additional information has been provided for this entity."
            ht::para
        }

        return [ht::get]
    }

    #-------------------------------------------------------------------
    # Actor-specific handlers
    #
    # TBD: Eventually, this should go elsewhere.

    # html_Actor url matchArray
    #
    # url        - The URL that was requested
    # matchArray - Array of matches from the URL

    proc html_Actor {url matchArray} {
        upvar $matchArray ""

        # Accumulate data
        set a $(1)

        if {![rdb exists {SELECT * FROM actors WHERE a=$a}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: $url."
        }

        # Begin the page
        array set data [actor get $a]

        ht::page "Actor: $a"
        ht::h1 "Actor: $data(longname) ($a)"

        # Asset Summary
        ht::put "Fiscal assets: about $[moneyfmt $data(cash)],"
        ht::put "plus about $[moneyfmt $data(income)] per week."
        ht::put "Groups owned:"
        ht::push

        rdb eval {
            SELECT g FROM gui_agroups 
            WHERE a=$a
            ORDER BY g
        } {
            # TBD: we want to be able to add punctuation.
            # How?
            ht::link /group/$g $g
        }

        set text [ht::pop]

        if {$text ne ""} {
            ht::put $text
        } else {
            ht::put "None."
        }
        
        ht::para

        # Goals
        ht::h2 "Goals"

        ht::push
        rdb eval {
            SELECT narrative, flag, goal_id FROM goals
            WHERE owner=$a AND state = 'normal'
        } {
            ht::ul {
                ht::li {
                    if {$flag ne ""} {
                        if {$flag} {
                            ht::image ::marsgui::smthumbupgreen
                        } else {
                            ht::image ::marsgui::smthumbdownred
                        }
                    }
                    ht::put $narrative
                    ht::tinyi "(goal=$goal_id)"
                }
            }
            ht::para
        }

        set text [ht::pop]

        if {$text ne ""} {
            ht::put $text
        } else {
            ht::put "None."
            ht::para
        }

        # Deployment
        ht::h2 "Force Deployment"

        ht::push
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
            ht::tr {
                ht::td       { ht::link /nbhood/$n $n             }
                ht::td-right { ht::put $personnel                 }
                ht::td       { ht::link /group/$g "$g: $longname" }
                ht::td       { ht::put $gtype/$subtype            }
            }
        }

        set rows [ht::pop]

        if {$rows eq ""} {
            ht::put "None."
            ht::para
        } else {
            ht::table {Nbhood Personnel Group Type} {
                ht::put $rows
            }
            ht::para
        }

        # Civilian Support
        ht::h2 "Topics Not Yet Covered"

        ht::put {We might add information about the following topics.}

        ht::ul {
            ht::li {
                ht::put {
                    <b>Sphere of Influence</b>: the neighborhoods
                    the actor controls, wishes to control, and has
                    influence in.   The text should show the 
                    neighborhoods in which he has the most influence
                    first.
                }
            }

            ht::li {
                ht::put {
                    <b>Civilian Support</b>: a breakdown of which
                    groups support or oppose the actor, by 
                    neighborhood.
                }
            }

            ht::li {
                ht::put {
                    <b>Recent Tactics</b>: The tactics recently used
                    by the actor.
                }
            }

            ht::li {
                ht::put {
                    <b>Significant events</b:  Things the actor has
                    recently accomplished, or that have recently
                    happened to him, e.g., gained or lost control of a
                    neighborhood.
                }
            }

        }

        ht::para


        ht::/page

        return [ht::get]
    }


    #-------------------------------------------------------------------
    # HTML Boilerplate routines

}

