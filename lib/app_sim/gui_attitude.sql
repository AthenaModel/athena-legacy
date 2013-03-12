------------------------------------------------------------------------
-- TITLE:
--    gui_attitude.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views, Attitude area
--
--    This file is loaded by scenario.tcl!
--
--    GUI views translate the internal data formats of the scenariodb(n)
--    tables into presentation format.  They are defined here instead of
--    in scenariodb(n) so that they can contain application-specific
--    SQL functions.
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- BELIEF SYSTEM VIEWS 

-- gui_mam_topic: All MAM topics
CREATE TEMPORARY VIEW gui_mam_topic AS
SELECT tid                                            AS id,
       tid                                            AS tid,
       title                                          AS title,
       CASE relevance WHEN 1 THEN 'YES' ELSE 'NO' END AS relevance
FROM mam_topic;


-- gui_mam_belief: All MAM beliefs
CREATE TEMPORARY VIEW gui_mam_belief AS
SELECT eid || ' ' || tid                AS id,
       eid                              AS eid,
       tid                              AS tid,
       qposition('name',position)       AS position,
       qemphasis('name',emphasis)       AS emphasis
FROM mam_belief;


-- gui_mam_acompare: A view that shows A.fg and A.gf in parallel.
CREATE TEMPORARY VIEW gui_mam_acompare AS
SELECT id,
       f,
       g,
       format("%4.1f", afg) AS afg,
       format("%4.1f", agf) AS agf
FROM mam_acompare_view;



------------------------------------------------------------------------
-- COOPERATION VIEWS

-- gui_coop_view: A view used for editing baseline cooperation levels
-- in Scenario Mode.
CREATE TEMPORARY VIEW gui_coop_view AS
SELECT f || ' ' || g                            AS id,
       f                                        AS f,
       g                                        AS g,
       format('%5.1f', base)                    AS base,
       regress_to                               AS regress_to,
       CASE WHEN regress_to='BASELINE' 
            THEN format('%5.1f', base)
            ELSE format('%5.1f', natural) END   AS natural
FROM coop_fg
ORDER BY f,g;


-- gui_uram_coop: A view used for displaying cooperation levels and
-- their components in Simulation Mode.
CREATE TEMPORARY VIEW gui_uram_coop AS
SELECT f || ' ' || g                              AS id,
       f                                          AS f,
       g                                          AS g,
       format('%5.1f', coop0)                     AS coop0,
       format('%5.1f', bvalue0)                   AS base0,
       CASE WHEN uram_gamma('COOP') > 0.0
            THEN format('%5.1f', cvalue0)
            ELSE 'n/a' END                        AS nat0,
       format('%5.1f', coop)                      AS coop,
       format('%5.1f', bvalue)                    AS base,
       CASE WHEN uram_gamma('COOP') > 0.0
            THEN format('%5.1f', cvalue)
            ELSE 'n/a' END                        AS nat,
       curve_id                                   AS curve_id,
       fg_id                                      AS fg_id
FROM uram_coop
ORDER BY f,g;


-- gui_coop_ng: Neighborhood cooperation levels.
CREATE TEMPORARY VIEW gui_coop_ng AS
SELECT n || ' ' || g            AS id,
       n                        AS n,
       g                        AS g,
       format('%5.1f', nbcoop0) AS coop0,
       format('%5.1f', nbcoop)  AS coop
FROM uram_nbcoop;

------------------------------------------------------------------------
-- HORIZONTAL RELATIONSHIP VIEWS 

-- gui_hrel_view: A view used for editing baseline horizontal 
-- relationship levels in Scenario Mode.
CREATE TEMPORARY VIEW gui_hrel_view AS
SELECT HV.f || ' ' || HV.g                           AS id,
       HV.f                                          AS f,
       F.gtype                                       AS ftype,
       HV.g                                          AS g,
       G.gtype                                       AS gtype,
       format('%+4.1f', HV.base)                     AS base,
       format('%+4.1f', HV.nat)                      AS nat,
       CASE WHEN override THEN 'Y' ELSE 'N' END      AS override
FROM hrel_view AS HV
JOIN groups AS F ON (F.g = HV.f)
JOIN groups AS G ON (G.g = HV.g)
WHERE F.g != G.g;

-- A gui_hrel_view subview: overridden relationships only.
CREATE TEMPORARY VIEW gui_hrel_override_view AS
SELECT * FROM gui_hrel_view
WHERE override = 'Y';


-- gui_uram_hrel: A view used for displaying the current horizontal
-- relationships and their components in Simulation Mode.
CREATE TEMPORARY VIEW gui_uram_hrel AS
SELECT UH.f || ' ' || UH.g                           AS id,
       UH.f                                          AS f,
       F.gtype                                       AS ftype,
       UH.g                                          AS g,
       G.gtype                                       AS gtype,
       format('%+4.1f', UH.hrel0)                    AS hrel0,
       format('%+4.1f', UH.bvalue0)                  AS base0,
       CASE WHEN uram_gamma('HREL') > 0.0
            THEN format('%+4.1f', UH.cvalue0)
            ELSE 'n/a' END                           AS nat0,
       format('%+4.1f', UH.hrel)                     AS hrel,
       format('%+4.1f', UH.bvalue)                   AS base,
       CASE WHEN uram_gamma('HREL') > 0.0
            THEN format('%+4.1f', UH.cvalue)
            ELSE 'n/a' END                           AS nat,
       UH.curve_id                                   AS curve_id,
       UH.fg_id                                      AS fg_id
