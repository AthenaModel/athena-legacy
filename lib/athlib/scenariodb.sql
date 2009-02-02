------------------------------------------------------------------------
-- TITLE:
--    scenariodb.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n).
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

-- Checkpoint Table: saves saveable(i) data

CREATE TABLE checkpoint (
    saveable   TEXT PRIMARY KEY,
    checkpoint TEXT
);

-- Critical Input Table: Saves user orders and (temporarily) any
-- undo information.

CREATE TABLE cif (
    -- Unique ID; used for ordering
    id       INTEGER UNIQUE,

    -- Simulation time at which the order was entered.
    time     INTEGER DEFAULT 0,

    -- Order name
    name     TEXT,

    -- Parameter Dictionary
    parmdict TEXT,

    -- Undo Command, or ''
    undo     TEXT DEFAULT ''
);

CREATE INDEX cif_index ON cif(time,id);


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



-- Neighborhood definitions
CREATE TABLE nbhoods (
    -- Symbolic neighborhood name     
    n              TEXT PRIMARY KEY,

    -- Full neighborhood name
    longname       TEXT,

    -- Stacking order: 1 is low, N is high
    stacking_order INTEGER,

    -- Urbanization: eurbanization
    urbanization   TEXT,

    -- Neighborhood reference point: map coordinates {mx my}
    refpoint       TEXT,

    -- Neighborhood polygon: list of map coordinates {mx my ...}
    polygon        TEXT,

    -- If refpoint is obscured by another neighborhood, the name
    -- of the neighborhood; otherwise ''.
    obscured_by    TEXT DEFAULT ''
);

------------------------------------------------------------------------
-- Group Tables

-- Generic Group Data
CREATE TABLE groups (
    -- Symbolic group name
    g           TEXT PRIMARY KEY,

    -- Full group name
    longname    TEXT,

    -- Group Color, as #RRGGBB
    color       TEXT DEFAULT '#00FFFF',

    -- Group type, CIV, FRC, ORG
    gtype       TEXT 
);

-- Force Groups
CREATE TABLE frcgroups (
    -- Symbolic group name
    g           TEXT PRIMARY KEY,

    -- Force Type
    forcetype   TEXT,

    -- Local or foreign: 1 if local, 0 if foreign
    local       INTEGER,

    -- Member of US-led coalition: 1 if member, 0 otherwise
    coalition   INTEGER
);

-- Force Group View: joins groups with frcgroups.
CREATE VIEW frcgroups_view AS
SELECT * FROM groups JOIN frcgroups USING (g);


-- Org Groups
CREATE TABLE orggroups (
    -- Symbolic group name
    g              TEXT PRIMARY KEY,

    -- Organization type: eorgtype
    orgtype        TEXT DEFAULT 'NGO',

    -- Capability flags, 1 or 0
    medical        INTEGER DEFAULT 0,
    engineer       INTEGER DEFAULT 0,
    support        INTEGER DEFAULT 0,

    -- Group rollup-weight (non-negative) (JRAM input)
    rollup_weight  DOUBLE DEFAULT 1.0,

    -- Indirect effects multiplier (non-negative) (JRAM input)
    effects_factor DOUBLE DEFAULT 1.0
);

-- Org Group View: joins groups with orggroups.
CREATE VIEW orggroups_view AS
SELECT * FROM groups JOIN orggroups USING (g);

-- Civ Group View: Limits groups to CIV groups
-- (There's no CIV-specific group data at the top-level.)

CREATE VIEW civgroups_view AS
SELECT * FROM groups WHERE gtype='CIV';

-- Neighborhood Groups: Civilian Groups in Neighborhoods
CREATE TABLE nbgroups (
    -- Symbolic neighborhood name
    n              TEXT,

    -- Symbolic civgroup name
    g              TEXT,

    -- Local name: human readable name
    local_name     TEXT,

    -- Group demeanor: edemeanor
    demeanor       TEXT,

    -- Group rollup-weight (non-negative) (JRAM input)
    rollup_weight  DOUBLE DEFAULT 1.0,

    -- Indirect effects multiplier (non-negative) (JRAM input)
    effects_factor DOUBLE DEFAULT 1.0,

    PRIMARY KEY (n,g)
);

CREATE VIEW nbgroups_view AS
SELECT * FROM groups JOIN nbgroups USING (g);

------------------------------------------------------------------------
-- Concerns and concern views

-- Concern definitions
CREATE TABLE concerns (
    -- Symbolic concern name
    c         TEXT PRIMARY KEY,

    -- Full concern name
    longname  TEXT,

    -- Concern type: egrouptype
    gtype     TEXT
);

CREATE VIEW civ_concerns AS
SELECT * FROM concerns WHERE gtype='CIV';

CREATE VIEW org_concerns AS
SELECT * FROM concerns WHERE gtype='ORG';


------------------------------------------------------------------------
-- Initial Satisfaction Data


-- Neighborhood/pgroup/concern triples (n,g,c) for both nbhood groups
-- and org groups.  This table contains the data used to initialize
-- JRAM.

CREATE TABLE sat_ngc (
    -- Symbolic nbhoods name
    n          TEXT,

    -- Symbolic groups name
    g          TEXT,

    -- Symbolic concerns name
    c          TEXT,

    -- Group type: CIV or ORG
    gtype      TEXT,

    -- Initial satisfaction value
    sat0       DOUBLE DEFAULT 0.0,

    -- Long-term Trend
    trend0     DOUBLE DEFAULT 0.0,

    -- Saliency of concern c to group g in nbhood n
    saliency   DOUBLE DEFAULT 1.0,

    PRIMARY KEY (n, g, c)
);


------------------------------------------------------------------------
-- Initial Relationship Data

-- rel_fg: Group f's relationship with group g, from f's point of view.
-- This table contains the relationships between all groups in the set
-- of force groups and organization groups.

CREATE TABLE rel_fg (
    -- Symbolic group name: group f
    f           TEXT,

    -- Symbolic group name: group g
    g           TEXT,

    -- Group relationship, from f's point of view.
    rel         DOUBLE DEFAULT 0.0,

    PRIMARY KEY (f, g)
);


-- rel_nfg: Civilian group relationships.  Unlike the force and
-- organization relationships described above, civilian group
-- relationships are always local to a neighborhood.  Thus, 
-- in this table at least one of f and g will be a civilian group;
-- the other can be a civilian, force, or organization group.
--
-- The table is populated as follows:
--
-- For all nbhoods n:
--    For all civ groups f and all civ groups g
--    For all civ groups f and all frc/org groups g, f resides in n
--    For all frc/org groups f and all civ groups g, g resides in n


CREATE TABLE rel_nfg (
    -- Symbolic nbhood name
    n           TEXT,

    -- Symbolic group name: group f
    f           TEXT,

    -- Symbolic group name: group g
    g           TEXT,

    -- Group relationship, from f's point of view.
    rel         DOUBLE DEFAULT 0.0,

    PRIMARY KEY (n, f, g)
);


------------------------------------------------------------------------
-- Primary Entities
--
-- Anything with an ID and a long name is a primary entity.  All IDs and 
-- long names of primary entities must be unique.  The following view is 
-- used to check this.

CREATE VIEW entities AS
SELECT n AS id, longname FROM nbhoods   UNION
SELECT g AS id, longname FROM groups    UNION
SELECT c AS id, longname FROM concerns;
