--
-- Name: trigfn_i_t_param_value(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE FUNCTION mc.trigfn_i_t_param_value() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**        Adds an entry to t_event_log for new entries with type_id = 17 (mgractive)
**
**  Auth:   mem
**  Date:   01/14/2020 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, %', TG_TABLE_NAME, TG_WHEN, TG_LEVEL, TG_OP;

    -- Add a new row to t_event_log
    INSERT INTO t_event_log( target_type,
                             target_id,
                             target_state,
                             prev_target_state )
    SELECT 1 AS target_type,
           inserted.mgr_id,
           CASE inserted.value
               WHEN 'True' THEN 1
               ELSE 0
           END AS target_state,
           -1 AS prev_target_state
    FROM inserted
    WHERE inserted.type_id = 17
    ORDER BY inserted.mgr_id;

    RETURN null;
END
$$;


ALTER FUNCTION mc.trigfn_i_t_param_value() OWNER TO d3l243;
