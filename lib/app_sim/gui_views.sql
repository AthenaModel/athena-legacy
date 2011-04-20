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

-- An Actors view for use by the GUI
CREATE TEMPORARY VIEW gui_actors AS
SELECT a                                               AS id,
       a                                               AS a,
       'my://app/actor/' || a                          AS url,
       pair(longname, a)                               AS fancy,
       link('my://app/actor/' || a, a)                 AS link,
       link('my://app/actor/' || a, pair(longname, a)) AS longlink,
       longname                                        AS longname,
       moneyfmt(cash_reserve)                          AS cash_reserve,
       moneyfmt(income)                                AS income,
       moneyfmt(cash_on_hand)                          AS cash_on_hand
FROM actors;

-- A nbhoods view for use by the GUI
CREATE TEMPORARY VIEW gui_nbhoods AS
SELECT N.n                                                    AS id,
       N.n                                                    AS n,
       'my://app/nbhood/' || N.n                              AS url,
       pair(N.longname, N.n)                                  AS fancy,
       link('my://app/nbhood/' || N.n, N.n)                   AS link,
       link('my://app/nbhood/' || N.n, pair(N.longname, N.n)) AS longlink,
       N.longname                                             AS longname,
       CASE N.local WHEN 1 THEN 'YES' ELSE 'NO' END           AS local,
       N.urbanization                                         AS urbanization,
       COALESCE(C.controller,N.controller, 'NONE')            AS controller,
       COALESCE(C.since, 0)                                   AS since_ticks,
       tozulu(COALESCE(C.since, 0))                           AS since,
       format('%4.1f',N.vtygain)                              AS vtygain,
       N.stacking_order                                      AS stacking_order,
       N.obscured_by                                          AS obscured_by,
       m2ref(N.refpoint)                                      AS refpoint,
       m2ref(N.polygon)                                       AS polygon,
       COALESCE(F.volatility,0)                               AS volatility,
       COALESCE(D.displaced,0)                                AS displaced,
       COALESCE(D.displaced_labor_force,0)                    AS dlf,
       COALESCE(D.population,0)                               AS population,
       COALESCE(D.subsistence,0)                              AS subsistence,
       COALESCE(D.consumers,0)                                AS consumers,
       COALESCE(D.labor_force,0)                              AS labor_force,
       COALESCE(D.unemployed,0)                               AS unemployed,
       format('%.3f',COALESCE(GR.sat0, 0.0))                  AS mood0,
       format('%.3f',COALESCE(GR.sat, 0.0))                   AS mood
FROM nbhoods              AS N
JOIN demog_n              AS D  USING (n)
LEFT OUTER JOIN force_n   AS F  USING (n)
LEFT OUTER JOIN gram_n    AS GR USING (n)
LEFT OUTER JOIN control_n AS C  USING (n);

-- A Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_groups AS
SELECT g                                               AS id,
       g                                               AS g,
       'my://app/group/' || g                          AS url,
       pair(longname, g)                               AS fancy,
       link('my://app/group/' || g, g)                 AS link,
       link('my://app/group/' || g, pair(longname, g)) AS longlink,
       gtype                                           AS gtype,
       longname                                        AS longname,
       color                                           AS color,
       shape                                           AS shape,
       demeanor                                        AS demeanor,
       basepop                                         AS basepop
FROM groups;


-- A CIV Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_civgroups AS
SELECT G.id                                         AS id,
       G.g                                          AS g,
       G.url                                        AS url,
       G.fancy                                      AS fancy,
       G.link                                       AS link,
       G.longlink                                   AS longlink,
       G.gtype                                      AS gtype,
       G.longname                                   AS longname,
       G.color                                      AS color,
       G.shape                                      AS shape,
       G.demeanor                                   AS demeanor,
       G.basepop                                    AS basepop,
       CG.n                                         AS n,
       CG.sap                                       AS sap,
       DG.population                                AS population,
       DG.displaced                                 AS displaced,
       DG.attrition                                 AS attrition,
       DG.subsistence                               AS subsistence,
       DG.consumers                                 AS consumers,
       DG.labor_force                               AS labor_force,
       DG.unemployed                                AS unemployed,
       format('%.1f', DG.upc)                       AS upc,
       format('%.2f', DG.uaf)                       AS uaf,
       format('%.3f', coalesce(gram_g.sat0, 0.0))   AS mood0,
       format('%.3f', coalesce(gram_g.sat,  0.0))   AS mood
