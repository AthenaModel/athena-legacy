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
PRAGMA user_version=3;

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

    -- Order narrative
    narrative TEXT default '',

    -- Parameter Dictionary
    parmdict TEXT,

    -- Undo Command, or ''
    undo     TEXT DEFAULT ''
);

CREATE INDEX cif_index ON cif(time,id);

-- Significant Simulation Events Log
--
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

-- Marks table.  An event can be marked to indicate the beginning of
-- a new sequence of events, e.g., events related to a particular 
-- game turn.  This allows a portion of the log to be displayed,
-- relative to a particular kind of mark.

CREATE TABLE sigevent_marks (
    event_id INTEGER REFERENCES sigevents(event_id)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    mark     TEXT,

    PRIMARY KEY (event_id, mark)
);

CREATE VIEW sigevents_view AS
SELECT *
FROM sigevents JOIN sigevent_tags USING (event_id);


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

    -- 1 if Local (e.g., part of the region of interest), 0 o.w.
    local          INTEGER DEFAULT 1.0,

    -- Stacking order: 1 is low, N is high
    stacking_order INTEGER,

    -- Urbanization: eurbanization
    urbanization   TEXT,

    -- Actor controlling the neighborhood at time 0.
    controller     TEXT REFERENCES actors(a)
                   ON DELETE SET NULL
                   DEFERRABLE INITIALLY DEFERRED, 

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
    m             TEXT REFERENCES nbhoods(n)
                  ON DELETE CASCADE
                  DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic nbhood name
    n             TEXT REFERENCES nbhoods(n)
                  ON DELETE CASCADE
                  DEFERRABLE INITIALLY DEFERRED,

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
-- Actor Tables

-- Actor Data
CREATE TABLE actors (
    -- Symbolic actor name
    a           TEXT PRIMARY KEY,

    -- Full actor name
    longname    TEXT,

    -- Money saved for later, in $.
    cash_reserve DOUBLE DEFAULT 0,

    -- Income/tactics tock, in $.
    -- TBD: A present this is an input; later it will be computed.
    income      DOUBLE DEFAULT 0,

    -- Money available to be spent, in $.
    -- Unspent cash accumulates from tock to tock.
    cash_on_hand DOUBLE DEFAULT 0
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

    -- Group demeanor: edemeanor
    demeanor    TEXT DEFAULT 'AVERAGE',

    -- Base Population/Personnel for this group
    basepop     INTEGER DEFAULT 0,

    -- Maintenance Cost, in $/person/week (FRC/ORG groups only)
    cost        DOUBLE DEFAULT 0,

    -- Relationship Entity
    rel_entity  TEXT REFERENCES mam_entity(eid)
                ON DELETE SET NULL 
                DEFERRABLE INITIALLY DEFERRED,

    -- Group type, CIV, FRC, ORG
    gtype       TEXT
);

-- Civ Groups
CREATE TABLE civgroups (
    -- Symbolic group name
    g           TEXT PRIMARY KEY,

    -- Symbolic neighborhood name for neighborhood of residence.
    n              TEXT,

    -- Subsistence Agriculture Percentage in n.
    sap            INTEGER DEFAULT 0
);

-- Civ Groups View: joins groups with civgroups.
CREATE VIEW civgroups_view AS
SELECT g, 
       longname,
       color,
       shape,
       symbol,
       demeanor,
       basepop,
       rel_entity,
       gtype,
       n,
       sap 
FROM groups JOIN civgroups USING (g);

-- Force Groups
CREATE TABLE frcgroups (
    -- Symbolic group name
    g           TEXT PRIMARY KEY,

    -- Owning Actor
    a           TEXT REFERENCES actors(a)
                ON DELETE SET NULL
                DEFERRABLE INITIALLY DEFERRED, 

    -- Force Type
    forcetype   TEXT,

    -- Uniformed or Non-uniformed: 1 or 0
    uniformed   INTEGER DEFAULT 1,

    -- Local or foreign: 1 if local, 0 if foreign
    local       INTEGER
);

-- Force Group View: joins groups with frcgroups.
CREATE VIEW frcgroups_view AS
SELECT * FROM groups JOIN frcgroups USING (g);


-- Org Groups
CREATE TABLE orggroups (
    -- Symbolic group name
    g           TEXT PRIMARY KEY,

    -- Owning Actor
    a           TEXT REFERENCES actors(a)
                ON DELETE SET NULL
                DEFERRABLE INITIALLY DEFERRED, 

    -- Organization type: eorgtype
    orgtype     TEXT DEFAULT 'NGO'
);

