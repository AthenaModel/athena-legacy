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

-- A sigvents view for use by the GUI.

CREATE TEMPORARY VIEW gui_sigevents AS
SELECT event_id                                        AS event_id,
       level                                           AS level,
       t                                               AS t,
       tozulu(t)                                       AS zulu,
       component                                       AS component,
       mklinks(narrative)                              AS narrative
FROM sigevents
ORDER BY event_id ASC;

CREATE TEMPORARY VIEW gui_sigevents_wtag AS
SELECT event_id                                        AS event_id,
       level                                           AS level,
       t                                               AS t,
       tozulu(t)                                       AS zulu,
       component                                       AS component,
       mklinks(narrative)                              AS narrative,
       tag                                             AS tag
FROM sigevents_view
ORDER BY event_id ASC;
     

-- An Actors view for use by the GUI
CREATE TEMPORARY VIEW gui_actors AS
SELECT a                                               AS id,
       a                                               AS a,
       'my://app/actor/' || a                          AS url,
       pair(longname, a)                               AS fancy,
       link('my://app/actor/' || a, a)                 AS link,
       link('my://app/actor/' || a, pair(longname, a)) AS longlink,
       longname                                        AS longname,
       CASE WHEN supports = a      THEN 'SELF'
            WHEN supports IS NULL  THEN 'NONE'
            ELSE supports 
            END                                        AS supports,
       CASE WHEN supports = a      THEN 'SELF'
            WHEN supports IS NULL  THEN 'NONE'
            ELSE link('my://app/actor/' || supports, supports)
            END                                        AS supports_link,
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
       N.stacking_order                                       AS stacking_order,
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
       -- TBD: These should be "nbmood", not "mood".
       format('%.3f',COALESCE(UN.nbmood0, 0.0))               AS mood0,
       format('%.3f',COALESCE(UN.nbmood, 0.0))                AS mood
FROM nbhoods              AS N
JOIN demog_n              AS D  USING (n)
LEFT OUTER JOIN force_n   AS F  USING (n)
LEFT OUTER JOIN uram_n    AS UN USING (n)
LEFT OUTER JOIN control_n AS C  USING (n);

-- A Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_groups AS
SELECT g                                                 AS id,
       g                                                 AS g,
       'my://app/group/' || g                            AS url,
       pair(longname, g)                                 AS fancy,
       link('my://app/group/' || g, g)                   AS link,
       link('my://app/group/' || g, pair(longname, g))   AS longlink,
       gtype                                             AS gtype,
       link('my://app/groups/' || lower(gtype), gtype)   AS gtypelink,
       longname                                          AS longname,
       color                                             AS color,
       shape                                             AS shape,
       demeanor                                          AS demeanor,
       moneyfmt(cost)                                    AS cost
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
       CG.basepop                                   AS basepop,
       CG.n                                         AS n,
       CG.sap                                       AS sap,
       DG.population                                AS population,
       DG.displaced                                 AS displaced,
       DG.attrition                                 AS attrition,
       DG.subsistence                               AS subsistence,
       DG.consumers                                 AS consumers,
       DG.labor_force                               AS labor_force,
       DG.unemployed                                AS unemployed,
       CASE WHEN SR.req_funding IS NULL
            THEN 'N/A' 
            ELSE moneyfmt(SR.req_funding) END       AS req_funding, 
       CASE WHEN SR.sat_funding IS NULL
            THEN 'N/A' 
            ELSE moneyfmt(SR.sat_funding) END       AS sat_funding, 
       format('%.1f', DG.upc)                       AS upc,
       format('%.2f', DG.uaf)                       AS uaf,
       format('%.3f', coalesce(UM.mood0, 0.0))      AS mood0,
       format('%.3f', coalesce(UM.mood, 0.0))       AS mood
FROM gui_groups AS G
JOIN civgroups  AS CG USING (g)
JOIN demog_g    AS DG USING (g)
LEFT OUTER JOIN sr_service AS SR USING (g)
LEFT OUTER JOIN uram_mood  AS UM USING (g);

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
       coalesce(P.personnel, 0)                         AS personnel,
       G.cost                                           AS cost,
       F.a                                              AS a,
       F.forcetype                                      AS forcetype,
       F.base_personnel                                 AS base_personnel,
       moneyfmt(F.attack_cost)                          AS attack_cost,
       CASE F.uniformed WHEN 1 THEN 'YES' ELSE 'NO' END AS uniformed,
       CASE F.local     WHEN 1 THEN 'YES' ELSE 'NO' END AS local
FROM gui_groups  AS G
JOIN frcgroups   AS F USING (g)
LEFT OUTER JOIN personnel_g AS P USING (g);

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
       coalesce(P.personnel, 0)                         AS personnel,
       G.cost                                           AS cost,
       O.a                                              AS a,
       O.orgtype                                        AS orgtype,
       O.base_personnel                                 AS base_personnel