FROM gui_groups AS G
JOIN civgroups  AS CG USING (g)
JOIN demog_g    AS DG USING (g)
LEFT OUTER JOIN gram_g USING (g);

-- A Force Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_frcgroups AS
SELECT G.id                                             AS id,
       G.g                                              AS g,
       G.url                                            AS url,
       G.fancy                                          AS fancy,
       G.link                                           AS link,
       G.longlink                                       AS longlink,
       G.gtype                                          AS gtype,
       G.longname                                       AS longname,
       G.color                                          AS color,
       G.shape                                          AS shape,
       G.demeanor                                       AS demeanor,
       G.basepop                                        AS basepop,
       F.a                                              AS a,
       F.forcetype                                      AS forcetype,
       CASE F.uniformed WHEN 1 THEN 'YES' ELSE 'NO' END AS uniformed,
       CASE F.local     WHEN 1 THEN 'YES' ELSE 'NO' END AS local
FROM gui_groups AS G
JOIN frcgroups  AS F USING (g);

-- An Org Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_orggroups AS
SELECT G.id                                             AS id,
       G.g                                              AS g,
       G.url                                            AS url,
       G.fancy                                          AS fancy,
       G.link                                           AS link,
       G.longlink                                       AS longlink,
       G.gtype                                          AS gtype,
       G.longname                                       AS longname,
       G.color                                          AS color,
       G.shape                                          AS shape,
       G.demeanor                                       AS demeanor,
       G.basepop                                        AS basepop,
       O.a                                              AS a,
       O.orgtype                                        AS orgtype
FROM gui_groups AS G
JOIN orggroups  AS O USING (g);

-- All groups that can be owned by actors
CREATE TEMP VIEW gui_agroups AS
SELECT g, url, fancy, link, longlink, gtype, longname, a, 
       forcetype           AS subtype,
       'FRC/' || forcetype AS fulltype
FROM gui_frcgroups
UNION
SELECT g, url, fancy, link, longlink, gtype, longname, a, 
       orgtype           AS subtype,
       'ORG/' || orgtype AS fulltype
FROM gui_orggroups;

-- A belief system topics for use by the GUI
CREATE TEMPORARY VIEW gui_mam_topic AS
SELECT tid                                            AS id,
       tid                                            AS tid,
       title                                          AS title,
       CASE relevance WHEN 1 THEN 'YES' ELSE 'NO' END AS relevance
FROM mam_topic;

-- A belief system beliefs view for use by the GUI
CREATE TEMPORARY VIEW gui_mam_belief AS
SELECT eid || ' ' || tid                AS id,
       eid                              AS eid,
       tid                              AS tid,
       qposition('name',position)       AS position,
       qtolerance('name',tolerance)     AS tolerance
FROM mam_belief;

-- An affinity comparison view
CREATE TEMPORARY VIEW gui_mam_acompare AS
SELECT id,
       f,
       g,
       format("%4.1f", afg) AS afg,
       format("%4.1f", agf) AS agf
FROM mam_acompare_view;


-- A personnel_ng view for use by the GUI.
CREATE TEMPORARY VIEW gui_personnel_ng AS
SELECT n || ' ' || g                                 AS id,
       n                                             AS n,
       g                                             AS g,
       personnel                                     AS personnel
FROM personnel_ng;
       

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

-- A universe attroeuf view, for use when creating new ROEs with
-- f uniformed.

CREATE TEMPORARY VIEW gui_attroeuf_univ AS
SELECT nbhoods.n || ' ' || F.g || ' ' || G.g          AS id,
       nbhoods.n                                      AS n,
       F.g                                            AS f,
       G.g                                            AS g