-- Org Group View: joins groups with orggroups.
CREATE VIEW orggroups_view AS
SELECT * FROM groups JOIN orggroups USING (g);

-- AGroups View: Groups that can be owned by actors
CREATE VIEW agroups AS
SELECT g, gtype, longname, a, cost, forcetype AS subtype
FROM frcgroups JOIN groups USING (g)
UNION
SELECT g, gtype, longname, a, cost, orgtype   AS subtype
FROM orggroups JOIN groups USING (g);


------------------------------------------------------------------------
-- Support/Control tables

-- vrel_ga table: Vertical relationships between groups and actors.
--
-- Note: We don't cascade deletions, as this table is populated only 
-- during simulation, when actors and groups aren't being deleted.

CREATE TABLE vrel_ga (
    -- Symbolic group name
    g           TEXT REFERENCES groups(g)
                DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a           TEXT REFERENCES actors(a)
                DEFERRABLE INITIALLY DEFERRED,

    -- Tick of bvrel_tga entry used to compute vrel
    bvt         INTEGER DEFAULT 0,

    -- Vertical Relationship of g with a
    vrel        REAL DEFAULT 0.0,

    -- Deltas to vrel: qmag(n) symbols, or 0.  This is for
    -- visualization purposes.

    dv_beliefs  TEXT DEFAULT '0', -- deltaV due to changed beliefs
    dv_mood     TEXT DEFAULT '0', -- deltaV due to group mood
    dv_services TEXT DEFAULT '0', -- deltaV due to basic services
    dv_tactics  TEXT DEFAULT '0', -- deltaV due actor's choice of tactics

    PRIMARY KEY (g, a)
);

-- bvrel_tga table: Base vertical relationships at transition points.

CREATE TABLE bvrel_tga (
    -- Time of shift of control in g's neighborhood
    t                 INTEGER,

    -- Symbolic group name
    g           TEXT REFERENCES groups(g)
                DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a           TEXT REFERENCES actors(a)
                DEFERRABLE INITIALLY DEFERRED,

    -- Base Vertical Relationship of g with a
    bvrel       REAL DEFAULT 0.0,

    -- Delta due to change of control: qmag(n) symbol, or 0
    dv_control  TEXT DEFAULT '0',

    PRIMARY KEY (t, g, a)
);

-- support_nga table: Support for actor a by group g in nbhood n

CREATE TABLE support_nga (
    -- Symbolic group name
    n         TEXT REFERENCES nbhoods(n)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic group name
    g         TEXT REFERENCES groups(g)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a         TEXT REFERENCES actors(a)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Vertical Relationship of g with a
    vrel      REAL DEFAULT 0.0,

    -- g's personnel in n
    personnel INTEGER DEFAULT 0,

    -- g's security in n
    security  INTEGER DEFAULT 0,

    -- Contribution of g to a's support in n
    support   REAL DEFAULT 0.0,

    -- Contribution of g to a's influence in n.
    -- (support divided total support in n)
    influence REAL DEFAULT 0.0,

    PRIMARY KEY (n, g, a)
);


-- influence_na table: Actor's influence in neighborhood.
--
-- Note: We don't cascade deletions, as this table is populated only 
-- during simulation, when the referenced entities aren't being deleted.

CREATE TABLE influence_na (
    -- Symbolic group name
    n         TEXT REFERENCES nbhoods(n)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a         TEXT REFERENCES actors(a)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Support for a in n
    support   REAL DEFAULT 0.0,

    -- Influence of a in n
    influence REAL DEFAULT 0.0,

    PRIMARY KEY (n, a)
);

-- control_n table: Control of neighborhood n

CREATE TABLE control_n (
    -- Symbolic group name
    n          TEXT PRIMARY KEY 
               REFERENCES nbhoods(n)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Support for a in n
    controller TEXT REFERENCES actors(a)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Time at which controller took control
    since      INTEGER DEFAULT 0
);

------------------------------------------------------------------------
-- Condition Collection Table
--
-- Tactics and Goals are both "condition collections"; they can have
-- attached conditions.

CREATE TABLE cond_collections (
    cc_id   INTEGER PRIMARY KEY,
    cc_type TEXT NOT NULL        -- tactic|goal
);

