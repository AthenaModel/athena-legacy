------------------------------------------------------------------------
-- FILE: gram2.sql
--
-- SQL Schema for the gram(n) 2.0 module.
--
-- PACKAGE:
--    simlib(n) -- Simulation Infrastructure Package
--
-- PROJECT:
--    Mars Simulation Infrastructure Library
--
-- AUTHOR:
--    Will Duquette
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Drivers

-- gram(n) drivers table.  Drivers are events and situations, things
-- which drive satisfaction or cooperation change.
CREATE TABLE gram_driver (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Driver ID
    driver        INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Data

    -- Driver type--an application defined string
    dtype         TEXT DEFAULT 'unknown',

    -- Short name for this specific driver
    name          TEXT DEFAULT '',

    -- One-line description of this driver
    oneliner      TEXT DEFAULT 'unknown',

    -- Count of inputs entered for this driver
    last_input    INTEGER DEFAULT 0
);
 

------------------------------------------------------------------------
-- Effect Curves Tables

-- gram(n) Curves table
CREATE TABLE gram_curves (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- This curve_id uniquely identifies the curve and is
    -- set automatically when a curve is created.
    curve_id    INTEGER PRIMARY KEY,

    -- Curve Type (used to implement scaling), 'SAT' or 'COOP'.
    curve_type  TEXT,

    --------------------------------------------------------------------
    -- Initial Values

    -- Initial value
    val0        DOUBLE,

    --------------------------------------------------------------------
    -- Current Values

    -- Current value
    val         DOUBLE,

    -- Delta during last time advance
    delta       DOUBLE,

    -- Slope during last time advance
    slope       DOUBLE
);

-- Table: gram_effects
--
-- gram(n) Level and Slope Effects table
CREATE TABLE gram_effects (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- ID of this effect.  This ID is assigned automatically,
    -- and is globally unique.
    id         INTEGER PRIMARY KEY,

    -- ID of the gram_curve to which this effect contributes.
    curve_id   INTEGER,

    -- ID of the entity receiving the direct effect, e.g., the
    -- gc_id of the group/concern for 
    -- satisfaction inputs.
    direct_id  INTEGER,

    -- Driver ID.
    driver     INTEGER,

    -- Driver input: a counter, 1, 2, 3, for each
    -- input made for a particular driver
    input      INTEGER,

    --------------------------------------------------------------------
    -- General Definition

    -- Effect Type: 'L' for Level, 'S' for Slope
    etype      TEXT,

    -- Cause for which this effect contributes.
    cause      TEXT,

    -- proximity of effect to target:
    -- -1 if effect is the direct effect on the target
    --  0 if effect is indirect "here" (in the target neighborhood)
    --  1 if effect is indirect "near" (to the target neighborhood)
    --  2 if effect is indirect "far"  (from the target neighborhood)
    prox       INTEGER,

    -- Start time of effect, in ticks.
    ts         INTEGER,

    -- end time of effect in ticks.  For slope effects, if 
    -- there are no future links, a sentinel value is used 
    -- (99999999).
    te         INTEGER,
    
    -- Ascending Threshold
    athresh    DOUBLE,
    
    -- Descending Threshold
    dthresh    DOUBLE,
    
    --------------------------------------------------------------------
    -- General Variables

    -- Time of last contribution
    tlast      INTEGER,

    -- Nominal contribution during last time advance
    ncontrib   DOUBLE DEFAULT 0.0,

    -- Actual contribution during last time advance
    acontrib   DOUBLE DEFAULT 0.0,

    -- Nominal contribution to date for this effect.
    nominal    DOUBLE DEFAULT 0.0,

    -- Actual contribution to date for this effect.
    actual     DOUBLE DEFAULT 0.0,

    --------------------------------------------------------------------
    -- Level Effect Details

    -- Realization time in decimal days
    days       DOUBLE,

    -- Time constant
    tau        DOUBLE,

    -- Max change limit.
    llimit     DOUBLE,

    --------------------------------------------------------------------
    -- Slope Effect Details

    -- Time delay of this effect.  This can actually be set for
    -- both levels and slopes, but it only matters for slopes.
    delay      INTEGER,

    -- current nominal satisfaction change/day
    slope      DOUBLE,

    -- future slope links: Tcl list of {ts slope ...}
    -- If empty, there are no future links.
    future     TEXT DEFAULT ''
);

