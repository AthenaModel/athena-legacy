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
SELECT n                      AS n,
       longname               AS longname,
       urbanization           AS urbanization,
       stacking_order         AS stacking_order,
       obscured_by            AS obscured_by,
       m2ref(refpoint)        AS refpoint,
       m2ref(polygon)         AS polygon
FROM nbhoods;

-- A Force Groups view for use by the GUI
CREATE TEMPORARY VIEW gui_frcgroups AS
SELECT g                                              AS g,
       longname                                       AS longname,
       forcetype                                      AS forcetype,
       CASE local     WHEN 1 THEN 'Yes' ELSE 'No' END AS local,
       CASE coalition WHEN 1 THEN 'Yes' ELSE 'No' END AS coalition
FROM groups JOIN frcgroups USING (g);
