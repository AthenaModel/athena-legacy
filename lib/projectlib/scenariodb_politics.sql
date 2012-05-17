------------------------------------------------------------------------
-- TITLE:
--    scenariodb_politics.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Politics Area
--
-- SECTIONS:
--    Support, Influence, and Control
--    Goals, Tactics, and Conditions
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- SUPPORT, INFLUENCE, AND CONTROL

-- supports_na table: Actor supported by Actor a in n.

CREATE TABLE supports_na (
    -- Symbolic group name
    n         TEXT REFERENCES nbhoods(n)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a         TEXT REFERENCES actors(a)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    -- Supported actor name, or NULL
    supports  TEXT REFERENCES actors(a)
              ON DELETE CASCADE
              DEFERRABLE INITIALLY DEFERRED,

    PRIMARY KEY (n, a)
);


-- support_nga table: Support for actor a by group g in nbhood n

CREATE TABLE support_nga (
    -- Symbolic group name
    n                TEXT REFERENCES nbhoods(n)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic group name
    g                TEXT REFERENCES groups(g)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a                TEXT REFERENCES actors(a)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Vertical Relationship of g with a
    vrel             REAL DEFAULT 0.0,

    -- g's personnel in n
    personnel        INTEGER DEFAULT 0,

    -- g's security in n
    security         INTEGER DEFAULT 0,

    -- Direct Contribution of g to a's support in n
    direct_support   REAL DEFAULT 0.0,

    -- Actual Contribution of g to a's support in n,
    -- given a's support of other actors, and other actor's support
    -- of a.
    support          REAL DEFAULT 0.0,

    -- Contribution of g to a's influence in n.
    -- (support divided total support in n)
    influence        REAL DEFAULT 0.0,

    PRIMARY KEY (n, g, a)
);


-- influence_na table: Actor's influence in neighborhood.
--
-- Note: We don't cascade deletions, as this table is populated only 
-- during simulation, when the referenced entities aren't being deleted.

CREATE TABLE influence_na (
    -- Symbolic group name
    n                TEXT REFERENCES nbhoods(n)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic actor name
    a                TEXT REFERENCES actors(a)
                     ON DELETE CASCADE
                     DEFERRABLE INITIALLY DEFERRED,

    -- Direct Support for a in n
    direct_support   REAL DEFAULT 0.0,

    -- Actual Support for a in n, including direct support and support
    -- from other actors's followers.
    support          REAL DEFAULT 0.0,

    -- Influence of a in n
    influence        REAL DEFAULT 0.0,

    PRIMARY KEY (n, a)
);

-- control_n table: Control of neighborhood n

CREATE TABLE control_n (
    -- Symbolic group name
    n          TEXT PRIMARY KEY 
               REFERENCES nbhoods(n)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Actor controlling n, or NULL.
    controller TEXT REFERENCES actors(a)
               ON DELETE CASCADE
               DEFERRABLE INITIALLY DEFERRED,

    -- Time at which controller took control
    since      INTEGER DEFAULT 0
);


------------------------------------------------------------------------
-- GOALS, TACTICS, AND CONDITIONS

-- An agent is an entity that can own goals and tactics.  In theory, any 
-- kind of entity can be an agent.  At present there are two kinds, actors 
-- and the SYSTEM.

CREATE VIEW agents AS
SELECT 'SYSTEM' AS agent_id, 'system' AS agent_type
UNION
SELECT a        AS agent_id, 'actor'  AS agent_type  FROM actors;


-- Condition Collection Table
--
-- Tactics and Goals are both "condition collections"; they can have
-- attached conditions.

CREATE TABLE cond_collections (
    cc_id   INTEGER PRIMARY KEY,
    cc_type TEXT NOT NULL        -- tactic|goal
);

-- Goals Table
--
-- The goals table stores the goals pursued by the various actors.

CREATE TABLE goals (
    -- The goal_id is, in fact, a cond_collections.cc_id.  We do not
    -- reference it explicitly because the cond_collections record is
    -- deleted when a tactics or goals row is deleted, not the
    -- other way around.
    goal_id      INTEGER PRIMARY KEY, 
    
    -- Owning agent; see agents
    owner        TEXT,

    -- Narrative: For goals, this is a user-edited string.
    narrative    TEXT NOT NULL,

    -- State: normal, disabled, invalid (egoal_state)
    state        TEXT DEFAULT 'normal',

    -- Flag: 1 (met), 0 (unmet), or NULL (unknown)
    flag         INTEGER
);