-- This index speeds up most things involving effects.
CREATE INDEX gram_effects_index
ON gram_effects(curve_id,direct_id);

-- This index speeds up termination and rescheduling (?)
CREATE INDEX gram_effects_index_direct
ON gram_effects(direct_id,etype,driver,cause,prox); 

-- This speeds up processing of nominal contributions.
CREATE INDEX gram_effects_index_ncontrib
ON gram_effects(etype,ts,prox);

-- gram(n) Curve Delta History Table
-- This table contains the actual tock-by-tock deltas for each curve.
CREATE TABLE gram_deltas (
    --------------------------------------------------------------------
    -- Primary Key Fields

    -- Sim time of this contribution
    time       INTEGER,

    -- ID of curve being contributed to.
    curve_id   INTEGER,
    
    --------------------------------------------------------------------
    -- Variables

    -- Delta at this time.
    delta      DOUBLE DEFAULT 0.0,

    PRIMARY KEY(time,curve_id)
);

-- gram(n) Contribution History table
-- This table contains the actual tock-by-tock contributions of each
-- event and situation to each curve.
CREATE TABLE gram_contribs (
    --------------------------------------------------------------------
    -- Primary Key Fields

    -- Sim time of this contribution
    time       INTEGER,

    -- Driver ID
    driver     INTEGER,

    -- ID of curve being contributed to.
    curve_id   INTEGER,

    --------------------------------------------------------------------
    -- Variables

    -- Actual contribution made at this time.
    acontrib   DOUBLE DEFAULT 0.0,

    PRIMARY KEY(time,driver,curve_id)
);

--------------------------------------------------------------------------------
-- Neighborhood Data

-- gram(n) "n" table.
-- This table contains data for individual neighborhoods.
CREATE TABLE gram_n (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Neighborhood ID
    n_id           INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Neighborhood identification

    n              TEXT UNIQUE,    -- Name of nbhood

    --------------------------------------------------------------------
    -- Satisfaction Outputs

    -- Neighborhood n's current and initial mood
    sat            DOUBLE DEFAULT 0.0,   -- sat.n
    sat0           DOUBLE DEFAULT 0.0    -- sat0.n
);

-- gram(n) "mn" table.
--
-- This table contains data for pairs of neighborhoods.
CREATE TABLE gram_mn (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Neighborhood pair ID
    mn_id          INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Neighborhood identification

    m              TEXT,    -- Name of nbhood m
    n              TEXT,    -- Name of nbhood n

    --------------------------------------------------------------------
    -- m,n Inputs

    -- Proximity of neighborhood m to neighborhood n from the
    -- point of view of residents of m.
    --  0 if m is "here" (m = n)
    --  1 if m is "near" n
    --  2 if m is "far" from n
    --  3 if m is "remote" from n
    proximity INTEGER,

    -- Effects delay: time in decimal days for a direct effect
    -- in n to begin having an indirect effect in m.

    effects_delay DOUBLE,

    -- Indicate that the m,n coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (m, n)
);

--------------------------------------------------------------------------------
-- CIV Group Definition Tables

-- gram(n) "g" table.
-- This table contains data for individual civilian groups.
-- TBD: Rename gram_civ_g
CREATE TABLE gram_g (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group ID
    g_id           INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Group identification

    g              TEXT UNIQUE,  -- Name of group

    --------------------------------------------------------------------
    -- Group Attributes

    n              TEXT,              -- Nbhood in which group resides
    population     INTEGER,           -- Population of group
    alive          INTEGER DEFAULT 1, -- 1 if alive, 0 if dead
    parent         TEXT DEFAULT '',   -- Name of parent group, if any.
    ancestor       TEXT DEFAULT '',   -- Name of ultimate parent, if any.

    --------------------------------------------------------------------
    -- Cached Values

    -- Total Saliency: the sum of the group's saliencies over all
    -- concerns.  This is used by the "sat drivers" code to compute
    -- contribution to mood.
    total_saliency DOUBLE,

    --------------------------------------------------------------------
    -- Satisfaction Outputs:

    -- Group g's current and initial mood
    sat            DOUBLE DEFAULT 0.0,   -- sat.g
    sat0           DOUBLE DEFAULT 0.0    -- sat0.g
);

