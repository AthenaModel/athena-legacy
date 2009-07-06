------------------------------------------------------------------------
-- TITLE:
--    helpdb.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for helpdb(n).
--
------------------------------------------------------------------------

-- Schema Version
PRAGMA user_version=1;

------------------------------------------------------------------------
-- Help Pages

CREATE TABLE helpdb_pages (
    -- Name of the page.  This is the name used in HREFs.
    -- It should contain no whitespace.
    name   TEXT PRIMARY KEY,

    -- Page title: This is what is displayed in the Help Tree and
    -- in the browser.
    title  TEXT,

    -- Name of parent page, or ''
    parent TEXT,

    -- The HTML text of the page.
    text   TEXT
);

CREATE INDEX helpdb_pages_parent ON helpdb_pages(parent);

------------------------------------------------------------------------
-- Page names and reserved words

CREATE TEMPORARY VIEW helpdb_reserved AS
SELECT '_helpdb:index' AS id UNION
SELECT '_helpdb:error' AS id UNION
SELECT name            AS id FROM helpdb_pages;
