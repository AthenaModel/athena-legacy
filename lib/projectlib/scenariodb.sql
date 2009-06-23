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

    -- Volatility gain: rgain
    vtygain        REAL DEFAULT 1.0,

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

    -- Group demeanor: edemeanor
    demeanor    TEXT DEFAULT 'AVERAGE',

    -- Uniformed or Non-uniformed: 1 or 0
    uniformed   INTEGER DEFAULT 1,

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

    -- Group demeanor: edemeanor
    demeanor       TEXT DEFAULT 'AVERAGE',

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

    -- Base Population
    basepop        INTEGER DEFAULT 1,

    -- Group demeanor: edemeanor
    demeanor       TEXT DEFAULT 'AVERAGE',

    -- Group rollup-weight (non-negative) (JRAM input)
    rollup_weight  DOUBLE DEFAULT 1.0,

    -- Indirect effects multiplier (non-negative) (JRAM input)
    effects_factor DOUBLE DEFAULT 1.0,

    PRIMARY KEY (n,g)
);

CREATE VIEW nbgroups_view AS
SELECT * FROM groups JOIN nbgroups USING (g);

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

    -- Neighborhood of Origin, or 'NONE'
    origin           TEXT DEFAULT 'NONE',

    -- Total Personnel
    personnel        INTEGER DEFAULT 0,

    -- Location, in map coordinates
    location         TEXT,

    -- Unit activity: eactivity(n) value
    a                TEXT DEFAULT 'NONE',

    --------------------------------------------------------------------
    -- Computed parameters

    -- Group type (for convenience)
    gtype            TEXT DEFAULT '',

    -- Neighborhood in which unit is currently located, a nbhood ID or ""
    -- if outside all neighborhoods.
    n                TEXT DEFAULT '',

    -- Activity effective flag: 1 if activity is effective, and 0 otherwise.
    a_effective      INTEGER DEFAULT 0
);

--------------------------------------------------------------------
-- Force and Security Tables

-- nbstat Table: Total Force and Volatility in neighborhoods
CREATE TABLE force_n (
    -- Symbolic nbhood name
    n                   TEXT    PRIMARY KEY,

    -- Total force in nbhood, including nearby.
    total_force         INTEGER DEFAULT 0,

    -- Gain on volatility, a multiplier >= 0.0
    volatility_gain     DOUBLE  DEFAULT 1.0,

    -- Nominal Volatility, excluding gain, 0 to 100
    nominal_volatility  INTEGER DEFAULT 0,

    -- Effective Volatility, including gain, 0 to 100
    volatility          INTEGER DEFAULT 0,

    -- Total civilian population of neighborhood,
    -- excluding unit personnel.
    population          INTEGER DEFAULT 0
);

-- nbstat Table: Group force in neighborhoods
CREATE TABLE force_ng (
    n           TEXT,         -- Symbolic nbhood name
    g           TEXT,         -- Symbolic group name

    personnel     INTEGER     -- Group's personnel
        DEFAULT 0,
    own_force     INTEGER     -- Group's own force (Q.ng)
        DEFAULT 0,
    local_force   INTEGER     -- own_force + friends in n
        DEFAULT 0,
    local_enemy   INTEGER     -- enemies in n
        DEFAULT 0,
    force         INTEGER     -- own_force + friends nearby
        DEFAULT 0,
    pct_force     INTEGER     -- 100*force/total_force
        DEFAULT 0,
    enemy         INTEGER     -- enemies nearby
        DEFAULT 0,
    pct_enemy     INTEGER     -- 100*enemy/total_force
        DEFAULT 0,
    security      INTEGER     -- Group's security in n
        DEFAULT 0,

    PRIMARY KEY (n, g)
);


--------------------------------------------------------------------
-- Group Activity Tables

-- Note that "a" is constrained to match g's gtype, as indicated
-- in the temporary activity_gtype table.
CREATE TABLE activity_nga (
    n                   TEXT,     -- Symbolic nbhoods name
    g                   TEXT,     -- Symbolic groups name
    a                   TEXT,     -- Symbolic activity name
         
    -- 1 if there's enough security to conduct the activity,
    -- and 0 otherwise.
    security_flag       INTEGER  DEFAULT 0,

    -- 1 if the group can do the activity in the neighborhood,
    -- and 0 otherwise.
    can_do              INTEGER  DEFAULT 0,

    -- Number of personnel in units in nbhood n belonging to 
    -- group g which are assigned activity a.
    nominal             INTEGER  DEFAULT 0,

    -- Number of personnel in units in nbhood n belonging to 
    -- group g which can actively pursue a given the assigned-to-active
    -- ratio.
    active              INTEGER  DEFAULT 0,

    -- Number of the active personnel that are effectively performing
    -- the activity.  This will be 0 if security_flag is 0.
    effective           INTEGER  DEFAULT 0,

    -- Coverage fraction, 0.0 to 1.0, for this activity.
    coverage            DOUBLE   DEFAULT 0.0,

    -- Type of activity situation associated with this activity
    stype               TEXT,

    -- Activity Situation ID.  This is the ID of the
    -- Activity Situation associated with this activity, if
    -- any, and 0 otherwise.
    s                   INTEGER  DEFAULT 0,


    PRIMARY KEY (n,g,a)
);


