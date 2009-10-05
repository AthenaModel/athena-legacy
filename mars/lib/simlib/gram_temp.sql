------------------------------------------------------------------------
-- TITLE:
--    gram_temp.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema, Temporary Tables, for GRAM.
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Result of satisfaction driver queries

-- gram_sat_drivers: Table populated by the "sat drivers" method

CREATE TEMPORARY TABLE gram_sat_drivers (
    -- Object
    object        TEXT,

    -- Driver ID
    driver        INTEGER,

    -- Neighborhood
    n             TEXT,

    -- Group
    g             TEXT,

    -- Concern (or "mood")
    c             TEXT,

    -- Actual contribution
    acontrib      DOUBLE DEFAULT 0.0,

    PRIMARY KEY (object, driver, n, g, c)
);


