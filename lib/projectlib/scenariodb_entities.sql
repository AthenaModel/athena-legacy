------------------------------------------------------------------------
-- TITLE:
--    scenariodb_entities.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for scenariodb(n): Primary Entities
--
-- SECTIONS:
--    Meta-Data
--    Actors
--    Neighborhoods
--    Groups
--
------------------------------------------------------------------------

-- Schema Version
PRAGMA user_version=3;


------------------------------------------------------------------------
-- META-DATA 

-- Scenario Table: Scenario meta-data
--
-- The notion is that it can contain arbitrary meta-data; all it's
-- used for at the moment is as a flag that this is a scenario file.

CREATE TABLE scenario (
    parm  TEXT PRIMARY KEY,
    value TEXT DEFAULT ''
);


------------------------------------------------------------------------
-- ACTORS

-- Actor Data
CREATE TABLE actors (
    -- Symbolic actor name
    a            TEXT PRIMARY KEY,

    -- Full actor name
    longname     TEXT,

    -- Supports actor (actor name or NULL)
    supports     TEXT REFERENCES actors(a)
                 ON DELETE SET NULL
                 DEFERRABLE INITIALLY DEFERRED,

    -- Actor type, INCOME or BUDGET
    atype        TEXT DEFAULT 'INCOME',

    -- Money saved for later, in $.  Usually only INCOME actors
    -- will use this.
    cash_reserve DOUBLE DEFAULT 0,

    -- Money available to be spent, in $.
    -- For INCOME actors, unspent cash accumulates from tock to tock.
    cash_on_hand DOUBLE DEFAULT 0,

    -- Income by income class, in $/week, for INCOME actors.
    -- Ultimately, these should go in a separate table.
    income_goods     DOUBLE  DEFAULT 0,
    shares_black_nr  INTEGER DEFAULT 0,
    income_black_tax DOUBLE  DEFAULT 0,
    income_pop       DOUBLE  DEFAULT 0,
    income_graft     DOUBLE  DEFAULT 0,
    income_world     DOUBLE  DEFAULT 0,

    -- Budget in $/week, for BUDGET actors.
    budget           DOUBLE  DEFAULT 0
);

CREATE TRIGGER actor_delete
AFTER DELETE ON actors BEGIN
    DELETE FROM goals      WHERE owner = old.a;
    DELETE FROM tactics    WHERE owner = old.a;
    DELETE FROM conditions WHERE owner = old.a;
END;

CREATE TABLE income_a (
    -- Actor a's current income, as computed by the Econ model.
    -- If the Econ model is disabled, this table should be empty.
    -- 
    -- NOTE: This table is defined here, rather than in the Econ
    -- area, so that it can be used in the actors_view.
    --
    -- NOTE: Only INCOME actors have income.
    
    a         TEXT PRIMARY KEY,   -- Symbolic actor name
    income    DOUBLE,             -- Actor's current income

    -- Tax like rates
    t_goods        DOUBLE DEFAULT 0,  -- From goods sector
    t_black        DOUBLE DEFAULT 0,  -- From black sector
    t_pop          DOUBLE DEFAULT 0,  -- From pop sector
    t_world        DOUBLE DEFAULT 0,  -- From world sector

    -- Other income, treated as tax like rates
    graft_region   DOUBLE DEFAULT 0,  -- rate skimmed from region
    cut_black      DOUBLE DEFAULT 0,  -- rate from black market profits

    -- The current actual income sector by sector, these added together
    -- make the income column above
    inc_goods      DOUBLE DEFAULT 0,
    inc_black_t    DOUBLE DEFAULT 0, -- Income from tax-like rate
    inc_black_nr   DOUBLE DEFAULT 0, -- Income from black market profits
    inc_pop        DOUBLE DEFAULT 0,
    inc_world      DOUBLE DEFAULT 0,
    inc_region     DOUBLE DEFAULT 0
);

-- actors_view: Actor data, including computations

CREATE VIEW actors_view AS
SELECT a, 
       longname,
       supports,
       atype,
       cash_reserve,
       cash_on_hand,
       income_goods,
       shares_black_nr,
       income_black_tax,
       income_pop,
       income_graft,
       income_world,
       budget,
       -- For INCOME actors, get the income from the income_a table,
       -- if it exists, otherwise the sum of the income_* columns.
       -- For BUDGET actors, get the actor's budget.
       CASE WHEN atype == 'INCOME' THEN
           coalesce(income, income_goods + income_black_tax +
                        income_pop + income_graft + income_world)
           ELSE budget END  AS income
FROM actors
LEFT OUTER JOIN income_a USING (a);


------------------------------------------------------------------------
-- NEIGHBORHOODS

-- Neighborhood definitions
CREATE TABLE nbhoods (
    -- Symbolic neighborhood name     
    n              TEXT PRIMARY KEY,

    -- Full neighborhood name
    longname       TEXT,

    -- 1 if Local (e.g., part of the region of interest), 0 o.w.
    local          INTEGER DEFAULT 1.0,

    -- Stacking order: 1 is low, N is high
    stacking_order INTEGER,

    -- Urbanization: eurbanization
    urbanization   TEXT,

    -- Actor controlling the neighborhood at time 0.
    controller     TEXT REFERENCES actors(a)
                   ON DELETE SET NULL
                   DEFERRABLE INITIALLY DEFERRED, 

    -- Volatility gain: rgain
    vtygain        REAL DEFAULT 1.0,

    -- Neighborhood reference point: map coordinates {mx my}
    refpoint       TEXT,

    -- Neighborhood polygon: list of map coordinates {mx my ...}
    polygon        TEXT,

    -- If refpoint is obscured by another neighborhood, the name
    -- of the neighborhood; otherwise ''.
    obscured_by    TEXT DEFAULT ''
);

