#-----------------------------------------------------------------------
# TITLE:
#    driver.tcl
#
# AUTHOR:
#    Will Duquette
#
# DESCRIPTION:
#    athena_sim(1): Driver Manager
#
#    This module is responsible for managing the creation of
#    attitude drivers.  Each driver has an integer ID, a type, and
#    a narrative text string that describes it.  Driver IDs are given
#    to URAM.
#-----------------------------------------------------------------------

snit::type driver {
    # Make it a singleton
    pragma -hasinstances no

    #-------------------------------------------------------------------
    # Type Variables

    # Initial driver ID.  This is set to 1000 so as to be higher than
    # standard cause's numeric ID, so that numeric driver IDs can be 
    # used as numeric cause ID.  There are fewer than 100 standard causes;
    # using 1000 leaves lots of room and is visually distinctive when
    # looking at the database.

    typevariable initialID 1000

    #-------------------------------------------------------------------
    # Queries
    #
    # These routines query information about the entities; they are
    # not allowed to modify them.


    # names
    #
    # Returns the list of DRIVER ids

    typemethod names {} {
        rdb eval {SELECT driver_id FROM drivers}
    }

    # validate id
    #
    # id  - Possibly, a driver ID.
    #
    # Validates a driver id

    typemethod validate {id} {
        if {![rdb exists {
            SELECT driver_id FROM drivers WHERE driver_id=$id
        }]} {
            return -code error -errorcode INVALID \
                "Driver does not exist: \"$id\""
        }

        return $id
    }



    # longnames
    #
    # Returns the list of extended DRIVER ids

    typemethod longnames {} {
        rdb eval {
            SELECT driver_id || ' - ' || narrative AS longid 
            FROM drivers
        }
    }

    #-------------------------------------------------------------------
    # Public Typemethods

    # create dtype narrative ?signature?
    #
    # dtype      - The driver type, usually a rule set name
    # narrative  - A brief human-readable string identifying the driver.
    # signature  - A dtype-specific signature for this particular driver.
    #
    # Creates a new driver, returning the driver ID.  If the signature
    # is given, it must be unique for this driver type; it and the 
    # driver type can then be used to retrieve the driver ID.  In 
    # practice, driver types that use the signature usually only call
    # [driver create]; if the signature is present, and there is already
    # a driver with the required dtype and signature, it will be returned.

    typemethod create {dtype narrative {signature ""}} {
        # FIRST, if signature is not zero, and there's a driver with
        # that signature return it.
        if {$signature ne ""} {
            set id [$type getid $dtype $signature]

            if {$id ne ""} {
                return $id
            }
        }

        # NEXT, get a new driver ID
        rdb eval {
            SELECT coalesce(max(driver_id)+1, $initialID) 
            AS new_id FROM drivers
        } {}

        # NEXT, create the entry
        rdb eval {
            INSERT INTO drivers(driver_id, dtype, narrative, signature)
            VALUES($new_id, $dtype, $narrative, $signature);
        }

        return $new_id
    }

    # delete driver_id
    #
    # driver_id   - A driver ID
    #
    # Deletes the given driver ID from the drivers table.
    # No attempt is made to clean up URAM.  Note that the driver ID
    # might be re-used.

    typemethod delete {driver_id} {
        rdb delete drivers "driver_id=$driver_id"
    }

    # getid dtype signature
    #
    # dtype    - The driver type
    # signature  - A driver's signature
    #
    # Retrieves the driver's ID given its dtype and signature.

    typemethod getid {dtype signature} {
        rdb onecolumn {
            SELECT driver_id FROM drivers
            WHERE dtype=$dtype AND signature=$signature
        }
    }

    # narrative get driver_id
    #
    # driver_id   - A driver ID
    #
    # Returns the narrative for the given driver.

    typemethod {narrative get} {driver_id} {
        rdb onecolumn {
            SELECT narrative FROM drivers
            WHERE driver_id=$driver_id
        }
    }

    # narrative set driver_id text
    #
    # driver_id   - A driver ID
    # text        - A new narrative string
    #
    # Sets the narrative for the given driver.

    typemethod {narrative set} {driver_id text} {
        $type validate $driver_id

        rdb eval {
            UPDATE drivers
            SET narrative=$text
            WHERE driver_id=$driver_id
        }
    }

    # inputs get driver_id
    #
    # driver_id   - A driver ID
    # 
    # Returns the number of inputs created for this driver ID by
    # DAM.

    typemethod {inputs get} {driver_id} {
        rdb onecolumn {
            SELECT inputs FROM drivers
            WHERE driver_id=$driver_id
        }
    }
    
    # inputs incr driver_id ?increment?
    #
    # driver_id   - A driver ID
    # increment   - An integer increment; default is 1.
    #
    # Sets the narrative for the given driver.

    typemethod {inputs incr} {driver_id {increment 1}} {
        $type validate $driver_id

        rdb eval {
            UPDATE drivers
            SET inputs=inputs + $increment
            WHERE driver_id=$driver_id
        }
    }

}

