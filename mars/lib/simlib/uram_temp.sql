------------------------------------------------------------------------
-- TITLE:
--    uram_temp.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema, Temporary Tables, for URAM
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Contribution Analysis

CREATE TEMPORARY TABLE uram_contribs (
    -- Contributions table.  This table is populated by the
    -- [contribs *] subcommands.

    driver    INTEGER PRIMARY KEY,     -- Driver ID
    contrib   DOUBLE DEFAULT 0.0       -- Net contribution
);