CREATE INDEX gram_g_index_ng ON gram_g(n,g);

-- gram(n) "fg" table.
--
-- This table describes pairs of CIV groups.
-- Relationships between groups need not be symmetric; 
-- values in the table are from group F's point of view.

CREATE TABLE gram_fg (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group F/Group G
    fg_id     INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Group Indices

    f          TEXT,    -- Name of first CIV group
    g          TEXT,    -- Name of second CIV group

    --------------------------------------------------------------------
    -- Relationship data

    rel        DOUBLE,  -- Relationship, 1.0 to -1.0, from f's
                        -- point of view.

    --------------------------------------------------------------------
    -- Neighborhood Relationship data

    -- Proximity of f to g
    -- -1 if f=g
    --  0 if f is "here"
    --  1 if f is "near"
    --  2 if f is "far"
    --  3 if f is "remote"
    prox       INTEGER,

    -- Effects delay from g to f
    delay      INTEGER,

    -- Indicate that the f,g coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (f, g)
);

-- gram_fg_index_g_proc: Speeds of scheduling of effects.
CREATE INDEX gram_fg_index_g_prox
ON gram_fg(g,prox);

--------------------------------------------------------------------------------
-- FRC Group Definition Tables

-- gram(n) "frc_g" table.
-- This table contains data for individual force groups.
CREATE TABLE gram_frc_g (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group ID
    g_id           INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Group identification

    g              TEXT UNIQUE   -- Name of group
);

-- gram(n) force "ng" table.
-- This table tracks data about each force group in each neighborhood.

CREATE TABLE gram_frc_ng (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Nbhood/Group ID
    frc_ng_id      INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Neighborhood/group indices 

    n              TEXT,    -- Name of affected neighborhood
    g              TEXT,    -- Name of affected frc group

    --------------------------------------------------------------------
    -- Cooperation roll-ups

    -- Neighborhood n's current and initial composite cooperation
    -- with force group g.  (coop.ng, coop0.ng)
    coop            DOUBLE DEFAULT 0.0,
    coop0           DOUBLE DEFAULT 0.0,

    -- Indicate that the n,g coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (n, g)
);

CREATE INDEX gram_frc_ng_index_ng ON gram_frc_ng(n,g);

-- gram(n) "frc_fg" table: FRC/FRC group relationships

CREATE TABLE gram_frc_fg (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group F/Group G
    -- TBD: frc_fg_id?
    fg_id     INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Nbhood/Group Indices
    
    -- TBD: Use FRC g_id's?

    n          TEXT,    -- Name of neighborhood
    f          TEXT,    -- Name of first group
    g          TEXT,    -- Name of second group

    --------------------------------------------------------------------
    -- Relationship data

    rel        DOUBLE,  -- Relationship, 1.0 to -1.0, from f's
                        -- point of view.

    -- Indicate that the f,g coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (f, g)
);


--------------------------------------------------------------------------------
-- Satisfaction Model Tables

-- gram(n) "c" table.
-- This table contains data for individual concerns.
CREATE TABLE gram_c (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group ID
    c_id           INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Concern identification

    c              TEXT UNIQUE  -- Name of concern
);


-- gram(n) "gc" table.
--
-- This table maps each satisfaction curve, identified by its
-- g,c, to the underlying gram_curves entity.

