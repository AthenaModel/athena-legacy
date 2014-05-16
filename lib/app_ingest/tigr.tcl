#-----------------------------------------------------------------------
# FILE: tigr.tcl
#
#   TIGR message retriever.
#
# PACKAGE:
#   app_ingest(n) -- athena_ingest(1) implementation package
#
# PROJECT:
#   Athena S&RO Simulation
#
# AUTHOR:
#    Will Duquette
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# tigr
#
# app_ingest(n) TIGR I/F
#
# This module is responsible for retrieving TIGR messages from the 
# disk or a server, and making them available to the application.

snit::type tigr {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    # TBD

    #-------------------------------------------------------------------
    # Type Variables

    # info array: data structure for the ingested data.
    #
    # messages  - Dictionary of TIGR messages, by ID.

    typevariable info -array {
        messages {
            1  {
                id   1
                week 2014W17
                n     EL
                title "Flash Flood"
            }
            2  {
                id   2
                week 2014W17
                n     PE
                title "Terror Bombing"
            }
            3  {
                id   3
                week 2014W17
                n     CITY
                title "Neighborhood Combat"
            }
            4  {
                id   4
                week 2014W17
                n     EL
                title "Bad Hair Day"
            }
            5  {
                id   5
                week 2014W17
                n     PE
                title "Excessive Sarcasm"
            }
            6  {
                id   6
                week 2014W18
                n     PE
                n     CITY
                title "Flushed with Pride"
            }
            7  {
                id   7
                week 2014W18
                n     EL
                title "Joe wins the Big One"
            }
            8  {
                id   8
                week 2014W18
                n     PE
                title "Sarcasm on Parade"
            }
            9  {
                id   9
                week 2014W18
                n     CITY
                title "Will and Dave's Excellent Adventure"
            }
            10 {
                id   10
                week 2014W18
                n     EL
                title "Grand Canyon Goes Missing"
            }
            11 {
                id   11
                week 2014W19
                n     PE
                title "Sales Riot"
            }
            12 {
                id   12
                week 2014W19
                n     CITY
                title "Dogs Gone Wild"
            }
            13 {
                id   13
                week 2014W19
                n     EL
                title "Brian Buys A Car"
            }
            14 {
                id   14
                week 2014W19
                n     PE
                title "Deer in the Headlights"
            }
            15 {
                id   15
                week 2014W19
                n     CITY
                title "Surely You're Joking"
            }
            16 {
                id   16
                week 2014W20
                n     EL
                title "Overacting"
            }
            17 {
                id   17
                week 2014W20
                n     PE
                title "Infrastructure Breakdown"
            }
            18 {
                id   18
                week 2014W20
                n     CITY
                title "Industrial Spill"
            }
            19 {
                id   19
                week 2014W20
                n     EL
                title "Crying About Spilled Industry"
            }
            20 {
                id   20
                week 2014W20
                n     PE
                title "Intel Oversight"
            }
            21 {
                id   21
                week 2014W21
                n     CITY
                title "Airduct Infiltration"
            }
            22 {
                id   22
                week 2014W21
                n     EL
                title "Fish with Bicycles"
            }
            23 {
                id    23
                week 2014W21
                n     PE
                title "Cow Kicks Lantern"
            }
            24 {
                id   24
                week 2014W21
                n     CITY
                title "A Few More Bugs"
            }
            25 {
                id   25
                week 2014W21
                n     EL
                title "Bull By The Horns"
            }
        }
    }
    

    #-------------------------------------------------------------------
    # Application Initialization

    # init
    #
    # Initializes the tigr, which prepares the data structures.
    
    typemethod init {} {
        # TBD
    }

    # retrieveMessages
    #
    # For now, pretends to retrieve messages; the messages are
    # loaded into the RDB.

    typemethod retrieveMessages {} {
        # FIRST, load the canned data into the RDB.  Replace
        # existing messages, if any; we might have gotten new versions
        # of them.
        dict for {id dict} $info(messages) {
            array set data $dict
            rdb eval {
                INSERT OR REPLACE INTO messages(cid,week,n,title)
                VALUES($data(id), $data(week), $data(n), $data(title))
            }
        }

        # NEXT, assign week numbers.
        $type AssignWeekNumbers
    }

    # AssignWeekNumbers
    #
    # Assigns a week number (an integer) to each message, based
    # on the week strings.  The first week is week 1.

    typemethod AssignWeekNumbers {} {
        set weeks [rdb eval {
            SELECT DISTINCT week FROM messages ORDER BY week ASC
        }]

        set t 0
        foreach week $weeks {
            incr t

            rdb eval {
                UPDATE messages
                SET t = $t
                WHERE week = $week
            }
        }
    }

    # ids
    #
    # Returns the retrieved message IDs

    typemethod ids {} {
        return [rdb eval {SELECT cid FROM messages}]
    }

    # view id
    #
    # Gets a "view" dictionary for the given message.

    typemethod view {id} {
        rdb eval {
            SELECT * FROM messages WHERE cid=$id
        } row {
            unset -nocomplain row(*)

            return [array get row]
        }

        return [dict create]
    }

    # detail id
    #
    # Returns detail about the message and its contents in the 
    # form of an HTML string.
    # 
    # TBD: Pull the data from the RDB, and include everything
    # known to date.

    typemethod detail {id} {
        set title [dict get $info(messages) $id title]
        append out "<h1>$id</h1>\n"

        append out [join [lrepeat 100 $title] " "]

        return $out
    }

}



