--
-- Name: trigfn_t_cached_experiment_stats_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_cached_experiment_stats_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update last_affected in t_cached_experiment_stats
**
**  Auth:   mem
**  Date:   05/05/2024 - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_cached_experiment_stats
    SET last_affected = CURRENT_TIMESTAMP
    WHERE t_cached_experiment_stats.exp_id = NEW.exp_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_cached_experiment_stats_after_update() OWNER TO d3l243;

