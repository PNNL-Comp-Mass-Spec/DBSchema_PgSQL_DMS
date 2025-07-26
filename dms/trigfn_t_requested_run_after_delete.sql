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
**          07/25/2025 mem - Also update t_requested_run_updates
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    ---------------------------------------------------
    -- Add entries to t_event_log for each requested run deleted from t_requested_run
    ---------------------------------------------------

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

    ---------------------------------------------------
    -- Add entries to t_requested_run_updates for each requested run deleted from t_requested_run
    ---------------------------------------------------

    INSERT INTO t_requested_run_updates (
        request_id,
        work_package_change,
        eus_proposal_change,
        eus_usage_type_change,
        service_type_change,
        entered_by
    )
    SELECT deleted.request_id,
           CASE WHEN deleted.work_package IS NULL
                THEN NULL
                ELSE format('%s -> ""', deleted.work_package)
           END,
           CASE WHEN deleted.eus_proposal_id IS NULL
                THEN NULL
                ELSE format('%s -> ""', deleted.eus_proposal_id)
           END,
           format('%s -> 0', deleted.eus_usage_type_id),
           format('%s -> 0', deleted.service_type_id),
           format('%s; %s', public.get_user_login_without_domain(''), deleted.request_name)
    FROM deleted
    ORDER BY deleted.request_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_requested_run_after_delete() OWNER TO d3l243;

