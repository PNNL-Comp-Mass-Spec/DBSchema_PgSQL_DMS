--
-- Name: trigfn_d_t_param_value(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE FUNCTION mc.trigfn_d_t_param_value() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**        Adds an entry to t_event_log if type_id 17 (mgractive) is deleted
**
**  Auth:   mem
**  Date:   01/14/2020 mem - Initial version
**
*****************************************************/
BEGIN
    RAISE NOTICE '% trigger, % %, %', TG_TABLE_NAME, TG_WHEN, TG_LEVEL, TG_OP;

    -- Add a new row to t_event_log
    INSERT INTO t_event_log( target_type,
                             target_id,
                             target_state,
                             prev_target_state )
    SELECT 1 AS target_type,
           deleted.mgr_id,
           -1 AS target_state,
           CASE deleted.value
               WHEN 'True' THEN 1
               ELSE 0
           END AS prev_target_state
    FROM deleted
    WHERE deleted.type_id = 17
    ORDER BY deleted.mgr_id;

    RETURN null;
END
$$;


ALTER FUNCTION mc.trigfn_d_t_param_value() OWNER TO d3l243;
