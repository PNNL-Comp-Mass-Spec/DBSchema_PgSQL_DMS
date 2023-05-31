--
-- Name: trigfn_t_analysis_job_request_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_request_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the deleted analysis job request
**
**  Auth:   mem
**  Date:   03/26/2013 mem - Initial version
**          08/04/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_event_log for each job request deleted from t_analysis_job_request
    INSERT INTO t_event_log
        (
            target_type,
            target_id,
            target_state,
            prev_target_state,
            entered,
            entered_by
        )
    SELECT 12 AS target_type,
           deleted.request_id AS target_id,
           0 AS target_state,
           deleted.request_state_id AS prev_target_state,
           CURRENT_TIMESTAMP,
           format('%s; %s', SESSION_USER, deleted.request_name)
    FROM deleted
    ORDER BY deleted.request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_request_after_delete() OWNER TO d3l243;

