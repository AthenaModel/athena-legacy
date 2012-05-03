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

    PRIMARY KEY (m, n)
);

------------------------------------------------------------------------
-- Actor Tables

-- Actor Data
CREATE TABLE actors (
    -- Symbolic actor name
    a            TEXT PRIMARY KEY,

    -- Full actor name
    longname     TEXT,

    -- Supports actor (actor name or NULL)
    supports     TEXT REFERENCES actors(a)
                 ON DELETE SET NULL
                 DEFERRABLE INITIALLY DEFERRED,

    -- Money saved for later, in $.
    cash_reserve DOUBLE DEFAULT 0,

    -- Income/tactics tock, in $.
    -- TBD: A present this is an input; later it will be computed.
    income       DOUBLE DEFAULT 0,

    -- Money available to be spent, in $.
    -- Unspent cash accumulates from tock to tock.
    cash_on_hand DOUBLE DEFAULT 0
);

CREATE TRIGGER actor_delete
AFTER DELETE ON actors BEGIN
    DELETE FROM goals      WHERE owner = old.a;
    DELETE FROM tactics    WHERE owner = old.a;
    DELETE FROM conditions WHERE owner = old.a;
END;


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

    -- Base Population/Personnel for this group
    basepop     INTEGER DEFAULT 0,

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

    -- Cost/Attack, in $
    attack_cost DOUBLE DEFAULT 0,

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

-- supports_na table: Actor supported by Actor a in n.

CREATE TABLE supports_na (
    -- Symbolic group name
    n         TEXT REFERENCES nbhoods(n)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a         TEXT REFERENCES actors(a)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Supported actor name, or NULL
    supports  TEXT REFERENCES actors(a)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    PRIMARY KEY (n, a)
);


-- support_nga table: Support for actor a by group g in nbhood n

CREATE TABLE support_nga (
    -- Symbolic group name
    n                TEXT REFERENCES nbhoods(n)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic group name
    g                TEXT REFERENCES groups(g)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a                TEXT REFERENCES actors(a)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Vertical Relationship of g with a
    vrel             REAL DEFAULT 0.0,

    -- g's personnel in n
    personnel        INTEGER DEFAULT 0,

    -- g's security in n
    security         INTEGER DEFAULT 0,

    -- Direct Contribution of g to a's support in n
    direct_support   REAL DEFAULT 0.0,

    -- Actual Contribution of g to a's support in n,
    -- given a's support of other actors, and other actor's support
    -- of a.
    support          REAL DEFAULT 0.0,

    -- Contribution of g to a's influence in n.
    -- (support divided total support in n)
    influence        REAL DEFAULT 0.0,

    PRIMARY KEY (n, g, a)
);


-- influence_na table: Actor's influence in neighborhood.
--
-- Note: We don't cascade deletions, as this table is populated only 
-- during simulation, when the referenced entities aren't being deleted.

CREATE TABLE influence_na (
    -- Symbolic group name
    n                TEXT REFERENCES nbhoods(n)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a                TEXT REFERENCES actors(a)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Direct Support for a in n
    direct_support   REAL DEFAULT 0.0,

    -- Actual Support for a in n, including direct support and support
    -- from other actors's followers.
    support          REAL DEFAULT 0.0,

    -- Influence of a in n
    influence        REAL DEFAULT 0.0,

    PRIMARY KEY (n, a)
);

-- control_n table: Control of neighborhood n

CREATE TABLE control_n (
    -- Symbolic group name
    n          TEXT PRIMARY KEY 
               REFERENCES nbhoods(n)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Actor controlling n, or NULL.
    controller TEXT REFERENCES actors(a)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Time at which controller took control
    since      INTEGER DEFAULT 0
);

------------------------------------------------------------------------
-- Agent
--
-- An agent is an entity that can own goals and tactics.  In theory, any 
-- kind of entity can be an agent.  At present there are two kinds, actors 
-- and the SYSTEM.