FROM gui_groups  AS G
JOIN orggroups   AS O USING (g)
LEFT OUTER JOIN personnel_g AS P USING (g);

-- All groups that can be owned by actors
CREATE TEMP VIEW gui_agroups AS
SELECT g, url, fancy, link, longlink, gtype, longname, a, cost,
       forcetype           AS subtype,
       'FRC/' || forcetype AS fulltype
FROM gui_frcgroups
UNION
SELECT g, url, fancy, link, longlink, gtype, longname, a, cost,
       orgtype           AS subtype,
       'ORG/' || orgtype AS fulltype
FROM gui_orggroups;


-- Support of one actor by another in neighborhoods.
CREATE TEMPORARY VIEW gui_supports AS
SELECT NA.n                                             AS n,
       N.link                                           AS nlink,
       N.longlink                                       AS nlonglink,
       NA.a                                             AS a,
       A.link                                           AS alink,
       A.longlink                                       AS alonglink,
       CASE WHEN NA.supports = NA.a   THEN 'SELF'
            WHEN NA.supports IS NULL  THEN 'NONE'
            ELSE NA.supports 
            END                                         AS supports,
       CASE WHEN NA.supports = NA.a   THEN 'SELF'
            WHEN NA.supports IS NULL  THEN 'NONE'
            ELSE link('my://app/actor/' || NA.supports, NA.supports)
            END                                         AS supports_link
FROM supports_na AS NA
JOIN gui_nbhoods AS N ON (NA.n = N.n)
JOIN gui_actors  AS A ON (A.a = NA.a);

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
       qemphasis('name',emphasis)       AS emphasis
FROM mam_belief;

-- An affinity comparison view
CREATE TEMPORARY VIEW gui_mam_acompare AS
SELECT id,
       f,
       g,
       format("%4.1f", afg) AS afg,
       format("%4.1f", agf) AS agf
FROM mam_acompare_view;

-- Conflicts: a view of frc groups in conflict.
CREATE TEMPORARY VIEW gui_conflicts AS
SELECT A.n                                               AS n,
       N.longlink                                        AS nlink,
       A.f                                               AS f,
       F.longlink                                        AS flink,
       F.a                                               AS factor,
       FA.longlink                                       AS factorlink,
       FP.personnel                                      AS fpersonnel,
       A.roe                                             AS froe,
       A.max_attacks                                     AS fattacks,
       A.g                                               AS g,
       G.longlink                                        AS glink,
       G.a                                               AS gactor,
       GA.longlink                                       AS gactorlink,
       G.uniformed                                       AS guniformed,
       GP.personnel                                      AS gpersonnel,
       coalesce(D.roe, 'n/a')                            AS groe
FROM attroe_nfg AS A
JOIN gui_nbhoods AS N ON (N.n = A.n)
JOIN gui_frcgroups AS F ON (F.g = A.f)
JOIN gui_frcgroups AS G on (G.g = A.g)
JOIN gui_actors    AS FA on (FA.a = F.a)
JOIN gui_actors    AS GA on (GA.a = G.a)
JOIN deploy_ng AS FP ON (FP.n=A.n AND FP.g=A.f)
JOIN deploy_ng AS GP ON (GP.n=A.n AND GP.g=A.g)
LEFT OUTER JOIN defroe_view AS D ON (D.n=A.n AND D.g=A.g)
WHERE A.roe != 'DO_NOT_ATTACK';

-- Def ROEs: a view of frc group defense
CREATE TEMPORARY VIEW gui_defroe AS
SELECT D.n                                               AS n,
       N.longlink                                        AS nlink,
       D.g                                               AS g,
       G.longlink                                        AS glink,
       D.roe                                             AS roe,
       G.a                                               AS owner,
       GA.longlink                                       AS ownerlink,
       GP.personnel                                      AS personnel,
       D.override                                        AS override
FROM defroe_view AS D
JOIN gui_nbhoods AS N ON (N.n = D.n)
JOIN gui_frcgroups AS G on (G.g = D.g)
JOIN gui_actors    AS GA on (GA.a = G.a)
JOIN deploy_ng AS GP ON (GP.n=D.n AND GP.g=D.g);

-- A GUI service_g view
CREATE TEMPORARY VIEW gui_service_g AS
SELECT g                                           AS id,
       g                                           AS g,
       url                                         AS url,
       fancy                                       AS fancy,
       link                                        AS link,
       longlink                                    AS longlink,
       n                                           AS n,
       sat_funding                                 AS saturation_funding,
       required                                    AS required,
       percent(required)                           AS pct_required,
       moneyfmt(funding)                           AS funding,
       actual                                      AS actual,
       percent(actual)                             AS pct_actual,
       expected                                    AS expected,
       percent(expected)                           AS pct_expected,
       format('%.2f', needs)                       AS needs,
       format('%.2f', expectf)                     AS expectf
