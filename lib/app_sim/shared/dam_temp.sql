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
    id INTEGER PRIMARY KEY,
    atype,            -- sat, coop, hrel, vrel
    mode,             -- P or T
    curve,            -- Curve indices, e.g., "$g $c" for sat
    mag,              -- Numeric magnitude
    cause,            -- Cause name (ecause)
    s,                -- Here effects multiplier
    p,                -- Near effects multiplier
    q,                -- Far effects multiplier
    note              -- Note on this input.
);

