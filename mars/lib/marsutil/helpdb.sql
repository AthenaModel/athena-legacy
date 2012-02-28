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
-- Searching

CREATE VIRTUAL TABLE helpdb_search USING fts3(
    -- Name of the page.  This is the name used in HREFs.
    -- It should contain no whitespace.
    name,

    -- Page title: This is what is displayed in the Help Tree and
    -- in the browser.
    title,

    -- The text of the page, with HTML stripped out.
    text
);


------------------------------------------------------------------------
-- Images

CREATE TABLE helpdb_images (
    -- Name of the image.  This is the name used in IMG SRC.  It
    -- should contain no whitespace.
    name     TEXT PRIMARY KEY,

    -- Caption
    title    TEXT,

    -- The image data, in PNG format
    data     BLOB
);

------------------------------------------------------------------------
-- Page names and reserved words

CREATE TEMPORARY VIEW helpdb_reserved AS
SELECT name, title FROM helpdb_pages   UNION
SELECT name, title FROM helpdb_images;