CREATE TABLE gram_gc (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group/Concern ID
    gc_id     INTEGER PRIMARY KEY,

    -- Group ID
    g_id      INTEGER,

    -- Satisfaction Curve ID from gram_curves
    curve_id   UNIQUE,

    --------------------------------------------------------------------
    -- Identification

    g          TEXT,    -- Name of group
    c          TEXT,    -- Name of concern

    --------------------------------------------------------------------
    -- Satisfaction Curve Details, other than those in 
    -- the gram_curves table.

    saliency   DOUBLE,  -- Saliency, 0.0 to 1.0, of c to g.

    -- Indicate that the g,c coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (g, c)
);


CREATE INDEX gram_gc_index_g_id
ON gram_gc(g_id,c);

-- gram(n) Satisfaction View
-- This view joins gram_gc with gram_curves to give a complete
-- list of all satisfaction curves.
CREATE VIEW gram_sat AS
SELECT -- This instance
       -- Group/concern ID
       gc_id,

       -- Group ID
       gram_g.g_id AS g_id,

       -- Satisfaction Curve indices, etc.
       gram_g.n     AS n,
       gram_g.g     AS g, 
       gram_g.alive AS alive,
       c,
       saliency,

       -- Effects Curve index and values
       curve_id, 
       val0     AS sat0, 
       val      AS sat, 
       delta    AS delta,
       slope    AS slope
FROM gram_gc 
JOIN gram_curves USING (curve_id)
JOIN gram_g ON (gram_gc.g_id = gram_g.g_id);

-- gram_sat Triggers: These allow sat0, and sat to be
-- set by updates to gram_sat.
CREATE TRIGGER gram_sat_trigger 
INSTEAD OF UPDATE OF sat0, sat ON gram_sat
BEGIN
    UPDATE gram_curves
    SET val0  = new.sat0,
        val   = new.sat
    WHERE curve_id = old.curve_id;        
END;      

-- gram_sat_influence
-- This view yields the values needed to schedule satisfaction level and
-- slope inputs.
CREATE VIEW gram_sat_influence AS
SELECT -- Influence Details
       gram_fg.prox             AS prox,
       gram_fg.delay            AS delay,
       gram_fg.rel              AS factor,
       gram_fg.g                AS direct_g,

       -- Direct gc details
       direct.gc_id             AS direct_id,
       direct.g                 AS dg,
       direct.c                 AS c,

       -- Influenced gc details
       curve.curve_id           AS curve_id,
       curve.g                  AS g
FROM gram_fg
JOIN gram_gc AS direct 
     ON direct.g = gram_fg.g
JOIN gram_gc AS curve 
     ON curve.g = gram_fg.f
     AND curve.c = direct.c
JOIN gram_g AS cg ON cg.g = curve.g
WHERE cg.alive;

-- gram(n) Satisfaction Effects View.
-- This view joins the gram_effects with gram_gc to give a complete
-- list of all level and slope effects that contribute to 
-- satisfaction curves.
CREATE VIEW gram_sat_effects AS
SELECT -- Effect Identification
       gram_effects.id        AS id,
       gram_effects.etype     AS etype,
       gram_effects.curve_id  AS curve_id,
       gram_effects.cause     AS cause,
       gram_effects.direct_id AS direct_gc,
       gram_effects.driver    AS driver,
       gram_effects.input     AS input,
       gram_effects.prox      AS prox,
       gram_effects.ts        AS ts,
       gram_effects.te        AS te,
       gram_effects.athresh   AS athresh,
       gram_effects.dthresh   AS dthresh,

       -- Contribution Details
       gram_effects.tlast     AS tlast,
       gram_effects.ncontrib  AS ncontrib,
       gram_effects.acontrib  AS acontrib,
       gram_effects.nominal   AS nominal,
       gram_effects.actual    AS actual,

       -- Level Effect Details
       gram_effects.days      AS days,
       gram_effects.tau       AS tau,
       gram_effects.llimit    AS llimit,

       -- Slope Effect Details
       gram_effects.delay     AS delay,
       gram_effects.slope     AS slope,
       gram_effects.future    AS future,

       -- Satisfaction Curve Identity
       curve.n                AS n,
       curve.g                AS g,
       curve.c                AS c,
       curve.sat              AS sat,

       -- Target Identity
       DG.n                   AS dn,
       direct.g               AS dg
