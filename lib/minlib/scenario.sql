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

CREATE TABLE maps (
    -- Zoom level of this map; 100 = 100% zoom, or full size.
    zoom   INTEGER PRIMARY KEY DEFAULT 100,

    -- Map data: a BLOB of data in "jpeg" format.
    data   BLOB
);


