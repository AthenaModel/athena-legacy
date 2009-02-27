------------------------------------------------------------------------
-- TITLE:
--    gui_views.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views
--
--    These views translate the internal data formats of the scenariodb(n)
--    tables into presentation format.  They are defined here instead of
--    in scenariodb(n) so that they can contain application-specific
--    SQL functions.
--
------------------------------------------------------------------------

-- A nbhoods view for use by the GUI
CREATE TEMPORARY VIEW gui_nbhoods AS
SELECT n                      AS id,
       n                      AS n,
       longname               AS longname,
       urbanization           AS urbanization,
       stacking_order         AS stacking_order,
       obscured_by            AS obscured_by,
       m2ref(refpoint)        AS refpoint,
       m2ref(polygon)         AS polygon
FROM nbhoods;

-- A Force Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_civgroups AS
SELECT g                                              AS id,
       g                                              AS g,
       longname                                       AS longname,
       color                                          AS color,
       shape                                          AS shape
FROM civgroups_view;

-- A Force Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_frcgroups AS
SELECT g                                              AS id,
       g                                              AS g,
       longname                                       AS longname,
       color                                          AS color,
       shape                                          AS shape,
       forcetype                                      AS forcetype,
       CASE local     WHEN 1 THEN 'YES' ELSE 'NO' END AS local,
       CASE coalition WHEN 1 THEN 'YES' ELSE 'NO' END AS coalition
FROM groups JOIN frcgroups USING (g);

-- An Org Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_orggroups AS
SELECT g                                             AS id,
       g                                             AS g,
       longname                                      AS longname,
       color                                         AS color,
       shape                                         AS shape,
       orgtype                                       AS orgtype,
       CASE medical  WHEN 1 THEN 'YES' ELSE 'NO' END AS medical,
       CASE engineer WHEN 1 THEN 'YES' ELSE 'NO' END AS engineer,
       CASE support  WHEN 1 THEN 'YES' ELSE 'NO' END AS support,
       format('%.2f', rollup_weight)                 AS rollup_weight,
       format('%.2f', effects_factor)                AS effects_factor
FROM groups JOIN orggroups USING (g);

-- An NB Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_nbgroups AS
SELECT n || ' ' || g                                 AS id,
       n                                             AS n,
       g                                             AS g,
       local_name                                    AS local_name,
       demeanor                                      AS demeanor,
       format('%.2f', rollup_weight)                 AS rollup_weight,
       format('%.2f', effects_factor)                AS effects_factor
FROM groups JOIN nbgroups USING (g);

-- A sat_ngc view for use by the GUI
CREATE TEMPORARY VIEW gui_sat_ngc AS
SELECT n || ' ' || g || ' ' || c                     AS id,
       n                                             AS n,
       g                                             AS g,
       c                                             AS c,
       format('%.3f', sat0)                          AS sat0,
       format('%.3f', trend0)                        AS trend0,
       format('%.2f', saliency)                      AS saliency
FROM sat_ngc;

-- A rel_nfg view for use by the GUI
CREATE TEMPORARY VIEW gui_rel_nfg AS
SELECT n || ' ' || f || ' ' || g                     AS id,
       n                                             AS n,
       f                                             AS f,
       g                                             AS g,
       format('%+4.1f', rel)                         AS rel
FROM rel_nfg;

-- A coop_nfg view for use by the GUI
CREATE TEMPORARY VIEW gui_coop_nfg AS
SELECT n || ' ' || f || ' ' || g                     AS id,
       n                                             AS n,
       f                                             AS f,
       g                                             AS g,
       format('%5.1f', coop0)                        AS coop0
FROM coop_nfg;

-- An nbrel_mn view for use by the GUI
CREATE TEMPORARY VIEW gui_nbrel_mn AS
SELECT m || ' ' || n                                 AS id,
       m                                             AS m,
       n                                             AS n,
       proximity                                     AS proximity,
       format('%5.1f', effects_delay)                AS effects_delay
FROM nbrel_mn;

-- A units view for use by the GUI
CREATE TEMPORARY VIEW gui_units AS
SELECT u                      AS id,
       u                      AS u,
       g                      AS g,
       gtype                  AS gtype,
       n                      AS n,
       personnel              AS personnel,
       m2ref(location)        AS location,
       activity               AS activity
FROM units;