FROM nbhoods 
JOIN frcgroups AS F
JOIN frcgroups AS G
WHERE F.uniformed = 1
AND   G.uniformed = 0;


-- An attroe_nfg view for use by the GUI; f is non-uniformed
CREATE TEMPORARY VIEW gui_attroenf_nfg AS
SELECT *
FROM gui_attroe_nfg WHERE NOT uniformed;

-- A universe attroenf view, for use when creating new ROEs with
-- f non-uniformed.

CREATE TEMPORARY VIEW gui_attroenf_univ AS
SELECT nbhoods.n || ' ' || F.g || ' ' || G.g          AS id,
       nbhoods.n                                      AS n,
       F.g                                            AS f,
       G.g                                            AS g
FROM nbhoods 
JOIN frcgroups AS F
JOIN frcgroups AS G
WHERE F.uniformed = 0
AND   G.uniformed = 1;


-- A defroe view for use by the GUI
CREATE TEMPORARY VIEW gui_defroe_view AS
SELECT n || ' ' || g                                  AS id,
       n                                              AS n,
       g                                              AS g,
       roe                                            AS roe,
       override                                       AS override
FROM defroe_view;

-- A sat_gc view for use by the GUI: 
-- NOTE: presumes there is a single gram(n)!
CREATE TEMPORARY VIEW gui_sat_gc AS
SELECT main.g || ' ' || main.c                        AS id,
       main.g                                         AS g,
       main.c                                         AS c,
       CG.n                                           AS n,
       format('%.3f', coalesce(gram.sat0, main.sat0)) AS sat0,
       format('%.3f', coalesce(gram.sat, main.sat0))  AS sat,
       format('%.2f', main.saliency)                  AS saliency,
       format('%.2f', main.atrend)                    AS atrend,
       format('%.1f', main.athresh)                   AS athresh,
       format('%.2f', main.dtrend)                    AS dtrend,
       format('%.1f', main.dthresh)                   AS dthresh
FROM sat_gc AS main
JOIN civgroups AS CG ON (main.g = CG.g) 
LEFT OUTER JOIN gram_sat AS gram ON (main.g = gram.g AND main.c = gram.c);


-- A rel_fg view for use by the GUI
CREATE TEMPORARY VIEW gui_rel_view AS
SELECT R.f || ' ' || R.g                             AS id,
       R.f                                           AS f,
       F.gtype                                       AS ftype,
       R.g                                           AS g,
       G.gtype                                       AS gtype,
       format('%+4.1f', R.rel)                       AS rel,
       CASE WHEN override THEN 'Y' ELSE 'N' END      AS override
FROM rel_view AS R
JOIN groups AS F ON (F.g = R.f)
JOIN groups as G on (G.g = R.g)
WHERE F.g != G.g;

-- A gui_rel_view subview, for overridden relationships only.
CREATE TEMPORARY VIEW gui_rel_override_view AS
SELECT * FROM gui_rel_view
WHERE override = 'Y';

-- A coop_fg view for use by the GUI:
-- NOTE: presumes there is a single gram(n)!
CREATE TEMPORARY VIEW gui_coop_fg AS
SELECT f || ' ' || g                                     AS id,
       f                                                 AS f,
       g                                                 AS g,
       format('%5.1f', coalesce(gram.coop0, main.coop0)) AS coop0,
       format('%5.1f', coalesce(gram.coop, main.coop0))  AS coop,
       format('%.2f', main.atrend)                       AS atrend,
       format('%.1f', main.athresh)                      AS athresh,
       format('%.2f', main.dtrend)                       AS dtrend,
       format('%.1f', main.dthresh)                      AS dthresh
FROM coop_fg AS main 
LEFT OUTER JOIN gram_coop AS gram USING (f,g);

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
FROM nbrel_mn
WHERE m != n;

-- A units view for use by the GUI
CREATE TEMPORARY VIEW gui_units AS
SELECT u                                                AS id,
       u                                                AS u,
       cid                                              AS cid,
       n                                                AS n,
       g                                                AS g,
       gtype                                            AS gtype,
       origin                                           AS origin,
       a                                                AS a,
       personnel                                        AS personnel,
       m2ref(location)                                  AS location,
       CASE a_effective WHEN 1 THEN 'YES' ELSE 'NO' END AS a_effective
