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
-- Neighborhood Relationships

-- Neighborhood relationships from m's point of view
CREATE TABLE nbrel_mn (
    -- Symbolic nbhood name
    m             TEXT,

    -- Symbolic nbhood name
    n             TEXT,

    -- Proximity of m to n from m's point of view: eproximity value
    -- By default, a direct effect in n has no indirect effects in m,
    -- unless m == n (this is set automatically).
    proximity     TEXT DEFAULT 'REMOTE',

    -- Indirect effects delay: how long in decimal days before a
    -- direct effect in n has an indirect effect in m.
    effects_delay DOUBLE DEFAULT 0.0, 

    PRIMARY KEY (m, n)
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

    -- Unit Shape (eunitshape(n))
    shape       TEXT DEFAULT 'NEUTRAL',

    -- Unit Symbol (list of eunitsymbol(n), or '')
    symbol      TEXT DEFAULT '',

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

-- rel_nfg: Group f's relationship with group g in neighborhood n, from
-- f's point of view.
--
-- Relationships between force and org groups are at the playbox level,
-- indicated by setting n='PLAYBOX'.  This is a special token, used 
-- to indicate non-neighborhood-specific relationships.
--
-- All relationships with civilian groups occur at the neighborhood
-- level.
--
-- Thus, the table is populated as follows:
--
-- At the PLAYBOX level: all frc/org groups f with all all frc/org groups g.
--
-- For each nbhood n:
--    For all civ groups f and all civ groups g, provided that there's at
--    least one civ group resident in n.
--    For each civ group f resident in n with with all frc/org groups g
--    For all frc/org groups f with each civ group g resident in n.


CREATE TABLE rel_nfg (
    -- Symbolic nbhood name, or 'PLAYBOX'.
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
-- Initial Cooperation Data

-- coop_nfg: Group f's cooperation with group g in neighborhood n, that
-- is, the likelihood that f will provide intel to g.
--
-- At present, cooperation is defined only between all
-- nbgroups nf and all force groups g.

CREATE TABLE coop_nfg (
    -- Symbolic nbhood name.
    n           TEXT,

    -- Symbolic civ group name: group f
    f           TEXT,

    -- Symbolic frc group name: group g
    g           TEXT,

    -- cooperation of f with g at time 0.
    coop0       DOUBLE DEFAULT 0.0,

    PRIMARY KEY (n, f, g)
);

------------------------------------------------------------------------
-- Units

-- General unit data
CREATE TABLE units (
    -- Symbolic unit name
    u                TEXT PRIMARY KEY,

    -- Group to which the unit belongs
    g                TEXT,

    -- Total Personnel
    personnel        INTEGER DEFAULT 0,

    -- Location, in map coordinates
    location         TEXT,

    -- Unit activity: eactivity(n) value
    activity         TEXT DEFAULT 'NONE',

    --------------------------------------------------------------------
    -- Computed parameters

    -- Group type (for convenience)
    gtype            TEXT DEFAULT '',

    -- Neighborhood in which unit is currently located, a nbhood ID or ""
    -- if outside all neighborhoods.
    n                TEXT DEFAULT ''
);


------------------------------------------------------------------------
-- Primary Entities
--
-- Anything with an ID and a long name is a primary entity.  All IDs and 
-- long names of primary entities must be unique.  The following view is 
-- used to check this, and to retrieve the entity type for a given ID.

CREATE VIEW entities AS
SELECT 'PLAYBOX' AS id, 
       'Playbox' AS longname, 
       'pseudo'  AS etype
UNION
SELECT n         AS id, 
       longname  AS longname, 
       'nbhood'  AS etype 
FROM nbhoods
UNION
SELECT g         AS id, 
       longname  AS longname, 
       'group'   AS etype 
FROM groups
UNION
SELECT c         AS id, 
       longname  AS longname, 
       'concern' AS etype 
FROM concerns
UNION
SELECT u         AS id,
       u         AS longname,
       'unit'    AS etype
FROM units;
