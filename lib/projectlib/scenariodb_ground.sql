------------------------------------------------------------------------
-- TITLE:
--    scenariodb_ground.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Ground Area
--
-- SECTIONS:
--    Personnel and Related Statistics
--    Situations
--    Attrition
--    Services
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- PERSONNEL AND RELATED STATISTICS 

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


------------------------------------------------------------------------
-- ATTRITION 

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


-- An instance of magic attrition to a group or a neighborhood.
-- These records are accumulated while the sim is paused and then applied 
-- during attrition assessment.

CREATE TABLE magic_attrit (
    -- Unique ID, assigned automatically.
    id         INTEGER PRIMARY KEY,

    -- Mode of the magic attrtion: NBHOOD or GROUP
    mode       TEXT,    

    -- For NBHOOD or GROUP mode, the neighborhood suffering attrition
    n          TEXT,

    -- For GROUP mode, the group suffering attrition
    f          TEXT,

    -- The number of casualties to apply
    casualties INTEGER,

    -- A responsible group or ""
    g1         TEXT,

    -- A responsible group or ""
    g2         TEXT
);

    
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
-- STANCE

CREATE TABLE stance_fg (
    -- Contains the stance (designated relationship) of force group f
    -- toward group g, as specified by a STANCE tactic.  Rows exist only
    -- when stance has been explicitly set.

    f      TEXT,    -- Force group f
    g      TEXT,    -- Other group g

    stance DOUBLE,  -- stance.fg

    PRIMARY KEY (f,g)
);

CREATE TABLE stance_nfg (
    -- Contains neighborhood-specific overrides to stance.fg.  For example,
    -- if group f is attacking group g in neighborhood n, it has a maximum
    -- stance toward g as set by force.maxAttackingStance.  This table
    -- contains all such overrides.

    n      TEXT,    -- Neighborhood n
    f      TEXT,    -- Force group f
    g      TEXT,    -- Other group g

    stance DOUBLE,  -- stance.nfg

    PRIMARY KEY (n,f,g)
);

-- stance_nfg_view:  Group f's stance toward g in n.  Defaults to 
-- hrel.fg.  The default can be overridden by an explicit stance, as
-- contained in stance_fg, and that can be overridden by neighborhood,
-- as contained in stance_nfg.
CREATE VIEW stance_nfg_view AS
SELECT N.n                                           AS n,
       F.g                                           AS f,
       G.g                                           AS g,
       coalesce(SN.stance,S.stance,UH.hrel)          AS stance,
       CASE WHEN SN.stance IS NOT NULL THEN 'ATTROE'
            WHEN S.stance  IS NOT NULL THEN 'ACTOR'
            ELSE 'DEFAULT' END                       AS source
FROM nbhoods   AS N
JOIN frcgroups AS F
JOIN groups    AS G
LEFT OUTER JOIN stance_nfg AS SN ON (SN.n=N.n AND SN.f=F.g AND SN.g=G.g)
LEFT OUTER JOIN stance_fg  AS S  ON (S.f=F.g AND S.g=G.g)
LEFT OUTER JOIN uram_hrel  AS UH ON (UH.f=F.g AND UH.g=G.g);

-- stance_nfg_only_view:  Group f's stance toward g in n; differs
-- from stance_nfg_view in containing only the overrides to uram_hrel.
CREATE VIEW stance_nfg_only_view AS
SELECT N.n                                           AS n,
       F.g                                           AS f,
       G.g                                           AS g,
       coalesce(SN.stance,S.stance)                  AS stance,
       CASE WHEN SN.stance IS NOT NULL THEN 'ATTROE'
            WHEN S.stance  IS NOT NULL THEN 'ACTOR'
            ELSE 'DEFAULT' END                       AS source
FROM nbhoods   AS N
JOIN frcgroups AS F
JOIN groups    AS G
LEFT OUTER JOIN stance_nfg AS SN ON (SN.n=N.n AND SN.f=F.g AND SN.g=G.g)
LEFT OUTER JOIN stance_fg  AS S  ON (S.f=F.g AND S.g=G.g);

------------------------------------------------------------------------
-- FORCE AND SECURITY STATISTICS

-- nbstat Table: Total Force and Volatility in neighborhoods
CREATE TABLE force_n (
    -- Symbolic nbhood name
    n                   TEXT    PRIMARY KEY,

    -- Criminal suppression in neighborhood. This is the fraction of 
    -- civilian criminal activity that is suppressed by law enforcement
    -- activities.
    suppression         DOUBLE DEFAULT 0.0,

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
    n             TEXT,              -- Symbolic nbhood name
    g             TEXT,              -- Symbolic group name

    personnel     INTEGER DEFAULT 0, -- Group's personnel
    own_force     INTEGER DEFAULT 0, -- Group's own force (Q.ng)
    crim_force    INTEGER DEFAULT 0, -- Civ group's criminal force.
                                     -- 0.0 for non-civ groups.
    noncrim_force INTEGER DEFAULT 0, -- Group's own force, less criminals
    local_force   INTEGER DEFAULT 0, -- own_force + friends in n
    local_enemy   INTEGER DEFAULT 0, -- enemies in n
    force         INTEGER DEFAULT 0, -- own_force + friends nearby
    pct_force     INTEGER DEFAULT 0, -- 100*force/total_force
    enemy         INTEGER DEFAULT 0, -- enemies nearby
    pct_enemy     INTEGER DEFAULT 0, -- 100*enemy/total_force
    security      INTEGER DEFAULT 0, -- Group's security in n

    PRIMARY KEY (n, g)
);

-- nbstat Table: Civilian group statistics
CREATE TABLE force_civg (
    g          TEXT PRIMARY KEY,   -- Symbolic civ group name
    nominal_cf DOUBLE,             -- Nominal Criminal Fraction
    actual_cf  DOUBLE              -- Actual Criminal Fraction
);


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
-- SITUATIONS

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
-- SERVICES

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
-- End of File
------------------------------------------------------------------------
