------------------------------------------------------------------------
-- TITLE:
--    dam_rules_temp.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    Temporary SQL Schema for dam(sim).
--
------------------------------------------------------------------------


-- Temporary Table: DAM Inputs
CREATE TEMP TABLE dam_inputs (
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
    s,                -- Here effects multiplier
    p,                -- Near effects multiplier
    q                 -- Far effects multiplier
);

