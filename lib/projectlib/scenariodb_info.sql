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
--    Info Ops Messages (IOMs)
--    IOM Payloads
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

CREATE TABLE hooks(
    -- TBD: Place-holder
    hook_id TEXT PRIMARY KEY
);   


------------------------------------------------------------------------
-- INFO OPS MESSAGES (IOMS)

CREATE TABLE ioms (
    -- Messages sent by actors via CAPs.  Each IOM has a hook and
    -- any number of payloads.  The hook must be set before the scenario
    -- is locked, or there will be a sanity check failure.

    iom_id     TEXT PRIMARY KEY,                -- Entity ID
    longname   TEXT,                            -- Human-readable name
    hook_id    TEXT REFERENCES hooks(hook_id)   -- Semantic hook
               ON DELETE SET NULL
               DEFERRABLE INITIALLY DEFERRED, 
    narrative  TEXT DEFAULT ''                  -- Computed from the hook 
                                                -- and payloads
);

------------------------------------------------------------------------
-- IOM PAYLOADS 

CREATE TABLE payloads (
    -- Payloads for Info Ops messages.  A payload effects some attitude
    -- or set of attitudes in some particular way.  Each payload has
    -- a payload type; the kind of effect it has, and the other data
    -- required, depends on the payload type.
    --
    -- Every payload is associated with some message.
    
    iom_id         TEXT REFERENCES ioms(iom_id)
                   ON DELETE CASCADE
                   DEFERRABLE INITIALLY DEFERRED, 
    payload_num    INTEGER,
    payload_type   TEXT,   -- epayloadpart(n) value
    
    -- Narrative: different payloads use different sets of parameters, 
    -- so a conventional browser of all of the columns is 
    -- user-unfriendly.  Instead, we compute a narrative string.
    narrative      TEXT,

    -- State: normal, disabled, invalid (epayload_state)
    state          TEXT DEFAULT 'normal',
    
    -- Payload Type parameters.  The use of these varies by type;
    -- all are NULL if unused.  There are no foreign key constraints;
    -- errors are checked by the payload type's "check" method.
    a              TEXT,   -- Actor ID
    c              TEXT,   -- Concern ID
    g              TEXT,   -- Group ID
    mag            REAL,   -- Numeric qmag(n) value

    PRIMARY KEY (iom_id, payload_num)
);

------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------