FROM gram_effects 
JOIN gram_sat AS curve 
JOIN gram_gc  AS direct
JOIN gram_g   AS DG
WHERE curve.curve_id = gram_effects.curve_id
AND   direct.gc_id = gram_effects.direct_id
AND   DG.g = direct.g;

-- gram(n) Satisfaction Contributions view.
-- This view joins gram_contribs with gram_gc to provide a 
-- history of contributions to satisfaction curves.

CREATE VIEW gram_sat_contribs AS
SELECT -- History values
       gram_contribs.time     AS time,
       gram_contribs.driver   AS driver,
       gram_contribs.acontrib AS acontrib,
       gram_contribs.curve_id AS curve_id,

       -- Satisfaction Curve identification
       gram_g.n              AS n,
       gram_gc.g             AS g,
       gram_gc.c             AS c
FROM gram_contribs 
JOIN gram_gc USING (curve_id)
JOIN gram_g USING (g_id);

CREATE VIEW gram_sat_deltas AS
SELECT -- History values
       gram_deltas.time      AS time,
       gram_deltas.delta     AS delta,
       gram_deltas.curve_id  AS curve_id,

       -- Satisfaction Curve identification
       gram_g.n              AS n,
       gram_gc.g             AS g,
       gram_gc.c             AS c
FROM gram_deltas 
JOIN gram_gc USING (curve_id)
JOIN gram_g  USING (g_id);

------------------------------------------------------------------------
-- Cooperation Model Tables 

-- gram(n) "coop_fg" table.
--
-- This table describes the cooperation of CIV groups with FRC groups.

CREATE TABLE gram_coop_fg (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group F/Group G
    -- TBD: Make this coop_fg_id?
    fg_id     INTEGER PRIMARY KEY,

    -- Cooperation curve_id
    curve_id    INTEGER UNIQUE,

    --------------------------------------------------------------------
    -- Nbhood/Group Indices

    f          TEXT,    -- Name of CIV group
    g          TEXT,    -- Name of FRC group

    -- Indicate that the f,g coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (f, g)
);

-- gram(n) Cooperation View
-- This view joins gram_coop_fg with gram_curves to give a complete
-- list of all cooperation curves.
CREATE VIEW gram_coop AS
SELECT -- Nbhood/group/group ID
       gram_coop_fg.fg_id       AS fg_id,

       -- Cooperation Curve indices, etc.
       gram_coop_fg.curve_id    AS curve_id,
       gram_coop_fg.f           AS f,
       F.n                      AS n, 
       F.alive                  AS alive,
       gram_coop_fg.g           AS g, 

       -- Effects Curve index and values
       gram_curves.val0         AS coop0, 
       gram_curves.val          AS coop, 
       gram_curves.delta        AS delta,
       gram_curves.slope        AS slope
FROM gram_coop_fg 
JOIN gram_curves USING (curve_id)
JOIN gram_g AS F ON (gram_coop_fg.f = F.g);


-- gram_coop Triggers: These allow coop0 and coop to be
-- set by updates to gram_coop.
CREATE TRIGGER gram_coop_trigger 
INSTEAD OF UPDATE OF coop0, coop ON gram_coop
BEGIN
    UPDATE gram_curves
    SET val0  = new.coop0,
        val   = new.coop
    WHERE curve_id = old.curve_id;        
END;      

-- gram_coop_influence
-- This view yields the values needed to schedule cooperation level and
-- slope inputs.
CREATE VIEW gram_coop_influence AS
SELECT -- Influence Details
       CASE WHEN CIV.prox = -1 AND FRC.f != FRC.g 
            THEN 0
            ELSE CIV.prox END                       AS prox,
       CIV.delay                                    AS delay,
       CIV.rel                                      AS civrel,
       CIV.f                                        AS f,
       CIV.g                                        AS df,
       FRC.f                                        AS g,
       FRC.g                                        AS dg,
       FRC.rel                                      AS factor,

       -- Direct fg details
       direct.fg_id                                 AS direct_id,

       -- Influenced fg details
       curve.curve_id                               AS curve_id