------------------------------------------------------------------------
-- Goals Table
--
-- The goals table stores the goals pursued by the various actors.

CREATE TABLE goals (
    -- The goal_id is, in fact, a cond_collections.cc_id.  We do not
    -- reference it explicitly because the cond_collections record is
    -- deleted when a tactics or goals row is deleted, not the
    -- other way around.
    goal_id      INTEGER PRIMARY KEY, 
    
    -- Owning Actor
    owner        TEXT REFERENCES actors(a)
                 ON DELETE CASCADE
                 DEFERRABLE INITIALLY DEFERRED, 

    -- Narrative: For goals, this is a user-edited string.
    narrative    TEXT NOT NULL,

    -- State: normal, disabled, invalid (egoal_state)
    state        TEXT DEFAULT 'normal',

    -- Flag: 1 (met), 0 (unmet), or NULL (unknown)
    flag         INTEGER
);

-- A goal is a condition owner; thus, we need a trigger to delete
-- the cond_collections row when a goal is deleted.

CREATE TRIGGER goal_delete
AFTER DELETE ON goals BEGIN
    DELETE FROM cond_collections WHERE cc_id = old.goal_id;
END;


------------------------------------------------------------------------
-- Tactics Table
--
-- The tactics table stores the tactics in use by the various actors.

CREATE TABLE tactics (
    -- The tactic_id is, in fact, a cond_collections.cc_id.  We do not
    -- reference it explicitly because the cond_collections record is
    -- deleted when a tactics or goals row is deleted, not the
    -- other way around.
    tactic_id    INTEGER PRIMARY KEY, 
    tactic_type  TEXT,
    
    -- Owning Actor
    owner        TEXT REFERENCES actors(a)
                 ON DELETE CASCADE
                 DEFERRABLE INITIALLY DEFERRED, 

    -- Narrative: different tactics use different sets of parameters, 
    -- so a conventional browser of all of the columns is 
    -- user-unfriendly.  Instead, we compute a narrative string.
    narrative    TEXT,

    -- Priority: This is used to place each actor's tactics in 
    -- order of execution.
    priority     INTEGER,

    -- Once flag, 1 or 0.  If 1, the tactic will be automatically disabled
    -- on successful execution.
    once         INTEGER DEFAULT 0,

    -- State: normal, disabled, invalid (etactic_state)
    state        TEXT DEFAULT 'normal',

    -- time of last execution, in ticks
    exec_ts      INTEGER,

    -- Flag: 1 if tactic was selected for execution at the last tactics 
    -- tock, and 0 otherwise.
    exec_flag    INTEGER DEFAULT 0,

    -- Type-specific Parameters: These columns are used in different
    -- ways by different tactics; all are NULL if unused.  No
    -- foreign key constraints; errors are checked by tactic-type
    -- sanity checker, to give the user more flexibility.

    -- Neighborhoods; use n first.
    m            TEXT,   -- One neighborhood
    n            TEXT,   -- One neighborhood
    nlist        TEXT,   -- List of neighborhoods

    -- Groups; use g first.
    f            TEXT,
    g            TEXT,

    -- Data items
    text1        TEXT,
    int1         INTEGER
);

-- A tactic is a condition owner; thus, we need a trigger to delete
-- the cond_collections row when a tactic is deleted.

CREATE TRIGGER tactics_delete
AFTER DELETE ON tactics BEGIN
    DELETE FROM cond_collections WHERE cc_id = old.tactic_id;
END;


------------------------------------------------------------------------
-- Conditions Table
--
-- The conditions table stores the conditions in use by the various
-- goals and tactics.

CREATE TABLE conditions (
    condition_id   INTEGER PRIMARY KEY,
    condition_type TEXT, -- econdition_type(n)
    
    -- Condition collection (a goal or tactic)
    cc_id          INTEGER REFERENCES cond_collections(cc_id)
                   ON DELETE CASCADE
                   DEFERRABLE INITIALLY DEFERRED, 

    -- Owning Actor: The actor that owns the condition collection
    owner          TEXT REFERENCES actors(a)
                   ON DELETE CASCADE
                   DEFERRABLE INITIALLY DEFERRED, 

    -- Narrative: different conditions use different sets of parameters, 
    -- so a conventional browser of all of the columns is 
    -- user-unfriendly.  Instead, we compute a narrative string.
    narrative     TEXT,

    -- State: normal, disabled, invalid (econdition_state)
    state         TEXT DEFAULT 'normal',

    -- Flag: 1 (met), 0 (unmet), or NULL (unknown)
    flag         INTEGER,

    -- Type-specific Parameters: These columns are used in different
    -- ways by different conditions; all are NULL if unused.

    a             TEXT,    -- An actor
    g             TEXT,    -- An group
    n             TEXT,    -- A neighborhood
    op1           TEXT,    -- An operation
    t1            INTEGER, -- A time in ticks
    t2            INTEGER, -- A time in ticks
    text1         TEXT,    -- A text string
    list1         TEXT,    -- A list
    x1            REAL     -- A number
);

