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

        $server register /docs/{path}.html {(docs/.+\.html)} \
            text/html [myproc text_File ""]                    \
            "An HTML file in the Athena docs/ tree."

        $server register /docs/{path}.txt {(docs/.+\.txt)} \
            text/plain [myproc text_File ""]                 \
            "A .txt file in the Athena docs/ tree."

        $server register /docs/{imageFile} {(docs/.+\.(gif|jpg|png))} \
            tk/image [myproc image_File ""]                           \
            "A .gif, .jpg, or .png file in the Athena /docs/ tree."

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
                subset of the model parameter database.
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
    #
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
                   cash_reserve  AS "Reserve, $",
                   income        AS "Income, $/week",
                   cash_on_hand  AS "On Hand, $"
            FROM gui_actors
        } -default "None." -align LRRR

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
        ht subtitle "Power Base" base

        if {[Locked -disclaimer]} {
            set vmin [parm get control.support.vrelMin]

            ht putln "Actor $a has the following supporters "
            ht putln "(and would-be supporters).  "
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
        }

        # Deployment
        ht subtitle "Force Deployment" forces

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


        ht subtitle "Attack Status" attack

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

        ht para


        ht subtitle "Defense Status" defense

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

        ht subtitle "Significant Events" sigevents

        ht putln {
            The following are the most recent significant events 
            involving this actor, oldest first.
        }

        ht para



        SigEvents -tags $a -mark run

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
                   proximity       AS "Proximity",
                   effects_delay   AS "Effects Delay"
            FROM gui_nbrel_mn 
            ORDER BY m_longlink, n_longlink
        } -default "No neighborhood relationships exist." -align LLLR

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

        # Support and Control
        ht subtitle "Support and Control" control

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
        } -default "None." -align LR

        ht para
        ht putln "Actor support comes from the following groups."
        ht putln "Note that a group only supports an actor if"
        ht putln "its vertical relationship with the actor is at"
        ht putln "least [parm get control.support.vrelMin]."
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
                           sap          AS "SA%"
                    FROM gui_civgroups 
                    ORDER BY longlink
                } -default "None." -align LLLRR
            } else {
                ht query {
                    SELECT longlink     AS "Group",
                           n            AS "Nbhood",
                           demeanor     AS "Demeanor",
                           population   AS "Population",
                           sap          AS "SA%",
                           mood0        AS "Mood at T0",
                           mood         AS "Mood Now"
                    FROM gui_civgroups 
                    ORDER BY longlink
                } -default "None." -align LLLRRRR
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
        # FIRST, get the data about this group
        rdb eval {SELECT * FROM gui_civgroups WHERE g=$g}       data {}
        rdb eval {SELECT * FROM gui_nbhoods   WHERE n=$data(n)} nb   {}

        # NEXT, begin the page.
        ht page "Civilian Group: $g"
        ht title "$data(longname) ($g)" "Civilian Group" "Summary"

        # NEXT, what we do depends on whether the simulation is locked
        # or not.
        let locked {[sim state] ne "PREP"}

        if {$locked} {
            ht linkbar {
                "#actors"     "Relationships with Actors"
                "#rel"        "Friends and Enemies"
                "#sat"        "Satisfaction Levels"
                "#drivers"    "Drivers"
                "#sigevents"  "Significant Events"
            }
        } else {
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

        ht subtitle "Relationships with Actors" actors \
            /group/$g/vrel "View Analysis"

        ht query {
            SELECT link('/actor/' || a, pair(longname, a)),
                   qaffinity('format',vrel),
                   g || ' ' || qaffinity('longname',vrel) 
                     || ' ' || a
            FROM vrel_ga JOIN actors USING (a)
            WHERE g=$g
            ORDER BY vrel DESC
        } -labels {
            "Actor"
            "Vertical<br>Rel."
            "Narrative"
        } -align LRL
        
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

        ht subtitle "Satisfaction Levels" sat

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

        ht subtitle "Satisfaction Drivers" drivers

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

        ht subtitle "Significant Events" sigevents

        ht putln {
            The following are the most recent significant events 
            involving this group, oldest first.
        }

        ht para

        SigEvents -tags [list $g $data(n)] -mark run

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

        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        ht linkbar {
            "#deployment" "Deployment"
            "#attack"     "Attack Status"
            "#defense"    "Defense Status"
            "#sigevents"  "Significant Events"
        }

        ht subtitle "Deployment" deployment

        ht query {
            SELECT N.longlink     AS "Neighborhood",
                   D.personnel    AS "Personnel"
            FROM deploy_ng AS D
            JOIN gui_nbhoods AS N ON (D.n = N.n)
            WHERE D.g = $g AND D.personnel > 0
            ORDER BY N.longlink
        } -default "No personnel are deployed." -align LR

        
        ht subtitle "Attack Status" attack

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
                ht td left {
                    ht put $nlink
                }

                ht td left {
                    ht put $froe
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
            ht putln "Group $g has the following attacking ROEs."
            ht putln {
                The background will be gray for potential conflicts, 
                i.e., those in which one or the other group (or both)
                has no personnel in the neighborhood in question.
            }
            ht para

            ht table {
                "Nbhood" "Att. ROE" "Max Attacks" "Defender" "Personnel" "Def. ROE"
            } {
                ht putln $text
            }
        } else {
            ht putln "Group $g is not attacking any other groups."
        }

        ht para


        ht subtitle "Defense Status" defense

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

        ht subtitle "Significant Events" sigevents

        ht putln {
            The following are the most recent significant events 
            involving this group, oldest first.
        }

        ht para

        SigEvents -tags $g -mark run

        ht /page

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

        if {![Locked -disclaimer]} {
            ht /page
            return [ht get]
        }

        ht linkbar {
            "#deployment" "Deployment"
            "#sigevents"  "Significant Events"
        }

        ht subtitle "Deployment" deployment

        ht query {
            SELECT N.longlink     AS "Neighborhood",
                   D.personnel    AS "Personnel"
            FROM deploy_ng AS D
            JOIN gui_nbhoods AS N ON (D.n = N.n)
            WHERE D.g = $g AND D.personnel > 0
            ORDER BY N.longlink
        } -default "No personnel are deployed." -align LR


        ht subtitle "Significant Events" sigevents

        ht putln {
            The following are the most recent significant events 
            involving this group, oldest first.
        }

        ht para

        SigEvents -tags $g -mark run

        ht /page

        return [ht get]
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
                   V.dv_mood,
                   V.dv_services
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
            "+ &Delta;V.services"
        } -align LRRRR

        ht subtitle "Description"

        ht putln "
            The vertical relationship <i>V.ga</i> is recomputed
            every [parm get strategy.ticksPerTock] days.  Initially
            it depends on group <i>g</i>'s affinity for actor <i>a</i>,
            as determined by their belief systems.  It is affected over
            time by a number of factors.
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
            at the time of assessment.  The deltas as expressed as
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

        ht putln "<dt><b>&Delta;V.services</b>"
        ht putln <dd>
        ht put {
            Change in <i>V</i> due to the current level of basic services
            in the neighborhood.  This term is non-zero if the level of 
            basic services in the neighborhood is bettor or worse 
            than expected.
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
    # Parmdb

    # linkdict_Parmdb udict matchArray
    #
    # udict      - A dictionary containing the URL components
    # matchArray - Array of pattern matches
    #
    # Returns a parmdb resource as a tcl/linkdict.

    proc linkdict_Parmdb {udict matchArray} {
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
    #   $(1) - The major subset
    #
    # Returns a page that documents the current parmdb(5) values.
    # There can be a query; if so, it is treated as a glob-pattern,
    # and only parameters that match are included.

    proc html_Parmdb {udict matchArray} {
        upvar 1 $matchArray ""

        # FIRST, get the pattern, if any.
        set pattern [dict get $udict query]

        if {$pattern eq "" && $(1) ne ""} {
            set pattern "$(1).*"
        }

        # NEXT, begin the page.
        if {$pattern eq ""} {
            set parms [parm names]

            ht page "Model Parameters"
            ht title "Model Parameters"
        } else {
            set parms [parm names $pattern]

            set ptext [htools escape $pattern]

            ht page "Model Parameters: $ptext"
            ht title "Model Parameters: $ptext"
        }

        # NEXT, if no parameters are found, note it and return.
        if {$pattern ne "" && [llength $parms] == 0} {
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