-- A goal is a condition owner; thus, we need a trigger to delete
-- the cond_collections row when a goal is deleted.

CREATE TRIGGER goal_delete
AFTER DELETE ON goals BEGIN
    DELETE FROM cond_collections WHERE cc_id = old.goal_id;
END;


-- Tactics Table
--
-- The tactics table stores the tactics in use by the various actors.

CREATE TABLE tactics (
    -- The tactic_id is, in fact, a cond_collections.cc_id.  We do not
    -- reference it explicitly because the cond_collections record is
    -- deleted when a tactics or goals row is deleted, not the
    -- other way around.
    tactic_id    INTEGER PRIMARY KEY, 
    tactic_type  TEXT,
    
    -- Owning agent; see agents
    owner        TEXT,

    -- Narrative: different tactics use different sets of parameters, 
    -- so a conventional browser of all of the columns is 
    -- user-unfriendly.  Instead, we compute a narrative string.
    narrative    TEXT,

    -- Priority: This is used to place each actor's tactics in 
    -- order of execution.
    priority     INTEGER,

    -- Once flag, 1 or 0.  If 1, the tactic will be automatically disabled
    -- on successful execution.
    once         INTEGER DEFAULT 0,

    -- On-lock flag, 1 or 0. If 1, the tactic will be executed on lock 
    -- regardless of any other condition
    on_lock      INTEGER DEFAULT 0,

    -- State: normal, disabled, invalid (etactic_state)
    state        TEXT DEFAULT 'normal',

    -- time of last execution, in ticks
    exec_ts      INTEGER,

    -- Flag: 1 if tactic was selected for execution at the last tactics 
    -- tock, and 0 otherwise.
    exec_flag    INTEGER DEFAULT 0,

    -- Type-specific Parameters: These columns are used in different
    -- ways by different tactics; all are NULL if unused.  No
    -- foreign key constraints; errors are checked by tactic-type
    -- sanity checker, to give the user more flexibility.

    -- Actors; use a first.
    a            TEXT,   -- One actor
    b            TEXT,   -- One actor

    -- Neighborhoods; use n first.
    m            TEXT,   -- One neighborhood
    n            TEXT,   -- One neighborhood
    nlist        TEXT,   -- List of neighborhoods

    -- Groups; use g first.
    f            TEXT,
    g            TEXT,
    glist        TEXT,   -- List of groups

    -- Data items
    text1        TEXT,
    int1         INTEGER,
    x1           REAL
);

-- A tactic is a condition owner; thus, we need a trigger to delete
-- the cond_collections row when a tactic is deleted.

CREATE TRIGGER tactics_delete
AFTER DELETE ON tactics BEGIN
    DELETE FROM cond_collections WHERE cc_id = old.tactic_id;
END;


-- Conditions Table
--
-- The conditions table stores the conditions in use by the various
-- goals and tactics.

CREATE TABLE conditions (
    condition_id   INTEGER PRIMARY KEY,
    condition_type TEXT, -- econdition_type(n)
    
    -- Condition collection (a goal or tactic)
    cc_id          INTEGER REFERENCES cond_collections(cc_id)
                   ON DELETE CASCADE
                   DEFERRABLE INITIALLY DEFERRED, 

    -- Owning agent; see agents
    owner          TEXT,

    -- Narrative: different conditions use different sets of parameters, 
    -- so a conventional browser of all of the columns is 
    -- user-unfriendly.  Instead, we compute a narrative string.
    narrative     TEXT,

    -- State: normal, disabled, invalid (econdition_state)
    state         TEXT DEFAULT 'normal',

    -- Flag: 1 (met), 0 (unmet), or NULL (unknown)
    flag         INTEGER,

    -- Type-specific Parameters: These columns are used in different
    -- ways by different conditions; all are NULL if unused.

    a             TEXT,    -- An actor
    g             TEXT,    -- An group
    n             TEXT,    -- A neighborhood
    op1           TEXT,    -- An operation
    t1            INTEGER, -- A time in ticks
    t2            INTEGER, -- A time in ticks
    text1         TEXT,    -- A text string
    list1         TEXT,    -- A list
    int1          INTEGER, -- An integer
    x1            REAL     -- A number
);


------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------