CREATE VIEW agents AS
SELECT 'SYSTEM' AS agent_id, 'system' AS agent_type
UNION
SELECT a        AS agent_id, 'actor'  AS agent_type  FROM actors;


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
    
    -- Owning agent; see agents
    owner        TEXT,

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
    
    -- Owning agent; see agents
    owner        TEXT,

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

    -- On-lock flag, 1 or 0. If 1, the tactic will be executed on lock 
    -- regardless of any other condition
    on_lock      INTEGER DEFAULT 0,

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

    -- Actors; use a first.
    a            TEXT,   -- One actor
    b            TEXT,   -- One actor

    -- Neighborhoods; use n first.
    m            TEXT,   -- One neighborhood
    n            TEXT,   -- One neighborhood
    nlist        TEXT,   -- List of neighborhoods

    -- Groups; use g first.
    f            TEXT,
    g            TEXT,
    glist        TEXT,   -- List of groups

    -- Data items
    text1        TEXT,
    int1         INTEGER,
    x1           REAL
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

    -- Owning agent; see agents
    owner          TEXT,

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
    int1          INTEGER, -- An integer
    x1            REAL     -- A number
);

------------------------------------------------------------------------
-- Personnel Tables

-- Status Quo Deployment Table: FRC and ORG personnel deployed 
-- into neighborhoods prior to time 0, as part of the status quo.

CREATE TABLE sqdeploy_ng (
    -- Symbolic neighborhood name
    n          TEXT REFERENCES nbhoods(n)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic group name
    g          TEXT REFERENCES groups(g)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Personnel
    personnel  INTEGER DEFAULT 0,
    
    PRIMARY KEY (n,g)
);

-- An sqdeploy_ng view that fills in 0's for missing values.
CREATE VIEW sqdeploy_view AS
SELECT N.n                                           AS n,
       G.g                                           AS g,
       coalesce(SQ.personnel,0)                      AS personnel       
FROM nbhoods AS N
JOIN groups AS G
LEFT OUTER JOIN sqdeploy_ng AS SQ USING (n,g)
WHERE G.gtype IN ('FRC', 'ORG');


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
    n           TEXT REFERENCES nbhoods(n)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED,

    -- Attacking force group
    f           TEXT REFERENCES frcgroups(g)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED,

    -- Attacked force group
    g           TEXT REFERENCES frcgroups(g)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED,

    -- 1 if f is uniformed, and 0 otherwise.
    uniformed   INTEGER,

    -- ROE: eattroenf for non-uniformed forces, eattroeuf for uniformed
    -- forces.  Note: a missing record for n,f,g is equivalent to an
    -- ROE of DO_NOT_ATTACK.
    roe         TEXT DEFAULT 'DO_NOT_ATTACK',

    -- Maximum number of attacks per week.
    max_attacks INTEGER DEFAULT 0,

    -- Actual number of attacks
    attacks     INTEGER DEFAULT 0,

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
LEFT OUTER JOIN defroe_ng USING (n,g)
WHERE frcgroups.uniformed;


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
-- This table contains the data used to initialize URAM.

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

    PRIMARY KEY (g, c)
);


------------------------------------------------------------------------
-- Initial Horizontal Relationship Data

-- hrel_fg: Normally, an initial baseline horizontal relationship is 
-- the affinity between the two groups; however, this can be overridden.  
-- This table contains the overrides.  See hrel_view for the full set of 
-- data, and uram_hrel for the current relationships.
--
-- Thus base is group f's initial baseline relationship with group g,
-- from f's point of view.

CREATE TABLE hrel_fg (
    -- Symbolic group name: group f
    f    TEXT REFERENCES groups(g)
         ON DELETE CASCADE
         DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic group name: group g
    g    TEXT REFERENCES groups(g)
         ON DELETE CASCADE
         DEFERRABLE INITIALLY DEFERRED,

    -- Initial baseline horizontal relationship, from f's point of view.
    base DOUBLE DEFAULT 0.0,

    PRIMARY KEY (f, g)
);

------------------------------------------------------------------------
-- Horizontal Relationship View

-- This view computes the initial baseline horizontal relationship for 
-- each pair of groups.  The initial baseline, base, defaults to the
-- affinity between the groups' relationship entities, and can be
-- explicitly overridden in the hrel_fg table.  The natural level,
-- nat, is just the affinity.  Note that the the relationship of a
-- group with itself is forced to 1.0; and this cannot be overridden.
-- A group has a self-identity that it does not share with other
-- groups and that the affinity model does not take into account.

CREATE VIEW hrel_view AS
SELECT F.g                                         AS f,
       G.g                                         AS g,
       CASE WHEN F.g = G.g
            THEN 1.0
            ELSE A.affinity END                    AS nat,
       CASE WHEN F.g = G.g
            THEN 1.0
            ELSE coalesce(R.base, A.affinity) END  AS base,
       CASE WHEN R.base IS NOT NULL 
            THEN 1
            ELSE 0 END                             AS override