FROM units
WHERE active;


-- A force_ng view for use by the GUI
CREATE TEMPORARY VIEW gui_security AS
SELECT n || ' ' || g                  AS id,
       n                              AS n,
       g                              AS g,
       force_ng.personnel             AS personnel,
       security                       AS security,
       qsecurity('longname',security) AS symbol,
       pct_force                      AS pct_force,
       pct_enemy                      AS pct_enemy,
       volatility                     AS volatility,
       volatility_gain                AS volatility_gain,
       nominal_volatility             AS nominal_volatility
FROM force_ng JOIN force_n USING (n)
ORDER BY n, g;

-- An activity calendar view for use by the GUI
CREATE TEMPORARY VIEW gui_calendar AS
SELECT C.cid                                            AS cid,
       C.n                                              AS n,
       C.g                                              AS g,
       C.a                                              AS a,
       C.tn                                             AS tn,
       C.personnel                                      AS personnel,
       C.priority                                       AS priority,
       C.start                                          AS start_tick,
       CASE WHEN C.start == now()     THEN 'NOW'
            WHEN C.start == now() + 1 THEN 'NOW+1'
            ELSE tozulu(C.start)      END               AS start,
       C.finish                                         AS finish_tick,
       CASE WHEN C.finish == ''        THEN 'NEVER'
            WHEN C.finish == now()     THEN 'NOW'
            WHEN C.finish == now() + 1 THEN 'NOW+1'
            ELSE tozulu(C.finish)      END              AS finish,
       C.pattern                                        AS pattern,
       calpattern_narrative(C.pattern,C.start,C.finish) AS narrative,
       U.u                                              AS u
FROM calendar AS C
LEFT OUTER JOIN units AS U USING (cid)
ORDER BY priority, g, n, a, tn;

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

-- A demsits view for use by the GUI: All demsits
CREATE TEMPORARY VIEW gui_demsits AS
SELECT s                        AS id,
       s                        AS s,
       change                   AS change,
       state                    AS state,
       driver                   AS driver,
       stype                    AS stype,
       n                        AS n,
       g                        AS g,
       format('%4.2f',ngfactor) AS ngfactor,
       format('%4.2f',nfactor)  AS nfactor,
       tozulu(ts)               AS ts,
       tozulu(tc)               AS tc
FROM demsits;

-- Demsits view: current demsits: live or freshly ended
CREATE TEMPORARY VIEW gui_demsits_current AS
SELECT * FROM gui_demsits 
WHERE state != 'ENDED' OR change != '';
       
--Demsits view: ended demsits
CREATE TEMPORARY VIEW gui_demsits_ended AS
SELECT * FROM gui_demsits WHERE state == 'ENDED';

-- An ensits view for use by the GUI
CREATE TEMPORARY VIEW gui_ensits AS
SELECT s                                              AS id,
       s || ' -- ' || stype || ' in '|| n             AS longid,
       s                                              AS s,
       change                                         AS change,
       state                                          AS state,
       driver                                         AS driver,
       stype                                          AS stype,
       n                                              AS n,
       g                                              AS g,
       format('%6.4f',coverage)                       AS coverage,
       tozulu(ts)                                     AS ts,
       tozulu(tc)                                     AS tc,
       m2ref(location)                                AS location,
       flist                                          AS flist,
       resolver                                       AS resolver,
       rduration                                      AS rduration,
       tozulu(ts+rduration)                           AS tr,
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
       narrative AS narrative,
       parmdict  AS parmdict
FROM eventq_queue_order_execute;

--View of scheduled force level orders
CREATE TEMPORARY VIEW gui_plan_force_level_orders AS
SELECT id        AS id,
       t         AS tick,
       tozulu(t) AS zulu,
       name      AS name,
       narrative AS narrative,
       parmdict  AS parmdict
FROM eventq_queue_order_execute
WHERE name GLOB 'PERSONNEL:*';

