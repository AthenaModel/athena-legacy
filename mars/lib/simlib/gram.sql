------------------------------------------------------------------------
-- FILE: gram.sql
--
-- SQL Schema for the gram(n) module.
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
-- Drivers table

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
    -- ngc_id of the neighborhood/group/concern for 
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
-- Satisfaction Model Tables

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
    -- (based on CIV groups only)
    sat            DOUBLE DEFAULT 0.0,   -- sat.n
    sat0           DOUBLE DEFAULT 0.0    -- sat0.n
);


-- gram(n) "g" table.
-- This table contains data for individual groups.
CREATE TABLE gram_g (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group ID
    g_id           INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Group identification

    g              TEXT UNIQUE,  -- Name of pgroup
    gtype          TEXT,         -- Group type, CIV or ORG or FRC

    --------------------------------------------------------------------
    -- Satisfaction Outputs: CIV and ORG only

    -- Group g's current and initial top-level mood
    sat            DOUBLE DEFAULT 0.0,   -- sat.g
    sat0           DOUBLE DEFAULT 0.0    -- sat0.g
);

-- gram(n) "c" table.
-- This table contains data for individual concerns.
CREATE TABLE gram_c (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group ID
    c_id           INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Concern identification

    c              TEXT UNIQUE,  -- Name of concern
    gtype          TEXT,         -- Concern type, CIV or ORG

    --------------------------------------------------------------------
    -- Satisfaction Outputs

    -- Concern c's current and initial top-level composite
    sat            DOUBLE DEFAULT 0.0,   -- sat.c
    sat0           DOUBLE DEFAULT 0.0    -- sat0.c
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
    proximity INTEGER,

    -- Effects delay: time in decimal days for a direct effect
    -- in n to begin having an indirect effect in m.

    effects_delay DOUBLE,

    -- Indicate that the m,n coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (m, n)
);
       

-- gram(n) "ng" table.
-- This table tracks data about each neighborhood group.
-- (CIV and ORG groups only)
CREATE TABLE gram_ng (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Nbhood/Group ID
    ng_id          INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Neighborhood/group indices 

    n              TEXT,    -- Name of affected neighborhood
    g              TEXT,    -- Name of affected pgroup

    --------------------------------------------------------------------
    -- Group Attributes from db_ng

    population     INTEGER,
    rollup_weight  DOUBLE,
    effects_factor DOUBLE,

    --------------------------------------------------------------------
    -- Cached Values

    -- Satisfaction Tracked Flag: 1 if we track satisfaction
    -- for group g in nbhood n. It is 0 only for CIV groups when 
    -- population = 0.
    sat_tracked    INTEGER DEFAULT 1,

    -- Total Saliency: the sum of the group's saliencies over all
    -- concerns.  This is used by the "sat drivers" code to compute
    -- contribution to mood.
    total_saliency DOUBLE,

    --------------------------------------------------------------------
    -- Satisfaction roll-ups

    -- Group g's current and initial mood in n (sat.ng, sat0.ng)
    sat            DOUBLE DEFAULT 0.0,
    sat0           DOUBLE DEFAULT 0.0,

    -- Indicate that the n,g coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (n, g)
);

CREATE INDEX gram_ng_index_ng ON gram_ng(n,g);

-- gram(n) force "ng" table.
-- This table tracks data about each force group in each neighborhood.
-- TBD: We may want a single gram_ng table to assign ng_id's,
-- plus child tables for the different kinds of group.
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

-- gram(n) "nc" table.
-- This table tracks data about each concern in each neighborhood
CREATE TABLE gram_nc (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Nbhood/Concern ID
    nc_id          INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Neighborhood/Concern indices 

    n              TEXT,    -- Name of neighborhood
    c              TEXT,    -- Name of concern

    --------------------------------------------------------------------
    -- Satisfaction roll-ups

    -- Concern c's current and initial composite satisfaction
    -- in n (sat.nc, sat0.nc)
    sat            DOUBLE DEFAULT 0.0,
    sat0           DOUBLE DEFAULT 0.0,

    -- Indicate that the n,g coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (n, c)
);

