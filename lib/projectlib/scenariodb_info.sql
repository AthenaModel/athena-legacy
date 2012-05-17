------------------------------------------------------------------------
-- TITLE:
--    scenariodb_info.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Information Area
--
-- SECTIONS:
--    Communications Asset Packages (CAPs)
--    Semantic Hooks
--    Message Payloads
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- COMMUNICATIONS ASSET PACKAGES (CAPS)

CREATE TABLE caps (
    -- A CAP is collection of people and infrastructure that supports
    -- civilian communication (e.g., a newspaper, the phone system).

    k           TEXT PRIMARY KEY,               -- CAP ID
    longname    TEXT,                           -- Human-readable name
    owner       TEXT REFERENCES actors(a)       -- Owning Actor
                ON DELETE SET NULL
                DEFERRABLE INITIALLY DEFERRED, 
    capacity    DOUBLE DEFAULT 1.0,             -- Capacity, 0.0 to 1.0
    cost        DOUBLE DEFAULT 0.0              -- $ per message per week
);

CREATE TABLE cap_kn (
    -- CAP/Nbhood table.  By default, a CAP's coverage of a neighborhood
    -- is 0.0, as indicated by the caps_kn_view.  This table is used to
    -- override the default.

    k           TEXT REFERENCES caps(k)         -- CAP ID
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED, 
    n           TEXT REFERENCES nbhoods(n)      -- Nbhood ID
                ON DELETE CASCADE
                DEFERRABLE INITIALLY DEFERRED, 
    nbcov       DOUBLE DEFAULT 1.0,              -- Coverage of nbhood

    PRIMARY KEY (k,n)
);

-- This view gives the complete picture of nbhood coverage by CAP:
-- 0.0 for all neighborhoods, unless overridden by cap_kn.
CREATE VIEW cap_kn_view AS
SELECT K.k                     AS k,
       K.owner                 AS owner,
       N.n                     AS n,
       coalesce(KN.nbcov, 0.0) AS nbcov
FROM caps               AS K
JOIN nbhoods            AS N
LEFT OUTER JOIN cap_kn  AS KN USING (k,n);


CREATE TABLE cap_kg (
    -- CAP/CivGroup table.  By default, a CAP's penetration of a
    -- neighborhood is 0.0, as indicated by the caps_kg_view.  This
    -- table is used to override the default.

    k    TEXT REFERENCES caps(k)         -- CAP ID
         ON DELETE CASCADE
         DEFERRABLE INITIALLY DEFERRED, 
    g    TEXT REFERENCES civgroups(g)    -- Group ID
         ON DELETE CASCADE
         DEFERRABLE INITIALLY DEFERRED, 
    pen  DOUBLE DEFAULT 1.0,             -- Group penetration, 0.0 to 1.0

    PRIMARY KEY (k,g)
);

-- This view gives the complete picture of group penetration by CAP:
-- 0.0 for all groups, unless overridden by cap_kg.
CREATE VIEW cap_kg_view AS
SELECT K.k                     AS k,
       K.owner                 AS owner,
       G.g                     AS g,
       G.n                     AS n,
       coalesce(KG.pen, 0.0)   AS pen
FROM caps               AS K
JOIN civgroups          AS G
LEFT OUTER JOIN cap_kg  AS KG USING (k,g);


-- View giving CAP coverage by group, given capacity, nbhood coverage,
-- and group penetration.

CREATE VIEW capcov AS
SELECT KG.k                        AS k,
       KG.g                        AS g,
       KG.n                        AS n,
       K.owner                     AS owner,
       K.capacity                  AS capacity,
       KN.nbcov                    AS nbcov,
       KG.pen                      AS pen,
       K.capacity*KN.nbcov*KG.pen  AS capcov
FROM cap_kg_view AS KG
JOIN cap_kn_view AS KN USING (k,n)
JOIN caps        AS K  USING (k);





------------------------------------------------------------------------
-- SEMANTIC HOOKS

-- TBD



------------------------------------------------------------------------
-- MESSAGE PAYLOADS 

-- TBD


------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------
