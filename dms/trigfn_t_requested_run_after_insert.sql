--
-- Name: trigfn_t_requested_run_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_requested_run_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the new Requested Run
**
**  Auth:   mem
**  Date:   12/12/2011 mem - Initial version
**          08/06/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 11 AS target_type,
           inserted.request_id,
           RRS.state_id,
           0,
           CURRENT_TIMESTAMP
    FROM inserted INNER JOIN
         t_requested_run_state_name RRS
           ON inserted.state_name = RRS.state_name
    ORDER BY inserted.request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_requested_run_after_insert() OWNER TO d3l243;

