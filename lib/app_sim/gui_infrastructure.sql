------------------------------------------------------------------------
-- TITLE:
--    gui_infrastructure.sql
--
-- AUTHOR:
--    Dave Hanks
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views, Infrastructure area
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
-- INFRASTRUCTURE PLANT VIEWS

CREATE TEMPORARY VIEW gui_plants_na AS
SELECT PS.n || ' ' || PS.a                     AS id,
       PS.n                                    AS n,
       N.longlink                              AS nlink,
       PS.a                                    AS a,
       coalesce(A.longlink,AG.longlink)        AS alink,
       coalesce(A.pretty_am_flag, 'Yes')       AS auto_maintain,
       format('%.2f', coalesce(PN.rho,PS.rho)) AS rho,
       coalesce(PN.num,PS.num)                 AS num
FROM plants_shares         AS PS
JOIN gui_nbhoods           AS N  ON (PS.N=N.n)
LEFT OUTER JOIN gui_agents AS AG ON (PS.a=AG.agent_id)
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