FROM uram_hrel AS UH
JOIN groups AS F ON (F.g = UH.f)
JOIN groups AS G ON (G.g = UH.g)
WHERE F.g != G.g;

------------------------------------------------------------------------
-- SATISFACTION VIEWS

-- gui_sat_view: A view used for editing baseline satisfaction levels
-- in Scenario Mode.
CREATE TEMPORARY VIEW gui_sat_view AS
SELECT GC.g || ' ' || GC.c                          AS id,
       GC.g                                         AS g,
       GC.c                                         AS c,
       G.n                                          AS n,
       format('%.3f', GC.base)                      AS base,
       format('%.2f', GC.saliency)                  AS saliency
FROM sat_gc AS GC
JOIN civgroups AS G ON (GC.g = G.g)
ORDER BY g,c;


-- gui_uram_sat: A view used for displaying satisfaction levels and
-- their components in Simulation mode.
CREATE TEMPORARY VIEW gui_uram_sat AS
SELECT US.g || ' ' || US.c                           AS id,
       US.g                                          AS g,
       US.c                                          AS c,
       G.n                                           AS n,
       format('%+4.1f', US.sat0)                     AS sat0,
       format('%+4.1f', US.bvalue0)                  AS base0,
       CASE WHEN uram_gamma(c) > 0.0
            THEN format('%+4.1f', US.cvalue0)
            ELSE 'n/a' END                           AS nat0,
       format('%+4.1f', US.sat)                      AS sat,
       format('%+4.1f', US.bvalue)                   AS base,
       CASE WHEN uram_gamma(c) > 0.0
            THEN format('%+4.1f', US.cvalue)
            ELSE 'n/a' END                           AS nat,
       US.curve_id                                   AS curve_id,
       US.gc_id                                      AS gc_id
FROM uram_sat AS US
JOIN civgroups AS G USING (g)
ORDER BY g,c;


------------------------------------------------------------------------
-- VERTICAL RELATIONSHIPS VIEWS 

-- gui_vrel_view: A view used for editing baseline vertical relationships
-- in Scenario Mode.
CREATE TEMPORARY VIEW gui_vrel_view AS
SELECT g || ' ' || a                              AS id,
       g                                          AS g,
       gtype                                      AS gtype,
       a                                          AS a,
       format('%+4.1f', base)                     AS base,
       format('%+4.1f', nat)                      AS nat,
       CASE WHEN override THEN 'Y' ELSE 'N' END   AS override
FROM vrel_view;

-- A gui_vrel_view subview: overridden relationships only.
CREATE TEMPORARY VIEW gui_vrel_override_view AS
SELECT * FROM gui_vrel_view
WHERE override = 'Y';


-- gui_uram_vrel: A view used for display vertical relationships and
-- their components in Simulation Mode.
CREATE TEMPORARY VIEW gui_uram_vrel AS
SELECT UV.g || ' ' || UV.a                           AS id,
       UV.g                                          AS g,
       G.gtype                                       AS gtype,
       UV.a                                          AS a,
       format('%+4.1f', UV.vrel0)                    AS vrel0,
       format('%+4.1f', UV.bvalue0)                  AS base0,
       CASE WHEN uram_gamma('VREL') > 0.0
            THEN format('%+4.1f', UV.cvalue0)
            ELSE 'n/a' END                           AS nat0,
       format('%+4.1f', UV.vrel)                     AS vrel,
       format('%+4.1f', UV.bvalue)                   AS base,
       CASE WHEN uram_gamma('VREL') > 0.0
            THEN format('%+4.1f', UV.cvalue)
            ELSE 'n/a' END                           AS nat,
       UV.curve_id                                   AS curve_id,
       UV.ga_id                                      AS ga_id
FROM uram_vrel AS UV
JOIN groups AS G ON (G.g = UV.g);


------------------------------------------------------------------------
-- MAGIC ATTITUDE DRIVER VIEWS 

-- gui_mads: All magic attitude drivers
CREATE TEMPORARY VIEW gui_mads AS
SELECT M.driver_id                         AS driver_id,
       M.driver_id || ' - ' || D.narrative AS longid,
       D.narrative                         AS narrative,
       M.cause                             AS cause,
       format('%5.3f',M.s)                 AS s,
       format('%5.3f',M.p)                 AS p,
       format('%5.3f',M.q)                 AS q,
       count(R.firing_id)                  AS firings
FROM mads         AS M
JOIN drivers      AS D USING (driver_id)
LEFT OUTER JOIN rule_firings AS R USING (driver_id)
GROUP BY driver_id;

-- A gui_mads subview: MADs for which no inputs have yet been given 
-- to URAM.
CREATE TEMPORARY VIEW gui_mads_initial AS
SELECT * FROM gui_mads WHERE firings = 0;


-----------------------------------------------------------------------
-- End of File
-----------------------------------------------------------------------