-- Neighborhood relationships from m's point of view
CREATE TABLE nbrel_mn (
    -- Symbolic nbhood name
    m             TEXT REFERENCES nbhoods(n)
                  ON DELETE CASCADE
                  DEFERRABLE INITIALLY DEFERRED,

    -- Symbolic nbhood name
    n             TEXT REFERENCES nbhoods(n)
                  ON DELETE CASCADE
                  DEFERRABLE INITIALLY DEFERRED,

    -- Proximity of m to n from m's point of view: eproximity value
    -- By default, a direct effect in n has no indirect effects in m,
    -- unless m == n (this is set automatically).
    proximity     TEXT DEFAULT 'REMOTE',

    PRIMARY KEY (m, n)
);



------------------------------------------------------------------------
-- GROUPS 

-- Generic Group Data
CREATE TABLE groups (
    -- Symbolic group name
    g           TEXT PRIMARY KEY,

    -- Full group name
    longname    TEXT,

    -- Group Color, as #RRGGBB
    color       TEXT DEFAULT '#00FFFF',

    -- Unit Shape (eunitshape(n))
    shape       TEXT DEFAULT 'NEUTRAL',

    -- Unit Symbol (list of eunitsymbol(n), or '')
    symbol      TEXT DEFAULT '',

    -- Group demeanor: edemeanor
    demeanor    TEXT DEFAULT 'AVERAGE',

    -- Maintenance Cost, in $/person/week (FRC/ORG groups only)
    cost        DOUBLE DEFAULT 0,

    -- Relationship Entity
    rel_entity  TEXT REFERENCES mam_entity(eid)
                ON DELETE SET NULL 
                DEFERRABLE INITIALLY DEFERRED,

    -- Group type, CIV, FRC, ORG
    gtype       TEXT
);

-- Civ Groups
CREATE TABLE civgroups (
    -- Symbolic group name
    g        TEXT PRIMARY KEY,

    -- Symbolic neighborhood name for neighborhood of residence.
    n        TEXT,

    -- Base Population/Personnel for this group
    basepop  INTEGER DEFAULT 0,

    -- Population Change Rate for this group in percent per year.
    -- This could be a negative number
    pop_cr   DOUBLE DEFAULT 0.0,

    -- Subsistence Agriculture Flag: if 1, the group does 
    -- subsistence agriculture and does not participate in the
    -- cash economy.  If 0, they do.
    sa_flag  INTEGER DEFAULT 0
);

-- Civ Groups View: joins groups with civgroups.
CREATE VIEW civgroups_view AS
SELECT g, 
       longname,
       color,
       shape,
       symbol,
       demeanor,
       basepop,
       pop_cr,
       rel_entity,
       gtype,
       n,
       sa_flag 
FROM groups JOIN civgroups USING (g);

-- Force Groups
CREATE TABLE frcgroups (
    -- Symbolic group name
    g              TEXT PRIMARY KEY,

    -- Owning Actor
    a              TEXT REFERENCES actors(a)
                   ON DELETE SET NULL
                   DEFERRABLE INITIALLY DEFERRED, 

    -- Force Type
    forcetype      TEXT,

    -- Training Level
    training       TEXT,

    -- The base number personnel 
    base_personnel INTEGER DEFAULT 0,

    -- Cost/Attack, in $
    attack_cost    DOUBLE DEFAULT 0,

    -- Uniformed or Non-uniformed: 1 or 0
    uniformed      INTEGER DEFAULT 1,

    -- Local or foreign: 1 if local, 0 if foreign
    local          INTEGER
);

-- Force Group View: joins groups with frcgroups.
CREATE VIEW frcgroups_view AS
SELECT * FROM groups JOIN frcgroups USING (g);


-- Org Groups
CREATE TABLE orggroups (
    -- Symbolic group name
    g                TEXT PRIMARY KEY,

    -- Owning Actor
    a                TEXT REFERENCES actors(a)
                     ON DELETE SET NULL
                     DEFERRABLE INITIALLY DEFERRED, 

    -- Organization type: eorgtype
    orgtype          TEXT DEFAULT 'NGO',

    -- The base number of personnel
    base_personnel   INTEGER DEFAULT 0
);

-- Org Group View: joins groups with orggroups.
CREATE VIEW orggroups_view AS
SELECT * FROM groups JOIN orggroups USING (g);

-- AGroups View: Groups that can be owned by actors
CREATE VIEW agroups AS
SELECT g, gtype, longname, a, cost, forcetype AS subtype, base_personnel
FROM frcgroups JOIN groups USING (g)
UNION
SELECT g, gtype, longname, a, cost, orgtype   AS subtype, base_personnel
FROM orggroups JOIN groups USING (g);


------------------------------------------------------------------------
-- End of File
------------------------------------------------------------------------