------------------------------------------------------------------------
-- Situations
--
-- Base situation data is stored in the situations table; then, 
-- Derived situation data is stored in the kind-specific table.

-- situations: base situation data

CREATE TABLE situations (
    -- Situation ID
    s             INTEGER PRIMARY KEY,

    -- Situation Kind: the singleton command of the situation kind,
    -- e.g., ::actsit
    kind      TEXT,
 
    -- Situation Type (the rule set name)
    stype     TEXT,

    -- GRAM Driver ID
    driver    INTEGER DEFAULT -1,

    -- Neighborhood
    n         TEXT,

    -- Coverage: fraction of neighborhood affected.
    coverage  DOUBLE DEFAULT 1.0,

    -- State: esitstate
    state     TEXT,

    -- Start Time, in ticks
    ts        INTEGER,

    -- Change Time, in ticks
    tc        INTEGER,

    -- Change: nature of last change
    change    TEXT DEFAULT '',

    -- List of affected groups, or 'ALL' for all
    flist     TEXT DEFAULT 'ALL',

    -- Causing Group, or 'NONE'
    g         TEXT DEFAULT 'NONE',

    -- Signature (used by Athena Driver Assessment rules)
    signature TEXT DEFAULT ''
);

-- Activity Situations
CREATE TABLE actsits_t (
    -- Situation ID
    s         INTEGER PRIMARY KEY,

    -- Activity
    a         TEXT
);

-- Activity Situations View
CREATE VIEW actsits AS
SELECT * FROM situations JOIN actsits_t USING (s);

-- Current Activity Situations View
CREATE VIEW actsits_current AS
SELECT * FROM situations JOIN actsits_t USING (s)
WHERE state != 'ENDED' OR change != '';

-- Environmental Situations
CREATE TABLE ensits_t (
    -- Situation ID
    s          INTEGER PRIMARY KEY,

    -- Location, in map coordinates
    location   TEXT,

    --------------------------------------------------------------------
    -- The following columns are set when the GRAM implications of the
    -- situation need to be assessed at the next time tick.

    -- Flag: 1 if this is a new situation, and inception effects should 
    -- be assessed; 0 otherwise.  (This will be set to 0 for situations
    -- that are on-going at time 0.)
    inception  INTEGER,

    -- Resolving group (may be empty): name of the group that resolved
    -- the situation, if any.  This will only be set in the ENDED state.
    resolver   TEXT DEFAULT '',

    -- Resolution Driver; 0 if the situation's resolution has not been
    -- assessed, and a GRAM driver ID if it has.
    rdriver INTEGER DEFAULT 0
);

-- Environmental Situations View
CREATE VIEW ensits AS
SELECT * FROM situations JOIN ensits_t USING (s);

-- Current Environmental Situations View: i.e., situations of current
-- interest to the analyst
CREATE VIEW ensits_current AS
SELECT * FROM situations JOIN ensits_t USING (s)
WHERE state != 'ENDED' OR change != '';


------------------------------------------------------------------------
-- Demographic Model
--
-- The following tables are used to track the demographics of each
-- neighborhood.

-- Demographics of the neighborhood as a whole

CREATE TABLE demog_n (
    -- Symbolic neighborhood name
    n            TEXT PRIMARY KEY,

    -- Total population (e.g., consumers) in the neighborhood at the
    -- current time.
    population   INTEGER DEFAULT 0,

    -- Total labor force in the neighborhood at the current time
    labor_force  INTEGER DEFAULT 0
);

-- Demographics of particular nbgroups

CREATE TABLE demog_ng (
    -- Symbolic neighborhood name
    n              TEXT,

    -- Symbolic civgroup name
    g              TEXT,

    -- Attrition to this nbgroup (total killed)
    attrition      INTEGER DEFAULT 0,

    -- Explicit population: personnel in units regardless of location
    explicit       INTEGER DEFAULT 0,

    -- Displaced population: personnel in units in other neighborhoods
    displaced      INTEGER DEFAULT 0,

    -- Implicit population: population implicit in the neighborhood
    implicit       INTEGER DEFAULT 0,

    -- Total population of this nbgroup in this neighborhood at the
    -- current time.
    population     INTEGER DEFAULT 0,

   
    PRIMARY KEY (n, g)
);