-- gram(n) "nfg" table.
--
-- This table describes pairs of groups in neighborhoods.
-- Relationships between groups need not be symmetric; 
-- values in the table are from group F's point of view.
CREATE TABLE gram_nfg (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Nbhood/Group F/Group G
    nfg_id     INTEGER PRIMARY KEY,

    -- Cooperation curve_id, or null.
    curve_id    INTEGER,

    --------------------------------------------------------------------
    -- Nbhood/Group Indices

    n          TEXT,    -- Name of neighborhood
    f          TEXT,    -- Name of first group
    g          TEXT,    -- Name of second group

    --------------------------------------------------------------------
    -- Relationship data

    rel        DOUBLE,  -- Relationship, 1.0 to -1.0, from f's
                        -- point of view.

    -- Indicate that the n,f,g coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (n, f, g)
);

CREATE INDEX gram_nfg_index_curve_id 
ON gram_nfg(curve_id);

-- gram(n) "gc" table.
--
-- This table contains the playbox data for each group and concern
CREATE TABLE gram_gc (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Group/Concern ID
    gc_id     INTEGER PRIMARY KEY,

    --------------------------------------------------------------------
    -- Identification

    g          TEXT,    -- Name of pgroup
    c          TEXT,    -- Name of concern

    --------------------------------------------------------------------
    -- Satisfaction roll-ups

    -- Group g's current and initial composite satisfaction
    -- for concern c, playbox-wide (sat.gc, sat0.gc)
    sat            DOUBLE DEFAULT 0.0,
    sat0           DOUBLE DEFAULT 0.0,

    -- Group g's current slope for concern c, playbox-wide
    -- (slope.gc).
    slope          DOUBLE DEFAULT 0.0,

    -- Indicate that the g,c coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (g, c)
);

-- gram(n) "ngc" table.
--
-- This table maps each satisfaction curve, identified by its
-- n,g,c, to the underlying gram_curves entity.
--
-- NOTE: nbhood groups for which satisfaction is not tracked
-- have no entries in this table! (And hence, no matching entries
-- in the gram_curves table.)
CREATE TABLE gram_ngc (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Nbhood/Group/Concern ID
    ngc_id     INTEGER PRIMARY KEY,

    -- Nbhood/Group ID
    ng_id      INTEGER,

    -- Satisfaction Curve ID from gram_curves; NULL if none!
    curve_id   UNIQUE,

    --------------------------------------------------------------------
    -- Satisfaction Curve Indices

    n          TEXT,    -- Name of neighborhood
    g          TEXT,    -- Name of pgroup
    c          TEXT,    -- Name of concern
    gtype      TEXT,    -- CIV or ORG

    --------------------------------------------------------------------
    -- Satisfaction Curve Details, other than those in 
    -- the gram_curves table.

    saliency   DOUBLE,  -- Saliency, 0.0 to 1.0, of c to g in n.

    -- Indicate that the n,g,c coordinates are unique,
    -- and index on them for fast lookups
    UNIQUE (n, g, c)
);

CREATE INDEX gram_ngc_index_ng_id
ON gram_ngc(ng_id,c);

CREATE INDEX gram_ngc_index_ngc ON gram_ngc(n,g,c);


-- gram(n) Satisfaction View
-- This view joins gram_ngc with gram_curves to give a complete
-- list of all satisfaction curves.
CREATE VIEW gram_sat AS
SELECT -- This instance
       -- Nbhood/group/concern ID
       ngc_id,

       -- Nbhood group ID
       ng_id,

       -- Satisfaction Curve indices, etc.
       n, 
       g, 
       c,
       gtype,
       saliency,

       -- Effects Curve index and values
       curve_id, 
       val0     AS sat0, 
       val      AS sat, 
       delta    AS delta,
       slope    AS slope
FROM gram_ngc 
JOIN gram_curves USING (curve_id);

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


-- gram(n) satisfaction influence map.  For each gram_ng
-- which can receive a satisfaction input, this table records
-- the ng's which can receive an effect, with sufficient
-- information to compute the magnitude of the effect given the
-- the direct effect.