------------------------------------------------------------------------
-- Personnel Tables

-- FRC and ORG personnel in playbox.
CREATE TABLE personnel_g (
    -- Symbolic group name
    g          TEXT PRIMARY KEY
               REFERENCES groups(g)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Personnel in playbox
    personnel  INTEGER DEFAULT 0
);

-- Deployment Table: FRC and ORG personnel deployed into neighborhoods.
CREATE TABLE deploy_ng (
    -- Symbolic neighborhood name
    n          TEXT REFERENCES nbhoods(n)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic group name
    g          TEXT REFERENCES groups(g)
               DEFERRABLE INITIALLY DEFERRED,

    -- Personnel
    personnel  INTEGER DEFAULT 0,

    -- Unassigned personnel.
    unassigned INTEGER DEFAULT 0,
    
    PRIMARY KEY (n,g)
);


------------------------------------------------------------------------
-- Athena Attrition Model: ROE tables

-- Attacking ROE table: Uniformed and Non-uniformed Forces

CREATE TABLE attroe_nfg (
    -- Neighborhood in which to attack
    n          TEXT REFERENCES nbhoods(n)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Attacking force group
    f          TEXT REFERENCES frcgroups(g)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Attacked force group
    g          TEXT REFERENCES frcgroups(g)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- 1 if f is uniformed, and 0 otherwise.
    uniformed  INTEGER,

    -- ROE: eattroenf for non-uniformed forces, eattroeuf for uniformed
    -- forces.  Note: a missing record for n,f,g is equivalent to an
    -- ROE of DO_NOT_ATTACK.
    roe        TEXT DEFAULT 'DO_NOT_ATTACK',

    -- Cooperation limit: f will not attack unless n's cooperation with
    -- f meets or exceeds cooplimit.
    cooplimit  DOUBLE DEFAULT 50.0,

    -- Nominal attacks/day.  (Non-uniformed forces only.)
    rate       DOUBLE DEFAULT 0.0,
    
    PRIMARY KEY (n,f,g)
);


-- Defending ROE table: overrides defending ROE for
-- Uniformed Forces only.

CREATE TABLE defroe_ng (
    -- Neighborhood in which to defend
    n          TEXT REFERENCES nbhoods(n)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Defending force group
    g          TEXT REFERENCES frcgroups(g)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- ROE: edefroeuf.
    roe        TEXT,

    PRIMARY KEY (n,g)
);

-- Defending ROE view
--
-- This view computes the current defending ROE for every 
-- uniformed force group.
--
-- * The ROE defaults to FIRE_BACK_IF_PRESSED...
-- * ...unless there's an overriding entry in defroe_ng.

CREATE VIEW defroe_view AS
SELECT nbhoods.n                             AS n,
       frcgroups.g                           AS g,
       COALESCE(roe, 'FIRE_BACK_IF_PRESSED') AS roe,
       CASE WHEN defroe_ng.roe IS NOT NULL 
            THEN 1
            ELSE 0 END                       AS override
       
FROM nbhoods
JOIN frcgroups
LEFT OUTER JOIN defroe_ng USING (n,g);


-- An instance of attrition to a group in a neighborhood.  These records
-- are accumulated between attrition tocks and are used to assess 
-- satisfaction implications.

CREATE TABLE attrit_nf (
    -- Unique ID, assigned automatically.
    id         INTEGER PRIMARY KEY,

    -- Neighborhood.  For ORG's the nbhood which the attrition occurred.
    -- For CIV's, the nbhood of origin (which is usually the same thing).
    n          TEXT,
   
    -- Group to which the attrition occurred
    f          TEXT,

    -- Total attrition (in personnel) to group f.
    casualties INTEGER
);

