------------------------------------------------------------------------
-- TITLE:
--    scenariodb_temp.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Temporary Entity Schema for scenariodb(n).
--
------------------------------------------------------------------------


------------------------------------------------------------------------
-- Concerns and concern views

-- Concern definitions
CREATE TEMPORARY TABLE concerns (
    -- Symbolic concern name
    c         TEXT PRIMARY KEY,

    -- Full concern name
    longname  TEXT,

    -- Concern type: egrouptype
    gtype     TEXT
);

CREATE TEMPORARY VIEW civ_concerns AS
SELECT * FROM concerns WHERE gtype='CIV';

CREATE TEMPORARY VIEW org_concerns AS
SELECT * FROM concerns WHERE gtype='ORG';


--------------------------------------------------------------------
-- Activity Definition Tables

-- Main activity table.  Lists all activity names and long names
CREATE TEMPORARY TABLE activity (
    -- Symbolic activity name
    a         TEXT PRIMARY KEY,

    -- Human-readable name
    longname  TEXT
);

-- Activity/group type table.
CREATE TEMPORARY TABLE activity_gtype (
    -- Symbolic activity name
    a           TEXT,

    -- Symbolic group type: FRC or ORG
    gtype       TEXT,

    -- Assignable: 1 or 0
    assignable  INTEGER DEFAULT 0,

    -- Situation Type Name, or ''
    stype       TEXT DEFAULT '',

    PRIMARY KEY (a, gtype)
);


