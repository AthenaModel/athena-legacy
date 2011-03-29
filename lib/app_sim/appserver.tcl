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
        /actors {
            doc     {Links to the currently defined actors.}
            pattern {^actors/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityLinks /actors /actor}
                text/html  {html_EntityLinks /actors /actor}
            }
        }

        /actor/{a} {
            doc     {Detail page for actor {a}.}
            pattern {^actor/(\w+)/?$}
            ctypes  {
                text/html {html_Actor}
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

        /groups {
            doc     {Links to the currently defined groups of all types.}
            pattern {^groups/?$}
            ctypes  {
                tcl/linkdict {linkdict_GroupLinks}
                text/html  {html_GroupLinks}
            }
        }

        /groups/{gtype} {
            doc     {
                Links to the currently defined groups of type {gtype}
                (civ, frc, or org).
            }
            pattern {^groups/(civ|frc|org)/?$}
            ctypes  {
                tcl/linkdict {linkdict_GroupLinks}
                text/html  {html_GroupLinks}
            }
        }


        /group/{g} {
            doc     {Detail page for group {g}.}
            pattern {^group/(\w+)/?$}
            ctypes  {
                text/html {html_Group}
            }
        }

        /image/{name} {
            doc     {Any Tk image, by its {name}.}
            pattern {^image/(.+)$}
            ctypes  {
                tk/image {image_TkImage}
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

        /nbhoods {
            doc     {Links to the currently defined neighborhoods.}
            pattern {^nbhoods/?$}
            ctypes  {
                tcl/linkdict {linkdict_EntityLinks /nbhoods /nbhood}
                text/html  {html_EntityLinks /nbhoods /nbhood}
            }
        }

        /nbhood/{n} {
            doc     {Detail page for neighborhood {n}.}
            pattern {^nbhood/(\w+)/?$}
            ctypes  {
                text/html {html_Nbhood}
            }
        }

        /schema {
            doc     {RDB Schema Links.}
            pattern {^schema/?$}
            ctypes  {
                text/html {html_RdbSchemaLinks}
            }
        }

        /schema/item/{name} {
            doc     {Schema for an RDB table, view, or trigger.}
            pattern {^schema/item/(\w+)$}
            ctypes  {
                text/html {html_RdbSchemaItem}
            }
        }

        /schema/{subset} {
            doc     {
                Links for a {subset} of the RDB Schema Links.
                Valid subsets are "main", "temp"; anything else
                is assumed to be a wildcard pattern.
            }
            pattern {^schema/([A-Za-z0-9_*]+)$}
            ctypes  {
                text/html {html_RdbSchemaLinks}
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

        / {
            doc     {Athena Welcome Page}
            pattern {^/?$}
            ctypes  {
                text/html {html_Welcome}
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
        /actors {
            label    "Actors"
            listIcon ::projectgui::icon::actor12
            table    actors
            key      a
        }

        /nbhoods {
            label    "Neighborhoods"
            listIcon ::projectgui::icon::nbhood12
            table    nbhoods
            key      n
        }

        /groups/civ {
            label    "Civ. Groups"
            listIcon ::projectgui::icon::civgroup12
            table    civgroups_view
            key      g
        }

        /groups/frc {
            label    "Force Groups"
            listIcon ::projectgui::icon::frcgroup12
            table    frcgroups_view
            key      g
        }

        /groups {
            label    "Groups"
            listIcon ::projectgui::icon::group12
            table    groups
            key      g
        }

        /groups/org {
            label    "Org. Groups"
            listIcon ::projectgui::icon::orggroup12
            table    orggroups_view
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
    # Public methods

    # resources
    #
    # Returns a list of the resource types accepted by the server.

    method resources {} {
        return [dict keys $rinfo]
    }

    # ctypes rtype
    #
    # rtype   - A resource type
    #
    # Returns a list of the content types for each resource type.

    method ctypes {rtype} {
        return [dict keys [dict get $rinfo $rtype ctype]]
    }

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
                "Content-type unavailable: $contentTypes"
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
        upvar 1 $matchArray match

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
        ht::putln <dl>

        foreach rtype $rtypes {
            set doc [string map $trans [dict get $rinfo $rtype doc]]
            set ctypes [dict keys [dict get $rinfo $rtype ctypes]]
            set rtype [string map $trans $rtype]

            ht::putln <dt><b>$rtype</b></dt>
            ht::putln <dd>$doc ([join $ctypes {, }])<p>
        }

        ht::putln </dl>
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
        upvar 1 $matchArray ""

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
    # RDB Introspection

    # html_RdbSchemaLinks url matchArray
    #
    # url        - The /schema URL
    # matchArray - Array of pattern matches
    # 
    # Produces an HTML page with a table of the RDB tables, views,
    # etc., for which schema text is available.
    #
    # Match parm $(1) is the subset of the schema to display:
    #
    #   ""         - All items are displayed
    #   main       - Items from sqlite_master
    #   temp       - Items from sqlite_temp_master
    #   <pattern>  - A wildcard pattern

    proc html_RdbSchemaLinks {url matchArray} {
        upvar 1 $matchArray ""

        set pattern $(1)
        
        set main {
            SELECT type, link('/schema/item/' || name, name) AS name, 
                   "Persistent"
            FROM sqlite_master
            WHERE name NOT GLOB 'sqlite_*'
            AND   type != 'index'
            AND   sql IS NOT NULL
        }

        set temp {
            SELECT type, link('/schema/item/' || name, name) AS name, 
                   "Temporary"
            FROM sqlite_temp_master
            WHERE name NOT GLOB 'sqlite_*'
            AND   type != 'index'
            AND   sql IS NOT NULL
        }
        
        switch -exact -- $pattern {
            "" { 
                set sql "$main UNION $temp ORDER BY name"
                set text ""
            }

            main { 
                set sql "$main ORDER BY name"
                set text "Persistent items only.<p>"
            }

            temp { 
                set sql "$temp ORDER BY name"
                set text "Temporary items only.<p>"
            }

            default { 
                set sql "
                    $main AND name GLOB \$pattern UNION
                    $temp AND name GLOB \$pattern ORDER BY name
                "

                set text "Items matching \"$pattern\".<p>"
            }
        }

        ht::page "RDB Schema"
        ht::h1 "RDB Schema"

        ht::putln $text

        ht::query $sql -labels {Type Name Persistence} -maxcolwidth 0

        ht::/page

        return [ht::get]
    }

    # html_RdbSchemaItem url matchArray
    #
    # url        - The /urlhelp URL
    # matchArray - Array of pattern matches
    # 
    # Produces an HTML page with the schema of a particular 
    # table or view for which schema text is available.

    proc html_RdbSchemaItem {url matchArray} {
        upvar 1 $matchArray ""

        set name $(1)

        rdb eval {
            SELECT sql FROM sqlite_master
            WHERE name=$name
            UNION
            SELECT sql FROM sqlite_temp_master
            WHERE name=$name
        } {
            ht::page "RDB Schema: $name" {
                ht::h1 "RDB Schema: $name"
                ht::pre $sql
            }

            return [ht::get]
        }

        return -code error -errorcode NOTFOUND \
            "The requested schema entry was not found."
    }

    #-------------------------------------------------------------------
    # Welcome Page

    # html_Welcome url matchArray
    #
    # url        - The URL of the resource
    # matchArray - Array of pattern matches
    #
    # Formats and displays the welcome page from welcome.ehtml.

    proc html_Welcome {url matchArray} {
        if {[catch {
            set text [readfile [appdir join lib app_sim welcome.ehtml]]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "The Welcome page could not be loaded from disk: $result"
        }

        return [tsubst $text]
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
                set subset {
                    /actors 
                    /nbhoods 
                    /groups/civ 
                    /groups/frc 
                    /groups/org
                }
            }

            bsystem { 
                set subset {/actors /groups/civ}    
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


    # linkdict_EntityLinks etype eroot url matchArray
    #
    # etype      - entityTypes key
    # eroot      - root URL for the entity type
    # url        - The URL of the collection resource
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns tcl/linkdict for a collection resource, based on an RDB 
    # table.

    proc linkdict_EntityLinks {etype eroot url matchArray} {
        set result [dict create]

        

        dict with entityTypes $etype {
            rdb eval "
                SELECT $key AS id, longname 
                FROM $table 
                ORDER BY longname, $key
            " {
                dict set result "$eroot/$id" \
                    [dict create label "$longname ($id)" listIcon $listIcon]
            }
        }

        return $result
    }


    # html_EntityLinks etype eroot url matchArray
    #
    # etype      - entityTypes key
    # eroot      - root URL for the entity type
    # url        - The URL of the collection resource
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns a text/html of links for a collection resource, based on 
    # an RDB table.

    proc html_EntityLinks {etype eroot url matchArray} {
        dict with entityTypes $etype {
            ht::page $label
            ht::h1 $label

            ht::push

            rdb eval "
                SELECT $key AS id, longname FROM $table ORDER BY longname
            " {
                ht::li { ht::link $eroot/$id "$longname ($id)" }
            }

            set links [ht::pop]

            if {$links eq ""} {
                ht::putln "No entities of this type have been defined."
                ht::para
            } else {
                ht::ul { ht::put $links }
            }

            ht::/page
            
            return [ht::get]
        }
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
        upvar 1 $matchArray ""

        # Accumulate data
        set a [string toupper $(1)]

        if {![rdb exists {SELECT * FROM actors WHERE a=$a}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: $url."
        }

        # Begin the page
        array set data [actor get $a]

        ht::page "Actor: $a"
        ht::title "$data(longname) ($a)" "Actor" 

        # Asset Summary
        ht::putln "Fiscal assets: about $[moneyfmt $data(cash)], "
        ht::put "plus about $[moneyfmt $data(income)] per week."
        ht::putln "Groups owned: "

        ht::linklist [rdb eval {
            SELECT '/group/' || g, g FROM gui_agroups 
            WHERE a=$a
            ORDER BY g
        }]

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
                            ht::image ::marsgui::icon::smthumbupgreen middle
                        } else {
                            ht::image ::marsgui::icon::smthumbdownred middle
                        }
                    }
                    ht::put $narrative
                    ht::tinyi " (goal=$goal_id)"
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
        # TBD: recast to use ht::query.
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
                ht::td left  { ht::link /nbhood/$n $n              }
                ht::td right { ht::put $personnel                  }
                ht::td left  { ht::link /group/$g "$longname ($g)" }
                ht::td left  { ht::put $gtype/$subtype             }
            }
        }

        set rows [ht::pop]

        if {$rows eq ""} {
            ht::put "No forces deployed."
            ht::para
        } else {
            ht::table {Nbhood Personnel Group Type} {
                ht::put $rows
            }
            ht::para
        }

        # Civilian Support
        ht::h2 "Topics Not Yet Covered"

        ht::putln {We might add information about the following topics.}
        ht::para

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
    # Neighborhood-specific handlers

    # html_Nbhood url matchArray
    #
    # url        - The URL that was requested
    # matchArray - Array of matches from the URL
    #
    # Formats the summary page for /nbhood/{n}.

    proc html_Nbhood {url matchArray} {
        upvar 1 $matchArray ""

        # Get the neighborhood
        set n [string toupper $(1)]

        if {![rdb exists {SELECT * FROM nbhoods WHERE n=$n}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: $url."
        }

        rdb eval {SELECT * FROM gui_nbhoods WHERE n=$n} data {}
        rdb eval {SELECT * FROM demog_n     WHERE n=$n} dem  {}
        rdb eval {SELECT * FROM econ_n      WHERE n=$n} econ {}

        let locked {[sim state] ne "PREP"}

        # Begin the page
        ht::page "Neighborhood: $n"
        ht::title "$data(longname) ($n)" "Neighborhood" 

        if {!$locked} {
            ht::putln ""
            ht::tinyi {
                More information will be available once the scenario has
                been locked.
            }
            ht::para
        }

        # Non-local?
        if {!$data(local)} {
            ht::putln "$n is located outside of the main playbox."
        }

        # When not locked.
        if {!$locked} {
            ht::putln "Resident groups: "

            ht::linklist -default "None" [rdb eval {
                SELECT '/group/' || g, g FROM civgroups WHERE n=$n
            }]

            ht::put ". "

            ht::/page
            return [ht::get]
        }

        # Population, groups.
        set urb    [eurbanization longname $data(urbanization)]
        let labPct {double($dem(labor_force))/$dem(population)}
        let sagPct {double($dem(subsistence))/$dem(population)}
        set mood   [qsat name $data(mood)]

        ht::putln "$data(longname) ($n) is "
        ht::putif {$urb eq "Urban"} "an " "a "
        ht::put "$urb neighborhood with a population of "
        ht::put [commafmt $dem(population)]
        ht::put ", [percent $labPct] of which are in the labor force and "
        ht::put "[percent $sagPct] of which are engaged in subsistence "
        ht::put "agriculture."

        ht::putln "The population belongs to the following groups: "

        ht::linklist -default "None" [rdb eval {
            SELECT '/group/' || g, g FROM civgroups WHERE n=$n
        }]
        
        ht::put "."

        ht::putln "Their overall mood is [qsat format $data(mood)] "
        ht::put "([qsat longname $data(mood)])."
        ht::putln "The level of basic services is TBD, which is "
        ht::put "(more than)/(less than) expected. "

        if {$data(local)} {
            if {$dem(labor_force) > 0} {
                let rate {double($dem(unemployed))/$dem(labor_force)}
                ht::putln "The unemployment rate is [percent $rate]."
            }
            ht::putln "$n's production capacity is [percent $econ(pcf)]."
        }
        ht::para

        # Actors
        ht::putln \
            "Actor TBD is in control of $n."          \
            "Actors TBD would like to be in control." \
            "Actors TBD are also active."             \
            "Actors TBD have influence in $n."
        ht::para

        # Groups
        ht::putln \
            "The following force and organization groups are" \
            "active in $n: "

        ht::linklist -default "None" [rdb eval {
            SELECT '/group/' || g, g 
            FROM force_ng 
            JOIN gui_agroups USING (g)
            WHERE n=$n AND personnel > 0
        }]

        ht::put "."
        ht::para

        # Civilian groups
        ht::h2 "Civilian Groups"
        
        ht::putln "The following civilian groups live in $n:"
        ht::para

        ht::query {
            SELECT link('/group/' || G.g, pair(G.longname, G.g))
                       AS 'Name',
                   D.population 
                       AS 'Population',
                   pair(qsat('format',M.sat), qsat('longname',M.sat))
                       AS 'Mood',
                   pair(qsecurity('format',S.security), 
                        qsecurity('longname',S.security))
                       AS 'Security'
            FROM groups    AS G
            JOIN civgroups AS C USING (g)
            JOIN demog_g   AS D USING (g)
            JOIN gram_g    AS M USING (g)
            JOIN force_ng  AS S USING (g)
            WHERE C.n=$n AND S.n=$n
            ORDER BY G.g
        }

        # Force/Org groups

        ht::h2 "Forces Present"

        ht::query {
            SELECT link('/group/' || G.g, pair(G.longname, G.g))
                       AS 'Group',
                   P.personnel 
                       AS 'Personnel', 
                   G.gtype || '/' || AG.subtype
                       AS 'Type',
                   CASE WHEN G.gtype='FRC'
                   THEN pair(C.coop, qcoop('longname',C.coop))
                   ELSE 'n/a' END
                       AS 'Coop. of Nbhood'
            FROM force_ng     AS P
            JOIN groups       AS G  USING (g)
            JOIN gui_agroups  AS AG USING (g)
            LEFT OUTER JOIN gui_coop_ng  AS C ON (C.n=P.n AND C.g=P.g)
            WHERE P.n=$n
            AND   personnel > 0
            ORDER BY G.g
        } -default "None."

        # Topics Yet to be Covered
        ht::h2 "Topics Yet To Be Covered"

        ht::putln "The following topics might be covered in the future:"

        ht::ul {
            ht::li-text {
                <b>Power Struggles:</b> Analysis of who is in control and
                why.
            }
            ht::li-text { 
                <b>Conflicts:</b> Pairs of force groups with 
                significant ROEs.
            }
            ht::li-text {
                <b>Significant Events:</b> Recent events in the
                neighborhood, e.g., the last turn-over of control.
            }
        }

        ht::/page
        return [ht::get]
    }

    #-------------------------------------------------------------------
    # Group-specific handlers

    # linkdict_GroupLinks url matchArray
    #
    # url        - The URL of the collection resource
    # matchArray - Array of pattern matches
    #
    # Matches:
    #   $(1) - The egrouptype. 
    #
    # Returns tcl/linkdict for a group collection, based on an RDB 
    # table.

    proc linkdict_GroupLinks {url matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the etype.
        if {$(1) eq ""} {
            set etype /groups
        } else {
            set etype /groups/$(1)
        }

        # NEXT, get the results
        set result [dict create]

        dict with entityTypes $etype {
            rdb eval "
                SELECT $key AS id, longname 
                FROM $table 
                ORDER BY longname
            " {
                dict set result "/group/$id" \
                    [dict create label "$longname ($id)" listIcon $listIcon]
            }
        }

        return $result
    }


    # html_GroupLinks url matchArray
    #
    # url        - The URL of the collection resource
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns a text/html of links for a collection resource, based on 
    # an RDB table.

    proc html_GroupLinks {url matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the etype.
        if {$(1) eq ""} {
            set etype /groups
        } else {
            set etype /groups/$(1)
        }

        # NEXT, get the results.
        dict with entityTypes $etype {
            ht::page $label
            ht::h1 $label

            ht::push
            rdb eval "
                SELECT $key AS id, longname 
                FROM $table 
                ORDER BY longname
            " {
                ht::li { ht::link /group/$id "$longname ($id)" }
            }

            set links [ht::pop]

            if {$links eq ""} {
                ht::putln "No entities of this type have been defined."
                ht::para
            } else {
                ht::ul { ht::put $links }
            }

            ht::/page
            
            return [ht::get]
        }
    }

    # html_Group url matchArray
    #
    # url        - The URL that was requested
    # matchArray - Array of matches from the URL
    #
    # Formats the summary page for /group/{g}.

    proc html_Group {url matchArray} {
        upvar 1 $matchArray ""

        # Get the group
        set g [string toupper $(1)]

        if {![rdb exists {SELECT * FROM groups WHERE g=$g}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: $url."
        }

        # Next, what kind of group is it?
        set gtype [group gtype $g]

        switch $gtype {
            CIV     { return [html_GroupCiv $url $g] }
            FRC     { return [html_GroupFrc $url $g] }
            ORG     { return [html_GroupOrg $url $g] }
            default { error "Unknown group type."    }
        }

    }

    # html_GroupCiv url g
    #
    # url        - The URL that was requested
    # g          - The group
    #
    # Formats the summary page for civilian /group/{g}.

    proc html_GroupCiv {url g} {
        # FIRST, get the data about this group
        rdb eval {SELECT * FROM gui_civgroups WHERE g=$g}       data {}
        rdb eval {SELECT * FROM gui_nbhoods   WHERE n=$data(n)} nb   {}

        # NEXT, begin the page.
        ht::page "Civilian Group: $g"
        ht::title "$data(longname) ($g)" "Civilian Group" 

        ht::linkbar {
            actors  "Relationships with Actors"
            rel     "Friends and Enemies"
            sat     "Satisfaction Levels"
            drivers "Drivers"
        }

        # NEXT, what we do depends on whether the simulation is locked
        # or not.
        let locked {[sim state] ne "PREP"}

        if {!$locked} {
            ht::putln ""
            ht::tinyi {
                More information will be available once the scenario has
                been locked.
            }

            ht::para
        }


        ht::putln "$data(longname) ($g) resides in neighborhood "
        ht::link  /nbhood/$data(n) "$nb(longname) ($data(n))"
        ht::put   " and has a population of "

        # TBD: Once demog_g is populated only when the simulation is locked,
        # we can update gui_civgroups to coalesce basepop into population,
        # and just use the one column.
        if {$locked} {
            ht::put [commafmt $data(population)]
        } else {
            ht::put [commafmt $data(basepop)]
        }

        ht::put "."

        ht::putln "The group's demeanor is "
        ht::put   [edemeanor longname $data(demeanor)].

        if {!$locked} {
            ht::/page
            return [ht::get]
        }

        # NEXT, the rest of the summary
        let lf {double($data(labor_force))/$data(population)}
        let sa {double($data(subsistence))/$data(population)}
        let ur {double($data(unemployed))/$data(labor_force)}
        
        ht::putln "[percent $lf] of the group is in the labor force, "
        ht::put   "and [percent $sa] of the group is engaged in "
        ht::put   "subsistence agriculture."
        
        ht::putln "The unemployment rate is [percent $ur]."
            
        ht::putln "$g's overall mood is [qsat format $data(mood)] "
        ht::put   "([qsat longname $data(mood)])."
        ht::para

        # Actors
        set controller [rdb onecolumn {
            SELECT controller FROM control_n WHERE n=$data(n)
        }]

        if {$controller eq ""} {
            ht::putln "No actor is in control of $data(n)."
        } else {
            set vrel_c [rdb onecolumn {
                SELECT vrel FROM vrel_ga
                WHERE g=$g AND a=$controller
            }]

            # TBD: Need Vmin parameter here!
            ht::putln "$g "
            ht::putif {$vrel_c > 0.2} "supports" "does not support"
            ht::put   " actor "
            ht::link /actor/$controller $controller
            ht::put   ", who is in control of neighborhood $data(n)."
        }

        rdb eval {
            SELECT a,vrel FROM vrel_ga
            WHERE g=$g
            ORDER BY vrel DESC
            LIMIT 1
        } fave {}

        if {$fave(vrel) > $vrel_c} {
            if {$fave(vrel) > 0.2} {
                ht::putln "$g would prefer to see actor "
                ht::put "$fave(a) in control of $data(n)."
            } else {
                ht::putln ""
                ht::putif {$controller ne ""} "In fact, "
                ht::put "$g does not support "
                ht::put   "any of the actors."
            }
        } else {
            ht::putln ""
            ht::putif {$vrel_c <= 0.2} "However, "
            ht::putln "$g prefers $controller to the other candidates."
        }
    
        ht::para
        
        # NEXT, Detail Block: Relationships with actors
        
        ht::h2 "Relationships with Actors" actors

        ht::query {
            SELECT link('/actor/' || a, pair(longname, a)) AS 'Actor',
                   qaffinity('format',vrel)                AS 'Vert. Rel.',
                   g || ' ' || qaffinity('longname',vrel) 
                     || ' ' || a                           AS 'Narrative'
            FROM vrel_ga JOIN actors USING (a)
            WHERE g=$g
            ORDER BY vrel DESC
        } -align {left right left}
        
        ht::h2 "Friend and Enemies" rel

        ht::query {
            SELECT link('/group/' || g, pair(longname, g)) AS 'Friend/Enemy',
                   gtype                                   AS 'Type',
                   qaffinity('format',rel)                 AS 'Relationship',
                   $g || ' ' || qaffinity('longname',rel) 
                      || ' ' || g                          AS 'Narrative'
            FROM rel_view JOIN groups USING (g)
            WHERE f=$g AND g != $g AND qaffinity('name',rel) != 'IND'
            ORDER BY rel DESC
        } -align {left left right left}

        ht::h2 "Satisfaction Levels" sat

        ht::putln "$g's overall mood is [qsat format $data(mood)] "
        ht::put   "([qsat longname $data(mood)]).  $g's satisfactions "
        ht::put   "with the various concerns are as follows."
        ht::para

        ht::query {
            SELECT pair(C.longname, C.c)            AS 'Concern',
                   qsat('format',sat)               AS 'Satisfaction',
                   qsat('longname',sat)             AS 'Narrative',
                   qsaliency('longname',saliency)   AS 'Saliency'
            FROM gram_sat JOIN concerns AS C USING (c)
            WHERE g=$g
            ORDER BY C.c
        } -align {left right left left}

        ht::h2 "Satisfaction Drivers" drivers

        ht::putln "The most important satisfaction drivers for this group "
        ht::put   "at the present time are as follows:"
        ht::para

        aram sat drivers               \
            -group   $g                \
            -concern mood              \
            -start   [simclock now -7]

        rdb eval {
            DROP TABLE IF EXISTS temp_satcontribs;
    
            CREATE TEMP TABLE temp_satcontribs AS
            SELECT driver,
                   acontrib
            FROM gram_sat_drivers
            WHERE g=$g AND c='mood' AND abs(acontrib) >= 0.001
        }

        ht::query {
            SELECT format('%8.3f', acontrib) AS 'Delta',
                   driver                    AS 'ID',
                   oneliner                  AS 'Description'
            FROM temp_satcontribs
            JOIN gram_driver USING (driver)
            ORDER BY abs(acontrib) DESC
        } -default "No significant drivers." -align {right right left}

        ht::/page

        return [ht::get]
    }


    # html_GroupFrc url g
    #
    # url        - The URL that was requested
    # g          - The group
    #
    # Formats the summary page for force /group/{g}.

    proc html_GroupFrc {url g} {
        rdb eval {SELECT * FROM frcgroups_view WHERE g=$g} data {}

        ht::page "Force Group: $g"
        ht::title "$data(longname) ($g)" "Force Group" 

        ht::putln "No data yet available."

        ht::/page

        return [ht::get]
    }

    # html_GroupOrg url g
    #
    # url        - The URL that was requested
    # g          - The group
    #
    # Formats the summary page for org /group/{g}.

    proc html_GroupOrg {url g} {
        rdb eval {SELECT * FROM orggroups_view WHERE g=$g} data {}

        ht::page "Organization Group: $g"
        ht::title "$data(longname) ($g)" "Organization Group" 

        ht::putln "No data yet available."

        ht::/page

        return [ht::get]
    }
}