-- View of the CIF
CREATE TEMPORARY VIEW gui_cif AS
SELECT id                                            AS id,
       time                                          AS tick,
       tozulu(time)                                  AS zulu,
       name                                          AS name,
       narrative                                     AS narrative,
       parmdict                                      AS parmdict,
       undo                                          AS undo,
       CASE WHEN undo != '' THEN 'Yes' ELSE 'No' END AS canUndo
FROM cif WHERE id <= ciftop()
ORDER BY id DESC;

-- View of MADs for use in browsers and order dialogs

CREATE TEMPORARY VIEW gui_mads AS
SELECT mads.id                             AS id,
       mads.id || ' - ' || mads.oneliner   AS longid,
       mads.oneliner                       AS oneliner,
       mads.cause                          AS cause,
       format('%5.3f',mads.s)              AS s,
       format('%5.3f',mads.p)              AS p,
       format('%5.3f',mads.q)              AS q,
       mads.driver                         AS driver,
       COALESCE(last_input, 0)             AS inputs
FROM mads
LEFT OUTER JOIN gram_driver USING (driver);


CREATE TEMPORARY VIEW gui_mads_initial AS
SELECT * FROM gui_mads WHERE inputs = 0;

------------------------------------------------------------------------
-- Economic Model views

-- An econ_n view for use by the GUI
CREATE TEMPORARY VIEW gui_econ_n AS
SELECT E.n                                          AS id,
       E.n                                          AS n,
       E.longname                                   AS longname,
       CASE E.local WHEN 1 THEN 'YES' ELSE 'NO' END AS local,
       E.urbanization                               AS urbanization,
       format('%.2f',E.pcf)                         AS pcf,
       moneyfmt(E.ccf)                              AS ccf,
       moneyfmt(E.cap0)                             AS cap0,
       moneyfmt(E.cap)                              AS cap,
       COALESCE(D.population,0)                     AS population,
       COALESCE(D.subsistence,0)                    AS subsistence,
       COALESCE(D.consumers,0)                      AS consumers,
       COALESCE(D.labor_force,0)                    AS labor_force,
       D.unemployed                                 AS unemployed,
       format('%.1f', D.upc)                        AS upc,
       format('%.2f', D.uaf)                        AS uaf
FROM econ_n_view AS E
JOIN demog_n as D using (n)
JOIN nbhoods AS N using (n)
WHERE N.local;

-- A civgroups view for econ data, used by the GUI
CREATE TEMPORARY VIEW gui_econ_g AS
SELECT * FROM gui_civgroups 
JOIN nbhoods USING (n)
WHERE nbhoods.local;


------------------------------------------------------------------------
-- Primary Entities
--
-- Any primary entity's ID must be unique in the scenario.  This
-- view creates a list of primary entity IDs, so that we can verify 
-- this, and retrieve the entity type for a given ID.  The list
-- includes a number of reserved words.
--
-- TBD: Should we just have an "entities" table and insert a row
-- into it for each entity?

CREATE TEMPORARY VIEW entities AS
SELECT 'PLAYBOX' AS id, 'reserved' AS etype                  UNION
SELECT 'CIV'     AS id, 'reserved' AS etype                  UNION
SELECT 'FRC'     AS id, 'reserved' AS etype                  UNION
SELECT 'ORG'     AS id, 'reserved' AS etype                  UNION
SELECT 'ALL'     AS id, 'reserved' AS etype                  UNION
SELECT 'NONE'    AS id, 'reserved' AS etype                  UNION
SELECT n         AS id, 'nbhood'   AS etype FROM nbhoods     UNION
SELECT a         AS id, 'actor'    AS etype FROM actors      UNION
SELECT g         AS id, 'group'    AS etype FROM groups      UNION
SELECT c         AS id, 'concern'  AS etype FROM concerns    UNION
SELECT a         AS id, 'activity' AS etype FROM activity    UNION
SELECT u         AS id, 'unit'     AS etype FROM units       UNION
SELECT tid       AS id, 'topic'    AS etype FROM mam_topic;

