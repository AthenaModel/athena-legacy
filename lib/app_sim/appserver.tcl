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
    # Type Components

    typecomponent server   ;# The myserver(n) instance.
    typecomponent ht       ;# The htools(n) instance.



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
    #           regexp into values "0" through "9"
    # doc     - A documentation string for the resource type.  Note
    #           that "{" and "}" in resource types and doc strings
    #           are converted to "<i>" and "</i>" when displayed as
    #           HTML.

    typevariable rinfo {}

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
            table    gui_actors
            key      a
        }

        /nbhoods {
            label    "Neighborhoods"
            listIcon ::projectgui::icon::nbhood12
            table    gui_nbhoods
            key      n
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

        /groups {
            label    "Groups"
            listIcon ::projectgui::icon::group12
            table    gui_groups
            key      g
        }

        /groups/org {
            label    "Org. Groups"
            listIcon ::projectgui::icon::orggroup12
            table    gui_orggroups
            key      g
        }
    }

    #-------------------------------------------------------------------
    # Type Variables

    # Image Cache
    # 
    # Image files loaded from disk are cached as Tk images in the 
    # imageCache array.  The keys are image file URLs; the 
    # values are pairs, Tk image name and [file mtime].

    typevariable imageCache -array {}

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
        $server register /actors {actors/?} \
            tcl/linkdict [myproc linkdict_EntityLinks /actors /actor] \
            text/html    [myproc html_EntityLinks /actors /actor]     \
            "Links to the currently defined actors."

        $server register /actor/{a} {actor/(\w+)/?} \
            text/html [myproc html_Actor]           \
            "Detail page for actor {a}."

        $server register /docs/{path}.html {(docs/[.]+\.html)} \
            text/html [myproc text_File ""]                    \
            "An HTML file in the Athena docs/ tree."

        $server register /docs/{path}.txt {(docs/[.]+\.txt)} \
            text/plain [myproc text_File ""]                 \
            "A .txt file in the Athena docs/ tree."

        $server register /docs/{imageFile} {(docs/.+\.(gif|jpg|png))} \
            tk/image [myproc image_File ""]                           \
            "A .gif, .jpg, or .png file in the Athena /docs/ tree."

        $server register /entitytype {entitytype/?}              \
            tcl/linkdict [myproc linkdict_EntityType]            \
            text/html    [myproc html_EntityType "Entity Types"] \
            "Links to the main Athena entity types."

        $server register /entitytype/bsystem {entitytype/(bsystem)/?}   \
            tcl/linkdict [myproc linkdict_EntityType]                   \
            text/html    [myproc html_EntityType "Belief Entity Types"] {
                Links to the Athena entity types for which belief 
                systems are defined.
            }

        $server register /groups {groups/?} \
            tcl/linkdict [myproc linkdict_GroupLinks]              \
            text/html    [myproc html_GroupLinks]                  \
            "Links to the currently defined groups of all types."

        $server register /groups/{gtype} {groups/(civ|frc|org)/?}     \
            tcl/linkdict [myproc linkdict_GroupLinks]                 \
            text/html    [myproc html_GroupLinks]                     {
                Links to the currently defined groups of type {gtype}
                (civ, frc, or org).
            }


        $server register /group/{g} {group/(\w+)/?} \
            text/html [myproc html_Group]           \
            "Detail page for group {g}."

        $server register /image/{name} {image/(.+)} \
            tk/image [myproc image_TkImage]         \
            "Any Tk image, by its {name}."

        $server register /mars/docs/{path}.html {(mars/docs/.+\.html)} \
            text/html [myproc text_File ""]                            \
            "An HTML file in the Athena mars/docs/ tree."

        $server register /mars/docs/{path}.txt {(mars/docs/.+\.txt)} \
            text/plain [myproc text_File ""]                         \
            "A .txt file in the Athena mars/docs/ tree."

        $server register /mars/docs/{imageFile} \
            {(mars/docs/.+\.(gif|jpg|png))}     \
            tk/image [myproc image_File ""]     {
                A .gif, .jpg, or .png file in the Athena mars/docs/ tree.
            }   

        $server register /nbhoods {nbhoods/?} \
            tcl/linkdict [myproc linkdict_EntityLinks /nbhoods /nbhood] \
            text/html    [myproc html_EntityLinks /nbhoods /nbhood]     \
            "Links to the currently defined neighborhoods."

        $server register /nbhood/{n} {nbhood/(\w+)/?} \
            text/html [myproc html_Nbhood]            \
            "Detail page for neighborhood {n}."

        $server register /schema {schema/?} \
            text/html [myproc html_RdbSchemaLinks] \
            "RDB Schema Links."

        $server register /schema/item/{name} {schema/item/(\w+)} \
            text/html [myproc html_RdbSchemaItem]                \
            "Schema for an RDB table, view, or trigger."

        $server register /schema/{subset} {schema/([A-Za-z0-9_*]+)} \
            text/html [myproc html_RdbSchemaLinks]                  {
                Links for a {subset} of the RDB Schema Links.
                Valid subsets are "main", "temp"; anything else
                is assumed to be a wildcard pattern.
            }

        $server register / {/?} \
            text/html [myproc html_Welcome] \
            "Athena Welcome Page"
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
            ht put [format "Simulation time: Day %04d, %s." \
                      [simclock now] [simclock asZulu]]
        }

        ht put [format " -- Wall Clock: %s" [clock format [clock seconds]]]

        ht put "</i></font>"
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

        ht page "RDB Schema"
        ht h1 "RDB Schema"

        ht putln $text

        ht query $sql -labels {Type Name Persistence} -maxcolwidth 0

        ht /page

        return [ht get]
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
            ht page "RDB Schema: $name" {
                ht h1 "RDB Schema: $name"
                ht pre $sql
            }

            return [ht get]
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
            set text [readfile [file join $::app_sim::library welcome.ehtml]]
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
            ht page $label
            ht h1 $label

            ht push

            rdb eval "
                SELECT longlink FROM $table ORDER BY fancy
            " {
                ht li { ht put $longlink }
            }

            set links [ht pop]

            if {$links eq ""} {
                ht putln "No entities of this type have been defined."
                ht para
            } else {
                ht ul { ht put $links }
            }

            ht /page
            
            return [ht get]
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
        rdb eval {SELECT * FROM gui_actors WHERE a=$a} data {}

        ht page "Actor: $a"
        ht title $data(fancy) "Actor" 

        ht linkbar {
            goals   "Goals"
            sphere  "Sphere of Influence"
            base    "Power Base"
            forces  "Force Deployment"
            future  "Future Topics"
        }
        
        # Asset Summary
        ht putln "Fiscal assets: about \$$data(cash), "
        ht put "plus about \$$data(income) per week."
        ht putln "Groups owned: "

        ht linklist [rdb eval {
            SELECT url, g FROM gui_agroups 
            WHERE a=$a
            ORDER BY g
        }]

        ht put "."

        ht para

        # Goals
        ht h2 "Goals" goals

        ht push
        rdb eval {
            SELECT narrative, flag, goal_id FROM goals
            WHERE owner=$a AND state = 'normal'
        } {
            ht ul {
                ht li {
                    if {$flag ne ""} {
                        if {$flag} {
                            ht image ::marsgui::icon::smthumbupgreen middle
                        } else {
                            ht image ::marsgui::icon::smthumbdownred middle
                        }
                    }
                    ht put $narrative
                    ht tinyi " (goal=$goal_id)"
                }
            }
            ht para
        }

        set text [ht pop]

        if {$text ne ""} {
            ht put $text
        } else {
            ht put "None."
            ht para
        }

        # Sphere of Influence
        ht h2 "Sphere of Influence" sphere

        if {[Locked -disclaimer]} {
            ht putln "Actor $a has influence in the following neighborhoods:"
            ht para

            ht query {
                SELECT N.longlink                 AS 'Neighborhood',
                       format('%.2f',I.influence) AS 'Influence'
                FROM influence_na AS I
                JOIN gui_nbhoods  AS N USING (n)
                WHERE I.a=$a AND I.influence > 0.0 
                ORDER BY I.influence DESC, N.fancy
            } -default "None."

            ht para
        }

        # Power Base
        ht h2 "Power Base" base

        if {[Locked -disclaimer]} {
            set vmin [parm get control.support.vrelMin]

            ht putln "Actor $a has the following supporters "
            ht putln "(and would-be supporters).  "
            ht putln "Note that a group only supports an actor if"
            ht putln "its vertical relationship with the actor is at"
            ht putln "least $vmin, and"
            ht putln "its support makes a difference only if its"
            ht putln "security is at least"
            ht putln "[parm get control.support.secMin]."
            ht para

            ht query {
                SELECT N.link                            AS 'In Nbhood',
                       G.link                            AS 'Group',
                       G.gtype                           AS 'Type',
                       format('%.2f',S.influence)        AS 'Influence',
                       qaffinity('format',S.vrel)        AS 'Vert. Rel.',
                       G.g || ' ' || 
                       qaffinity('longname',S.vrel) ||
                       ' ' || S.a                        AS 'Narrative',
                       commafmt(S.personnel)             AS 'Personnel',
                       qfancyfmt('qsecurity',S.security) AS 'Security'
                FROM support_nga AS S
                JOIN gui_groups  AS G ON (G.g = S.g)
                JOIN gui_nbhoods AS N ON (N.n = S.n)
                WHERE S.a=$a AND S.personnel > 0 AND S.vrel >= $vmin
                ORDER BY S.influence DESC, S.vrel DESC, N.n
            } -default "None." -align {left left right right left right left}

            ht para
        }

        # Deployment
        ht h2 "Force Deployment" forces

        ht query {
            SELECT N.longlink              AS 'Neighborhood',
                   P.personnel             AS 'Personnel',
                   G.longlink              AS 'Group',
                   G.fulltype              AS 'Type'
            FROM personnel_ng AS P
            JOIN gui_agroups  AS G ON (G.g=P.g)
            JOIN gui_nbhoods  AS N ON (N.n=P.n)
            WHERE G.a=$a AND personnel > 0
        } -default "No forces are deployed."

        # Future Topics
        ht h2 "Future Topics" future

        ht putln {We might add information about the following topics.}
        ht para

        ht ul {
            ht li {
                ht put {
                    <b>Recent Tactics</b>: The tactics recently used
                    by the actor.
                }
            }

            ht li {
                ht put {
                    <b>Significant events</b:  Things the actor has
                    recently accomplished, or that have recently
                    happened to him, e.g., gained or lost control of a
                    neighborhood.
                }
            }

        }

        ht para


        ht /page

        return [ht get]
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
        rdb eval {SELECT * FROM econ_n      WHERE n=$n} econ {}
        rdb eval {
            SELECT * FROM gui_actors  
            WHERE a=$data(controller)
        } cdata {}

        let locked {[sim state] ne "PREP"}

        # Begin the page
        ht page "Neighborhood: $n"
        ht title $data(fancy) "Neighborhood" 

        if {$locked} {
            ht linkbar {
                civs    "Civilian Groups"
                forces  "Forces Present"
                control "Support and Control"
                future  "Future Topics"
            }

        } {
            ht putln ""
            ht tinyi {
                More information will be available once the scenario has
                been locked.
            }
            ht para
        }

        # Non-local?
        if {!$data(local)} {
            ht putln "$n is located outside of the main playbox."
        }

        # When not locked.
        if {!$locked} {
            ht putln "Resident groups: "

            ht linklist -default "None" [rdb eval {
                SELECT url,g FROM gui_civgroups WHERE n=$n
            }]

            ht put ". "

            if {$data(controller) eq "NONE"} {
                ht putln "No actor is initially in control."
            } else {
                ht putln "Actor "
                ht put "$cdata(link) is initially in control."
            }

            ht para

            ht /page
            return [ht get]
        }

        # Population, groups.
        set urb    [eurbanization longname $data(urbanization)]
        let labPct {double($data(labor_force))/$data(population)}
        let sagPct {double($data(subsistence))/$data(population)}
        set mood   [qsat name $data(mood)]

        ht putln "$data(fancy) is "
        ht putif {$urb eq "Urban"} "an " "a "
        ht put "$urb neighborhood with a population of "
        ht put [commafmt $data(population)]
        ht put ", [percent $labPct] of which are in the labor force and "
        ht put "[percent $sagPct] of which are engaged in subsistence "
        ht put "agriculture."

        ht putln "The population belongs to the following groups: "

        ht linklist -default "None" [rdb eval {
            SELECT url,g FROM gui_civgroups WHERE n=$n
        }]
        
        ht put "."

        ht putln "Their overall mood is [qsat format $data(mood)] "
        ht put "([qsat longname $data(mood)])."
        ht putln "The level of basic services is TBD, which is "
        ht put "(more than)/(less than) expected. "

        if {$data(local)} {
            if {$data(labor_force) > 0} {
                let rate {double($data(unemployed))/$data(labor_force)}
                ht putln "The unemployment rate is [percent $rate]."
            }
            ht putln "$n's production capacity is [percent $econ(pcf)]."
        }
        ht para

        # Actors
        if {$data(controller) eq "NONE"} {
            ht putln "$n is currently in a state of chaos: "
            ht put   "no actor is in control."
        } else {
            ht putln "Actor $cdata(link) is currently in control of $n."
        }

        ht putln "Actors with forces in $n: "

        ht linklist -default "None" [rdb eval {
            SELECT DISTINCT '/actor/' || a, a
            FROM gui_agroups
            JOIN force_ng USING (g)
            WHERE n=$n AND personnel > 0
            ORDER BY personnel DESC
        }]

        ht put "."

        ht putln "Actors with influence in $n: "

        ht linklist -default "None" [rdb eval {
            SELECT DISTINCT A.url, A.a
            FROM influence_na AS I
            JOIN gui_actors AS A USING (a)
            WHERE I.n=$n AND I.influence > 0
            ORDER BY I.influence DESC
        }]

        ht put "."

        ht para

        # Groups
        ht putln \
            "The following force and organization groups are" \
            "active in $n: "

        ht linklist -default "None" [rdb eval {
            SELECT G.url, G.g
            FROM gui_agroups AS G
            JOIN force_ng    AS F USING (g)
            WHERE F.n=$n AND F.personnel > 0
        }]

        ht put "."
        ht para

        # Civilian groups
        ht h2 "Civilian Groups" civs
        
        ht putln "The following civilian groups live in $n:"
        ht para

        ht query {
            SELECT G.longlink  
                       AS 'Name',
                   G.population 
                       AS 'Population',
                   pair(qsat('format',G.mood), qsat('longname',G.mood))
                       AS 'Mood',
                   pair(qsecurity('format',S.security), 
                        qsecurity('longname',S.security))
                       AS 'Security'
            FROM gui_civgroups AS G
            JOIN force_ng      AS S USING (g)
            WHERE G.n=$n AND S.n=$n
            ORDER BY G.g
        }

        # Force/Org groups

        ht h2 "Forces Present" forces

        ht query {
            SELECT G.longlink
                       AS 'Group',
                   P.personnel 
                       AS 'Personnel', 
                   G.fulltype
                       AS 'Type',
                   CASE WHEN G.gtype='FRC'
                   THEN pair(C.coop, qcoop('longname',C.coop))
                   ELSE 'n/a' END
                       AS 'Coop. of Nbhood'
            FROM force_ng     AS P
            JOIN gui_agroups  AS G USING (g)
            LEFT OUTER JOIN gui_coop_ng  AS C ON (C.n=P.n AND C.g=P.g)
            WHERE P.n=$n
            AND   personnel > 0
            ORDER BY G.g
        } -default "None."

        # Support and Control
        ht h2 "Support and Control" control

        if {$data(controller) eq "NONE"} {
            ht putln "$n is currently in a state of chaos: "
            ht put   "no actor is in control."
        } else {
            ht putln "Actor $cdata(link) is currently in control of $n."
        }

        ht putln "The actors with influence in this neighborhood are "
        ht put   "as follows:"
        ht para

        ht query {
            SELECT A.longlink                   AS 'Actor',
                   format('%.2f',I.influence)   AS 'Influence'
            FROM influence_na AS I
            JOIN gui_actors   AS A USING (a)
            WHERE I.n = $n AND I.influence > 0.0
            ORDER BY I.influence DESC
        } -default "None." -align {left right}

        ht para
        ht putln "Actor support comes from the following groups."
        ht putln "Note that a group only supports an actor if"
        ht putln "its vertical relationship with the actor is at"
        ht putln "least [parm get control.support.vrelMin], and"
        ht putln "its support makes a difference only if its"
        ht putln "security is at least"
        ht putln "[parm get control.support.secMin]."
        ht para

        ht query {
            SELECT A.link                            AS 'Actor',
                   G.link                            AS 'Group',
                   format('%.2f',S.influence)        AS 'Influence',
                   qaffinity('format',S.vrel)        AS 'Vert. Rel.',
                   G.g || ' ' || 
                     qaffinity('longname',S.vrel) ||
                     ' ' || A.a                      AS 'Narrative',
                   commafmt(S.personnel)             AS 'Personnel',
                   qfancyfmt('qsecurity',S.security) AS 'Security'
            FROM support_nga AS S
            JOIN gui_groups  AS G ON (G.g = S.g)
            JOIN gui_actors  AS A ON (A.a = S.a)
            WHERE S.n=$n AND S.personnel > 0
            ORDER BY S.influence DESC, S.vrel DESC, A.a
        } -default "None." -align {left left right right left right left}

        ht para

        # Topics Yet to be Covered
        ht h2 "Future Topics" future

        ht putln "The following topics might be covered in the future:"

        ht ul {
            ht li-text { 
                <b>Conflicts:</b> Pairs of force groups with 
                significant ROEs.
            }
            ht li-text {
                <b>Significant Events:</b> Recent events in the
                neighborhood, e.g., the last turn-over of control.
            }
        }

        ht /page
        return [ht get]
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
            ht page $label
            ht h1 $label

            ht push
            rdb eval "
                SELECT $key AS id, longname 
                FROM $table 
                ORDER BY longname
            " {
                ht li { ht link /group/$id "$longname ($id)" }
            }

            set links [ht pop]

            if {$links eq ""} {
                ht putln "No entities of this type have been defined."
                ht para
            } else {
                ht ul { ht put $links }
            }

            ht /page
            
            return [ht get]
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
        ht page "Civilian Group: $g"
        ht title "$data(longname) ($g)" "Civilian Group" 

        ht linkbar {
            actors  "Relationships with Actors"
            rel     "Friends and Enemies"
            sat     "Satisfaction Levels"
            drivers "Drivers"
        }

        # NEXT, what we do depends on whether the simulation is locked
        # or not.
        let locked {[sim state] ne "PREP"}

        if {!$locked} {
            ht putln ""
            ht tinyi {
                More information will be available once the scenario has
                been locked.
            }

            ht para
        }


        ht putln "$data(longname) ($g) resides in neighborhood "
        ht link  /nbhood/$data(n) "$nb(longname) ($data(n))"
        ht put   " and has a population of "

        # TBD: Once demog_g is populated only when the simulation is locked,
        # we can update gui_civgroups to coalesce basepop into population,
        # and just use the one column.
        if {$locked} {
            ht put [commafmt $data(population)]
        } else {
            ht put [commafmt $data(basepop)]
        }

        ht put "."

        ht putln "The group's demeanor is "
        ht put   [edemeanor longname $data(demeanor)].

        if {!$locked} {
            ht /page
            return [ht get]
        }

        # NEXT, the rest of the summary
        let lf {double($data(labor_force))/$data(population)}
        let sa {double($data(subsistence))/$data(population)}
        let ur {double($data(unemployed))/$data(labor_force)}
        
        ht putln "[percent $lf] of the group is in the labor force, "
        ht put   "and [percent $sa] of the group is engaged in "
        ht put   "subsistence agriculture."
        
        ht putln "The unemployment rate is [percent $ur]."
            
        ht putln "$g's overall mood is [qsat format $data(mood)] "
        ht put   "([qsat longname $data(mood)])."
        ht para

        # Actors
        set controller [rdb onecolumn {
            SELECT controller FROM control_n WHERE n=$data(n)
        }]

        if {$controller eq ""} {
            ht putln "No actor is in control of $data(n)."
            set vrel_c -1.0
        } else {
            set vrel_c [rdb onecolumn {
                SELECT vrel FROM vrel_ga
                WHERE g=$g AND a=$controller
            }]

            set vrelMin [parm get control.support.vrelMin]
            ht putln "$g "
            ht putif {$vrel_c > $vrelMin} "supports" "does not support"
            ht put   " actor "
            ht link /actor/$controller $controller
            ht put   ", who is in control of neighborhood $data(n)."
        }

        rdb eval {
            SELECT a,vrel FROM vrel_ga
            WHERE g=$g
            ORDER BY vrel DESC
            LIMIT 1
        } fave {}

        if {$fave(vrel) > $vrel_c} {
            if {$fave(vrel) > 0.2} {
                ht putln "$g would prefer to see actor "
                ht put "$fave(a) in control of $data(n)."
            } else {
                ht putln ""
                ht putif {$controller ne ""} "In fact, "
                ht put "$g does not support "
                ht put   "any of the actors."
            }
        } else {
            ht putln ""
            ht putif {$vrel_c <= 0.2} "However, "
            ht putln "$g prefers $controller to the other candidates."
        }
    
        ht para
        
        # NEXT, Detail Block: Relationships with actors
        
        ht h2 "Relationships with Actors" actors

        ht query {
            SELECT link('/actor/' || a, pair(longname, a)) AS 'Actor',
                   qaffinity('format',vrel)                AS 'Vert. Rel.',
                   g || ' ' || qaffinity('longname',vrel) 
                     || ' ' || a                           AS 'Narrative'
            FROM vrel_ga JOIN actors USING (a)
            WHERE g=$g
            ORDER BY vrel DESC
        } -align {left right left}
        
        ht h2 "Friend and Enemies" rel

        ht query {
            SELECT link('/group/' || g, pair(longname, g)) AS 'Friend/Enemy',
                   gtype                                   AS 'Type',
                   qaffinity('format',rel)                 AS 'Relationship',
                   $g || ' ' || qaffinity('longname',rel) 
                      || ' ' || g                          AS 'Narrative'
            FROM rel_view JOIN groups USING (g)
            WHERE f=$g AND g != $g AND qaffinity('name',rel) != 'INDIFF'
            ORDER BY rel DESC
        } -align {left left right left}

        ht h2 "Satisfaction Levels" sat

        ht putln "$g's overall mood is [qsat format $data(mood)] "
        ht put   "([qsat longname $data(mood)]).  $g's satisfactions "
        ht put   "with the various concerns are as follows."
        ht para

        ht query {
            SELECT pair(C.longname, C.c)            AS 'Concern',
                   qsat('format',sat)               AS 'Satisfaction',
                   qsat('longname',sat)             AS 'Narrative',
                   qsaliency('longname',saliency)   AS 'Saliency'
            FROM gram_sat JOIN concerns AS C USING (c)
            WHERE g=$g
            ORDER BY C.c
        } -align {left right left left}

        ht h2 "Satisfaction Drivers" drivers

        ht putln "The most important satisfaction drivers for this group "
        ht put   "at the present time are as follows:"
        ht para

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

        ht query {
            SELECT format('%8.3f', acontrib) AS 'Delta',
                   driver                    AS 'ID',
                   oneliner                  AS 'Description'
            FROM temp_satcontribs
            JOIN gram_driver USING (driver)
            ORDER BY abs(acontrib) DESC
        } -default "No significant drivers." -align {right right left}

        ht /page

        return [ht get]
    }


    # html_GroupFrc url g
    #
    # url        - The URL that was requested
    # g          - The group
    #
    # Formats the summary page for force /group/{g}.

    proc html_GroupFrc {url g} {
        rdb eval {SELECT * FROM frcgroups_view WHERE g=$g} data {}

        ht page "Force Group: $g"
        ht title "$data(longname) ($g)" "Force Group" 

        ht putln "No data yet available."

        ht /page

        return [ht get]
    }

    # html_GroupOrg url g
    #
    # url        - The URL that was requested
    # g          - The group
    #
    # Formats the summary page for org /group/{g}.

    proc html_GroupOrg {url g} {
        rdb eval {SELECT * FROM orggroups_view WHERE g=$g} data {}

        ht page "Organization Group: $g"
        ht title "$data(longname) ($g)" "Organization Group" 

        ht putln "No data yet available."

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # Boilerplate

    # Locked ?-disclaimer?
    #
    # -disclaimer  - Put a disclaimer, if option is given
    #
    # Returns whether or not the simulation is locked; optionally,
    # adds a disclaimer to the output.

    proc Locked {{option ""}} {
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
}

