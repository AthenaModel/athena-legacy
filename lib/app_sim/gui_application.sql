------------------------------------------------------------------------
-- TITLE:
--    gui_application.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views, Applications Entities
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
-- PRIMARY ENTITIES

-- entities: Primary entity IDs and reserved words.
-- 
-- Any primary entity's ID must be unique in the scenario.  This
-- view creates a list of primary entity IDs, so that we can verify 
-- this, and retrieve the entity type for a given ID.  The list
-- includes a number of reserved words.
--
-- Note: The agents table includes all actors.

CREATE TEMPORARY VIEW entities AS
SELECT 'PLAYBOX'  AS id, 'reserved' AS etype                  UNION
SELECT 'CIV'      AS id, 'reserved' AS etype                  UNION
SELECT 'FRC'      AS id, 'reserved' AS etype                  UNION
SELECT 'ORG'      AS id, 'reserved' AS etype                  UNION
SELECT 'ALL'      AS id, 'reserved' AS etype                  UNION
SELECT 'NONE'     AS id, 'reserved' AS etype                  UNION
SELECT 'SELF'     AS id, 'reserved' AS etype                  UNION
SELECT n          AS id, 'nbhood'   AS etype FROM nbhoods     UNION
SELECT agent_id   AS id, 'agent'    AS etype FROM agents      UNION
SELECT g          AS id, 'group'    AS etype FROM groups      UNION
SELECT k          AS id, 'cap'      AS etype FROM caps        UNION
SELECT iom_id     AS id, 'iom'      AS etype FROM ioms        UNION
SELECT c          AS id, 'concern'  AS etype FROM concerns    UNION
SELECT a          AS id, 'activity' AS etype FROM activity    UNION
SELECT u          AS id, 'unit'     AS etype FROM units       UNION
SELECT tid        AS id, 'topic'    AS etype FROM mam_topic;


------------------------------------------------------------------------
-- ORDER VIEWS 

-- gui_orders:  All scheduled orders
CREATE TEMPORARY VIEW gui_orders AS
SELECT id        AS id,
       t         AS tick,
       tozulu(t) AS zulu,
       name      AS name,
       narrative AS narrative,
       parmdict  AS parmdict
FROM eventq_queue_order_execute;


-- gui_cif: All orders in the CIF, with undo stack data.
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


------------------------------------------------------------------------
-- SIGNIFICANT EVENTS VIEWS

-- gui_sigevents: All logged significant events
CREATE TEMPORARY VIEW gui_sigevents AS
SELECT event_id                                        AS event_id,
       level                                           AS level,
       t                                               AS t,
       tozulu(t)                                       AS zulu,
       component                                       AS component,
       mklinks(narrative)                              AS narrative
FROM sigevents
ORDER BY event_id ASC;


-- gui_sigevents_wtag: significant events with tags.
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
     

-----------------------------------------------------------------------
-- End of File
-----------------------------------------------------------------------