FROM service_g
JOIN gui_civgroups USING (g);

-- A GUI service_ga view
CREATE TEMPORARY VIEW gui_service_ga AS
SELECT G.g                                         AS g,
       G.url                                       AS gurl,
       G.fancy                                     AS gfancy,
       G.link                                      AS glink,
       G.longlink                                  AS glonglink,
       A.a                                         AS a,
       A.url                                       AS aurl,
       A.fancy                                     AS afancy,
       A.link                                      AS alink,
       A.longlink                                  AS alonglink,
       N.n                                         AS n,
       N.fancy                                     AS fancy,
       N.url                                       AS nurl,
       N.link                                      AS nlink,
       N.longlink                                  AS nlonglink,
       funding                                     AS numeric_funding,
       moneyfmt(GA.funding)                        AS funding,
       GA.credit                                   AS credit,
       percent(GA.credit)                          AS pct_credit
FROM service_ga    AS GA
JOIN gui_civgroups AS G ON (GA.g = G.g)
JOIN gui_actors    AS A ON (GA.a = A.a)
JOIN gui_nbhoods   AS N ON (G.n = N.n);

-- A sat_gc view for use by the GUI during Scenario Mode: 
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

-- A uram_sat_view for use by the GUI during simulation. Replace the
-- natural level with "n/a" when gamma is 0.
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

-- An hrel_view for use by the GUI during scenario preparation.
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

-- A gui_hrel_view subview, for overridden relationships only.
CREATE TEMPORARY VIEW gui_hrel_override_view AS
SELECT * FROM gui_hrel_view
WHERE override = 'Y';

-- A uram_hrel_view for use by the GUI during simulation.
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


-- A vrel_view for use by the GUI in Scenario Mode.
CREATE TEMPORARY VIEW gui_vrel_view AS
SELECT g || ' ' || a                              AS id,
       g                                          AS g,
       gtype                                      AS gtype,
       a                                          AS a,
       format('%+4.1f', base)                     AS base,
       format('%+4.1f', nat)                      AS nat,
       CASE WHEN override THEN 'Y' ELSE 'N' END   AS override
FROM vrel_view;

-- A gui_vrel_view subview, for overridden relationships only.
CREATE TEMPORARY VIEW gui_vrel_override_view AS
SELECT * FROM gui_vrel_view
WHERE override = 'Y';

-- A uram_vrel_view for use by the GUI during simulation.
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

-- A coop_fg view for use by the GUI during Scenario Mode:
CREATE TEMPORARY VIEW gui_coop_view AS
SELECT f || ' ' || g                                     AS id,
       f                                                 AS f,
       g                                                 AS g,
       format('%5.1f', base)                             AS base
FROM coop_fg
ORDER BY f,g;

-- A uram_coop_view for use by the GUI during simulation. Replace the
-- natural level with "n/a" when gamma is 0.
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

-- A coop_ng view for use by the GUI:
CREATE TEMPORARY VIEW gui_coop_ng AS
SELECT n || ' ' || g            AS id,
       n                        AS n,
       g                        AS g,
       format('%5.1f', nbcoop0) AS coop0,
       format('%5.1f', nbcoop)  AS coop
FROM uram_nbcoop;

-- An nbrel_mn view for use by the GUI
CREATE TEMPORARY VIEW gui_nbrel_mn AS
SELECT MN.m || ' ' || MN.n                           AS id,
       MN.m                                          AS m,
       M.longlink                                    AS m_longlink,
       MN.n                                          AS n,
       N.longlink                                    AS n_longlink,
       MN.proximity                                  AS proximity
FROM nbrel_mn AS MN
JOIN gui_nbhoods AS M ON (MN.m = M.n)
JOIN gui_nbhoods AS N ON (MN.n = N.n)
WHERE MN.m != MN.n;

-- A units view for use by the GUI
CREATE TEMPORARY VIEW gui_units AS
SELECT u                                                AS id,
       u                                                AS u,
       tactic_id                                        AS tactic_id,
       n                                                AS n,
       g                                                AS g,
       gtype                                            AS gtype,
       origin                                           AS origin,
       a                                                AS a,
       personnel                                        AS personnel,
       m2ref(location)                                  AS location
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
       driver_id                AS driver_id,
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
       driver_id                AS driver_id,
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
       driver_id                                      AS driver_id,
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
FROM cif
ORDER BY id DESC;

-- View of MADs for use in browsers and order dialogs

CREATE TEMPORARY VIEW gui_mads AS
SELECT M.driver_id                         AS driver_id,
       M.driver_id || ' - ' || D.narrative AS longid,
       D.narrative                         AS narrative,
       M.cause                             AS cause,
       format('%5.3f',M.s)                 AS s,
       format('%5.3f',M.p)                 AS p,
       format('%5.3f',M.q)                 AS q,
       D.inputs                            AS inputs
