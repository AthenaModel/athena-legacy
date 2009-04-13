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
SELECT n                       AS id,
       n                       AS n,
       longname                AS longname,
       urbanization            AS urbanization,
       format('%4.1f',vtygain) AS vtygain,                
       stacking_order          AS stacking_order,
       obscured_by             AS obscured_by,
       m2ref(refpoint)         AS refpoint,
       m2ref(polygon)          AS polygon
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
       demeanor                                       AS demeanor,
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
       demeanor                                      AS demeanor,
       format('%.2f', rollup_weight)                 AS rollup_weight,
       format('%.2f', effects_factor)                AS effects_factor
FROM groups JOIN orggroups USING (g);

-- An NB Groups view for use by the GUI
-- NOTE: presumes there is a single gram(n)!
CREATE TEMPORARY VIEW gui_nbgroups AS
SELECT main.n || ' ' || main.g                       AS id,
       main.n                                        AS n,
       main.g                                        AS g,
       local_name                                    AS local_name,
       main.population                               AS population,
       demeanor                                      AS demeanor,
       format('%.3f', coalesce(gram.sat0, 0.0))      AS mood0,
       format('%.3f', coalesce(gram.sat,  0.0))      AS mood,
       format('%.2f', coalesce(gram.rollup_weight, 
                               main.rollup_weight))  AS rollup_weight,
       format('%.2f', coalesce(gram.effects_factor,
                               main.effects_factor)) AS effects_factor
FROM groups 
JOIN nbgroups AS main USING (g)
LEFT OUTER JOIN gram_ng AS gram USING(n,g);

-- A sat_ngc view for use by the GUI: 
-- NOTE: presumes there is a single gram(n)!
CREATE TEMPORARY VIEW gui_sat_ngc AS
SELECT n || ' ' || g || ' ' || c                      AS id,
       n                                              AS n,
       g                                              AS g,
       c                                              AS c,
       format('%.3f', coalesce(gram.sat0, main.sat0)) AS sat0,
       format('%.3f', coalesce(gram.sat, main.sat0))  AS sat,
       format('%.3f', main.trend0)                    AS trend0,
       format('%.2f', main.saliency)                  AS saliency
FROM sat_ngc AS main 
LEFT OUTER JOIN gram_sat AS gram USING (n,g,c);

-- A rel_nfg view for use by the GUI
CREATE TEMPORARY VIEW gui_rel_nfg AS
SELECT n || ' ' || f || ' ' || g                     AS id,
       n                                             AS n,
       f                                             AS f,
       g                                             AS g,
       format('%+4.1f', rel)                         AS rel
FROM rel_nfg;

-- A coop_nfg view for use by the GUI:
-- NOTE: presumes there is a single gram(n)!
CREATE TEMPORARY VIEW gui_coop_nfg AS
SELECT n || ' ' || f || ' ' || g                         AS id,
       n                                                 AS n,
       f                                                 AS f,
       g                                                 AS g,
       format('%5.1f', coalesce(gram.coop0, main.coop0)) AS coop0,
       format('%5.1f', coalesce(gram.coop, main.coop0))  AS coop
FROM coop_nfg AS main 
LEFT OUTER JOIN gram_coop AS gram USING (n,f,g);

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