CREATE TABLE gram_sat_influence (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Index of the ng receiving the direct effect
    direct_ng     INTEGER,

    -- Index of the ng receiving the indirect effect
    influenced_ng INTEGER,

    --------------------------------------------------------------------
    -- Influence parameters

    -- Proximity of influenced_ng to direct_ng
    -- -1 if effect is the direct effect on the target
    --  0 if effect is indirect "here"
    --  1 if effect is indirect "near"
    --  2 if effect is indirect "far"
    prox        INTEGER,

    -- Effects Delay from direct_ng to influenced_ng
    delay       INTEGER,

    -- Magnitude factor (based on effects_factor, rel)
    -- for effect on ng
    factor      DOUBLE,

    PRIMARY KEY (direct_ng,influenced_ng)
);

-- gram_sat_influence_index: speeds up scheduling of effects
CREATE INDEX gram_sat_influence_index 
ON gram_sat_influence(direct_ng,prox);

-- ngc influence view
-- This view yields the values needed to schedule level and
-- slope inputs.
CREATE VIEW gram_sat_influence_view AS
SELECT -- Influence Details
       gram_sat_influence.prox      AS prox,
       gram_sat_influence.delay     AS delay,
       gram_sat_influence.factor    AS factor,
       gram_sat_influence.direct_ng AS direct_ng,

       -- Direct ngc details
       direct.ngc_id            AS direct_id,
       direct.n                 AS dn,
       direct.g                 AS dg,
       direct.c                 AS c,

       -- Influenced ngc details
       curve.curve_id           AS curve_id,
       curve.n                  AS n,
       curve.g                  AS g
FROM gram_sat_influence
JOIN gram_ngc AS direct 
     ON direct.ng_id = gram_sat_influence.direct_ng
JOIN gram_ngc AS curve 
     ON curve.ng_id = gram_sat_influence.influenced_ng
     AND curve.c = direct.c;

-- gram(n) Satisfaction Effects View.
-- This view joins the gram_effects with gram_ngc to give a complete
-- list of all level and slope effects that contribute to 
-- satisfaction curves.
CREATE VIEW gram_sat_effects AS
SELECT -- Effect Identification
       gram_effects.id        AS id,
       gram_effects.etype     AS etype,
       gram_effects.curve_id  AS curve_id,
       gram_effects.cause     AS cause,
       gram_effects.direct_id AS direct_ngc,
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
       direct.n               AS dn,
       direct.g               AS dg
FROM gram_effects JOIN gram_sat AS curve JOIN gram_ngc AS direct
WHERE curve.curve_id = gram_effects.curve_id
AND   direct.ngc_id = gram_effects.direct_id;

-- gram(n) Satisfaction Contributions view.
-- This view joins gram_contribs with gram_ngc to provide a 
-- history of contributions to satisfaction curves.

CREATE VIEW gram_sat_contribs AS
SELECT -- History values
       gram_contribs.time     AS time,
       gram_contribs.driver   AS driver,
       gram_contribs.acontrib AS acontrib,
       gram_contribs.curve_id AS curve_id,

       -- Satisfaction Curve identification
       gram_ngc.n            AS n,
       gram_ngc.g            AS g,
       gram_ngc.c            AS c
FROM gram_contribs JOIN gram_ngc USING (curve_id);

CREATE VIEW gram_sat_deltas AS
SELECT -- History values
       gram_deltas.time      AS time,
       gram_deltas.delta     AS delta,
       gram_deltas.curve_id  AS curve_id,

       -- Satisfaction Curve identification
       gram_ngc.n            AS n,
       gram_ngc.g            AS g,
       gram_ngc.c            AS c
FROM gram_deltas JOIN gram_ngc USING (curve_id);

--------------------------------------------------------------------------------
-- Cooperation Model Tables 

-- gram(n) Cooperation View
-- This view joins gram_nfg with gram_curves to give a complete
-- list of all cooperation curves.
CREATE VIEW gram_coop AS
SELECT -- Nbhood/group/group ID
       gram_nfg.nfg_id          AS nfg_id,

       -- Cooperation Curve indices, etc.
       gram_nfg.curve_id        AS curve_id,
       gram_nfg.n               AS n, 
       gram_nfg.f               AS f,
       gram_nfg.g               AS g, 

       -- Effects Curve index and values
       gram_curves.val0         AS coop0, 
       gram_curves.val          AS coop, 
       gram_curves.delta        AS delta,
       gram_curves.slope        AS slope
FROM gram_nfg 
JOIN gram_curves USING (curve_id);

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


