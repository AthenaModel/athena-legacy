------------------------------------------------------------------------
-- FILE: gramdb2.sql
--
-- SQL Schema for the gramdb(n) V2.0 module.
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
    c      TEXT PRIMARY KEY                  -- Symbolic concern name
);

-- gramdb(5) Table -  Neighborhood definitions
CREATE TABLE gramdb_n (
    n              TEXT PRIMARY KEY          -- Symbolic name
);

-- gramdb(5) Table -  CIV group definitions
CREATE TABLE gramdb_civ_g (
    g              TEXT PRIMARY KEY,         -- Symbolic group name
    n              TEXT,                     -- Nbhood of reference
    population     INTEGER DEFAULT 0 
);

-- gramdb(5) Table -  FRC group definitions
CREATE TABLE gramdb_frc_g (
    g              TEXT PRIMARY KEY          -- Symbolic group name
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

-- gramdb(5) Table -  CIV group/concern pairs (g,c)
CREATE TABLE gramdb_gc (
    g              TEXT,                     -- Symbolic group name
    c              TEXT,                     -- Symbolic concern name

    sat0           DOUBLE DEFAULT 0.0,       -- Initial satisfaction
    saliency       DOUBLE DEFAULT 1.0,       -- Saliency

    PRIMARY KEY (g, c)
);

-- gramdb(5) Table -  CIV/CIV relationships
CREATE TABLE gramdb_civ_fg (
    f              TEXT,                     -- Symbolic group name
    g              TEXT,                     -- Symbolic group name

    rel            DOUBLE,                   -- Group relationship
    
    PRIMARY KEY (f, g)
);

-- gramdb(5) Table -  FRC/FRC relationships
CREATE TABLE gramdb_frc_fg (
    f              TEXT,                     -- Symbolic group name
    g              TEXT,                     -- Symbolic group name

    rel            DOUBLE,                   -- Group relationship
    
    PRIMARY KEY (f, g)
);

-- gramdb(5) Table -  CIV/FRC cooperations
CREATE TABLE gramdb_coop_fg (
    f              TEXT,                     -- Symbolic group name
    g              TEXT,                     -- Symbolic group name

    coop0          DOUBLE,                   -- Cooperation
    
    PRIMARY KEY (f, g)
);

