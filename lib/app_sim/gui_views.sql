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
       COALESCE(demog_n.population,0)             AS population,
       format('%.3f',COALESCE(gram_n.sat0, 0.0))  AS mood0,
       format('%.3f',COALESCE(gram_n.sat, 0.0))   AS mood
FROM nbhoods 
JOIN demog_n ON (demog_n.n = nbhoods.n)
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
       CASE uniformed WHEN 1 THEN 'YES' ELSE 'NO' END AS uniformed,
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
       main.basepop                                  AS basepop,
       demog_ng.population                           AS population,
       demog_ng.explicit                             AS explicit,
       demog_ng.implicit                             AS implicit,
       demog_ng.displaced                            AS displaced,
       demog_ng.attrition                            AS attrition,
       demeanor                                      AS demeanor,
       format('%.3f', coalesce(gram.sat0, 0.0))      AS mood0,
       format('%.3f', coalesce(gram.sat,  0.0))      AS mood,
       format('%.2f', coalesce(gram.rollup_weight, 
                               main.rollup_weight))  AS rollup_weight,
       format('%.2f', coalesce(gram.effects_factor,
                               main.effects_factor)) AS effects_factor
FROM groups 
JOIN nbgroups AS main USING (g)
JOIN demog_ng USING(n,g)
LEFT OUTER JOIN gram_ng AS gram USING(n,g);

-- An attroe_nfg view for use by the GUI
CREATE TEMPORARY VIEW gui_attroe_nfg AS
SELECT n || ' ' || f || ' ' || g                      AS id,
       n                                              AS n,
       f                                              AS f,
       g                                              AS g,
       uniformed                                      AS uniformed,
       roe                                            AS roe,
       cooplimit                                      AS cooplimit,
       rate                                           AS rate
FROM attroe_nfg;

-- An attroe_nfg view for use by the GUI; f is uniformed
CREATE TEMPORARY VIEW gui_attroeuf_nfg AS
SELECT *
FROM gui_attroe_nfg WHERE uniformed;

-- An attroe_nfg view for use by the GUI; f is non-uniformed
CREATE TEMPORARY VIEW gui_attroenf_nfg AS
SELECT *
FROM gui_attroe_nfg WHERE NOT uniformed;

-- A defroe_ng view for use by the GUI
CREATE TEMPORARY VIEW gui_defroe_ng AS
SELECT n || ' ' || g                                  AS id,
       n                                              AS n,
       g                                              AS g,
       roe                                            AS roe
FROM defroe_ng;

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
SELECT R.n || ' ' || R.f || ' ' || R.g               AS id,
       R.n                                           AS n,
       R.f                                           AS f,
       F.gtype                                       AS ftype,
       R.g                                           AS g,
       G.gtype                                       AS gtype,
       format('%+4.1f', R.rel)                       AS rel
FROM rel_nfg AS R
JOIN groups AS F ON (F.g = R.f)
JOIN groups as G on (G.g = R.g);

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

-- An ensits view for use by the GUI
CREATE TEMPORARY VIEW gui_ensits AS
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
       rduration                AS rduration,
       tozulu(ts+rduration+1)   AS tr,
       CASE inception WHEN 1 THEN 'YES' ELSE 'NO' END AS inception
FROM ensits;

--Ensits view: ensits in INITIAL state
CREATE TEMPORARY VIEW gui_ensits_initial AS
SELECT * FROM gui_ensits
WHERE state = 'INITIAL';

--Ensits view: current ensits: live or freshly ended
CREATE TEMPORARY VIEW gui_ensits_current AS
SELECT * FROM gui_ensits
WHERE state != 'ENDED' OR change != '';
       
--Actsits view: ended ensits
CREATE TEMPORARY VIEW gui_ensits_ended AS
SELECT * FROM gui_ensits WHERE state = 'ENDED';


--View of scheduled orders
CREATE TEMPORARY VIEW gui_orders AS
SELECT id        AS id,
       t         AS tick,
       tozulu(t) AS zulu,
       name      AS name,
       parmdict  AS parmdict
FROM eventq_queue_orderExecute;

-- View of the CIF
CREATE TEMPORARY VIEW gui_cif AS
SELECT id                                            AS id,
       time                                          AS tick,
       tozulu(time)                                  AS zulu,
       name                                          AS name,
       parmdict                                      AS parmdict,
       undo                                          AS undo,
       CASE WHEN undo != '' THEN 'Yes' ELSE 'No' END AS canUndo
FROM cif WHERE id <= ciftop();

-- View of MADs for use in browsers and order dialogs

CREATE TEMPORARY VIEW gui_mads AS
SELECT mads.id                 AS id,
       mads.oneliner           AS oneliner,
       mads.driver             AS driver,
       COALESCE(last_input, 0) AS inputs
FROM mads
LEFT OUTER JOIN gram_driver USING (driver);

CREATE TEMPORARY VIEW gui_mads_orders AS
SELECT id || ' - ' || oneliner   AS id,
       oneliner                  AS oneliner
FROM mads;

CREATE TEMPORARY VIEW gui_mads_orders_initial AS
SELECT id || ' - ' || oneliner   AS id,
       oneliner                  AS oneliner
FROM mads_initial;


------------------------------------------------------------------------
-- Primary Entities
--
-- Anything with an ID and a long name is a primary entity.  All IDs and 
-- long names of primary entities must be unique.  The following view is 
-- used to check this, and to retrieve the entity type for a given ID.

CREATE TEMPORARY VIEW entities AS
SELECT 'PLAYBOX'  AS id, 
       'Playbox'  AS longname, 
       'reserved' AS etype
UNION
SELECT 'ALL'      AS id, 
       'All'      AS longname, 
       'reserved' AS etype
UNION
SELECT 'NONE'     AS id, 
       'None'     AS longname, 
       'reserved' AS etype
UNION
SELECT n         AS id, 
       longname  AS longname, 
       'nbhood'  AS etype 
FROM nbhoods
UNION
SELECT g         AS id, 
       longname  AS longname, 
       'group'   AS etype 
FROM groups
UNION
SELECT c         AS id, 
       longname  AS longname, 
       'concern' AS etype 
FROM concerns
UNION
SELECT a          AS id, 
       longname   AS longname, 
       'activity' AS etype 
FROM activity
UNION
SELECT u         AS id,
       u         AS longname,
       'unit'    AS etype
FROM units;


