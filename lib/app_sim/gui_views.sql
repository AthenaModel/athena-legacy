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
SELECT nbhoods.n                                  AS id,
       nbhoods.n                                  AS n,
       longname                                   AS longname,
       urbanization                               AS urbanization,
       format('%4.1f',vtygain)                    AS vtygain,                
       stacking_order                             AS stacking_order,
       obscured_by                                AS obscured_by,
       m2ref(refpoint)                            AS refpoint,
       m2ref(polygon)                             AS polygon,
       COALESCE(volatility,0)                     AS volatility,
       COALESCE(population,0)                     AS population,
       format('%.3f',COALESCE(gram_n.sat0, 0.0))  AS mood0,
       format('%.3f',COALESCE(gram_n.sat, 0.0))   AS mood
FROM nbhoods 
LEFT OUTER JOIN force_n ON (force_n.n = nbhoods.n)
LEFT OUTER JOIN gram_n  ON (gram_n.n  = nbhoods.n);


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

-- A coop_ng view for use by the GUI:
-- NOTE: presumes there is a single gram(n)!
CREATE TEMPORARY VIEW gui_coop_ng AS
SELECT n || ' ' || g          AS id,
       n                      AS n,
       g                      AS g,
       format('%5.1f', coop0) AS coop0,
       format('%5.1f', coop)  AS coop
FROM gram_frc_ng;

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
SELECT u                                                AS id,
       u                                                AS u,
       g                                                AS g,
       gtype                                            AS gtype,
       origin                                           AS origin,
       n                                                AS n,
       personnel                                        AS personnel,
       m2ref(location)                                  AS location,
       a                                                AS a,
       CASE a_effective WHEN 1 THEN 'YES' ELSE 'NO' END AS a_effective
FROM units;


-- A force_ng view for use by the GUI
CREATE TEMPORARY VIEW gui_security AS
SELECT n || ' ' || g      AS id,
       n                  AS n,
       g                  AS g,
       security           AS security,
       pct_force          AS pct_force,
       pct_enemy          AS pct_enemy,
       volatility         AS volatility,
       volatility_gain    AS volatility_gain,
       nominal_volatility AS nominal_volatility
FROM force_ng JOIN force_n USING (n)
ORDER BY n, g;


-- An activity_nga view for use by the GUI
CREATE TEMPORARY VIEW gui_activity_nga AS
SELECT n || ' ' || g || ' ' || a     AS id,
       n                             AS n,
       g                             AS g,
       a                             AS a,
       format('%6.4f',coverage)      AS coverage,
       CASE security_flag WHEN 1 THEN 'YES' ELSE 'NO' END AS security_flag,
       CASE can_do        WHEN 1 THEN 'YES' ELSE 'NO' END AS can_do,
       nominal                       AS nominal,
       active                        AS active,
       effective                     AS effective,
       stype                         AS stype,
       s                             AS s
FROM activity_nga
WHERE nominal > 0
ORDER BY n,g,a;


-- An actsits view for use by the GUI: All actsits
CREATE TEMPORARY VIEW gui_actsits AS
SELECT s                        AS id,
       s                        AS s,
       change                   AS change,
       state                    AS state,
       driver                   AS driver,
       stype                    AS stype,
       n                        AS n,
       g                        AS g,
       a                        AS a,
       format('%6.4f',coverage) AS coverage,
       tozulu(ts)               AS ts,
       tozulu(tc)               AS tc
FROM actsits;

--Actsits view: current actsits: live or freshly ended
CREATE TEMPORARY VIEW gui_actsits_current AS
SELECT * FROM gui_actsits 
WHERE state != 'ENDED' OR change != '';
       
--Actsits view: ended actsits
CREATE TEMPORARY VIEW gui_actsits_ended AS
SELECT * FROM gui_actsits WHERE state == 'ENDED';

-- An envsits view for use by the GUI
CREATE TEMPORARY VIEW gui_envsits AS
SELECT s                        AS id,
       s                        AS s,
       change                   AS change,
       state                    AS state,
       driver                   AS driver,
       stype                    AS stype,
       n                        AS n,
       g                        AS g,
       format('%6.4f',coverage) AS coverage,
       tozulu(ts)               AS ts,
       tozulu(tc)               AS tc,
       m2ref(location)          AS location,
       flist                    AS flist,
       resolver                 AS resolver,
       CASE inception WHEN 1 THEN 'YES' ELSE 'NO' END AS inception
FROM envsits;

--Envsits view: envsits in INITIAL state
CREATE TEMPORARY VIEW gui_envsits_initial AS
SELECT * FROM gui_envsits
WHERE state = 'INITIAL';

--Envsits view: current envsits: live or freshly ended
CREATE TEMPORARY VIEW gui_envsits_current AS
SELECT * FROM gui_envsits
WHERE state != 'ENDED' OR change != '';
       
--Actsits view: ended envsits
CREATE TEMPORARY VIEW gui_envsits_ended AS
SELECT * FROM gui_envsits WHERE state = 'ENDED';
