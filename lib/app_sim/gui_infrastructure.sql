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
SELECT PN.n || ' ' || PN.a                     AS id,
       PN.n                                    AS n,
       N.longlink                              AS nlink,
       PN.a                                    AS a,
       coalesce(A.longlink,AG.longlink)        AS alink,
       coalesce(A.pretty_am_flag, 'Yes')       AS auto_maintain,
       format('%.2f', PN.rho)                  AS rho,
       PN.num                                  AS num
FROM plants_na             AS PN
JOIN gui_nbhoods           AS N  ON (PN.n=N.n)
LEFT OUTER JOIN gui_agents AS AG ON (PN.a=AG.agent_id)
LEFT OUTER JOIN gui_actors AS A  ON (PN.a=A.a);

CREATE TEMPORARY VIEW gui_plants_n AS
SELECT N.longlink                        AS nlonglink,
       P.n                               AS n,
       P.pcf                             AS pcf,
       P.nbpop                           AS nbpop
FROM plants_n_view AS P
JOIN gui_nbhoods AS N ON (N.n=P.n);

CREATE TEMPORARY VIEW gui_plants_build AS
SELECT B.n                              AS n,
       N.longlink                       AS nlink,
       B.a                              AS a,
       coalesce(A.longlink,AG.longlink) AS alink,
       B.num                            AS num,
       format('%.2f', B.sigma)          AS sigma,
       B.built                          AS built,
       timestr(start_time)              AS start_time,
       CASE WHEN end_time = -1
            THEN "N/A"
            ELSE timestr(end_time)
            END                         AS end_time
FROM plants_build AS B
JOIN gui_nbhoods  AS N ON (B.n=N.n)
LEFT OUTER JOIN gui_agents AS AG ON (B.a=AG.agent_id)
LEFT OUTER JOIN gui_actors AS A  ON (B.a=A.a);
       
-----------------------------------------------------------------------
-- End of File
-----------------------------------------------------------------------

