#-----------------------------------------------------------------------
# FILE: rdb.tcl
#
#   RDB Module: in-memory SQLite database.
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
# rdb
#
# app_ingest(n) RDB I/F
#
# This module is responsible for creating an in-memory SQLite3 data
# store and making it available to the application.

snit::type rdb {
    pragma -hastypedestroy 0 -hasinstances 0

    #-------------------------------------------------------------------
    # Type Components

    typecomponent db  ;# sqldocument(n)

    #-------------------------------------------------------------------
    # Type Variables

    # SQL schema

    typevariable schema {
        CREATE TABLE messages (
            -- TIGR Messages retrieved from the data source.

            -- TIGR Fields
            cid        TEXT PRIMARY KEY,
            title      TEXT,    -- Message title
            desc       TEXT,    -- Message description
            start_str  TEXT,    -- start time as string
            end_str    TEXT,    -- end time as string
            start      INTEGER, -- unix timestamp of start time
            end        INTEGER, -- unix timestamp of end time
            tz         TEXT,    -- time zone: +/-hhmm
            locs       TEXT,    -- list of lat/long pairs

            -- Derived Fields
            week   TEXT,    -- Julian week(n) string
            t      INTEGER, -- Simulation week number
            n      TEXT     -- Neighborhood ID
        );

        CREATE TABLE cid2etype (
            -- Mapping from TIGR event IDs to simevent type names.
            cid    TEXT,  -- TIGR ID
            etype  TEXT,  -- Event type name

            PRIMARY KEY (cid, etype)
        );


        -- Event Ingestion Views
        CREATE VIEW ingest_view AS
        SELECT n                                       AS n,
               t                                       AS t,
               etype                                   AS etype,
               '-n'       || ' ' || n    || ' ' || 
               '-t'       || ' ' || t    || ' ' || 
               '-week'    || ' ' || week || ' ' ||
               '-cidlist' || ' ' || cid                AS optlist 
        FROM messages
        JOIN cid2etype USING (cid);

        CREATE VIEW ingest_ACCIDENT AS
        SELECT * FROM ingest_view
        WHERE etype = 'ACCIDENT'
        ORDER BY n, t;

        CREATE VIEW ingest_CIVCAS AS
        SELECT * FROM ingest_view
        WHERE etype = 'CIVCAS'
        ORDER BY n, t;

        CREATE VIEW ingest_DROUGHT AS
        SELECT * FROM ingest_view
        WHERE etype = 'DROUGHT'
        ORDER BY n, t;

        CREATE VIEW ingest_EXPLOSION AS
        SELECT * FROM ingest_view
        WHERE etype = 'EXPLOSION'
        ORDER BY n, t;

        CREATE VIEW ingest_FLOOD AS
        SELECT * FROM ingest_view
        WHERE etype = 'FLOOD'
        ORDER BY n, t;

        CREATE VIEW ingest_VIOLENCE AS
        SELECT * FROM ingest_view
        WHERE etype = 'VIOLENCE'
        ORDER BY n, t;
    }
    

    #-------------------------------------------------------------------
    # Application Initialization

    delegate typemethod * to db

    # init
    #
    # Initializes the rdb, which prepares the data structures.
    
    typemethod init {} {
        set db [sqldocument ${type}::db \
                    -rollback off]

        $db open :memory:

        $db eval $schema
    }


}



