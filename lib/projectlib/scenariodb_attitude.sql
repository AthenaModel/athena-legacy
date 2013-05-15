------------------------------------------------------------------------
-- TITLE:
--    scenariodb_attitude.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Attitudes and Attitude Drivers
--
-- SECTIONS:
--    Cooperation
--    Horizontal Relationships
--    Satisfaction
--    Vertical Relationships
--    Attitude Drivers
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- COOPERATION: INITIAL DATA

CREATE TABLE coop_fg (
    -- At present, cooperation is defined only between all
    -- civgroups f and all force groups g.  This table contains the
    -- initial baseline cooperation levels.

    -- Symbolic civ group name: group f
    f           TEXT REFERENCES civgroups(g)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic frc group name: group g
    g           TEXT REFERENCES frcgroups(g)
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED,

    -- initial baseline cooperation of f with g at time 0.
    base        DOUBLE DEFAULT 50.0,

    -- if "BASELINE", regress to initial baseline; if "NATURAL",
    -- regress to explicit natural level.
    regress_to  STRING DEFAULT 'BASELINE',

    --  Natural level, if regress_to is "NATURAL".
    natural     DOUBLE DEFAULT 50.0,

    PRIMARY KEY (f, g)
);



------------------------------------------------------------------------
-- HORIZONTAL RELATIONSHIPS: INITIAL DATA

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

    -- Historical data flag: if 0, no historical attitude data.
    hist_flag   INTEGER DEFAULT 0,

    -- Initial current level, only if hist_flag = 1
    current     DOUBLE DEFAULT 0.0,

    PRIMARY KEY (f, g)
);

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
       CASE WHEN F.g = G.g
            THEN 0
            ELSE coalesce(R.hist_flag, 0) END      AS hist_flag,
       CASE WHEN F.g = G.g 
            THEN 1.0
            WHEN coalesce(R.hist_flag, 0)
            THEN R.current
            ELSE coalesce(R.base, A.affinity) END  AS current,
       CASE WHEN R.base IS NOT NULL 
            THEN 1
            ELSE 0 END                             AS override
FROM groups AS F
JOIN groups AS G
JOIN mam_affinity AS A ON (A.f = F.rel_entity AND A.g = G.rel_entity)
LEFT OUTER JOIN hrel_fg AS R ON (R.f = F.g AND R.g = G.g);

------------------------------------------------------------------------
-- SATISFACTION: INITIAL DATA

-- Group/concern pairs (g,c) for civilian groups
-- This table contains the data used to initialize URAM sat curves.

CREATE TABLE sat_gc (
    -- Symbolic groups name
    g          TEXT REFERENCES civgroups(g) 
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic concerns name
    c          TEXT,

    -- Initial baseline satisfaction value
    base       DOUBLE DEFAULT 0.0,

    -- Saliency of concern c to group g in nbhood n
    saliency   DOUBLE DEFAULT 1.0,

    -- Historical data flag: if 0, no historical attitude data.
    hist_flag   INTEGER DEFAULT 0,

    -- Initial current satisfaction level, only if hist_flag = 1
    current     DOUBLE DEFAULT 0.0,

    PRIMARY KEY (g, c)
);


------------------------------------------------------------------------
-- VERTICAL RELATIONSHIPS: INITIAL DATA 

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

    -- Historical data flag: if 0, no historical attitude data.
    hist_flag   INTEGER DEFAULT 0,

    -- Initial current level, only if hist_flag = 1
    current     DOUBLE DEFAULT 0.0,

    PRIMARY KEY (g, a)
);

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
       coalesce(V.hist_flag, 0)                     AS hist_flag,
       CASE WHEN coalesce(V.hist_flag,0)
            THEN V.current
            WHEN G.rel_entity = A.a 
            THEN coalesce(V.base, 1.0)
            ELSE coalesce(V.base, AF.affinity) END  AS current,
       CASE WHEN V.base IS NOT NULL 
            THEN 1
            ELSE 0 END                              AS override
FROM groups AS G
JOIN actors AS A
JOIN mam_affinity AS AF ON (AF.f = G.rel_entity AND AF.g = A.a)
LEFT OUTER JOIN vrel_ga AS V ON (V.g = G.g AND V.a = A.a);



------------------------------------------------------------------------
-- ATTITUDE DRIVERS

CREATE TABLE drivers (
    -- All attitude inputs to URAM are associated with an attitude 
    -- driver: an event, situation, or magic driver.  Drivers are
    -- identified by a unique integer ID.
    --
    -- For most driver types, the driver is associated with a signature
    -- that is unique for that driver type.  This allows the rule set to
    -- retrieve the driver ID given the driver type and signature.

    driver_id INTEGER PRIMARY KEY,  -- Integer ID
    dtype     TEXT,                 -- Driver type (usually a rule set name)
    signature TEXT                  -- Signature, by driver type.
);

CREATE INDEX drivers_signature_index ON drivers(dtype,signature);

-- Magic inputs to URAM are associated with MADs for causality purposes.
-- A MAD is similar to an event or situation.

