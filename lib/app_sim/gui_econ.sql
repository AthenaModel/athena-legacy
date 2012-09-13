------------------------------------------------------------------------
-- TITLE:
--    gui_econ.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views, Economics area
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
-- ECONOMICS VIEWS

-- gui_econ_n: Neighborhood economic data.
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

-- gui_econ_g: Civilian group economic data
CREATE TEMPORARY VIEW gui_econ_g AS
SELECT * FROM gui_civgroups 
JOIN nbhoods USING (n)
WHERE nbhoods.local;

-- gui_econ_income_a: Actor specific income from all sources
CREATE TEMPORARY VIEW gui_econ_income_a AS
SELECT a                                  AS id,
       a                                  AS a,
       moneyfmt(inc_goods)                AS income_goods,
       moneyfmt(inc_black_t)              AS income_black_t,
       moneyfmt(inc_black_nr)             AS income_black_nr,
       moneyfmt(inc_black_nr+inc_black_t) AS income_black_tot,
       moneyfmt(inc_pop)                  AS income_pop,
       moneyfmt(inc_world)                AS income_world,
       moneyfmt(inc_region)               AS income_graft
FROM income_a;


-----------------------------------------------------------------------
-- End of File
-----------------------------------------------------------------------

