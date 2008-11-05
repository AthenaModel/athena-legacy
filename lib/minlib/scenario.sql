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

-- Maps Table: Stores data for map images.

CREATE TABLE maps (
    -- Zoom level of this map; 100 = 100% zoom, or full size.
    zoom   INTEGER PRIMARY KEY DEFAULT 100,

    -- Map data: a BLOB of data in "jpeg" format.
    data   BLOB
);


