------------------------------------------------------------------------
-- TITLE:
--    gui_ground.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views, Ground area
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
-- PERSONNEL VIEWS

-- gui_activity_nga: Activities by neighborhood and group 
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
       stype                         AS stype
FROM activity_nga
WHERE nominal > 0
ORDER BY n,g,a;


-- gui_security: group security in neighborhoods, along with force 
-- statistics.
CREATE TEMPORARY VIEW gui_security AS
SELECT n || ' ' || g                      AS id,
       n                                  AS n,
       g                                  AS g,
       force_ng.personnel                 AS personnel,
       security                           AS security,
       qsecurity('longname',security)     AS symbol,
       actual_cf                          AS actual_cf,
       CASE WHEN actual_cf IS NULL 
            THEN 'n/a' 
            ELSE percent(actual_cf) END   AS pct_actual_cf,
       nominal_cf                         AS nominal_cf,
       CASE WHEN nominal_cf IS NULL 
            THEN 'n/a' 
            ELSE percent(nominal_cf) END  AS pct_nominal_cf,
       pct_force                          AS pct_force,
       pct_enemy                          AS pct_enemy,
       volatility                         AS volatility
FROM force_ng 
JOIN force_n USING (n)
LEFT OUTER JOIN force_civg USING (g)
WHERE personnel > 0
ORDER BY n, g;


-- gui_units: All active units.
CREATE TEMPORARY VIEW gui_units AS
SELECT u                                                AS id,
       u                                                AS u,
       tactic_id                                        AS tactic_id,
       n                                                AS n,
       g                                                AS g,
       gtype                                            AS gtype,
       a                                                AS a,
       personnel                                        AS personnel,
       m2ref(location)                                  AS location
FROM units
WHERE active;


------------------------------------------------------------------------
-- ENVIRONMENTAL SITUATIONS VIEWS

-- gui_ensits: All environmental situations
CREATE TEMPORARY VIEW gui_ensits AS
SELECT s                                              AS id,
       s || ' -- ' || stype || ' in '|| n             AS longid,
       s                                              AS s,
       state                                          AS state,
       stype                                          AS stype,
       n                                              AS n,
       format('%6.4f',coverage)                       AS coverage,
       timestr(ts)                                    AS ts,
       m2ref(location)                                AS location,
       resolver                                       AS resolver,
       rduration                                      AS rduration,
       timestr(tr)                                    AS tr,
       inception                                      AS inception,
       -- Null for g since it's deprecated
       NULL                                           AS g
FROM ensits;

-- gui_ensits subview: ensits in INITIAL state
CREATE TEMPORARY VIEW gui_ensits_initial AS
SELECT * FROM gui_ensits
WHERE state = 'INITIAL';

-- gui_ensits subview: ONGOING 
CREATE TEMPORARY VIEW gui_ensits_ongoing AS
SELECT * FROM gui_ensits
WHERE state = 'ONGOING';

-- gui_ensits subview: RESOLVED 
CREATE TEMPORARY VIEW gui_ensits_resolved AS
SELECT * FROM gui_ensits
WHERE state = 'RESOLVED';

------------------------------------------------------------------------
-- ATTRITION MODEL VIEWS

-- gui_conflicts: force groups in conflict given current ROEs, with 
-- required statistics.
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


-- gui_defroe: All defensive ROEs, with related data.
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


-- gui_magic_attrit: All pending magic attrition 
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
-- SERVICES MODELS VIEWS

-- gui_service_g: Provision of ENI services to civilian groups
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


-- gui_service_ga: Provision of ENI services to civilian groups
-- by particular actors.
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


------------------------------------------------------------------------
-- INFRASTRUCTURE PLANT VIEWS

CREATE TEMPORARY VIEW gui_plants_na AS
SELECT PS.n || ' ' || PS.a                     AS id,
       PS.n                                    AS n,
       N.longlink                              AS nlink,
       PS.a                                    AS a,
       coalesce(A.longlink,PN.a)               AS alink,
       format('%.2f', coalesce(PN.rho,PS.rho)) AS rho,
       coalesce(PN.num,PS.shares)              AS quant
FROM plants_shares         AS PS
JOIN gui_nbhoods           AS N  ON (PS.N=N.n)
LEFT OUTER JOIN gui_actors AS A  ON (PS.a=A.a)
LEFT OUTER JOIN plants_na  AS PN ON (PS.n=PN.N AND PS.a=PN.a);

CREATE TEMPORARY VIEW gui_plants_n AS
SELECT N.longlink                        AS nlonglink,
       P.n                               AS n,
       P.pcf                             AS pcf,
       P.nbpop                           AS nbpop
FROM plants_n_view AS P
JOIN gui_nbhoods AS N ON (N.n=P.n);

-----------------------------------------------------------------------
-- End of File
-----------------------------------------------------------------------


