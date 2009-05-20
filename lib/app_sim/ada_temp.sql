------------------------------------------------------------------------
-- TITLE:
--    ada_rules_temp.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    Temporary SQL Schema for ada_rules(sim).
--
------------------------------------------------------------------------


-- Temporary Table: ADA Inputs
CREATE TEMP TABLE ada_inputs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    input,            -- GRAM input ID
    itype,            -- sat, coop
    etype,            -- LEVEL, SLOPE
    n,                -- Neighborhood name
    f,                -- Group name
    g,                -- Group name (coop)
    c,                -- Concern name (sat)
    slope,            -- Slope (SLOPE)
    climit,           -- Limit (LEVEL)
    days,             -- Days value (LEVEL)
    cause,            -- Cause name (ecause)
    p,                -- Near effects multiplier
    q                 -- Far effects multiplier
);
