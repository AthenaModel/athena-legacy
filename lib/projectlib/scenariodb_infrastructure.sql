------------------------------------------------------------------------
-- TITLE:
--    scenariodb_infrastructure.sql
--
-- AUTHOR:
--    Dave Hanks
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Infrastructure Tables
--
-- SECTIONS:
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- INFRASTRUCTURE

-- Plants Table: plants owned and operated by actors.  Each plant has
-- a capacity to produce goods.  Taken together, the output of all plants
-- is the total capacity of goods produced in the modeled economy.

CREATE TABLE plants_na (
    -- Neighborhood ID
    n                TEXT,

    -- Agent ID, can be actor ID or 'SYSTEM'
    a                TEXT,

    -- Number of plants in operation by agent a in in nbhood n
    num              INTEGER DEFAULT 0,

    -- Average repair level of all plants in operation by agent a in nbhood n
    rho              REAL DEFAULT 1.0,

    PRIMARY KEY (n, a)
);

-- Plants Shares: during prep the analyst specifies which actors get some
-- number of shares of the total infrastructure along with the initial
-- repair levels.

CREATE TABLE plants_shares (
    -- Neighborhood ID
    n               TEXT REFERENCES nbhoods(n)
                    ON DELETE CASCADE
                    DEFERRABLE INITIALLY DEFERRED,

    -- Agent ID, can be actor ID or 'SYSTEM'
    a               TEXT,

    -- The number of shares of plants in the nbhood that the
    -- agent owns
    num             INTEGER DEFAULT 1,

    -- Average repair level of all plants in operation by agent a in
    -- nbhood n. The defaul level is fully repaired.
    rho             REAL DEFAULT 1.0,

    PRIMARY KEY (n, a)
);

-- Plants neighborhood view. Used during prep and initialization to 
-- determine how infrastructure plants are distributed among the 
-- neighborhoods as a function of total neighborhood population and
-- production capacity.

CREATE VIEW plants_n_view AS
SELECT N.n                                     AS n,
       N.pcf                                   AS pcf,
       total(coalesce(D.population,C.basepop)) AS nbpop
FROM civgroups          AS C
JOIN nbhoods            AS N USING (n)
LEFT OUTER JOIN demog_n AS D USING (n)
GROUP BY n;

------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------


