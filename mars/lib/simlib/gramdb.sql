------------------------------------------------------------------------
-- FILE: gramdb.sql
--
-- SQL Schema for the gramdb(n) module.
--
-- PACKAGE:
--    simlib(n) -- Simulation Infrastructure Package
--
-- PROJECT:
--    Mars Simulation Infrastructure Library
--
-- AUTHOR:
--    Will Duquette
--
------------------------------------------------------------------------

-- gramdb(5) Table -  concern definitions
CREATE TABLE gramdb_c (
    c      TEXT PRIMARY KEY,                 -- Symbolic concern name
    gtype  TEXT                              -- CIV, ORG, FRC
);

-- gramdb(5) Table -  group definitions
CREATE TABLE gramdb_g (
    g              TEXT PRIMARY KEY,         -- Symbolic group name
    gtype          TEXT,                     -- CIV, ORG, FRC
    rollup_weight  DOUBLE DEFAULT 1.0,       -- CIV, ORG only
    effects_factor DOUBLE DEFAULT 1.0        -- CIV, ORG only
);

-- gramdb(5) Table -  Neighborhood definitions
CREATE TABLE gramdb_n (
    n              TEXT PRIMARY KEY          -- Symbolic name
);

-- gramdb(5) Table -  Pairs of neighborhoods (m,n)
CREATE TABLE gramdb_mn (
    m              TEXT,                     -- Symbolic nbhood name
    n              TEXT,                     -- Symbolic nbhood name

    proximity      TEXT,                     -- eproximity, defaulted
                                             -- programmatically
    effects_delay  DOUBLE DEFAULT 0.0,       -- Decimal days
    
    PRIMARY KEY (m, n)
);

-- gramdb(5) Table -  Neighborhood/group pairs (n,g)
CREATE TABLE gramdb_ng (
    n              TEXT,                     -- Symbolic nbhood name
    g              TEXT,                     -- Symbolic group name

    -- Inputs, CIV only
    population     INTEGER DEFAULT 0,

    -- Inputs, CIV and ORG only
    rollup_weight  DOUBLE DEFAULT 1.0,       -- Default group weight
    effects_factor DOUBLE DEFAULT 1.0,       -- Indirect effects mult

    PRIMARY KEY (n, g)
);

-- gramdb(5) Table -  group/concern pairs (g,c)
CREATE TABLE gramdb_gc (
    g              TEXT,                     -- Symbolic group name
    c              TEXT,                     -- Symbolic concern name

    sat0           DOUBLE DEFAULT 0.0,       -- Initial satisfaction
    saliency       DOUBLE DEFAULT 1.0,       -- Saliency

    PRIMARY KEY (g, c)
);

-- gramdb(5) Table -  group/group pairs (f,g)
CREATE TABLE gramdb_fg (
    f              TEXT,                     -- Symbolic group name
    g              TEXT,                     -- Symbolic group name

    rel            DOUBLE,                   -- Group relationship
    coop0          DOUBLE,                   -- Cooperation
    
    PRIMARY KEY (f, g)
);
    
-- gramdb(5) Table -  Neighborhood/pgroup/concern triples (n,g,c)
-- Values default from gramdb_gc.
CREATE TABLE gramdb_ngc (
    n              TEXT,                     -- Symbolic nbhood name
    g              TEXT,                     -- Symbolic group name
    c              TEXT,                     -- Symbolic concern name

    sat0           DOUBLE,                   -- Initial satisfaction
    saliency       DOUBLE,                   -- Saliency
    
    PRIMARY KEY (n, g, c)
);

-- gramdb(5) Table -  Neighborhood/pgroup/pgroup triples (n,f,g)
-- Values default from gramdb_fg.
CREATE TABLE gramdb_nfg (
    n              TEXT,                     -- Symbolic nbhood name
    f              TEXT,                     -- Symbolic group name
    g              TEXT,                     -- Symbolic group name

    rel            DOUBLE,                   -- Group relationship
    coop0          DOUBLE,                   -- Cooperation level

    PRIMARY KEY (n, f, g)
);
