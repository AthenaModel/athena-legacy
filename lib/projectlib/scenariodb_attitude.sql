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
    -- For some driver types, the driver is associated with a signature
    -- that is unique for that driver type.  This allows the rule set to
    -- retrieve the driver ID given the driver type and signature.

    driver_id INTEGER PRIMARY KEY,  -- Integer ID
    dtype     TEXT,                 -- Driver type (usually a rule set name)
    signature TEXT,                 -- Signature, by driver type.
    narrative TEXT,                 -- Narrative text
    inputs    INTEGER DEFAULT 0     -- Number of inputs for this driver.
);

CREATE INDEX drivers_signature_index ON drivers(dtype,signature);

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
-- End of File
------------------------------------------------------------------------