FROM groups AS F
JOIN groups AS G
JOIN mam_affinity AS A ON (A.f = F.rel_entity AND A.g = G.rel_entity)
LEFT OUTER JOIN hrel_fg AS R ON (R.f = F.g AND R.g = G.g);

------------------------------------------------------------------------
-- Initial Vertical Relationship Data

-- vrel_ga: Normally, an initial baseline vertical relationship is 
-- the affinity between the group and the actor (unless the actor owns
-- the group); however, this can be overridden.  This table contains the
-- overrides.  See vrel_view for the full set of data,  
-- and uram_vrel for the current relationships.
--
-- Thus base is group g's initial baseline relationship with actor a.

CREATE TABLE vrel_ga (
    -- Symbolic group name: group g
    g    TEXT REFERENCES groups(g)
         ON DELETE CASCADE
         DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic group name: actor a
    a    TEXT REFERENCES actors(a)
         ON DELETE CASCADE
         DEFERRABLE INITIALLY DEFERRED,

    -- Initial vertical relationship
    base DOUBLE DEFAULT 0.0,

    PRIMARY KEY (g, a)
);

------------------------------------------------------------------------
-- Vertical Relationship View

-- This view computes the initial baseline vertical relationships for 
-- each group and actor.  The initial baseline, base, defaults to the 
-- affinity between the relationship entities, and can be explicitly 
-- overridden in the vrel_ga table.  The natural level, nat, is
-- just the affinity.  Note that the relationship of a group with
-- its owning actor defaults to 1.0.

CREATE VIEW vrel_view AS
SELECT G.g                                          AS g,
       G.gtype                                      AS gtype,
       A.a                                          AS a,
       -- Assume that actor A owns G if A is G's rel_entity.
       CASE WHEN G.rel_entity = A.a
            THEN 1.0
            ELSE AF.affinity END                    AS nat,
       CASE WHEN G.rel_entity = A.a
            THEN coalesce(V.base, 1.0)
            ELSE coalesce(V.base, AF.affinity) END  AS base,
       CASE WHEN V.base IS NOT NULL 
            THEN 1
            ELSE 0 END                              AS override
FROM groups AS G
JOIN actors AS A
JOIN mam_affinity AS AF ON (AF.f = G.rel_entity AND AF.g = A.a)
LEFT OUTER JOIN vrel_ga AS V ON (V.g = G.g AND V.a = A.a);


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

    PRIMARY KEY (f, g)
);

------------------------------------------------------------------------
-- Units