CREATE INDEX attrit_nf_index_nf ON attrit_nf(n,f);

-- Total attrition to a CIV group in a neighborhood by responsible group, 
-- as accumulated between attrition tocks.  Note that multiple groups
-- can be responsible for the same casualty, e.g., in a fire fight
-- between two force groups, both can be blamed for collateral damage.
-- This is used to assess cooperation implications.

CREATE TABLE attrit_nfg (
    -- Unique ID, assigned automatically.
    id         INTEGER PRIMARY KEY,

    -- Neighborhood of origin of the attrited personnel.
    n          TEXT,
   
    -- CIV group to which the attrition occurred
    f          TEXT,

    -- Responsible group.
    g          TEXT,

    -- Total attrition (in personnel) to group f.
    casualties INTEGER
);

CREATE INDEX attrit_nfg_index_nfg ON attrit_nfg(n,f,g);


------------------------------------------------------------------------
-- Initial Satisfaction Data


-- Group/concern pairs (g,c) for civilian groups
-- This table contains the data used to initialize GRAM.

CREATE TABLE sat_gc (
    -- Symbolic groups name
    g          TEXT REFERENCES civgroups(g) 
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic concerns name
    c          TEXT,

    -- Initial satisfaction value
    sat0       DOUBLE DEFAULT 0.0,

    -- Saliency of concern c to group g in nbhood n
    saliency   DOUBLE DEFAULT 1.0,

    -- Ascending trend and threshold
    atrend     DOUBLE DEFAULT 0.0,
    athresh    DOUBLE DEFAULT 0.0,

    -- Descending trend and threshold
    dtrend     DOUBLE DEFAULT 0.0,
    dthresh    DOUBLE DEFAULT 0.0,

    PRIMARY KEY (g, c)
);


------------------------------------------------------------------------
-- Initial Relationship Data

-- rel_fg: Group f's relationship with group g, from
-- f's point of view.

CREATE TABLE rel_fg (
    -- Symbolic group name: group f
    f    TEXT REFERENCES groups(g)
         ON DELETE CASCADE
         DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic group name: group g
    g    TEXT REFERENCES groups(g)
         ON DELETE CASCADE
         DEFERRABLE INITIALLY DEFERRED,

    -- Group relationship, from f's point of view.
    rel  DOUBLE DEFAULT 0.0,

    PRIMARY KEY (f, g)
);

------------------------------------------------------------------------
-- Relationship View

-- This view computes the horizontal relationship for each pair of 
-- groups.  The relationship defaults to the affinity between the
-- groups' relationship entities, and can be explicitly overridden
-- in the rel_fg table.  There are a couple of special cases:
--
-- * The relationship of a group with itself is forced to 1.0; and
--   this cannot be overridden.  A group has a self-identity that
--   it does not share with other groups and that the affinity model
--   does not take into account.
--
-- * IN THE FUTURE, the relationship of two CIV groups with the same 
--   rel_entity should also be 1.0.  This case would arise only because
--   of the split of a CIV group (something we do not yet do in
--   Athena); thus, the two groups are the same group, at least in the
--   short run.  (Once we have truly dynamic inter-group relationships,
--   all bets are off.)
--
-- * Two FRC/ORG groups with the same rel_entity do NOT have a 
--   relationship of 1.0, as they lack that self-identity.  
--   Consider the rivalry between the Army and the Navy.

CREATE VIEW rel_view AS
SELECT F.g                                       AS f,
       G.g                                       AS g,
       CASE WHEN F.g = G.g  -- TBD: Use rel_entity for CIVs, once
            THEN 1.0        -- groups can be split.
            ELSE coalesce(R.rel, A.affinity) END AS rel,
       CASE WHEN R.rel IS NOT NULL 
            THEN 1
            ELSE 0 END                           AS override
FROM groups AS F
JOIN groups AS G
JOIN mam_affinity AS A ON (A.f = F.rel_entity AND A.g = G.rel_entity)
LEFT OUTER JOIN rel_fg AS R ON (R.f = F.g AND R.g = G.g);


------------------------------------------------------------------------
-- Initial Cooperation Data

-- coop_fg: Group f's cooperation with group gn, that
-- is, the likelihood that f will provide intel to g.
--
-- At present, cooperation is defined only between all
-- civgroups f and all force groups g.