-- gram(n) Cooperation Effects View.
-- This view joins the gram_effects with gram_nfg to give a complete
-- list of all level and slope effects that contribute to 
-- cooperation curves.
CREATE VIEW gram_coop_effects AS
SELECT -- Effect Identification
       gram_effects.id        AS id,
       gram_effects.etype     AS etype,
       gram_effects.curve_id  AS curve_id,
       gram_effects.cause     AS cause,
       gram_effects.direct_id AS direct_nfg,
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
       direct.n               AS dn,
       direct.f               AS df,
       direct.g               AS dg
FROM gram_effects JOIN gram_coop AS curve JOIN gram_nfg AS direct
WHERE curve.curve_id = gram_effects.curve_id
AND   direct.nfg_id = gram_effects.direct_id;

-- gram(n) Cooperation Contributions view.
-- This view joins gram_contribs with gram_nfg to provide a 
-- history of contributions to cooperation curves.

CREATE VIEW gram_coop_contribs AS
SELECT -- History values
       gram_contribs.time     AS time,
       gram_contribs.driver   AS driver,
       gram_contribs.acontrib AS acontrib,
       gram_contribs.curve_id AS curve_id,

       -- Cooperation Curve identification
       gram_nfg.n            AS n,
       gram_nfg.f            AS f,
       gram_nfg.g            AS g
FROM gram_contribs JOIN gram_nfg USING (curve_id);

CREATE VIEW gram_coop_deltas AS
SELECT -- History values
       gram_deltas.time      AS time,
       gram_deltas.delta     AS delta,
       gram_deltas.curve_id  AS curve_id,

       -- Cooperation Curve identification
       gram_nfg.n            AS n,
       gram_nfg.f            AS f,
       gram_nfg.g            AS g
FROM gram_deltas JOIN gram_nfg USING (curve_id);

-- gram(n) cooperation influence map.  For each n,g
-- which can receive a satisfaction input, this table records
-- the n,g's which can receive an effect, with sufficient
-- information to compute the magnitude of the effect given the
-- the direct effect.  Note that the g's here are FRC groups.
--
-- Every coop input has an "f" as well; but as all indirect
-- effects are for the same "f", that name doesn't appear in
-- this table.

CREATE TABLE gram_coop_influence (
    --------------------------------------------------------------------
    -- Keys and Pointers

    -- Name of the nbhood receiving the direct effect
    dn            TEXT,

    -- Name of the FRC group receiving the direct effect.
    dg            TEXT,

    -- Name of the influenced neighborhood
    m             TEXT,

    -- Name of the influenced force group
    h             TEXT,

    --------------------------------------------------------------------
    -- Influence parameters

    -- Proximity of influenced m,h to direct n,h
    -- -1 if effect is the direct effect on the target
    --  0 if effect is indirect "here"
    --  1 if effect is indirect "near"
    --  2 if effect is indirect "far"
    prox        INTEGER,

    -- Effects Delay from n,g to m,h, in ticks.
    delay       INTEGER,

    -- Magnitude factor (rel.mhg)
    factor      DOUBLE,

    PRIMARY KEY (dn, dg, m, h)
);

-- gram(n): Cooperation influence index
CREATE INDEX gram_coop_influence_index
ON gram_coop_influence(dn, dg, prox);

-- gram(n) Cooperation influence view
CREATE VIEW gram_coop_influence_view AS
    SELECT INF.dn            AS dn,
           MF.g              AS df,
           INF.dg            AS dg,
           INF.m             AS m,
           INF.h             AS h,
           INF.prox          AS prox,
           INF.delay         AS delay,
           INF.factor        AS factor,
           MF.ng_id          AS mf_id,
           NFG.nfg_id        AS direct_id,
           MFH.curve_id      AS curve_id
    FROM gram_coop_influence AS INF
    JOIN gram_ng             AS MF
    JOIN gram_nfg            AS NFG
    JOIN gram_nfg            AS MFH
    WHERE MF.n               = m
    AND   MF.sat_tracked     = 1
    AND   NFG.n              = dn
    AND   NFG.f              = df
    AND   NFG.g              = dg
    AND   MFH.n              = m
    AND   MFH.f              = df
    AND   MFH.g              = h;
    


