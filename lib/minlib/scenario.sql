------------------------------------------------------------------------
-- TITLE:
--    scenario.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenario(n).
--
------------------------------------------------------------------------

-- Schema Version
PRAGMA user_version=1;

-- Scenario Table: Scenario meta-data
--
-- The notion is that it can contain arbitrary meta-data; all it's
-- used for at the moment is as a flag that this is a scenario file.

CREATE TABLE scenario (
    parm  TEXT PRIMARY KEY,
    value TEXT DEFAULT ''
);

-- Maps Table: Stores data for map images.
--
-- At this time, there's never more than one map image in the table.
-- The map with id=1 is the map to use.

CREATE TABLE maps (
    -- ID
    id       INTEGER PRIMARY KEY,

    -- Original file name of this map
    filename TEXT,

    -- Map data: a BLOB of data in "jpeg" format.
    data     BLOB
);


