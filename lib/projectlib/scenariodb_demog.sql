------------------------------------------------------------------------
-- TITLE:
--    scenariodb_demog.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Demographics Area
--
------------------------------------------------------------------------

-- Demographics of the region of interest (i.e., of nbhoods for
-- which local=1)

CREATE TABLE demog_local (
    -- Total population in local neighborhoods at the current time.
    population   INTEGER DEFAULT 0,

    -- Total consumers in local neighborhoods at the current time.
    consumers    INTEGER DEFAULT 0,

    -- Total labor force in local neighborhoods at the current time
    labor_force  INTEGER DEFAULT 0
);

-- Demographics of the neighborhood as a whole

CREATE TABLE demog_n (
    -- Symbolic neighborhood name
    n            TEXT PRIMARY KEY REFERENCES nbhoods(n)
                 ON DELETE CASCADE
                 DEFERRABLE INITIALLY DEFERRED,

    -- Total population in the neighborhood at the current time
    population   INTEGER DEFAULT 0,

    -- Total subsistence population in the neighborhood at the current time
    subsistence  INTEGER DEFAULT 0,

    -- Total consumers in the neighborhood at the current time
    consumers    INTEGER DEFAULT 0,

    -- Total labor force in the neighborhood at the current time
    labor_force  INTEGER DEFAULT 0,

    -- Unemployed workers in the neighborhood.
    unemployed   INTEGER DEFAULT 0,

    -- Unemployed per capita (percentage)
    upc          DOUBLE DEFAULT 0.0,

    -- Unemployment Attitude Factor
    uaf          DOUBLE DEFAULT 0.0
);

-- Demographics of particular civgroups

CREATE TABLE demog_g (
    -- Symbolic civgroup name
    g              TEXT PRIMARY KEY,

    -- Attrition to this group (total killed)
    attrition      INTEGER DEFAULT 0,

    -- Total residents of this group in its home neighborhood at the
    -- current time.
    population     INTEGER DEFAULT 0,

    -- Subsistence population: population doing subsistence agriculture
    -- and outside the regional economy.
    subsistence    INTEGER DEFAULT 0,

    -- Consumer population: population within the regional economy
    consumers      INTEGER DEFAULT 0,

    -- Labor Force: workers available to the regional economy
    labor_force    INTEGER DEFAULT 0,

    -- Unemployed workers in the home neighborhood.
    unemployed     INTEGER DEFAULT 0,

    -- Unemployed per capita (percentage)
    upc            DOUBLE DEFAULT 0.0,

    -- Unemployment Attitude Factor
    uaf            DOUBLE DEFAULT 0.0,

    -- Demographic Situation ID.  This is the ID of the
    -- demsit associated with this record, if
    -- any, and 0 otherwise.
    --
    -- NOTE: This implementation is fine so long as we have
    -- only *one* kind of demsit.  If we add more, we'll need
    -- to do something different.  The right answer depends on
    -- what demsits turn out to have in common.
    s              INTEGER  DEFAULT 0
);


-- Demographic Situation Context View
--
-- This view identifies the neighborhood groups that can have
-- demographic situations, and pulls in required context from
-- other tables.
CREATE VIEW demog_context AS
SELECT CG.n              AS n,
       DG.g              AS g,
       DG.population     AS population,
       DG.uaf            AS ngfactor,
       DG.s              AS s,
       DN.uaf            AS nfactor
FROM demog_g   AS DG
JOIN civgroups AS CG USING (g)
JOIN demog_n   AS DN USING (n);

------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------