CREATE TABLE coop_fg (
    -- Symbolic civ group name: group f
    f           TEXT REFERENCES civgroups(g)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic frc group name: group g
    g           TEXT REFERENCES frcgroups(g)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED,

    -- cooperation of f with g at time 0.
    coop0       DOUBLE DEFAULT 50.0,

    -- Ascending trend and threshold
    atrend     DOUBLE DEFAULT 0.0,
    athresh    DOUBLE DEFAULT 50.0,

    -- Descending trend and threshold
    dtrend     DOUBLE DEFAULT 0.0,
    dthresh    DOUBLE DEFAULT 50.0,

    PRIMARY KEY (f, g)
);

------------------------------------------------------------------------
-- Units

-- General unit data
CREATE TABLE units (
    -- Symbolic unit name
    u                TEXT PRIMARY KEY,

    -- Calendar Item ID, or 0 if a = NONE
    cid              INTEGER,

    -- Active flag: 1 if active, 0 otherwise.  A unit is active if it
    -- is currently scheduled.
    active           INTEGER,

    -- Neighborhood to which unit is deployed
    n                TEXT,

    -- Group to which the unit belongs
    g                TEXT,

    -- Group type
    gtype            TEXT,

    -- Neighborhood of Origin
    origin           TEXT,

    -- Unit activity: eactivity(n) value
    a                TEXT,

    -- Total Personnel
    personnel        INTEGER DEFAULT 0,

    -- Location, in map coordinates, within n
    location         TEXT,

    -- Activity effective flag: 1 if activity is effective, and 0 otherwise.
    -- TBD: Not set; might go away.
    a_effective      INTEGER DEFAULT 0,

    -- Attrition Flag: 1 if the unit is about to be attrited.
    attrit_flag      INTEGER DEFAULT 0
);

CREATE INDEX units_ngoa_index ON
units(n,g,origin,a);

CREATE INDEX units_ngap_index ON
units(n,g,a,personnel);

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
    volatility          INTEGER DEFAULT 0
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

    -- Number of personnel in nbhood n belonging to 
    -- group g which are assigned activity a.
    nominal             INTEGER  DEFAULT 0,

    -- Number of personnel in nbhood n belonging to 
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

-- Activity calendar
CREATE TABLE calendar (
    -- Calendar Item ID
    cid          INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Scheduled activity

    -- Neighborhood in which personnel are based
    n            TEXT REFERENCES nbhoods(n)
                 ON DELETE CASCADE
                 DEFERRABLE INITIALLY DEFERRED,

    -- Group providing personnel
    g            TEXT REFERENCES groups(g)
                 ON DELETE CASCADE
                 DEFERRABLE INITIALLY DEFERRED,

    -- Activity being performed        
    a            TEXT,

    -- Neighborhood targetted by activity
    tn           TEXT REFERENCES nbhoods(n)
                 ON DELETE CASCADE
                 DEFERRABLE INITIALLY DEFERRED,

    -- Number personnel scheduled.
    personnel    INTEGER,

    -- Priority of this item
    priority     INTEGER DEFAULT 0,

    -- Time tick at which item takes effect.
    start        INTEGER,

    -- Time tick at which item ceases, or ''  
    finish       INTEGER,  

    -- Pattern, calpattern(sim) value
    pattern      TEXT DEFAULT 'daily'
);

CREATE INDEX calendar_nga_index 
ON calendar(n,g,a);


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

    -- Inception Flag: 1 if this is a new situation, and inception 
    -- effects should be assessed, and 0 otherwise.  (This will be set 
    -- to 0 for situations that are on-going at time 0.)
    inception  INTEGER,

    -- Resolving group: name of the group that resolved/will resolve
    -- the situation, or 'NONE'
    resolver   TEXT DEFAULT 'NONE',

    -- Auto-resolution duration: 0 if the situation will not auto-resolve,
    -- and a duration in ticks otherwise.
    rduration  INTEGER DEFAULT 0,

    -- Resolution Driver; 0 if the situation's resolution has not been
    -- assessed, and a GRAM driver ID if it has.
    rdriver    INTEGER DEFAULT 0
);

-- Environmental Situations View
CREATE VIEW ensits AS
SELECT * FROM situations JOIN ensits_t USING (s);

-- Current Environmental Situations View: i.e., situations of current
-- interest to the analyst
CREATE VIEW ensits_current AS
SELECT * FROM situations JOIN ensits_t USING (s)
WHERE state != 'ENDED' OR change != '';