CREATE TABLE mads (
   -- MAD ID
   mad_id        INTEGER PRIMARY KEY,

   -- Narrative Text
   narrative     TEXT DEFAULT '',
   
   -- Cause: an ecause(n) value, or NULL
   cause         TEXT DEFAULT '',

   -- Here Factor (s), a real fraction (0.0 to 1.0)
   s             DOUBLE DEFAULT 1.0,

   -- Near Factor (p), a real fraction (0.0 to 1.0)
   p             DOUBLE DEFAULT 0.0,

   -- Near Factor (q), a real fraction (0.0 to 1.0)
   q             DOUBLE DEFAULT 0.0
);

CREATE TABLE curses (
    -- The curses table holds data associated with every CURSE
    -- defined by the user. The curse_injects table then references
    -- the CURSE each inject is associated with.

    -- CURSE ID
    curse_id     TEXT PRIMARY KEY,

    -- Description of the CURSE
    longname     TEXT DEFAULT '',

    -- ecause(n) value, or NULL
    cause        TEXT DEFAULT '',

    -- Here Factor (s), a real fraction (0.0 to 1.0)
    s            DOUBLE DEFAULT 1.0,
 
    -- Near Factor (p), a real fraction (0.0 to 1.0)
    p            DOUBLE DEFAULT 0.0,
 
    -- Near Factor (q), a real fraction (0.0 to 1.0)
    q            DOUBLE DEFAULT 0.0,

    -- State: normal, disabled, invalid (ecurse_state)
    state        TEXT DEFAULT 'normal'
);

CREATE TABLE curse_injects (
    -- CURSE ID
    curse_id     TEXT REFERENCES curses(curse_id)
                 ON DELETE CASCADE
                 DEFERRABLE INITIALLY DEFERRED,

    -- Unique inject number
    inject_num   INTEGER,

    -- Inject type: SAT, COOP, HREL, or VREL
    inject_type  TEXT,   -- ecinjectpart(n) value

    -- Mode: Persistent (P) or Transient (T)
    mode         TEXT,

    -- Narrative built by the inject object based on the inject
    -- type
    narrative    TEXT DEFAULT 'TBD',

    -- normal, disabled or invalid
    state        TEXT DEFAULT 'normal',

    -- CURSE Type parameters.  The use of these varies by type;
    -- all are NULL if unused.  There are no foreign key constraints;
    -- errors are checked by the curse input type's "check" method.
    a        TEXT,  -- Actor roles for VREL
    c        TEXT,  -- A concern, for SAT
    f        TEXT,  -- SAT -> n/a, HREL -> groups, 
                    -- VREL -> n/a, COOP -> civgroups
    g        TEXT,  -- SAT -> civgroups, HREL -> groups, 
                    -- VREL -> groups, COOP -> frcgroups
    mag      REAL,  -- Numeric qmag(n) value

    PRIMARY KEY (curse_id, inject_num)
);

------------------------------------------------------------------------
-- RULE FIRING HISTORY

CREATE TABLE rule_firings (
    -- Historical data about rule firings, used for later display.

    firing_id INTEGER PRIMARY KEY,  -- Integer ID
    t         INTEGER,              -- Sim time of rule firing, in ticks.
    driver_id INTEGER,              -- Driver ID
    ruleset   TEXT,                 -- Rule Set name (same as drivers.dtype)
    rule      TEXT,                 -- Rule name
    fdict     TEXT                  -- Dictionary of ruleset-specific data.
);

CREATE TABLE rule_inputs (
    -- Historical data about rule inputs, used for later display
    -- Theoretically, the sim time t column is not needed, but it makes
    -- purging the data easier.
    --
    -- This table includes the attitude curve indices for all four kinds
    -- of curve:
    --
    --     coop: (f,g) where f is a civilian group and g is a force group
    --     hrel: (f,g) where f and g are groups
    --     sat:  (g,c) where g is a civilian group and c is a concern
    --     vrel: (g,a) where g is a group and a is an actor
    --
    -- Index columns which do not apply to a particular attitude type will
    -- be NULL.
    --
    -- The s, p, and q columns apply only to coop and sat inputs, and will
    -- be NULL for hrel and vrel inputs.
    --
    -- The "note" column is used by rule sets where a single rule is
    -- implemented as a look-up table, and the specific case is not
    -- obvious from the rule_firings.fdict.  The "note" will identify
    -- which case applied.

    firing_id INTEGER,  -- The input's rule firing
    input_id  INTEGER,  -- Input no. for this rule firing
    t         INTEGER,  -- Sim time of rule firing.
    atype     TEXT,     -- Attitude type, coop, hrel, sat, vrel
    mode      TEXT,     -- P, T (persistent, transient)
    f         TEXT,     -- Group f (coop, vrel)
    g         TEXT,     -- Group g (coop, hrel, sat)
    c         TEXT,     -- Concern c (sat)
    a         TEXT,     -- Actor a (vrel)
    gain      DOUBLE,   -- Gain on magnitude
    mag       DOUBLE,   -- Numeric magnitude
    cause     TEXT,     -- Cause name
    s         DOUBLE,   -- Here effects multiplier
    p         DOUBLE,   -- Near effects multiplier
    q         DOUBLE,   -- Far effects multiplier
    note      TEXT,     -- Note on this input

    PRIMARY KEY (firing_id, input_id)
);





------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------
