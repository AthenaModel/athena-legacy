------------------------------------------------------------------------
-- TITLE:
--    gui_demog.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views, Demographics area
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
-- DEMOGRAPHIC SITUATIONS VIEWS

-- gui_demsits: All demographic situations
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

-- gui_demsits subview: current demsits (live or freshly ended)
CREATE TEMPORARY VIEW gui_demsits_current AS
SELECT * FROM gui_demsits 
WHERE state != 'ENDED' OR change != '';
       
-- gui_demsits subview: ended demsits
CREATE TEMPORARY VIEW gui_demsits_ended AS
SELECT * FROM gui_demsits WHERE state == 'ENDED';



-----------------------------------------------------------------------
-- End of File
-----------------------------------------------------------------------