-- Demographic Situations
CREATE TABLE demsits_t (
    -- Situation ID
    s         INTEGER PRIMARY KEY,

    -- Factors

    -- Neighborhood factor
    nfactor   DOUBLE,

    -- Neighborhood group factor
    ngfactor  DOUBLE
);

-- Demographic Situations View
CREATE VIEW demsits AS
SELECT * FROM situations JOIN demsits_t USING (s);

-- Current Demographic Situations View: i.e., situations of current
-- interest to the analyst
CREATE VIEW demsits_current AS
SELECT * FROM situations JOIN demsits_t USING (s)
WHERE state != 'ENDED' OR change != '';

------------------------------------------------------------------------
-- Magic Attitude Drivers (MADs)
--
-- Magic inputs to GRAM are associated with MADs for causality purposes.
-- A MAD is similar to an event or situation.

CREATE TABLE mads (
   -- MAD ID
   id            INTEGER PRIMARY KEY,
   
   -- One line description
   oneliner      TEXT,

   -- Cause: an ecause(n) value, or 'UNIQUE'
   cause         TEXT DEFAULT 'UNIQUE',

   -- Here Factor (s), a real fraction (0.0 to 1.0)
   s             DOUBLE DEFAULT 1.0,

   -- Near Factor (p), a real fraction (0.0 to 1.0)
   p             DOUBLE DEFAULT 0.0,

   -- Near Factor (q), a real fraction (0.0 to 1.0)
   q             DOUBLE DEFAULT 0.0,

   -- GRAM Driver ID
   driver        INTEGER DEFAULT -1
);


------------------------------------------------------------------------
-- Demographic Model
--
-- The following tables are used to track the demographics of each
-- neighborhood.

-- Demographics of the region of interest (i.e., of nbhoods for
-- which local=1)

CREATE TABLE demog_local (
    -- Total population in local neighborhoods at the current time.
    population   INTEGER DEFAULT 0,

    -- Total consumers in local neighborhoods at the current time.
    consumers    INTEGER DEFAULT 0,

    -- Total labor force in local neighborhoods at the current time
    labor_force  INTEGER DEFAULT 0
);

-- Demographics of the neighborhood as a whole

CREATE TABLE demog_n (
    -- Symbolic neighborhood name
    n            TEXT PRIMARY KEY REFERENCES nbhoods(n)
                 ON DELETE CASCADE
                 DEFERRABLE INITIALLY DEFERRED,

    -- Total displaced population in the neighborhood at the current time.
    displaced    INTEGER DEFAULT 0,

    -- Total displaced labor force in the neighborhood at the current time.
    displaced_labor_force INTEGER DEFAULT 0,

    -- Total population in the neighborhood at the current time
    -- (nbgroups + displaced)
    population   INTEGER DEFAULT 0,

    -- Total subsistence population in the neighborhood at the current time
    subsistence  INTEGER DEFAULT 0,

    -- Total consumers in the neighborhood at the current time
    -- (nbgroups + displaced)
    consumers    INTEGER DEFAULT 0,

    -- Total labor force in the neighborhood at the current time
    -- (nbgroups + displaced)
    labor_force  INTEGER DEFAULT 0,

    -- Unemployed workers in the neighborhood.
    unemployed   INTEGER DEFAULT 0,

    -- Unemployed per capita (percentage)
    upc          DOUBLE DEFAULT 0.0,

    -- Unemployment Attitude Factor
    uaf          DOUBLE DEFAULT 0.0
);

-- Demographics of particular civgroups

CREATE TABLE demog_g (
    -- Symbolic civgroup name
    g              TEXT PRIMARY KEY,

    -- Attrition to this group (total killed)
    attrition      INTEGER DEFAULT 0,

    -- Displaced population: personnel in units in other neighborhoods
    displaced      INTEGER DEFAULT 0,

    -- Total residents of this group in its home neighborhood at the
    -- current time.
    population     INTEGER DEFAULT 0,

    -- Subsistence population: population doing subsistence agriculture
    -- and outside the regional economy.
    subsistence    INTEGER DEFAULT 0,

    -- Consumer population: population within the regional economy
    consumers      INTEGER DEFAULT 0,

    -- Labor Force: workers available to the regional economy
    labor_force    INTEGER DEFAULT 0,

    -- Unemployed workers in the home neighborhood.
    unemployed     INTEGER DEFAULT 0,

    -- Unemployed per capita (percentage)
    upc            DOUBLE DEFAULT 0.0,

    -- Unemployment Attitude Factor
    uaf            DOUBLE DEFAULT 0.0,

    -- Demographic Situation ID.  This is the ID of the
    -- demsit associated with this record, if
    -- any, and 0 otherwise.
    --
    -- NOTE: This implementation is fine so long as we have
    -- only *one* kind of demsit.  If we add more, we'll need
    -- to do something different.  The right answer depends on
    -- what demsits turn out to have in common.
    s              INTEGER  DEFAULT 0
);


