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
       color                                          AS color
FROM civgroups_view;

-- A Force Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_frcgroups AS
SELECT g                                              AS id,
       g                                              AS g,
       longname                                       AS longname,
       color                                          AS color,
       forcetype                                      AS forcetype,
       CASE local     WHEN 1 THEN 'Yes' ELSE 'No' END AS local,
       CASE coalition WHEN 1 THEN 'Yes' ELSE 'No' END AS coalition
FROM groups JOIN frcgroups USING (g);

-- An Org Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_orggroups AS
SELECT g                                             AS id,
       g                                             AS g,
       longname                                      AS longname,
       color                                         AS color,
       orgtype                                       AS orgtype,
       CASE medical  WHEN 1 THEN 'Yes' ELSE 'No' END AS medical,
       CASE engineer WHEN 1 THEN 'Yes' ELSE 'No' END AS engineer,
       CASE support  WHEN 1 THEN 'Yes' ELSE 'No' END AS support,
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
