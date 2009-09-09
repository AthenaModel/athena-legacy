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

CREATE VIRTUAL TABLE helpdb_pages USING fts3(
    -- Name of the page.  This is the name used in HREFs.
    -- It should contain no whitespace.
    name,

    -- Page title: This is what is displayed in the Help Tree and
    -- in the browser.
    title,

    -- Name of parent page, or ''
    parent,

    -- The HTML text of the page.
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
