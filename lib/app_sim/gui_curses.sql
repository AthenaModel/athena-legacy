------------------------------------------------------------------------
-- TITLE:
--    gui_curses.sql
--
-- AUTHOR:
--    Dave Hanks
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
-- Complex User-defined Role-based Situations and Events (CURSE) views

-- gui_curses: All CURSEs
CREATE TEMPORARY VIEW gui_curses AS
SELECT curse_id                                  AS curse_id,
       longname                                  AS longname, 
       cause                                     AS cause,
       pair(longname, curse_id)                  AS fancy,
       longname || ' (Here factor: ' || s || 
                   ' Near factor: '  || p ||
                   ' Far factor: '   || q || ')' AS narrative,
       state                                     AS state
FROM curses;

CREATE TEMPORARY VIEW gui_injects AS
SELECT curse_id || ' ' || inject_num        AS id,
       curse_id                             AS curse_id,
       inject_num                           AS inject_num,
       inject_type                          AS inject_type,
       narrative                            AS narrative,
       state                                AS state,
       a                                    AS a,
       c                                    AS c,
       f                                    AS f,
       g                                    AS g,
       format('%.1f',mag)                   AS mag
FROM curse_injects;

CREATE TEMPORARY VIEW gui_injects_SAT AS
SELECT curse_id || ' ' || inject_num        AS id,
       curse_id                             AS curse_id,
       inject_num                           AS inject_num,
       narrative                            AS narrative,
       state                                AS state,
       g                                    AS g,
       c                                    AS c,
       format('%.1f',mag)                   AS mag
FROM curse_injects;

CREATE TEMPORARY VIEW gui_injects_COOP AS
SELECT curse_id || ' ' || inject_num        AS id,
       curse_id                             AS curse_id,
       inject_num                           AS inject_num,
       narrative                            AS narrative,
       state                                AS state,
       f                                    AS f,
       g                                    AS g,
       format('%.1f',mag)                   AS mag
FROM curse_injects;

CREATE TEMPORARY VIEW gui_injects_VREL AS
SELECT curse_id || ' ' || inject_num        AS id,
       curse_id                             AS curse_id,
       inject_num                           AS inject_num,
       narrative                            AS narrative,
       state                                AS state,
       g                                    AS g,
       a                                    AS a,
       format('%.1f',mag)                   AS mag
FROM curse_injects;

CREATE TEMPORARY VIEW gui_injects_HREL AS
SELECT curse_id || ' ' || inject_num       AS id,
       curse_id                            AS curse_id,
       inject_num                          AS inject_num,
       narrative                           AS narrative,
       state                               AS state,
       f                                   AS f,
       g                                   AS g,
       format('%.1f',mag)                  AS mag
FROM curse_injects;
