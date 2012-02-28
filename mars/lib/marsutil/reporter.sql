------------------------------------------------------------------------
-- TITLE:
--    reporter.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema for reporter(n).
--
------------------------------------------------------------------------

----------------------------------------------------------------
-- Reports Definitions

-- Reports Table
CREATE TABLE reports (
    -- The unique report ID.
    id         INTEGER PRIMARY KEY,

    -- The timestamp, in integer ticks.
    time       INTEGER,

    -- Timestamp
    stamp      TEXT,

    -- The report type code.
    rtype      TEXT,

    -- The report subtype code.
    subtype    TEXT,

    -- The report's title string.
    title      TEXT,

    -- The text of the report.
    text       TEXT,

    -- Requested flag: 1 for reports that were requested by the user,
    -- and 0 for reports generated automatically by the application.
    requested  INTEGER DEFAULT 0,

    -- Hot List flag: 1 for reports on the hot list, and 0 otherwise.
    hotlist    INTEGER DEFAULT 0,

    -- "Meta" fields: the meaning of these fields is defined by the
    -- application, for use in bins.  Meaning can be constant across
    -- all reports, or may vary by type or subtype.
    meta1      TEXT DEFAULT '',
    meta2      TEXT DEFAULT '',
    meta3      TEXT DEFAULT '',
    meta4      TEXT DEFAULT ''
);

-- Index Reports table on rtype, subtype, to support report
-- browsing.
CREATE INDEX reports_type_subtype_index ON reports(rtype,subtype,time);

-- Index Reports table on requested, to support browsing requested
-- reports.
CREATE INDEX reports_requested_index ON reports(requested, time);

-- Index Reports table on hotlisted, to support browsing hotlisted
-- reports.
CREATE INDEX reports_hotlist_index ON reports(hotlist, time);
