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
    # Object Types
    #
    # This data is used to handle the objects URLs.

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
            listIcon ::projectgui::icon::pencil12
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
            tcl/linkdict [myproc linkdict_ObjectLinks /actors] \
            text/html    [myproc html_Actors] {
                Links to all of the currently defined actors.  HTML
                content includes actor attributes.
            }

        $server register /actor/{a} {actor/(\w+)/?} \
            text/html [myproc html_Actor]           \
            "Detail page for actor {a}."

        $server register /contribs {contribs/?} \
            text/html [myproc html_Contribs]    \
            "Contributions to attitude curves."

        $server register /contribs/coop {contribs/(coop)/?} \
            text/html [myproc html_Contribs]    \
            "Contributions to cooperation curves."

        $server register /contribs/sat {contribs/(sat)/?} \
            text/html [myproc html_Contribs]    \
            "Contributions to satisfaction curves."

        $server register /contribs/sat/{g} {contribs/(sat)/(\w+)/?} \
            text/html [myproc html_Contribs]    \
            "Contributions to civilian group {g}'s satisfaction curves."

        $server register /contribs/sat/{g}/{c} {contribs/(sat)/(\w+)/(\w+)?} \
            text/html [myproc html_Contribs] {
                Contributions to civilian group {g}'s satisfaction with {c},
                where {c} may be AUT, CUL, QOL, SFT, or "mood".
            }

        $server register /docs/{path}.html {(docs/.+\.html)} \
            text/html [myproc text_File ""]                    \
            "An HTML file in the Athena docs/ tree."

        $server register /docs/{path}.txt {(docs/.+\.txt)} \
            text/plain [myproc text_File ""]                 \
            "A .txt file in the Athena docs/ tree."

        $server register /docs/{imageFile} {(docs/.+\.(gif|jpg|png))} \
            tk/image [myproc image_File ""]                           \
            "A .gif, .jpg, or .png file in the Athena /docs/ tree."

        $server register /drivers {drivers/?} \
            text/html [myproc html_Drivers] {
                A table displaying all of the attitude drivers to date.
            }

        $server register /drivers/{subset} {drivers/(\w+)/?} \
            text/html [myproc html_Drivers] {
                A table displaying all of the attitude drivers in the
                specified subset: "active", "inactive", "empty".
            }

        $server register /groups {groups/?} \
            tcl/linkdict [myproc linkdict_GroupLinks]              \
            text/html    [myproc html_Groups] {
                Links to the currently defined groups.  The HTML content
                includes group attributes.
            }

        $server register /groups/{gtype} {groups/(civ|frc|org)/?}     \
            tcl/linkdict [myproc linkdict_GroupLinks]                 \
            text/html    [myproc html_Groups]                         {
                Links to the currently defined groups of type {gtype}
                (civ, frc, or org).  The HTML content includes group
                attributes.
            }

        $server register /group/{g} {group/(\w+)/?} \
            text/html [myproc html_Group]           \
            "Detail page for group {g}."

        $server register /group/{g}/vrel {group/(\w+)/vrel} \
            text/html [myproc html_GroupVrel]       \
            "Analysis of Vertical Relationships for group {g}."

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
            tcl/linkdict [myproc linkdict_ObjectLinks /nbhoods] \
            text/html    [myproc html_Nbhoods]                          {
                Links to the currently defined neighborhoods.  The
                HTML content includes neighborhood attributes.
            }

        $server register /nbhoods/rel {nbhoods/rel/?} \
            text/html    [myproc html_Nbrel] {
                A tabular listing of neighborhood-to-neighborhood
                relationships: proximities and effects delays.
            }

        $server register /nbhood/{n} {nbhood/(\w+)/?} \
            text/html [myproc html_Nbhood]            \
            "Detail page for neighborhood {n}."

        $server register /objects {objects/?}                \
            tcl/linkdict [myproc linkdict_Objects]           \
            text/html    [myproc html_Objects "Objects"]     \
            "Links to the main Athena simulation objects."

        $server register /objects/bsystem {objects/(bsystem)/?}      \
            tcl/linkdict [myproc linkdict_Objects]                   \
            text/html    [myproc html_Objects "Belief System Objects"] {
                Links to the Athena objects for which belief 
                systems are defined.
            }

        $server register /overview {overview/?}     \
            tcl/linkdict [myproc linkdict_Overview] \
            text/html [myproc html_Overview]        \
            "Overview"

        $server register /overview/attroe {overview/attroe/?} \
            text/html [myproc html_Attroe] {
                All attacking ROEs for all force groups in all 
                neighborhoods.
            }

        $server register /overview/defroe {overview/defroe/?} \
            text/html [myproc html_Defroe] {
                All defending ROEs for all uniformed force groups in all 
                neighborhoods.
            }

        $server register /overview/deployment {overview/deployment/?} \
            text/html [myproc html_Deployment] {
                Deployment of force and organization group personnel
                to neighborhoods.
            }

        $server register /parmdb {parmdb/?} \
            tcl/linkdict [myproc linkdict_Parmdb] \
            text/html [myproc html_Parmdb] {
                An editable table displaying the contents of the
                model parameter database.  This resource can take a parameter,
                a wildcard pattern; the table will contain only
                parameters that match the pattern.
            }

        $server register /parmdb/{subset} {parmdb/(\w+)/?} \
            text/html [myproc html_Parmdb] {
                An editable table displaying the contents of the given
                subset of the model parameter database.  The subsets
                are the top-level divisions of the database, e.g.,
                "sim", "aam", "force", etc.  In addition, the subset
                "changed" will return all parameters with non-default
                values.
                This resource can take a parameter,
                a wildcard pattern; the table will contain only
                parameters that match the pattern.
            }


        $server register /sanity/onlock {sanity/onlock/?} \
            text/html [myproc html_SanityOnLock]          \
            "Scenario On-Lock sanity check report."

        $server register /sanity/ontick {sanity/ontick/?} \
            text/html [myproc html_SanityOnTick]          \
            "Simulation On-Tick sanity check report."

        $server register /sanity/strategy {sanity/strategy/?} \
            text/html [myproc html_SanityStrategy]            \
            "Sanity check report for actor strategies."

        $server register /sigevents {sigevents/?} \
            text/html [myproc html_SigEvents] {
                Significant simulation events occuring during the
                past game turn (i.e., since the Run Simulation button
                was last pressed.)
            }

        $server register /sigevents/all {sigevents/(all)/?} \
            text/html [myproc html_SigEvents] {
                Significant simulation events occuring since the
                scenario was locked.
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

    # image_TkImage udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Validates $(1) as a Tk image, and returns it as the tk/image
    # content.

    proc image_TkImage {udict matchArray} {
        upvar 1 $matchArray ""

        if {[catch {image type $(1)} result]} {
            return -code error -errorcode NOTFOUND \
                "Image not found: [dict get $udict url]"
        }

        return $(1)
    }

    #-------------------------------------------------------------------
    # App Files
    #
    # These routines serve files in the appdir tree.

    # text_File base udict matchArray
    #
    # base       - A directory within the appdir tree, or ""
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    #     (1) - *.html or *.txt
    #
    # Retrieves the file.

    proc text_File {base udict matchArray} {
        upvar 1 $matchArray ""

        set fullname [GetAppDirFile $base $(1)]

        if {[catch {
            set content [readfile $fullname]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "Page could not be found: $(1)"
        }

        return $content
    }

    # image_File base udict matchArray
    #
    # base       - A directory within the appdir tree, or ""
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    #     (1) - image file name, relative to appdir.
    #
    # Retrieves and caches the file, returning a tk/image.

    proc image_File {base udict matchArray} {
        upvar 1 $matchArray ""

        set path [dict get $udict path]

        set fullname [GetAppDirFile $base $(1)]

        # FIRST, see if we have it cached.
        if {[info exists imageCache($path)]} {
            lassign $imageCache($path) img mtime

            # FIRST, If the file exists and is unchanged, 
            # return the cached value.
            if {![catch {file mtime $fullname} newMtime] &&
                $newMtime == $mtime
            } {
                return $img
            }
            
            # NEXT, Otherwise, clear the cache.
            unset imageCache($path)
        }


        if {[catch {
            set mtime [file mtime $fullname]
            set img   [image create photo -file $fullname]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "Image file could not be found: $(1)"
        }

        set imageCache($path) [list $img $mtime]

        return $img
    }

    # GetAppDirFile base file
    #
    # base    - A base directory within the appdir
    # file    - A file at a relative path within the base directory.
    #
    # Gets the full, normalized file name, and verifies that it's
    # within the appdir.

    proc GetAppDirFile {base file} {
        set fullname [file normalize [appdir join $base $file]]

        if {[string first [appdir join] $fullname] != 0} {
            return -code error -errorcode NOTFOUND \
                "Page could not be found: $file"
        }

        return $fullname
    }

    #-------------------------------------------------------------------
    # Welcome Page

    # html_Welcome udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    # Formats and displays the welcome page from welcome.ehtml.

    proc html_Welcome {udict matchArray} {
        if {[catch {
            set text [readfile [file join $::app_sim::library welcome.ehtml]]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "The Welcome page could not be loaded from disk: $result"
        }

        return [tsubst $text]
    }

    # linkdict_Overview udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    # Returns a tcl/linkdict of overview pages

    proc linkdict_Overview {udict matchArray} {
        return {
            /sigevents { 
                label "Sig. Events: Recent" 
                listIcon ::projectgui::icon::eye12
            }
            /sigevents/all { 
                label "Sig. Events: All" 
                listIcon ::projectgui::icon::eye12
            }
            /overview/attroe { 
                label "Attacking ROEs" 
                listIcon ::projectgui::icon::eye12
            }
            /overview/defroe { 
                label "Defending ROEs" 
                listIcon ::projectgui::icon::eye12
            }
            /overview/deployment { 
                label "Personnel Deployment" 
                listIcon ::projectgui::icon::eye12
            }
            /nbhoods/rel { 
                label "Neighborhood Relationships" 
                listIcon ::projectgui::icon::eye12
            }
        }
    }

    # html_Overview udict matchArray
    #Attitude Drivers ($state
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    # Formats and displays the overview.ehtml page.

    proc html_Overview {udict matchArray} {
        if {[catch {
            set text [readfile [file join $::app_sim::library overview.ehtml]]
        } result]} {
            return -code error -errorcode NOTFOUND \
                "The Overview page could not be loaded from disk: $result"
        }

        return [tsubst $text]
    }

    #-------------------------------------------------------------------
    # Objects Tree Code

    #-------------------------------------------------------------------
    # Generic Simulation Object Code

    # linkdict_Objects udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    # Returns an objects[/*] resource as a tcl/linkdict 
    # where $(1) is the objects subset.

    proc linkdict_Objects {udict matchArray} {
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

    # html_Objects udict matchArray
    #
    # title      - The page title
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    # Returns an object/* resource as a text/html
    # where $(1) is the objects subset.

    proc html_Objects {title udict matchArray} {
        upvar 1 $matchArray ""

        set url [dict get $udict url]

        set types [linkdict_Objects $url ""]

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


    # linkdict_ObjectLinks otype udict matchArray
    #
    # otype      - objectInfo key
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns tcl/linkdict for a collection resource, based on an RDB 
    # table.

    proc linkdict_ObjectLinks {otype udict matchArray} {
        set result [dict create]

        dict with objectInfo $otype {
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


    #-------------------------------------------------------------------
    # Actor-specific handlers

    # html_Actors udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Tabular display of actor data; content depends on 
    # simulation state.

    proc html_Actors {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Actors"
        ht title "Actors"

        ht putln "The scenario currently includes the following actors:"
        ht para

        ht query {
            SELECT longlink      AS "Actor",
                   supports_link AS "Usually Supports",
                   cash_reserve  AS "Reserve, $",
                   income        AS "Income, $/week",
                   cash_on_hand  AS "On Hand, $"
            FROM gui_actors
        } -default "None." -align LLRRR

        ht /page

        return [ht get]
    }


    # html_Actor udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL

    proc html_Actor {udict matchArray} {
        upvar 1 $matchArray ""

        # Accumulate data
        set a [string toupper $(1)]

        if {![rdb exists {SELECT * FROM actors WHERE a=$a}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        # Begin the page
        rdb eval {SELECT * FROM gui_actors WHERE a=$a} data {}

        ht page "Actor: $a"
        ht title $data(fancy) "Actor" 

        ht linkbar {
            "#goals"     "Goals"
            "#sphere"    "Sphere of Influence"
            "#base"      "Power Base"
            "#eni"       "ENI Funding"
            "#forces"    "Force Deployment"
            "#attack"    "Attack Status"
            "#defense"   "Defense Status"
            "#sigevents" "Significant Events"
        }
        
        # Asset Summary
        ht putln "Fiscal assets: \$$data(income) per week, with "
        ht put "\$$data(cash_on_hand) cash on hand and "
        ht put "\$$data(cash_reserve) in reserve."

        ht putln "Groups owned: "

        ht linklist [rdb eval {
            SELECT url, g FROM gui_agroups 
            WHERE a=$a
            ORDER BY g
        }]

        ht put "."

        ht para

        # Goals
        ht subtitle "Goals" goals

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
        ht subtitle "Sphere of Influence" sphere

        if {[Locked -disclaimer]} {
            ht putln "Actor $a has support from groups in the"
            ht putln "following neighborhoods."
            ht putln "Note that an actor has influence in a neighborhood"
            ht putln "only if his total support from groups exceeds"
            ht putln [format %.2f [parm get control.support.min]].
            ht para

            set supports [rdb onecolumn {
                SELECT supports_link FROM gui_actors
                WHERE a=$a
            }]

            ht putln 

            if {$supports eq "SELF"} {
                ht putln "Actor $a usually supports himself"
            } elseif {$supports eq "NONE"} {
                ht putln "Actor $a doesn't usually support anyone,"
                ht putln "including himself,"
            } else {
                ht putln "Actor $a usually supports actor $supports"
            }

            ht putln "across the playbox."

            ht para

            ht query {
                SELECT N.longlink                      AS 'Neighborhood',
                       format('%.2f',I.direct_support) AS 'Direct Support',
                       S.supports_link                 AS 'Supports Actor',
                       format('%.2f',I.support)        AS 'Total Support',
                       format('%.2f',I.influence)      AS 'Influence'
                FROM influence_na AS I
                JOIN gui_nbhoods  AS N USING (n)
                JOIN gui_supports AS S ON (I.n = S.n AND I.a = S.a)
                WHERE I.a=$a AND (I.direct_support > 0.0 OR I.support > 0.0)
                ORDER BY I.influence DESC, I.support DESC, N.fancy
            } -default "None." -align LRLRR

            ht para
        }

        # Power Base
        ht subtitle "Power Base" base

        if {[Locked -disclaimer]} {
            set vmin [parm get control.support.vrelMin]

            ht putln "Actor $a receives direct support from the following"
            ht putln "supporters (and would-be supporters)."
            ht putln "Note that a group only supports an actor if"
            ht putln "its vertical relationship with the actor is at"
            ht putln "least $vmin."
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
            } -default "None." -align LLRRLRL

            ht para

            ht putln "In addition, actor $a receives indirect support from"
            ht putln "the following actors in the following neighborhoods:"

            ht para
            
            ht query {
                SELECT S.alonglink                      AS 'From Actor',
                       S.nlonglink                      AS 'In Nbhood',
                       format('%.2f',I.direct_support)  AS 'Contributed<br>Support'
                FROM gui_supports AS S
                JOIN influence_na AS I USING (n,a)
                WHERE S.supports = $a
                ORDER BY S.a, S.n
            } -default "None." -align LLR
        }

        # ENI Funding
        ht subtitle "ENI Funding" eni

        if {[Locked -disclaimer]} {
            ht put {
                The funding of ENI services by this actor is as
                follows.  Civilian groups judge actors by whether
                they are getting sufficient ENI services, and whether
                they are getting more or less than they expect.  
                ENI services also affect each group's mood.
            }

            ht para

            ht query {
                SELECT GA.nlink                AS 'Nbhood',
                       GA.glink                AS 'Group',
                       GA.funding              AS 'Funding<br>$/week',
                       GA.pct_credit           AS 'Actor''s<br>Credit',
                       G.pct_actual            AS 'Actual<br>LOS',
                       G.pct_expected          AS 'Expected<br>LOS',
                       G.pct_required          AS 'Required<br>LOS'
                FROM gui_service_ga AS GA
                JOIN gui_service_g  AS G USING (g)
                WHERE GA.a=$a AND numeric_funding > 0.0
                ORDER BY GA.numeric_funding;
            } -align LLRRRRR
        } 

        # Deployment
        ht subtitle "Force Deployment" forces

        if {[Locked]} {
            ht query {
                SELECT N.longlink              AS 'Neighborhood',
                       P.personnel             AS 'Personnel',
                       G.longlink              AS 'Group',
                       G.fulltype              AS 'Type'
                FROM deploy_ng AS P
                JOIN gui_agroups  AS G ON (G.g=P.g)
                JOIN gui_nbhoods  AS N ON (N.n=P.n)
                WHERE G.a=$a AND personnel > 0
            } -default "No forces are deployed."
        } else {
            ht put {
                The status quo deployment of the actor's force and
                organization group personnel is as follows; this is
                the disposition of the actor's personnel prior to the
                start of the simulation, as set on the
            }
            ht link gui:/tab/sqdeploy "Groups/Deployments tab"
            ht put "."
            ht putln {
                As such, it determines the initial neighborhood
                security levels, and the initial support and influence of
                the various actors, and hence provides the context for
                the initial strategy execution that takes place when
                the scenario is locked at time 0.
            }

            ht para

            ht query {
                SELECT N.longlink              AS 'Neighborhood',
                       P.personnel             AS 'Personnel',
                       G.longlink              AS 'Group',
                       G.fulltype              AS 'Type'
                FROM sqdeploy_ng AS P
                JOIN gui_agroups  AS G ON (G.g=P.g)
                JOIN gui_nbhoods  AS N ON (N.n=P.n)
                WHERE G.a=$a AND personnel > 0
            } -default "No forces are deployed."
        }


        ht subtitle "Attack Status" attack

        if {[Locked -disclaimer]} {
            # There might not be any.
            ht push

            rdb eval {
                SELECT nlink,
                       flink,
                       froe,
                       fpersonnel,
                       glink,
                       fattacks,
                       gpersonnel,
                       groe
                FROM gui_conflicts
                WHERE factor = $a;
            } {
                if {$fpersonnel && $gpersonnel > 0} {
                    set bgcolor white
                } else {
                    set bgcolor lightgray
                }

                ht tr bgcolor $bgcolor {
                    ht td left  { ht put $nlink      }
                    ht td left  { ht put $flink      }
                    ht td left  { ht put $froe       }
                    ht td right { ht put $fpersonnel }
                    ht td right { ht put $fattacks   }
                    ht td left  { ht put $glink      }
                    ht td right { ht put $gpersonnel }
                    ht td left  { ht put $groe       }
                }
            }

            set text [ht pop]

            if {$text ne ""} {
                ht putln "Actor $a's force groups have the following "
                ht put   "attacking ROEs."
                ht putln {
                    The background will be gray for potential conflicts,
                    i.e., those in which one or the other group (or both)
                    has no personnel in the neighborhood in question.
                }
                ht para

                ht table {
                    "Nbhood" "Attacker" "Att. ROE" "Att. Personnel"
                    "Max Attacks" "Defender" "Def. Personnel" "Def. ROE"
                } {
                    ht putln $text
                }
            } else {
                ht putln "No group owned by actor $a is attacking any other "
                ht put   "groups."
            }
        }

        ht para


        ht subtitle "Defense Status" defense

        if {[Locked -disclaimer]} {
            ht putln "Actor $a's force groups are defending against "
            ht put   "the following attacks:"
            ht para

            ht query {
                SELECT nlink                AS "Neighborhood",
                       glink                AS "Defender",
                       groe                 AS "Def. ROE",
                       gpersonnel           AS "Def. Personnel",
                       flink                AS "Attacker",
                       froe                 AS "Att. ROE",
                       fpersonnel           AS "Att. Personnel"
                FROM gui_conflicts
                WHERE gactor = $a
                AND   fpersonnel > 0
                AND   gpersonnel > 0
            } -default "None."

            ht para
        }

        # Sig Events; anchor is "sigevents"
        EntitySigEvents actor $a

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # Neighborhood-specific handlers

    # html_Nbhoods udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Tabular display of neighborhood data; content depends on 
    # simulation state.

    proc html_Nbhoods {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Neighborhoods"
        ht title "Neighborhoods"

        ht putln "The scenario currently includes the following neighborhoods:"
        ht para

        if {[sim state] eq "PREP"} {
            ht query {
                SELECT longlink      AS "Neighborhood",
                       local         AS "Local?",
                       urbanization  AS "Urbanization",
                       controller    AS "Controller",
                       vtygain       AS "VtyGain"
                FROM gui_nbhoods 
                ORDER BY longlink
            } -default "None." -align LLLLR
        } else {
            ht query {
                SELECT longlink      AS "Neighborhood",
                       local         AS "Local?",
                       urbanization  AS "Urbanization",
                       controller    AS "Controller",
                       since         AS "Since",
                       population    AS "Population",
                       mood0         AS "Mood at T0",
                       mood          AS "Mood Now",
                       vtygain       AS "VtyGain",
                       volatility    AS "Vty"
                FROM gui_nbhoods
                ORDER BY longlink
            } -default "None." -align LLLLR
        }

        ht /page

        return [ht get]
    }

    # html_Nbrel udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Tabular display of neighborhood relationship data.

    proc html_Nbrel {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Neighborhood Relationships"
        ht title "Neighborhood Relationships"

        ht putln {
            The neighborhoods in the scenario have the following 
            proximities and effects delays.
        }

        ht para

        ht query {
            SELECT m_longlink      AS "Of Nbhood",
                   n_longlink      AS "With Nbhood",
                   proximity       AS "Proximity"
            FROM gui_nbrel_mn 
            ORDER BY m_longlink, n_longlink
        } -default "No neighborhood relationships exist." -align LLL

        ht /page

        return [ht get]
    }

    # html_Nbhood udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Formats the summary page for /nbhood/{n}.

    proc html_Nbhood {udict matchArray} {
        upvar 1 $matchArray ""

        # Get the neighborhood
        set n [string toupper $(1)]

        if {![rdb exists {SELECT * FROM nbhoods WHERE n=$n}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
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
                "#civs"      "Civilian Groups"
                "#forces"    "Forces Present"
                "#eni"       "ENI Services"
                "#control"   "Support and Control"
                "#conflicts" "Force Conflicts" 
                "#sigevents" "Significant Events"
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
        ht subtitle "Civilian Groups" civs
        
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

        ht subtitle "Forces Present" forces

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


        # ENI Services
        ht subtitle "ENI Services" eni

        ht putln {
            Actors can provide Essential Non-Infrastructure (ENI) 
            services to the civilians in this neighborhood.  The level
            of service currently provided to the groups in this
            neighborhood is as follows.
        }

        ht para

        rdb eval {
            SELECT g,alink FROM gui_service_ga WHERE numeric_funding > 0.0
        } {
            lappend funders($g) $alink
        }

        ht table {
            "Group" "Funding,<br>$/week" "Actual" "Required" "Expected" 
            "Funding<br>Actors"
        } {
            rdb eval {
                SELECT g, longlink, funding, pct_required, 
                       pct_actual, pct_expected 
                FROM gui_service_g
                JOIN nbhoods USING (n)
                WHERE n = $n
                ORDER BY g
            } row {
                if {![info exists funders($row(g))]} {
                    set funders($row(g)) "None"
                }
                
                ht tr {
                    ht td left  { ht put $row(longlink)                }
                    ht td right { ht put $row(funding)                 }
                    ht td right { ht put $row(pct_actual)              }
                    ht td right { ht put $row(pct_required)            }
                    ht td right { ht put $row(pct_expected)            }
                    ht td left  { ht put [join $funders($row(g)) ", "] }
                }
            }
        }

        ht para
        ht putln {
            Service is said to be saturated when additional funding
            provides no additional service to the civilians.  We peg
            this level of service as 100% service, and express the actual,
            required, and expected levels of service as percentages.
            level required for survival.  The expected level of
            service is the level the civilians expect to receive
            based on past history.
        }

        ht para

        # Support and Control
        ht subtitle "Support and Control" control

        if {$data(controller) eq "NONE"} {
            ht putln "$n is currently in a state of chaos: "
            ht put   "no actor is in control."
        } else {
            ht putln "Actor $cdata(link) is currently in control of $n."
        }

        ht putln "The actors with support in this neighborhood are "
        ht putln "as follows."
        ht putln "Note that an actor has influence in a neighborhood"
        ht putln "only if his total support from groups exceeds"
        ht putln [format %.2f [parm get control.support.min]].
        ht para

        ht query {
            SELECT A.longlink                      AS 'Actor',
                   format('%.2f',I.influence)      AS 'Influence',
                   format('%.2f',I.direct_support) AS 'Direct Support',
                   format('%.2f',I.support)        AS 'Total Support'
            FROM influence_na AS I
            JOIN gui_actors   AS A USING (a)
            WHERE I.n = $n AND I.influence > 0.0
            ORDER BY I.influence DESC
        } -default "None." -align LR

        ht para
        ht putln "Actor support comes from the following groups."
        ht putln "Note that a group only supports an actor if"
        ht putln "its vertical relationship with the actor is at"
        ht putln "least [parm get control.support.vrelMin], or if"
        ht putln "another actor lends his direct support to the first actor."
        ht putln "See each actor's page for a detailed analysis of the actor's"
        ht putln "support and influence."
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
        } -default "None." -align LLRRLRL

        ht para

        ht subtitle "Force Conflicts" conflicts

        ht putln "The following force groups are actively in conflict "
        ht put   "in neighborhood $n:"
        ht para

        ht query {
            SELECT flink                AS "Attacker",
                   froe                 AS "Att. ROE",
                   fpersonnel           AS "Att. Personnel",
                   glink                AS "Defender",
                   groe                 AS "Def. ROE",
                   gpersonnel           AS "Def. Personnel"
            FROM gui_conflicts
            WHERE n=$n
            AND   fpersonnel > 0
            AND   gpersonnel > 0
        } -default "None."

        ht para

        ht subtitle "Significant Events" sigevents

        ht putln {
            The following are the most recent significant events 
            involving this neighborhood, oldest first.
        }

        ht para

        SigEvents -tags $n -mark run

        ht /page
        return [ht get]
    }

    #-------------------------------------------------------------------
    # Group-specific handlers

    # linkdict_GroupLinks udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    # Matches:
    #   $(1) - The egrouptype. 
    #
    # Returns tcl/linkdict for a group collection, based on an RDB 
    # table.

    proc linkdict_GroupLinks {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the otype.
        if {$(1) eq ""} {
            set otype /groups
        } else {
            set otype /groups/$(1)
        }

        # NEXT, get the results
        set result [dict create]

        dict with objectInfo $otype {
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


    # html_Groups udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns a text/html of links for a collection resource, based on 
    # an RDB table.

    proc html_Groups {udict matchArray} {
        upvar 1 $matchArray ""

        set gtype [string toupper $(1)]

        # FIRST, update the saturation and required levels of service
        # but only if we are in PREP
        service srcompute PREP

        # Begin the page
        if {$gtype eq ""} {
            ht page "Groups"
            ht title "Groups"

            ht putln "The scenario contains the following groups:"
            ht para

            ht query {
                SELECT longlink     AS "Group",
                       gtypelink    AS "Type",
                       demeanor     AS "Demeanor"
                FROM gui_groups 
                ORDER BY longlink
            } -default "None."

        } elseif {$gtype eq "CIV"} {
            ht page "Groups: Civilian"
            ht title "Groups: Civilian"

            ht putln "The scenario contains the following civilian groups:"
            ht para

            if {[sim state] eq "PREP"} {
                ht query {
                    SELECT longlink     AS "Group",
                           n            AS "Nbhood",
                           demeanor     AS "Demeanor",
                           basepop      AS "Population",
                           sap          AS "SA%",
                           req_funding  AS "Req. ENI<br>funding, $/wk",
                           sat_funding  AS "Sat. ENI<br>funding, $/wk"
                    FROM gui_civgroups 
                    ORDER BY longlink
                } -default "None." -align LLLRRRR
            } else {
                ht query {
                    SELECT longlink     AS "Group",
                           n            AS "Nbhood",
                           demeanor     AS "Demeanor",
                           population   AS "Population",
                           sap          AS "SA%",
                           req_funding  AS "Req. ENI<br>funding, $/wk",
                           sat_funding  AS "Sat. ENI<br>funding, $/wk",
                           mood0        AS "Mood at T0",
                           mood         AS "Mood Now"
                    FROM gui_civgroups 
                    ORDER BY longlink
                } -default "None." -align LLLRRRRRR
            }
        } elseif {$gtype eq "FRC"} {
            ht page "Groups: Force"
            ht title "Groups: Force"

            ht putln "The scenario contains the following force groups:"
            ht para

            ht query {
                SELECT longlink     AS "Group",
                       a            AS "Owner",
                       forcetype    AS "Force Type",
                       demeanor     AS "Demeanor",
                       personnel    AS "Personnel",
                       cost         AS "Cost, $/person/week",
                       attack_cost  AS "Cost, $/attack",
                       uniformed    AS "Uniformed?",
                       local        AS "Local?"
                FROM gui_frcgroups 
                ORDER BY longlink
            } -default "None."

        } elseif {$gtype eq "ORG"} {
            ht page "Groups: Organization"
            ht title "Groups: Organization"

            ht putln "The scenario contains the following organization groups:"
            ht para

            ht query {
                SELECT longlink     AS "Group",
                       a            AS "Owner",
                       orgtype      AS "Org. Type",
                       demeanor     AS "Demeanor",
                       personnel    AS "Personnel",
                       cost         AS "Cost, $/person/week"
                FROM gui_orggroups 
                ORDER BY longlink
            } -default "None."

        } else {
            # No special error needed; the gtype is validated by
            # the URL regexp.
            error "Unknown group type"
        }

        ht /page
        
        return [ht get]
    }
    # html_Group udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Formats the summary page for /group/{g}.

    proc html_Group {udict matchArray} {
        upvar 1 $matchArray ""

        # Get the group
        set g [string toupper $(1)]

        if {![rdb exists {SELECT * FROM groups WHERE g=$g}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        # Next, what kind of group is it?
        set gtype [group gtype $g]

        switch $gtype {
            CIV     { return [html_GroupCiv $g] }
            FRC     { return [html_GroupFrc $g] }
            ORG     { return [html_GroupOrg $g] }
            default { error "Unknown group type."    }
        }
    }

    # html_GroupCiv g
    #
    #
    # Formats the summary page for civilian /group/{g}.

    proc html_GroupCiv {g} {
        # FIRST, update the saturation and required levels of service
        # but only if we are in PREP
        service srcompute PREP

        # NEXT, get the data about this group
        rdb eval {SELECT * FROM gui_civgroups WHERE g=$g}       data {}
        rdb eval {SELECT * FROM gui_nbhoods   WHERE n=$data(n)} nb   {}
        rdb eval {SELECT * FROM gui_service_g WHERE g=$g}       eni  {}
        

        # NEXT, begin the page.
        ht page "Civilian Group: $g"
        ht title "$data(longname) ($g)" "Civilian Group" "Summary"

        # NEXT, what we do depends on whether the simulation is locked
        # or not.
        let locked {[sim state] ne "PREP"}

        ht linkbar {
            "#actors"     "Relationships with Actors"
            "#rel"        "Friends and Enemies"
            "#eni"        "ENI Service"
            "#sat"        "Satisfaction Levels"
            "#drivers"    "Drivers"
            "#sigevents"  "Significant Events"
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

        if {[Locked]} {
            # NEXT, the rest of the summary
            let lf {double($data(labor_force))/$data(population)}
            let sa {double($data(subsistence))/$data(population)}
            let ur {double($data(unemployed))/$data(labor_force)}
        
            ht putln "[percent $lf] of the group is in the labor force, "
            ht put   "and [percent $sa] of the group is engaged in "
            ht put   "subsistence agriculture."
        
            ht putln "The unemployment rate is [percent $ur]."

            ht putln "The group is receiving "

            if {$eni(actual) < $eni(required)} {
                ht put "less than the required level of "
            } elseif {$eni(pct_actual) eq $eni(pct_expected)} {
                ht put "about the expected amount of "
            } elseif {$eni(actual) < $eni(expected)} {
                ht put "less than the expected amount of "
            } else {
                ht put "more than the expected amount of "
            }

            ht put "ENI services."

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
                ht putif {$vrel_c > $vrelMin} "favors" "does not favor"
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
                    ht put "$g does not favor "
                    ht put   "any of the actors."
                }
            } else {
                ht putln ""
                ht putif {$vrel_c <= 0.2} "However, "
                ht putln "$g prefers $controller to the other candidates."
            }
        }

        ht para
        
        # NEXT, Detail Block: Relationships with actors

        if {[Locked]} {
            ht subtitle "Relationships with Actors" actors \
                /group/$g/vrel "View Analysis"
        } else {
            ht subtitle "Relationships with Actors" actors 
        }

        if {[Locked -disclaimer]} {
            ht query {
                SELECT A.longlink                  AS 'Actor',
                       qaffinity('format',V.vrel)  AS 'Vertical<br>Rel.',
                       V.g || ' ' || qaffinity('longname', V.vrel) 
                           || ' ' || V.a           AS 'Narrative',
                       format('%.2f',S.direct_support) 
                                                   AS 'Direct<br>Support',
                       format('%.2f',S.support)    AS 'Actual<br>Support',
                       format('%.2f',S.influence)  AS 'Contributed<br>Influence'
                FROM vrel_ga AS V 
                JOIN support_nga AS S USING (g,a)
                JOIN gui_actors AS A USING (a)
                WHERE V.g=$g
                ORDER BY V.vrel DESC
            } -align LRLRRR
        }
        
        ht subtitle "Friend and Enemies" rel

        ht query {
            SELECT link('/group/' || g, pair(longname, g)) AS 'Friend/Enemy',
                   gtype                                   AS 'Type',
                   qaffinity('format',rel)                 AS 'Relationship',
                   $g || ' ' || qaffinity('longname',rel) 
                      || ' ' || g                          AS 'Narrative'
            FROM rel_view JOIN groups USING (g)
            WHERE f=$g AND g != $g AND qaffinity('name',rel) != 'INDIFF'
            ORDER BY rel DESC
        } -align LLRL

        ht subtitle "ENI Services" eni

        if {[Locked]} {
            ht putln "$g can receive Essential Non-Infrastructure (ENI) "
            ht put   "services from actors. At present, $g is receiving "
            ht put   "\$$eni(funding)/week worth of "
            ht put   "ENI service.  $g's saturation level of funding is "
            ht put   "\$$data(sat_funding)/week, so $g is receiving "
            ht put   "$eni(pct_actual) of the saturation level of ENI service. "
            ht put   "$g expects to receive $eni(pct_expected); and "
            ht put   "$eni(pct_required) is the minimum required for survival. "
            ht put   "Thus, $g's required level of funding is "
            ht put   "\$$data(req_funding)/week. "
            ht putln "$g's <i>needs</i> factor is $eni(needs), and $g's "
            ht put   "<i>expectf</i> factor is $eni(expectf). "
            ht para

            if {$eni(actual) > 0.0} {
                ht putln "The following actors are providing ENI service to $g:"
                ht para

                ht query {
                    SELECT alonglink                   AS 'Actor',
                           funding                     AS 'Funding, $/week',
                           pct_credit                  AS 'Credit'
                    FROM gui_service_ga
                    WHERE g=$g
                    ORDER BY credit DESC
                } -align LRR
            }
        } else {
            ht putln "$g can receive Essential Non-Infrastructure (ENI) "
            ht put   "services from actors. "
            ht put   "$g's saturation level of funding is "
            ht put   "\$$data(sat_funding)/week and "
            ht putln "$g's required level of funding is "
            ht put   "\$$data(sat_funding)/week."
            ht put   "<br><br>"
            ht tinyi {
                More information will be available once the scenario has
                been locked.
            }
            ht para
        }

        ht subtitle "Satisfaction Levels" sat

        if {[Locked -disclaimer]} {
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
        } -align LRLL
        }

        ht subtitle "Satisfaction Drivers" drivers

        if {[Locked -disclaimer]} {
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
        } -default "No significant drivers." -align RRL
        }

        ht subtitle "Significant Events" sigevents

        if {[Locked -disclaimer]} {
        ht putln {
            The following are the most recent significant events 
            involving this group, oldest first.
        }

        ht para

        SigEvents -tags [list $g $data(n)] -mark run
        }
        ht /page

        return [ht get]
    }


    # html_GroupFrc g
    #
    # g          - The group
    #
    # Formats the summary page for force /group/{g}.

    proc html_GroupFrc {g} {
        rdb eval {SELECT * FROM frcgroups_view WHERE g=$g} data {}

        ht page "Force Group: $g"
        ht title "$data(longname) ($g)" "Force Group" 

        ht linkbar {
            "#deployment" "Deployment"
            "#attack"     "Attack Status"
            "#defense"    "Defense Status"
            "#sigevents"  "Significant Events"
        }

        # Deployment; anchor is "deployment".
        html_GroupDeployment $g


        ht subtitle "Attack Status" attack

        if {[Locked -disclaimer]} {
            # There might not be any.
            ht push

            rdb eval {
                SELECT nlink,
                       froe,
                       fpersonnel,
                       glink,
                       fattacks,
                       gpersonnel,
                       groe
                       FROM gui_conflicts
                WHERE f = $g;
            } {
                if {$fpersonnel && $gpersonnel > 0} {
                    set bgcolor white
                } else {
                    set bgcolor lightgray
                }

                ht tr bgcolor $bgcolor {
                    ht td left  { ht put $nlink      }
                    ht td left  { ht put $froe       }
                    ht td right { ht put $fattacks   }
                    ht td left  { ht put $glink      }
                    ht td right { ht put $gpersonnel }
                    ht td left  { ht put $groe       }
                }
            }

            set text [ht pop]

            if {$text ne ""} {
                ht putln "Group $g has the following attacking ROEs."
                ht putln {
                    The background will be gray for potential conflicts, 
                    i.e., those in which one or the other group (or both)
                    has no personnel in the neighborhood in question.
                }
                ht para

                ht table {
                    "Nbhood" "Att. ROE" "Max Attacks" "Defender" 
                    "Personnel" "Def. ROE"
                } {
                    ht putln $text
                }
            } else {
                ht putln "Group $g is not attacking any other groups."
            }
        }

        ht para


        ht subtitle "Defense Status" defense

        if {[Locked -disclaimer]} {
            ht putln "Group $g is defending against attack from the following "
            ht put   "groups:"
            ht para

            ht query {
                SELECT nlink                AS "Neighborhood",
                       groe                 AS "Def. ROE",
                       flink                AS "Attacker",
                       froe                 AS "Att. ROE",
                       fpersonnel           AS "Att. Personnel"
                FROM gui_conflicts
                WHERE g=$g
                AND   fpersonnel > 0
                AND   gpersonnel > 0
            } -default "None."

            ht para
        }

        # Significant events: anchor is "sigevents"
        EntitySigEvents group $g

        return [ht get]
    }

    # html_GroupOrg g
    #
    # g          - The group
    #
    # Formats the summary page for org /group/{g}.

    proc html_GroupOrg {g} {
        rdb eval {SELECT * FROM orggroups_view WHERE g=$g} data {}

        ht page "Organization Group: $g"
        ht title "$data(longname) ($g)" "Organization Group" 

        ht linkbar {
            "#deployment" "Deployment"
            "#sigevents"  "Significant Events"
        }

        # Deployment; anchor is "deployment".
        html_GroupDeployment $g

        # Significant events: anchor is "sigevents"
        EntitySigEvents group $g

        ht /page

        return [ht get]
    }

    # html_GroupDeployment g
    #
    # g   - A FRC/ORG group.
    #
    # Outputs the deployment for group g, with title; the 
    # anchor is "deployment".  During PREP, shows the status
    # quo deployment, with explanation.

    proc html_GroupDeployment {g} {
        ht subtitle "Deployment" deployment

        if {[Locked]} {
            ht put "Group $g is currently deployed into the following "
            ht put "neighborhoods:" 

            ht para

            ht query {
                SELECT N.longlink     AS "Neighborhood",
                       D.personnel    AS "Personnel"
                FROM deploy_ng AS D
                JOIN gui_nbhoods AS N ON (D.n = N.n)
                WHERE D.g = $g AND D.personnel > 0
                ORDER BY N.longlink
            } -default "No personnel are deployed." -align LR
        } else {
            ht put "The status quo deployment of group $g is as follows."
            ht put {
                This is the disposition of group personnel prior to
                the beginning of simulation, as set on the
            }
            ht link gui:/tab/sqdeploy "Groups/Deployments tab"
            ht put "."
            ht putln { 
                As such, it sets the context for
                the first strategy execution when the scenario is
                locked.  For example, it determines neighborhood
                security levels, and each actor's initial 
                support and influence.
            }

            ht para

            ht query {
                SELECT N.longlink     AS "Neighborhood",
                       D.personnel    AS "Personnel"
                FROM sqdeploy_ng AS D
                JOIN gui_nbhoods AS N ON (D.n = N.n)
                WHERE D.g = $g AND D.personnel > 0
                ORDER BY N.longlink
            } -default "No personnel are deployed." -align LR
        }

        ht para
    }

    # html_GroupVrel udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Formats the analysis page for /group/{g}/vrel.

    proc html_GroupVrel {udict matchArray} {
        upvar 1 $matchArray ""

        # Get the group
        set g [string toupper $(1)]

        if {![rdb exists {SELECT * FROM groups WHERE g=$g}]} {
            return -code error -errorcode NOTFOUND \
                "Unknown entity: [dict get $udict url]."
        }

        # Next, what kind of group is it?
        set gtype [group gtype $g]

        switch $gtype {
            CIV     { return [html_GroupCivVrel   $g] }
            FRC     { return [html_GroupOtherVrel $g] }
            ORG     { return [html_GroupOtherVrel $g] }
            default { error "Unknown group type."          }
        }
    }

    # html_GroupCivVrel g
    #
    # g          - The group
    #
    # Formats the vrel analysis page for civilian /group/{g}.

    proc html_GroupCivVrel {g} {
        # FIRST,  get the data about this group
        rdb eval {SELECT * FROM gui_civgroups WHERE g=$g} data {}

        # NEXT, begin the page.
        ht page "Vertical Relationships: $g"
        ht title $data(longlink) "Civilian Group" \
            "Analysis: Vertical Relationships"

        # NEXT, what we do depends on whether the simulation is locked
        # or not.
        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        # NEXT, Analysis of vertical relationships

        ht putln "
            The vertical relationship <i>V.ga</i> between
            civilian group $g and actor <i>a</i> varies over
            time according to a number of factors: mood, level of basic
            services, etc.  These factors are described following the
            table.
        "

        ht para

        ht query {
            SELECT A.link,
                   qaffinity('format',V.vrel),
                   qaffinity('format',B.bvrel),
                   CASE WHEN V.dv_mood == 0.0 THEN '0'
                        ELSE qmag('name',V.dv_mood) END,
                   CASE WHEN V.dv_eni == 0.0 THEN '0'
                        ELSE qmag('name',V.dv_eni) END
            FROM vrel_ga AS V
            JOIN gui_actors AS A USING (a)
            JOIN bvrel_tga AS B ON (B.t=V.bvt AND B.g=V.g AND B.a=V.a)
            WHERE V.g=$g
            ORDER BY vrel DESC
        } -labels {
            "Actor a"
            "V.ga"
            "= BV.ga(t.control)"
            "+ &Delta;V.mood"
            "+ &Delta;V.eni"
        } -align LRRRR

        ht subtitle "Description"

        ht putln "
            The vertical relationship <i>V.ga</i> is recomputed
            every week.  Initially it depends on group <i>g</i>'s 
            affinity for actor <i>a</i>, as determined by their 
            belief systems.  It is affected over time by a number 
            of factors.
        "
        ht para

        ht putln {
            At any given time, <i>V.ga</i> is computed as a base
            vertical relationship plus a number of deltas.
            The base value, <i>BV.ga</i>, is set when control of
            <i>g</i>'s neighborhood shifts; it depends on whether
            actor <i>a</i> was in control before or after the 
            transition.
        }

        ht para

        ht putln {
            The remaining terms depend on group <i>g</i>'s environment
            at the time of assessment.  The deltas are expressed as
            magnitude symbols (TBD: Need link to on-line help.)
        }

        ht putln <dl>
        ht putln "<dt><b>&Delta;V.mood</b>"
        ht putln <dd>
        ht put {
            Change in <i>V</i> due to changes in mood.  This term is
            non-zero if <i>g's</i> mood has changed signficantly since
            the last shift in control.
        }
        ht para

        ht putln "<dt><b>&Delta;V.eni</b>"
        ht putln <dd>
        ht put {
            Change in <i>V</i> due to the current level of 
            Essential Non-Infrastructure (ENI) services
            provided to the group.  This term is non-zero if the level of 
            ENI servies is better or worse than expected.
        }
        ht putln </dl>
        
        ht /page

        return [ht get]
    }

    # html_GroupOtherVrel g
    #
    # g          - The group
    #
    # Formats the vrel analysis page for non-civilian /group/{g}.

    proc html_GroupOtherVrel {g} {
        # FIRST,  get the data about this group
        rdb eval {SELECT * FROM gui_groups WHERE g=$g} data {}

        # NEXT, begin the page.
        ht page "Vertical Relationships: $g"

        if {$data(gtype) eq "FRC"} {
            set over "Force Group"
        } else {
            set over "Organization Group"
        }

        ht title $data(longlink) $over \
            "Analysis: Vertical Relationships"

        # NEXT, what we do depends on whether the simulation is locked
        # or not.
        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        # NEXT, Analysis of vertical relationships

        ht putln "
            Force and organization groups inherit their relationships
            from the actors that own them.  Consequently, the vertical
            relationship <i>V.ga</i> between group $g and its owning actor 
            is 1.0; and its vertical relationship with every other actor
            is simply the affinity of its owning actor for the other
            actor based on their belief systems.
        "

        ht para

        ht query {
            SELECT A.link,
                   qaffinity('format',V.vrel)
            FROM vrel_ga AS V
            JOIN gui_actors AS A USING (a)
            WHERE V.g=$g
            ORDER BY V.vrel DESC
        } -labels {
            "Actor a"
            "V.ga"
        } -align LR

        
        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # Overview Handlers


    # html_Attroe udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches; ignored.
    #
    # All Attacking ROEs.

    proc html_Attroe {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Attacking ROEs"
        ht title "Attacking ROEs"

        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        # There might not be any.
        ht push

        rdb eval {
            SELECT nlink,
                   flink,
                   froe,
                   fpersonnel,
                   glink,
                   fattacks,
                   gpersonnel,
                   groe
            FROM gui_conflicts
        } {
            if {$fpersonnel && $gpersonnel > 0} {
                set bgcolor white
            } else {
                set bgcolor lightgray
            }

            ht tr bgcolor $bgcolor {
                ht td left {
                    ht put $nlink
                }

                ht td left {
                    ht put $flink
                }

                ht td left {
                    ht put $froe
                }

                ht td right {
                    ht put $fpersonnel
                }

                ht td right {
                    ht put $fattacks
                }

                ht td left {
                    ht put $glink
                }

                ht td right {
                    ht put $gpersonnel
                }

                ht td left {
                    ht put $groe
                }
            }
        }

        set text [ht pop]

        if {$text ne ""} {
            ht putln {
                The following attacking ROEs are in force across the
                playbox.  The background will be gray for potential conflicts,
                i.e., those in which one or the other group (or both)
                has no personnel in the neighborhood in question.
            }
            ht para

            ht table {
                "Nbhood" "Attacker" "Att. ROE" "Att. Personnel"
                "Max Attacks" "Defender" "Def. Personnel" "Def. ROE"
            } {
                ht putln $text
            }
        } else {
            ht putln "No attacking ROEs are in force."
        }

        ht para

        ht /page
        
        return [ht get]
    }


    # html_Defroe udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches; ignored.
    #
    # All Defending ROEs.

    proc html_Defroe {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Defending ROEs"
        ht title "Defending ROEs"

        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }


        ht putln {
            Uniformed force groups are defending themselves given the
            following ROEs across the playbox:
        }

        ht para

        ht query {
            SELECT ownerlink           AS "Owning Actor",
                   glink               AS "Defender",
                   nlink               AS "Neighborhood",
                   roe                 AS "Def. ROE",
                   personnel           AS "Def. Personnel"
            FROM gui_defroe
            WHERE personnel > 0
            ORDER BY owner, g, n
        } -default "None."

        ht para

        ht /page
        
        return [ht get]
    }

    # html_Deployment udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches; ignored.
    #
    # Returns a text/html of FRC/ORG group deployment.

    proc html_Deployment {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        ht page "Personnel Deployment"
        ht title "Personnel Deployment"

        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        ht putln {
            Force and organization group personnel
            are deployed to neighborhoods as follows:
        }
        ht para

        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        ht query {
            SELECT G.longlink     AS "Group",
                   G.gtype        AS "Type",
                   N.longlink     AS "Neighborhood",
                   D.personnel    AS "Personnel"
            FROM deploy_ng AS D
            JOIN gui_agroups AS G USING (g)
            JOIN gui_nbhoods AS N ON (D.n = N.n)
            WHERE D.personnel > 0
            ORDER BY G.longlink, N.longlink
        } -default "No personnel are deployed." -align LLLR

        ht /page
        
        return [ht get]
    }





    #-------------------------------------------------------------------
    # Sanity Checks: On-Lock

    # html_SanityOnLock udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Formats the on-lock sanity check report for
    # /sanity/onlock.  Note that sanity is checked by the
    # "sanity onlock report" command; this command simply reports on the
    # results.

    proc html_SanityOnLock {udict matchArray} {
        upvar 1 $matchArray ""

        # NEXT, begin the page.
        ht page "Sanity Check: On-Lock" {
            ht title "On-Lock" "Sanity Check"

            ht putln {
                Athena checks the scenario's sanity before
                allowing the user to lock the scenario and begin
                simulation.
            }

            ht para
            
            sanity onlock report ::appserver::ht
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # Sanity Checks: On-Tick

    # html_SanityOnTick udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Formats the on-tick sanity check report for
    # /sanity/ontick.  Note that sanity is checked by the
    # "sanity ontick report" command; this command simply reports on the
    # results.

    proc html_SanityOnTick {udict matchArray} {
        upvar 1 $matchArray ""

        # NEXT, begin the page.
        ht page "Sanity Check: On-Tick" {
            ht title "On-Tick" "Sanity Check"

            ht putln {
                Athena checks the scenario's sanity before
                advancing time at each time tick.
            }


            ht para

            if {[sim state] ne "PREP"} {
                sanity ontick report ::appserver::ht
            } else {
                ht putln {
                    This check cannot be performed until after the scenario
                    is locked.
                }

                ht para
            }
        }

        return [ht get]
    }

    #-------------------------------------------------------------------
    # /contribs


    # html_Contribs udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches.
    #
    # Matches:
    #   $(1) - "sat" or "coop" -- Only "sat" is implemented at the moment.
    #
    #   If $(1) is "sat"
    #   $(2) - civilan group name
    #   $(3) - civilian concern name, or "MOOD"
    #
    # Returns a page that documents the contributions to a particular
    # attitude curve, or navigation pages that drill down to it.

    proc html_Contribs {udict matchArray} {
        upvar 1 $matchArray ""

        # Case 1: no attitude type given.
        if {$(1) eq ""} {
            ht page "Contributions to Attitude Curves" {
                ht title "Contributions to Attitude Curves"

                ht ul {
                    ht li {
                        ht link /contribs/sat "Satisfaction"
                    }
                    ht li {
                        ht link /contribs/coop "Cooperation"
                    }
                }
            }

            return [ht get]
        }

        # Case 2: sat contributions
        if {$(1) eq "sat"} {
            # FIRST, get the group and concern
            set g [string toupper $(2)]
            set c [string toupper $(3)]


            # Case 2.1: No group
            if {$g eq ""} {
                ht page "Contributions to Satisfaction" {
                    ht title "Contributions to Satisfaction"
                    
                    ht putln "Of group:"
                    ht para

                    ht ul {
                        foreach g [lsort [civgroup names]] {
                            ht li {
                                ht link /contribs/sat/$g $g
                            }
                        }
                    }
                }
                
                return [ht get]
            }
            
            # Validate the group
            if {[catch {civgroup validate $g} result]} {
                return -code error -errorcode NOTFOUND \
                    $result
            }

            # Case 2.2: Group, but no concern
            if {$c eq ""} {
                ht page "Contributions to Satisfaction of $g" {
                    ht title "Contributions to Satisfaction of $g"
                    
                    ht putln "With respect to:"
                    ht para

                    ht ul {
                        ht li {
                            ht link /contribs/sat/$g/mood Mood
                        }

                        foreach c [lsort [econcern names]] {
                            ht li {
                                ht link /contribs/sat/$g/$c $c
                            }
                        }
                    }
                }
                
                return [ht get]
            }


            # Validate the concern
            if {[catch {ptype c+mood validate $c} result]} {
                return -code error -errorcode NOTFOUND \
                    $result
            }


            # Case 2.3: Group and Concern
            return [html_ContribsSat $g $c $udict]

        }

        # Case 3: coop contributions
        if {$(1) eq "coop"} {
            return -code error -errorcode NOTFOUND \
                "The ability to query contributions to cooperation has not yet been implemented."

        }

        # This should never happen, as there's no matching URL 
        # registered with the server.
        return -code error -errorcode NOTFOUND \
            "Unknown attitude type: \"$(1)\""
    }

    # html_ContribsSat g c udict
    #
    # g          - The civilian group
    # c          - A concern name, or "MOOD"
    # udict      - A dictionary containing the URL components
    #
    #
    # Returns a page that documents the contributions to the given
    # satisfaction curve.
    #
    # The udict query is a "parm=value[+parm=value]" string with the
    # following parameters:
    #
    #    top    Max number of top contributors to include.
    #    start  Start time in ticks
    #    end    End time in ticks
    #
    # Unknown query parameters and invalid query values are ignored.

    proc html_ContribsSat {g c udict} {
        # FIRST, begin to format the report
        ht title "Contributions to Satisfaction (to $c of $g)"
        ht page "Contributions to Satisfaction (to $c of $g)"

        # NEXT, if we're not locked we're done.
        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        # NEXT, get the query parameters
        set q [split [dict get $udict query] "=+"]

        set top   [Restrict $q top   ipositive 20]
        set start [Restrict $q start iquantity 0]
        set end   [Restrict $q end   iquantity [simclock now]]

        # NEXT, fix up the concern
        if {$c eq "MOOD"} {
            set c "mood"
        }

        # NEXT, Get the drivers for this time period.
        aram sat drivers    \
            -group   $g     \
            -concern $c     \
            -start   $start \
            -end     $end

        # NEXT, pull them into a temporary table, in sorted order,
        # so that we can use the "rowid" as the rank.  Note that
        # if we asked for "mood", we have all of the
        # concerns as well; only take what we asked for.
        # Note: This query is passed as a string, because the LIMIT
        # is an integer, not an expression, so we can't use an SQL
        # variable.
        rdb eval "
            DROP TABLE IF EXISTS temp_satcontribs;
    
            CREATE TEMP TABLE temp_satcontribs AS
            SELECT driver,
                   acontrib
            FROM gram_sat_drivers
            WHERE g=\$g AND c=\$c
            ORDER BY abs(acontrib) DESC
            LIMIT $top
        "

        # NEXT, get the total contribution to this curve in this
        # time window.
        # for.

        set totContrib [rdb onecolumn {
            SELECT total(abs(acontrib))
            FROM gram_sat_drivers
            WHERE g=$g AND c=$c
        }]

        # NEXT, get the total contribution represented by the report.

        set totReported [rdb onecolumn {
            SELECT total(abs(acontrib)) 
            FROM temp_satcontribs
        }]


        # NEXT, format the body of the report.

        ht putln "Contributions to Satisfaction Curve:"
        ht para
        ht ul {
            ht li {
                ht put "Group: "
                ht put [GroupLongLink $g]
            }
            ht li {
                ht put "Concern: $c"
            }
            ht li {
                ht put "Window: [simclock toZulu $start] to "

                if {$end == [simclock now]} {
                    ht put "now"
                } else {
                    ht put "[simclock toZulu $end]"
                }
            }
        }

        ht para

        # NEXT, format the body of the report.
        ht query {
            SELECT format('%4d', temp_satcontribs.rowid) AS "Rank",
                   format('%8.3f', acontrib)             AS "Actual",
                   driver                                AS "ID",
                   name                                  AS "Name",
                   oneliner                              AS "Description"
            FROM temp_satcontribs
            JOIN gram_driver USING (driver);

            DROP TABLE temp_satcontribs;
        }  -default "None known." -align "RRRLL"

        ht para

        if {$totContrib > 0.0} {
            set pct [percent [expr {$totReported / $totContrib}]]

            ht putln "Reported events and situations represent"
            ht putln "$pct of the contributions made to this curve"
            ht putln "during the specified time window."
            ht para
        }

        ht /page

        return [ht get]
    }


    #-------------------------------------------------------------------
    # /drivers/{subset}


    # html_Drivers udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches.
    #
    # Matches:
    #   $(1) - The drivers subset: active, inactive, or empty, or "" 
    #          for all.
    #
    # Returns a page that documents the current attitude
    # drivers.

    proc html_Drivers {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the driver state
        if {$(1) eq ""} {
            set state "all"
        } else {
            set state $(1)
        }

        # NEXT, set the page title
        ht page "Attitude Drivers ($state)"
        ht title "Attitude Drivers ($state)"

        ht putln "The following drivers are affecting or have affected"
        ht putln "attitudes (satisfaction or cooperation) in the playbox."
        ht para

        # NEXT, get summary statistics
        rdb eval {
            DROP VIEW IF EXISTS temp_report_driver_view;
            DROP TABLE IF EXISTS temp_report_driver_effects;
            DROP TABLE IF EXISTS temp_report_driver_contribs;

            CREATE TEMPORARY TABLE temp_report_driver_effects AS
            SELECT driver, 
                   CASE WHEN min(ts) IS NULL THEN 0
                                             ELSE 1 END AS has_effects
            FROM gram_driver LEFT OUTER JOIN gram_effects USING (driver)
            GROUP BY driver;

            CREATE TEMPORARY TABLE temp_report_driver_contribs AS
            SELECT driver, 
                   CASE WHEN min(time) IS NULL 
                        THEN 0
                        ELSE 1 END                  AS has_contribs,
                   CASE WHEN min(time) NOT NULL    
                        THEN tozulu(min(time)) 
                        ELSE '' END                 AS ts,
                   CASE WHEN max(time) NOT NULL    
                        THEN tozulu(max(time)) 
                        ELSE '' END                 AS te
            FROM gram_driver LEFT OUTER JOIN gram_contribs USING (driver)
            GROUP BY driver;

            CREATE TEMPORARY VIEW temp_report_driver_view AS
            SELECT gram_driver.driver AS driver, 
                   dtype, 
                   name, 
                   oneliner,
                   CASE WHEN NOT has_effects AND NOT has_contribs 
                        THEN 'empty'
                        WHEN NOT has_effects AND has_contribs  
                        THEN 'inactive'
                        ELSE 'active'
                        END AS state,
                   ts,
                   te
            FROM gram_driver
            JOIN temp_report_driver_effects USING (driver)
            JOIN temp_report_driver_contribs USING (driver)
            ORDER BY driver DESC;
        }

        # NEXT, produce the query.
        set query {
            SELECT driver   AS "ID",
                   dtype    AS "Type",
                   name     AS "Name",
                   oneliner AS "Description",
                   state    AS "State",
                   ts       AS "Start Time",
                   te       AS "End Time"
            FROM temp_report_driver_view
        }

        if {$state ne "all"} {
            append query "WHERE state = '$state'"
        }

        # NEXT, generate the report text
        ht query $query \
            -default "No drivers found." \
            -align   RLLLLLL

        rdb eval {
            DROP VIEW  temp_report_driver_view;
            DROP TABLE temp_report_driver_effects;
            DROP TABLE temp_report_driver_contribs;
        }

        ht /page

        return [ht get]
    }

    #-------------------------------------------------------------------
    # Parmdb

    # linkdict_Parmdb udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    # Returns a parmdb resource as a tcl/linkdict.

    proc linkdict_Parmdb {udict matchArray} {
        dict set result /parmdb/changed label "Changed"
        dict set result /parmdb/changed listIcon ::projectgui::icon::pencil12

        foreach subset {
            sim
            aam
            activity
            control
            dam
            demsit
            demog
            econ
            ensit
            force
            gram
            rmf
            service
            strategy
        } {
            set url /parmdb/$subset

            dict set result $url label "$subset.*"
            dict set result $url listIcon ::projectgui::icon::pencil12
        }

        return $result
    }

    # html_Parmdb udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches.
    #
    # Matches:
    #   $(1) - The major subset, or "changed".
    #
    # Returns a page that documents the current parmdb(5) values.
    # There can be a query; if so, it is treated as a glob-pattern,
    # and only parameters that match are included.

    proc html_Parmdb {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, are we looking at all parms or only changed parms?
        if {$(1) eq "changed"} {
            set initialSet nondefaults
        } else {
            set initialSet names
        }

        # NEXT, get the pattern, if any.
        set pattern [dict get $udict query]

        # NEXT, get the base set of parms.
        if {$pattern eq ""} {
            set parms [parm $initialSet]
        } else {
            set parms [parm $initialSet $pattern]
        }

        # NEXT, if some subset other than "changed" was given, find
        # only those that match.

        if {$(1) ne "" && $(1) ne "changed"} {
            set subset "$(1).*"
            
            set allParms $parms
            set parms [list]

            foreach parm $allParms {
                if {[string match $subset $parm]} {
                    lappend parms $parm
                }
            }
        }

        # NEXT, get the title

        set parts ""

        if {$(1) eq "changed"} {
            lappend parts "Changed"
        } elseif {$(1) ne ""} {
            lappend parts "$(1).*"
        }

        if {$pattern ne ""} {
            lappend parts [htools escape $pattern]
        }

        set title "Model Parameters: "

        if {[llength $parts] == 0} {
            append title "All"
        } else {
            append title [join $parts ", "]
        }

        ht page $title
        ht title $title

        # NEXT, if no parameters are found, note it and return.
        if {[llength $parms] == 0} {
            ht putln "No parameters match the query."
            ht para
            
            ht /page
            return [ht get]
        }

        ht table {"Parameter" "Default Value" "Current Value" ""} {
            foreach parm $parms {
                ht tr {
                    ht td left {
                        set path [string tolower [join [split $parm .] /]]
                        ht link my://help/parmdb/$path $parm 
                    }
                    
                    ht td left {
                        set defval [htools escape [parm getdefault $parm]]
                        ht putln <tt>$defval</tt>
                    }

                    ht td left {
                        set value [htools escape [parm get $parm]]

                        if {$value eq $defval} {
                            set color black
                        } else {
                            set color "#990000"
                        }

                        ht putln "<font color=$color><tt>$value</tt></font>"
                    }

                    ht td left {
                        if {[parm islocked $parm]} {
                            ht image ::marsgui::icon::locked
                        } elseif {![order cansend PARM:SET]} {
                            ht image ::marsgui::icon::pencil22d
                        } else {
                            ht putln "<a href=\"gui:/order/PARM:SET?parm=$parm\">"
                            ht image ::marsgui::icon::pencil22
                            ht putln "</a>"
                        }
                    }
                }
            }
        }

        return [ht get]
    }




    #-------------------------------------------------------------------
    # Significant Events

    # html_SigEvents udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches.  $(1) is "" or "all".
    #
    # Returns a text/html of significant events.

    proc html_SigEvents {udict matchArray} {
        upvar 1 $matchArray ""

        # Begin the page
        if {$(1) eq "all"} {
            ht page "Significant Events: All"
            ht title "Significant Events: All"

            ht linkbar {
                /sigevents "Events Since Last Advance"
            }

            ht putln {
                The following significant simulation events have
                occurred since the scenario was locked.  Newer events
                are listed first.
            }

            set opts -desc
        } else {
            ht page "Significant Events: Last Advance"
            ht title "Significant Events: Last Advance"

            ht linkbar {
                /sigevents/all "All Significant Events"
            }

            ht putln {
                The following signficant events occurred during the previous
                time advance.
            }

            set opts [list -mark run]
        }

        ht para

        SigEvents {*}$opts

        ht /page
        
        return [ht get]
    }

    # SigEvents ?options...?
    #
    # Options:
    #
    # -tags     - A list of sigevents tags
    # -mark     - A sigevent mark type
    # -desc     - List in descending order.
    #
    # Formats the sigevents as HTML, in order of occurrence.  If
    # If -tags is given, then only events with those tags are included.
    # If -mark is given, then only events since the most recent mark of
    # the given type are included.  If -desc is given, sigevents are
    # shown in reverse order.

    proc SigEvents {args} {
        # FIRST, process the options.
        array set opts {
            -tags ""
            -mark "lock"
            -desc 0
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
                    error "Unknown SigEvents option: \"$opt\""
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
            ht table {"Day" "Zulu Time" "Model" "Narrative"} {
                ht putln $text
            }

            ht para
        } else {
            ht putln "No significant events occurred."
        }
    }

    # EntitySigEvents etype ename
    #
    # etype   - The entity type, e.g., "group"
    # ename   - The entity name, e.g., $g
    #
    # Outputs a "Signficant Events" block with title and unlocked
    # scenario disclaimer.

    proc EntitySigEvents {etype ename} {
        ht subtitle "Significant Events" sigevents

        if {[Locked -disclaimer]} {
            ht putln "
                The following are the most recent significant events 
                involving this $etype, oldest first.
            "

            ht para

            SigEvents -tags $ename -mark run
        }
    }

    #-------------------------------------------------------------------
    # Sanity Checks: Strategy

    # html_SanityStrategy udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of matches from the URL
    #
    # Formats the strategy sanity check report for
    # /sanity/strategy.  Note that sanity is checked by the
    # "strategy check" command; this command simply reports on the
    # results.

    proc html_SanityStrategy {udict matchArray} {
        upvar 1 $matchArray ""

        # NEXT, begin the page.
        ht page "Sanity Check: Actor's Strategies" {
            ht title "Actor's Strategies" "Sanity Check"
            
            strategy sanity report ::appserver::ht
        }

        return [ht get]
    }


    #-------------------------------------------------------------------
    # Boilerplate and Utilities

    # GroupLongLink g
    #
    # g      A group name
    #
    # Returns the group's long link.

    proc GroupLongLink {g} {
        rdb onecolumn {
            SELECT longlink FROM gui_groups WHERE g=$g
        }
    }

    # Restrict dict key vtype defval
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

    proc Restrict {dict key vtype defval} {
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


