------------------------------------------------------------------------
-- TITLE:
--    gui_info.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views, Information area
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
-- COMMUNICATIONS ASSET PACKAGE (CAP) VIEWS

-- gui_caps: All Communications Asset Packages
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


-- gui_cap_kn: CAP neighborhood coverage records
CREATE TEMPORARY VIEW gui_cap_kn AS
SELECT k || ' ' || n          AS id,
       k                      AS k,
       n                      AS n,
       format('%4.2f',nbcov)  AS nbcov
FROM cap_kn_view;

-- gui_cap_kn subview: cap_kn's with non-zero coverage
CREATE TEMPORARY VIEW gui_cap_kn_nonzero AS
SELECT * FROM gui_cap_kn
WHERE CAST (nbcov AS REAL) > 0.0;


-- gui_capcov: CAP group coverage.  This is used both for the 
-- CAP:PEN orders and for displaying the capcov results.
CREATE TEMPORARY VIEW gui_capcov AS
SELECT k || ' ' || g                                       AS id,
       k                                                   AS k,
       owner                                               AS owner,
       format('%4.2f',capacity)                            AS capacity,
       g                                                   AS g,
       n                                                   AS n,
       link('my://app/nbhood/' || n, n)                    AS nlink,
       link('my://app/group/'  || g, g)                    AS glink,
       format('%4.2f',nbcov)                               AS nbcov,
       format('%4.2f',pen)                                 AS pen,
       format('%4.2f',capcov)                              AS capcov,
       nbcov                                               AS raw_nbcov,
       pen                                                 AS raw_pen,
       capcov                                              AS raw_capcov,
       CASE WHEN pen > 0 AND nbcov = 0.0 
       THEN 1 ELSE 0 END                                   AS orphan
FROM capcov;

-- gui_capcov subview: capcov records, excluding zero capcov
CREATE TEMPORARY VIEW gui_capcov_nonzero AS
SELECT * FROM gui_capcov
WHERE CAST (capcov AS REAL) > 0.0;

-- gui_capcov subview: capcov records for orphans (pen > 0, nbcov = 0)
CREATE TEMPORARY VIEW gui_capcov_orphans AS
SELECT * FROM gui_capcov
WHERE orphan;


-----------------------------------------------------------------------
-- End of File
-----------------------------------------------------------------------