-- Demographic Situation Context View
--
-- This view identifies the neighborhood groups that can have
-- demographic situations, and pulls in required context from
-- other tables.
CREATE VIEW demog_context AS
SELECT CG.n              AS n,
       DG.g              AS g,
       DG.uaf            AS ngfactor,
       DG.s              AS s,
       DN.uaf            AS nfactor
FROM demog_g   AS DG
JOIN civgroups AS CG USING (g)
JOIN demog_n   AS DN USING (n);

------------------------------------------------------------------------
-- Economic Model
--
-- The following tables are used by the Economic model to track 
-- neighborhood inputs and outputs.

-- Neighborhood inputs and outputs.  
--
-- NOTE: All production capacities and related factors concern the 
-- "goods" sector; when we add additional kinds of production, we'll
-- probably need to elaborate this scheme considerably.

CREATE TABLE econ_n (
    -- Symbolic neighborhood name
    n          TEXT PRIMARY KEY REFERENCES nbhoods(n)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- The following columns can be ignored if nbhoods.local == 0.    

    -- Input, Production Capacity Factor (PCF)
    pcf        DOUBLE DEFAULT 1.0,

    -- Output, Capacity Calibration Factor (CCF)
    ccf        DOUBLE DEFAULT 0.0,

    -- Output, Production Capacity at time 0
    cap0       DOUBLE DEFAULT 0,

    -- Output, Production Capacity at time t
    cap        DOUBLE DEFAULT 0
);

-- A view of only those econ_n records that correspond to local
-- neighborhoods.
CREATE VIEW econ_n_view AS
SELECT * FROM nbhoods JOIN econ_n USING (n) WHERE nbhoods.local = 1;

------------------------------------------------------------------------
-- History
--
-- The following tables are used to save time series variable data
-- for plotting, etc.  Each table has a name like "history_<vartype>"
-- where <vartype> is a time series variable type.  In some cases,
-- one table might contain multiple variables; in that case it will
-- be named after the primary one.

-- sat.g.c
CREATE TABLE hist_sat (
    t   INTEGER,
    g   TEXT,
    c   TEXT,
    sat DOUBLE,

    PRIMARY KEY (t,g,c)
);

-- mood.g
CREATE TABLE hist_mood (
    t   INTEGER,
    g   TEXT,
    sat DOUBLE,

    PRIMARY KEY (t,g)
);

-- nbmood.n
CREATE TABLE hist_nbmood (
    t   INTEGER,
    n   TEXT,
    sat DOUBLE,

    PRIMARY KEY (t,n)
);

-- coop.f.g
CREATE TABLE hist_coop (
    t    INTEGER,
    f    TEXT,
    g    TEXT,
    coop DOUBLE,

    PRIMARY KEY (t,f,g)
);

-- nbcoop.n.g
CREATE TABLE hist_nbcoop (
    t      INTEGER,
    n      TEXT,
    g      TEXT,
    nbcoop DOUBLE,

    PRIMARY KEY (t,n,g)
);

-- econ
CREATE TABLE hist_econ (
    t           INTEGER PRIMARY KEY,
    consumers   INTEGER,
    labor       INTEGER,
    lsf         DOUBLE,
    cpi         DOUBLE,
    dgdp        DOUBLE,
    ur          DOUBLE
);

-- econ.i
CREATE TABLE hist_econ_i (
    t           INTEGER,
    i           TEXT,
    p           DOUBLE,
    qs          DOUBLE,
    rev         DOUBLE,

    PRIMARY KEY (t,i)
);

-- econ.i.j
CREATE TABLE hist_econ_ij (
    t           INTEGER,
    i           TEXT,
    j           TEXT,
    x           DOUBLE,
    qd          DOUBLE,

    PRIMARY KEY (t,i,j)        
);


