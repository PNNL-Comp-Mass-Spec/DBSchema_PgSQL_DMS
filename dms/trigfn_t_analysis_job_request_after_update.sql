--
-- Name: trigfn_t_analysis_job_request_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_request_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the updated analysis job request
**
**  Auth:   mem
**  Date:   03/26/2013 mem - Initial version
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 12, N.request_id, N.request_state_id, O.request_state_id, CURRENT_TIMESTAMP
    FROM OLD as O INNER JOIN
         NEW as N ON O.request_id = N.request_id
    WHERE N.request_state_id <> O.request_state_id          -- Use <> since request_state_id is never null
    ORDER BY N.request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_request_after_update() OWNER TO d3l243;

