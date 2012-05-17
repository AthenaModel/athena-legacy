------------------------------------------------------------------------
-- TITLE:
--    scenariodb_history.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Simulation History
--
------------------------------------------------------------------------

-- The following tables are used to save time series variable data
-- for plotting, etc.  Each table has a name like "history_<vartype>"
-- where <vartype> is a time series variable type.  In some cases,
-- one table might contain multiple variables; in that case it will
-- be named after the primary one.

-- sat.g.c
CREATE TABLE hist_sat (
    t   INTEGER,
    g   TEXT,
    c   TEXT,
    sat DOUBLE,

    PRIMARY KEY (t,g,c)
);

-- mood.g
CREATE TABLE hist_mood (
    t    INTEGER,
    g    TEXT,
    mood DOUBLE,

    PRIMARY KEY (t,g)
);

-- nbmood.n
CREATE TABLE hist_nbmood (
    t      INTEGER,
    n      TEXT,
    nbmood DOUBLE,

    PRIMARY KEY (t,n)
);

-- coop.f.g
CREATE TABLE hist_coop (
    t    INTEGER,
    f    TEXT,
    g    TEXT,
    coop DOUBLE,

    PRIMARY KEY (t,f,g)
);

-- nbcoop.n.g
CREATE TABLE hist_nbcoop (
    t      INTEGER,
    n      TEXT,
    g      TEXT,
    nbcoop DOUBLE,

    PRIMARY KEY (t,n,g)
);

-- econ
CREATE TABLE hist_econ (
    t           INTEGER PRIMARY KEY,
    consumers   INTEGER,
    labor       INTEGER,
    lsf         DOUBLE,
    cpi         DOUBLE,
    dgdp        DOUBLE,
    ur          DOUBLE
);

-- econ.i
CREATE TABLE hist_econ_i (
    t           INTEGER,
    i           TEXT,
    p           DOUBLE,
    qs          DOUBLE,
    rev         DOUBLE,

    PRIMARY KEY (t,i)
);

-- econ.i.j
CREATE TABLE hist_econ_ij (
    t           INTEGER,
    i           TEXT,
    j           TEXT,
    x           DOUBLE,
    qd          DOUBLE,

    PRIMARY KEY (t,i,j)        
);

-- control.n.a
CREATE TABLE hist_control (
    t   INTEGER,
    n   TEXT, -- Neighborhood
    a   TEXT, -- Actor controlling neighborhood n, or NULL if none.

    PRIMARY KEY (t,n)
);

-- security.n.g
CREATE TABLE hist_security (
    t        INTEGER,
    n        TEXT,     -- Neighborhood
    g        TEXT,     -- Group
    security INTEGER,  -- g's security in n.

    PRIMARY KEY (t,n,g)
);

-- support.n.a
CREATE TABLE hist_support (
    t              INTEGER,
    n              TEXT,    -- Neighborhood
    a              TEXT,    -- Actor
    direct_support REAL,    -- a's direct support in n
    support        REAL,    -- a's total support (direct + derived) in n
    influence      REAL,    -- a's influence in n

    PRIMARY KEY (t,n,a)
);

-- volatility.n.a
CREATE TABLE hist_volatility (
    t              INTEGER,
    n              TEXT,    -- Neighborhood
    volatility     INTEGER, -- Volatility of n

    PRIMARY KEY (t,n)
);

-- vrel.g.a
CREATE TABLE hist_vrel (
    t      INTEGER,
    g      TEXT,    -- Civilian group
    a      TEXT,    -- Actor
    vrel   REAL,    -- Vertical relationship of g with a.

    PRIMARY KEY (t,g,a)
);


------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------