-- General unit data
CREATE TABLE units (
    -- Symbolic unit name
    u                TEXT PRIMARY KEY,

    -- Tactic ID, or NULL if this is a base unit.
    -- NOTE: There is no FK reference because the unit can outlive the
    -- tactic that created it.  A unit is associated with at most one
    -- tactic.
    tactic_id        INTEGER UNIQUE,

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

    -- Unit activity: eactivity(n) value, or NONE if this is a base unit
    a                TEXT,

    -- Total Personnel
    personnel        INTEGER DEFAULT 0,

    -- Location, in map coordinates, within n
    location         TEXT,

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

    -- URAM Driver ID
    driver_id INTEGER DEFAULT -1,

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
    g         TEXT DEFAULT 'NONE'
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
    -- The following columns are set when the URAM implications of the
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
    -- assessed, and a URAM driver ID if it has.
    rdriver_id INTEGER DEFAULT 0
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
-- Services
--
-- NOTE: At present, there is only one kind of service,
-- Essential Non-Infrastructure (ENI).  When we add other services,
-- these tables may change considerably.

-- Service Group/Actor table: provision of service to a civilian
-- group by an actor.

CREATE TABLE service_ga (
    -- Civilian Group ID
    g            TEXT REFERENCES civgroups(g) 
                      ON DELETE CASCADE
                      DEFERRABLE INITIALLY DEFERRED,

    -- Actor ID
    a            TEXT REFERENCES actors(a)
                      ON DELETE CASCADE
                      DEFERRABLE INITIALLY DEFERRED,

    -- Funding, $/week (symbol: F.ga)
    funding      REAL DEFAULT 0.0,

    -- Credit, 0.0 to 1.0.  The fraction of unsaturated service
    -- provided by this actor.
    credit       REAL DEFAULT 0.0,

    PRIMARY KEY (g,a)
);

-- Service Table: level of service experienced by civilian groups.

CREATE TABLE service_g (
    -- Civilian Group ID
    g                   TEXT PRIMARY KEY
                             REFERENCES civgroups(g) 
                             ON DELETE CASCADE
                             DEFERRABLE INITIALLY DEFERRED,

    -- Saturation funding, $/week
    saturation_funding  REAL DEFAULT 0.0,

    -- Required level of service, fraction of saturation
    -- (from parmdb)
    required            REAL DEFAULT 0.0,

    -- Funding, $/week
    funding             REAL DEFAULT 0.0,

    -- Actual level of service, fraction of saturation
    actual              REAL DEFAULT 0.0,

    -- Expected level of service, fraction of saturation
    expected            REAL DEFAULT 0.0,

    -- Expectations Factor: measures degree to which expected exceeds
    -- actual (or vice versa) for use in ENI rule set.
    expectf             REAL DEFAULT 0.0,

    -- Needs Factor: measures degree to which actual exceeds required
    -- (or vice versa) for use in ENI rule set.
    needs               REAL DEFAULT 0.0,

    -- URAM Driver ID for satisfaction inputs
    driver_id           INTEGER
);

------------------------------------------------------------------------
-- Attitude Drivers
--
-- All attitude inputs to URAM are associated with an attitude 
-- driver: an event, situation, or magic driver.  Drives are
-- identified by a unique integer ID.

CREATE TABLE drivers (
   driver_id INTEGER PRIMARY KEY,  -- Integer ID
   dtype     TEXT,                 -- Driver type (usually a rule set name)
   narrative TEXT,                 -- Narrative text
   inputs    INTEGER DEFAULT 0     -- Number of inputs for this driver.
);


------------------------------------------------------------------------
-- Magic Attitude Drivers (MADs)
--
-- Magic inputs to URAM are associated with MADs for causality purposes.
-- A MAD is similar to an event or situation.

CREATE TABLE mads_t (
   -- Driver ID
   driver_id     INTEGER PRIMARY KEY,
   
   -- Cause: an ecause(n) value, or NULL
   cause         TEXT DEFAULT '',

   -- Here Factor (s), a real fraction (0.0 to 1.0)
   s             DOUBLE DEFAULT 1.0,

   -- Near Factor (p), a real fraction (0.0 to 1.0)
   p             DOUBLE DEFAULT 0.0,

   -- Near Factor (q), a real fraction (0.0 to 1.0)
   q             DOUBLE DEFAULT 0.0
);

CREATE VIEW mads AS
SELECT M.driver_id AS driver_id,
       D.dtype     AS dtype,
       D.narrative AS narrative,
       M.cause     AS cause,
       M.s         AS s,
       M.p         AS p,
       M.q         AS q
FROM mads_t  AS M
JOIN drivers AS D USING (driver_id);


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
    t    INTEGER,
    g    TEXT,
    mood DOUBLE,

    PRIMARY KEY (t,g)
);

-- nbmood.n
CREATE TABLE hist_nbmood (
    t      INTEGER,
    n      TEXT,
    nbmood DOUBLE,

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

-- control.n.a
CREATE TABLE hist_control (
    t   INTEGER,
    n   TEXT, -- Neighborhood
    a   TEXT, -- Actor controlling neighborhood n, or NULL if none.

    PRIMARY KEY (t,n)
);

-- security.n.g
CREATE TABLE hist_security (
    t        INTEGER,
    n        TEXT,     -- Neighborhood
    g        TEXT,     -- Group
    security INTEGER,  -- g's security in n.

    PRIMARY KEY (t,n,g)
);

-- support.n.a
CREATE TABLE hist_support (
    t              INTEGER,
    n              TEXT,    -- Neighborhood
    a              TEXT,    -- Actor
    direct_support REAL,    -- a's direct support in n
    support        REAL,    -- a's total support (direct + derived) in n
    influence      REAL,    -- a's influence in n

    PRIMARY KEY (t,n,a)
);

-- volatility.n.a
CREATE TABLE hist_volatility (
    t              INTEGER,
    n              TEXT,    -- Neighborhood
    volatility     INTEGER, -- Volatility of n

    PRIMARY KEY (t,n)
);

-- vrel.g.a
CREATE TABLE hist_vrel (
    t      INTEGER,
    g      TEXT,    -- Civilian group
    a      TEXT,    -- Actor
    vrel   REAL,    -- Vertical relationship of g with a.

    PRIMARY KEY (t,g,a)
);

