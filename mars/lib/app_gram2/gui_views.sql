------------------------------------------------------------------------
-- TITLE:
--    gui_views.sql
--
-- AUTHOR:
--    Will Duquette
--
-- DESCRIPTION:
--    SQL Schema: Application-specific views
--
--    These views translate internal data formats into presentation format.
--    
------------------------------------------------------------------------

-- gv_gram_sat
CREATE TEMPORARY VIEW gv_gram_sat AS
SELECT gc_id,
       n,
       g, 
       c,
       saliency,
       curve_id, 
       format('%.3f',sat0)  AS sat0, 
       format('%.3f',sat)   AS sat, 
       format('%.3f',delta) AS delta,
       format('%.3f',slope) AS slope
FROM gram_sat;

-- gv_gram_sat_levels
CREATE TEMPORARY VIEW gv_gram_sat_levels AS
SELECT driver,
       input,
       id,
       ts,
       te,
       dn,
       dg,
       n,
       g,
       c,
       cause,
       prox,
       format('%.1f',athresh)  AS athresh,
       format('%.1f',dthresh)  AS dthresh,
       format('%.3f',sat)      AS sat,
       format('%.3f',days)     AS days,
       format('%.5f',tau)      AS tau,
       format('%.2f',llimit)   AS llimit,
       tlast,
       format('%.5f',ncontrib) AS ncontrib,
       format('%.5f',acontrib) AS acontrib,
       format('%.5f',nominal)  AS nominal, 
       format('%.5f',actual)   AS actual 
FROM gram_sat_effects
WHERE etype='L';

-- gv_gram_sat_slopes_trend
CREATE TEMPORARY VIEW gv_gram_sat_slopes_trend AS
SELECT driver,
       input,
       id,
       ts,
       te,
       dn,
       dg,
       n,
       g,
       c,
       cause,
       prox,
       format('%.1f',athresh)  AS athresh,
       format('%.1f',dthresh)  AS dthresh,
       format('%.3f',sat)      AS sat, 
       delay,
       format('%.2f',slope)    AS slope, 
       future,
       tlast,
       format('%.5f',ncontrib) AS ncontrib,
       format('%.5f',acontrib) AS acontrib,
       format('%.5f',nominal)  AS nominal, 
       format('%.5f',actual)   AS actual 
FROM gram_sat_effects
WHERE etype='S';

-- gv_gram_sat_slopes
CREATE TEMPORARY VIEW gv_gram_sat_slopes AS
SELECT * FROM gv_gram_sat_slopes_trend
WHERE driver != 0;

-- gv_gram_coop
CREATE TEMPORARY VIEW gv_gram_coop AS
SELECT fg_id,
       curve_id,
       n,
       f,
       g,
       format('%.3f', coop0) AS coop0,
       format('%.3f', coop)  AS coop,
       format('%.3f', delta) AS delta,
       format('%.3f', slope) AS slope
FROM gram_coop;

-- gv_gram_coop_levels
CREATE TEMPORARY VIEW gv_gram_coop_levels AS
SELECT driver,
       input,
       id,
       ts,
       te,
       dn,
       df,
       dg,
       n,
       f,
       g,
       cause,
       prox,
       format('%.1f',athresh)  AS athresh,
       format('%.1f',dthresh)  AS dthresh,
       format('%.3f',coop)     AS coop,
       format('%.3f',days)     AS days,
       format('%.5f',tau)      AS tau,
       format('%.2f',llimit)   AS llimit,
       tlast,
       format('%.5f',ncontrib) AS ncontrib,
       format('%.5f',acontrib) AS acontrib,
       format('%.5f',nominal)  AS nominal, 
       format('%.5f',actual)   AS actual 
FROM gram_coop_effects
WHERE etype='L';

-- gv_gram_coop_slopes
CREATE TEMPORARY VIEW gv_gram_coop_slopes AS
SELECT driver,
       input,
       id,
       ts,
       te,
       dn,
       df,
       dg,
       n,
       f,
       g,
       cause,
       prox,
       format('%.1f',athresh)  AS athresh,
       format('%.1f',dthresh)  AS dthresh,
       format('%.3f',coop)     AS coop,
       delay,
       format('%.2f',slope)    AS slope, 
       future,
       tlast,
       format('%.5f',ncontrib) AS ncontrib,
       format('%.5f',acontrib) AS acontrib,
       format('%.5f',nominal)  AS nominal, 
       format('%.5f',actual)   AS actual 
FROM gram_coop_effects
WHERE etype='S';