FROM mads    AS M
JOIN drivers AS D USING (driver_id);


CREATE TEMPORARY VIEW gui_mads_initial AS
SELECT * FROM gui_mads WHERE inputs = 0;

-- View of magic attrition for use in the magic attrition browser.

CREATE TEMPORARY VIEW gui_magic_attrit AS
SELECT id                                              AS id,
       CASE WHEN mode = 'NBHOOD' 
            THEN 'Attrition to neighborhood ' || n
            WHEN mode = 'GROUP'
            THEN 'Attrition to ' || f || ' in neighborhood ' || n
            ELSE 'Unknown'
            END                                        AS narrative,
       casualties                                      AS casualties,
       CASE WHEN g1 IS NULL THEN '' ELSE g1 END AS g1,
       CASE WHEN g2 IS NULL THEN '' ELSE g2 END AS g2
FROM magic_attrit;

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
-- Communications Asset Package (CAP) Views

-- A GUI caps view

CREATE TEMPORARY VIEW gui_caps AS
SELECT k                                               AS id,
       k                                               AS k,
       'my://app/cap/' || k                            AS url,
       pair(longname, k)                               AS fancy,
       link('my://app/cap/' || k, k)                   AS link,
       link('my://app/cap/' || k, pair(longname, k))   AS longlink,
       longname                                        AS longname,
       owner                                           AS owner,
       format('%4.2f',capacity)                        AS capacity,
       moneyfmt(cost)                                  AS cost
FROM caps;

-- A GUI cap_kn_view

CREATE TEMPORARY VIEW gui_cap_kn AS
SELECT k || ' ' || n          AS id,
       k                      AS k,
       n                      AS n,
       format('%4.2f',nbcov)  AS nbcov
FROM cap_kn_view;

-- cap_kn's with non-zero coverage
CREATE TEMPORARY VIEW gui_cap_kn_nonzero AS
SELECT * FROM gui_cap_kn
WHERE CAST (nbcov AS REAL) > 0.0;

-- A GUI capcov.  This is used both for the CAP:PEN orders and
-- for displaying the capcov results.

CREATE TEMPORARY VIEW gui_capcov AS
SELECT k || ' ' || g                                       AS id,
       k                                                   AS k,
       owner                                               AS owner,
       format('%4.2f',capacity)                            AS capacity,
       g                                                   AS g,
       n                                                   AS n,
       format('%4.2f',nbcov)                               AS nbcov,
       format('%4.2f',pen)                                 AS pen,
       format('%4.2f',capcov)                              AS capcov,
       CASE WHEN pen > 0 AND nbcov = 0.0 
       THEN 1 ELSE 0 END                                   AS orphan
FROM capcov;

-- capcov records, excluding zero capcov
CREATE TEMPORARY VIEW gui_capcov_nonzero AS
SELECT * FROM gui_capcov
WHERE CAST (capcov AS REAL) > 0.0;

-- capcov records for orphans (pen > 0, nbcov = 0)
CREATE TEMPORARY VIEW gui_capcov_orphans AS
SELECT * FROM gui_capcov
WHERE orphan;

------------------------------------------------------------------------
-- Primary Entities
--
-- Any primary entity's ID must be unique in the scenario.  This
-- view creates a list of primary entity IDs, so that we can verify 
-- this, and retrieve the entity type for a given ID.  The list
-- includes a number of reserved words.
--
-- Note: The agents table includes all actors.

CREATE TEMPORARY VIEW entities AS
SELECT 'PLAYBOX' AS id, 'reserved' AS etype                  UNION
SELECT 'CIV'     AS id, 'reserved' AS etype                  UNION
SELECT 'FRC'     AS id, 'reserved' AS etype                  UNION
SELECT 'ORG'     AS id, 'reserved' AS etype                  UNION
SELECT 'ALL'     AS id, 'reserved' AS etype                  UNION
SELECT 'NONE'    AS id, 'reserved' AS etype                  UNION
SELECT 'SELF'    AS id, 'reserved' AS etype                  UNION
SELECT n         AS id, 'nbhood'   AS etype FROM nbhoods     UNION
SELECT agent_id  AS id, 'agent'    AS etype FROM agents      UNION
SELECT g         AS id, 'group'    AS etype FROM groups      UNION
SELECT k         AS id, 'cap'      AS etype FROM caps        UNION
SELECT c         AS id, 'concern'  AS etype FROM concerns    UNION
SELECT a         AS id, 'activity' AS etype FROM activity    UNION
SELECT u         AS id, 'unit'     AS etype FROM units       UNION
SELECT tid       AS id, 'topic'    AS etype FROM mam_topic;


