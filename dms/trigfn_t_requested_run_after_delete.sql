--
-- Name: trigfn_t_requested_run_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_requested_run_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the deleted Requested Run
**
**  Auth:   mem
**  Date:   12/12/2011 mem - Initial version
**          08/06/2022 mem - Ported to PostgreSQL
**          05/31/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_event_log for each Requested Run deleted from t_requested_run
    INSERT INTO t_event_log (
        target_type,
        target_id,
        target_state,
        prev_target_state,
        entered,
        entered_by
    )
    SELECT 11 AS target_type,
           request_id AS target_id,
           0 AS target_state,
           RRS.state_id AS prev_target_state,
           CURRENT_TIMESTAMP,
           format('%s; %s', SESSION_USER, deleted.request_name)
    FROM deleted
         INNER JOIN t_requested_run_state_name RRS
           ON deleted.state_name = RRS.state_name
    ORDER BY deleted.request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_requested_run_after_delete() OWNER TO d3l243;

