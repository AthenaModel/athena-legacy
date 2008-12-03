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

    #-------------------------------------------------------------------
    # Type Variables

    # info -- array of scalars
    #
    # undo       Command to undo the last operation, or ""

    typevariable info -array {
        undo {}
    }

    #-------------------------------------------------------------------
    # Initialization

    typemethod init {} {
        # FIRST, there's no map yet.
        set mapimage   ""
        set projection [mapref ${type}::proj]

        log normal map "Initialized"
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    delegate typemethod box   to projection
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

    # reconfigure
    #
    # Loads the current map, gets the right projection, and notifies the
    # app.

    typemethod reconfigure {} {
        # FIRST, delete the old map image.
        if {$mapimage ne ""} {
            # FIRST, delete the image
            image delete $mapimage
            set mapimage ""

            # NEXT, reset the projection
            $projection configure \
                -width  1000      \
                -height 1000
        }

        # NEXT, load the new map.
        rdb eval {
            SELECT width,height,data 
            FROM maps WHERE id=1
        } {
            # FIRST, create the image
            set mapimage [image create photo -format jpeg -data $data]

            # NEXT, configure the projection
            $projection configure \
                -width  $width    \
                -height $height
        }
    }

    # import filename
    #
    # filename     An image file
    #
    # Attempts to import the image into the RDB.  This command is
    # undoable.

    typemethod import {filename} {
        # FIRST, get the undo information
        rdb eval {
            SELECT * FROM maps WHERE id=1
        } row {
            unset row(*)
        }

        # NEXT, try to load it.
        $type load $filename

        # NEXT, log it.
        log normal app "Import Map: $filename"
        
        app puts "Imported Map: $filename"

        set info(undo) [mytypemethod UndoImport [array get row]]

        # NEXT, Notify the application.
        notifier send $type <MapChanged>
    }

    # lastundo
    #
    # Returns the undo command for the last mutator, or "" if none.
    # Clears the undo information automatically.

    typemethod lastundo {} {
        set undo $info(undo)
        unset info(undo)

        return $undo
    }

    # UndoImport dict
    #
    # dict    A dictionary of map parameters
    # 
    # Undoes a previous import

    typemethod UndoImport {dict} {
        # FIRST, restore the data
        dict for {key value} $dict {
            rdb eval "
                UPDATE maps
                SET $key = \$value
                WHERE id=1
            "
        }

        # NEXT, load the restored image
        $type reconfigure

        # NEXT, log it
        set filename [dict get $dict filename]

        log normal app "Restored Map: $filename"
        app puts "Restored Map: $filename"

        # NEXT, Notify the application.
        notifier send $type <MapChanged>
    }
    

    # load filename
    #
    # filename     An image file
    #
    # Attempts to load the image into the RDB.

    typemethod load {filename} {
        # FIRST, is it a real image?
        set img [pixane create]

        if {[catch {
            pixane load $img -file $filename
        } result]} {
            pixane delete $img

            error "Could not open the specified file as a map image"
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

        # NEXT, load the new map
        $type reconfigure
    }
}
