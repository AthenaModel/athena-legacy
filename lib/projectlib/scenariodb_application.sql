------------------------------------------------------------------------
-- TITLE:
--    scenariodb_application.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Application Tables
--
-- SECTIONS:
--    Scenario Management
--    Orders
--    Significant Events
--    Maps
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- SCENARIO MANAGEMENT

-- Saveables Table: saves saveable(i) data.  I.e., this table contains
-- checkpoints of in-memory data for specific objects.

CREATE TABLE saveables (
    saveable   TEXT PRIMARY KEY,
    checkpoint TEXT
);

-- Snapshots Table: saves scenario snapshots.  I.e., this table
-- contains snapshots of the scenario at different points in time.

CREATE TABLE snapshots (
    -- Time tick at which the snapshot was saved; 0 is restart
    -- checkpoint.
    tick       INTEGER PRIMARY KEY,

    -- XML text of the snapshot.
    snapshot TEXT
);


------------------------------------------------------------------------
-- ORDERS


-- Critical Input Table: Saves user orders and (temporarily) any
-- undo information.

CREATE TABLE cif (
    -- Unique ID; used for ordering
    id       INTEGER PRIMARY KEY,

    -- Simulation time at which the order was entered.
    time     INTEGER DEFAULT 0,

    -- Order name
    name     TEXT,

    -- Order narrative
    narrative TEXT default '',

    -- Parameter Dictionary
    parmdict TEXT,

    -- Undo Command, or ''
    undo     TEXT DEFAULT ''
);

CREATE INDEX cif_index ON cif(time,id);



------------------------------------------------------------------------
-- SIGNIFICANT EVENTS LOG

-- These two tables store significant simulation events, and allow
-- events to be tagged with zero or more entities.

CREATE TABLE sigevents (
    -- Used for sorting
    event_id   INTEGER PRIMARY KEY,
    t          INTEGER,               -- Time stamp, in ticks
    level      INTEGER DEFAULT 1,     -- level of importance, -1 to N
    component  TEXT,                  -- component/model logging the event
    narrative  TEXT                   -- Event narrative.
);

-- Tags table.  Individual events can be tagged with 0 or more tags;
-- this information can later be used to display tailored logs, e.g.,
-- events involving a particular neighborhood or actor.

CREATE TABLE sigevent_tags (
    event_id INTEGER REFERENCES sigevents(event_id)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    tag      TEXT,

    PRIMARY KEY (event_id, tag)
);

CREATE VIEW sigevents_view AS
SELECT *
FROM sigevents JOIN sigevent_tags USING (event_id);


------------------------------------------------------------------------
-- MAPS

-- Maps Table: Stores data for map images.
--
-- At this time, there's never more than one map image in the table.
-- The map with id=1 is the map to use.

CREATE TABLE maps (
    -- ID
    id       INTEGER PRIMARY KEY,

    -- Original file name of this map
    filename TEXT,

    -- Width and Height, in pixels
    width    INTEGER,
    height   INTEGER,

    -- Map data: a BLOB of data in "jpeg" format.
    data     BLOB
);

------------------------------------------------------------------------
-- BOOKMARKS

CREATE TABLE bookmarks (
    -- Detail Browser bookmarks.
    bookmark_id INTEGER PRIMARY KEY,
    url         TEXT,
    title       TEXT,
    rank        INTEGER  -- Used to order bookmarks in Bookmarks Manager
);

------------------------------------------------------------------------
-- EXECUTIVE SCRIPTS

CREATE TABLE scripts (
    -- Scripts Table: Executive scripts, maintained as part of the
    -- scenario.  Scripts are identified by name.  Scripts with
    -- the auto flag set (auto=1) are executed automatically on
    -- executive reset, in order of their sequence numbers.  Other
    -- scripts can be executed on demand.
    
    name     TEXT PRIMARY KEY,
    seq      INTEGER,
    auto     INTEGER DEFAULT 0,
    body     TEXT DEFAULT ''
);


------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------