FROM gram_fg       AS CIV
JOIN gram_frc_fg   AS FRC
JOIN gram_coop_fg  AS direct  ON direct.f = CIV.g AND direct.g = FRC.g
JOIN gram_coop_fg  AS curve   ON curve.f  = CIV.f AND curve.g  = FRC.f
JOIN gram_g        AS cg      ON cg.g     = curve.f
WHERE cg.alive;

-- gram(n) Cooperation Effects View.
-- This view joins the gram_effects with gram_coop_fg to give a complete
-- list of all level and slope effects that contribute to 
-- cooperation curves.
CREATE VIEW gram_coop_effects AS
SELECT -- Effect Identification
       gram_effects.id        AS id,
       gram_effects.etype     AS etype,
       gram_effects.curve_id  AS curve_id,
       gram_effects.cause     AS cause,
       gram_effects.direct_id AS direct_fg,
       gram_effects.driver    AS driver,
       gram_effects.input     AS input,
       gram_effects.prox      AS prox,
       gram_effects.ts        AS ts,
       gram_effects.te        AS te,
       gram_effects.athresh   AS athresh,
       gram_effects.dthresh   AS dthresh,

       -- Contribution Details
       gram_effects.tlast     AS tlast,
       gram_effects.ncontrib  AS ncontrib,
       gram_effects.acontrib  AS acontrib,
       gram_effects.nominal   AS nominal,
       gram_effects.actual    AS actual,

       -- Level Effect Details
       gram_effects.days      AS days,
       gram_effects.tau       AS tau,
       gram_effects.llimit    AS llimit,

       -- Slope Effect Details
       gram_effects.delay     AS delay,
       gram_effects.slope     AS slope,
       gram_effects.future    AS future,

       -- Cooperation Curve Identity
       curve.n                AS n,
       curve.f                AS f,
       curve.g                AS g,
       curve.coop             AS coop,

       -- Target Identity
       DF.n                   AS dn,
       direct.f               AS df,
       direct.g               AS dg
FROM gram_effects 
JOIN gram_coop AS curve 
JOIN gram_coop_fg AS direct
JOIN gram_g AS DF ON (DF.g = direct.f)
WHERE curve.curve_id = gram_effects.curve_id
AND   direct.fg_id = gram_effects.direct_id;

-- gram(n) Cooperation Contributions view.
-- This view joins gram_contribs with gram_coop_fg to provide a 
-- history of contributions to cooperation curves.

CREATE VIEW gram_coop_contribs AS
SELECT -- History values
       gram_contribs.time     AS time,
       gram_contribs.driver   AS driver,
       gram_contribs.acontrib AS acontrib,
       gram_contribs.curve_id AS curve_id,

       -- Cooperation Curve identification
       F.n                    AS n,
       gram_coop_fg.f         AS f,
       gram_coop_fg.g         AS g
FROM gram_contribs 
JOIN gram_coop_fg USING (curve_id)
JOIN gram_g AS F ON (gram_coop_fg.f = F.g);

CREATE VIEW gram_coop_deltas AS
SELECT -- History values
       gram_deltas.time      AS time,
       gram_deltas.delta     AS delta,
       gram_deltas.curve_id  AS curve_id,

       -- Cooperation Curve identification
       F.n                   AS n,
       gram_coop_fg.f        AS f,
       gram_coop_fg.g        AS g
FROM gram_deltas 
JOIN gram_coop_fg USING (curve_id)
JOIN gram_g AS F ON (gram_coop_fg.f = F.g);


------------------------------------------------------------------------
-- Other History Tables

-- gram(n) CIV group history table

CREATE TABLE gram_hist_g (
    time       INTEGER,            -- Time in ticks
    g          TEXT,               -- Civilian group name
    n          TEXT,               -- Neighborhood of residence
    alive      INTEGER,            -- 1 if group was alive, 0 if dead
    population INTEGER,            -- Population

    PRIMARY KEY (time, g)
);

