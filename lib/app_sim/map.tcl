#-----------------------------------------------------------------------
# TITLE:
#    map.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    minerva_sim(1): Map Manager
#
#    This module is responsible for loading the map image and creating
#    the projection object, and making them available to the rest of the
#    application.  It also validates map references and map coordinates,
#    and does conversions between the two.
#
#-----------------------------------------------------------------------

snit::type map {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Components

    typecomponent mapimage    ;# Tk image of current map, or ""
    typecomponent projection  ;# projection(i), or NoMap

    #-------------------------------------------------------------------
    # Type Variables

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        # FIRST, there's no map yet.
        set mapimage   ""
        set projection [myproc NoMap]

        # NEXT, bind to significant events
        notifier bind ::scenario <ScenarioNew>    $type [mytypemethod load]
        notifier bind ::scenario <ScenarioOpened> $type [mytypemethod load]

        log normal map "Initialized"
    }


    # NoMap ?args?
    #
    # No map has been loaded

    proc NoMap {args} {
        error "No map has been loaded"
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    delegate typemethod ref2m to projection
    delegate typemethod m2ref to projection
    delegate typemethod ref   to projection

    # image 
    #
    # Returns the current map image, or ""
    
    typemethod image {} {
        return $mapimage
    }

    # projection
    #
    # Returns the current map projection, or [myproc NoMap].

    typemethod projection {} {
        return $projection
    }

    # load
    #
    # Loads the current map, gets the right projection, and notifies the
    # app.

    typemethod load {} {
        # FIRST, delete the old map image.
        if {$mapimage ne ""} {
            # FIRST, delete the image
            image delete $mapimage
            set mapimage ""

            # NEXT, delete the projection
            rename $projection ""
            set projection [myproc NoMap]
        }

        # NEXT, load the new map.
        rdb eval {
            SELECT width,height,data 
            FROM maps WHERE id=1
        } {
            # FIRST, create the image
            set mapimage [image create photo -format jpeg -data $data]

            # NEXT, create the projection
            set projection [mapref ${type}::proj \
                                -width  $width   \
                                -height $height]
        }

        # NEXT, notify the app that the map has been loaded.
        notifier send $type <MapLoaded>
    }

    # import filename
    #
    # filename     An image file
    #
    # Attempts to import the image into the RDB.

    typemethod import {filename} {
        # FIRST, is it a real image?
        set img [pixane create]

        if {[catch {
            pixane load $img -file $filename
        } result]} {
            app error {
                |<--
                Could not open the specified file as a map image:

                $filename
            }

            pixane delete $img
            return
        }
        
        # NEXT, get the image data, and save it in the RDB
        set tail [file tail $filename]
        set data [pixane save $img -format jpeg]
        set width [pixane width $img]
        set height [pixane height $img]

        rdb eval {
            INSERT OR REPLACE
            INTO maps(id, filename, width, height, data)
            VALUES(1,$tail,$width,$height,$data);
        }

        pixane delete $img

        # NEXT, log it.
        log normal app "Import Map: $filename"

        # NEXT, load the new map
        $type load

        # NEXT, Notify the application.
        notifier send $type <MapImported> $filename
    }
}
