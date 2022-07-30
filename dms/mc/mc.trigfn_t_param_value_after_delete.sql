--
-- Name: trigfn_t_param_value_after_delete(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.trigfn_t_param_value_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds an entry to mc.t_event_log if type_id 17 (mgractive) is deleted
**
**  Auth:   mem
**  Date:   01/14/2020 mem - Initial version
*           07/30/2022 mem - Use schema name when referencing tables
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    -- Add a new row to t_event_log
    INSERT INTO mc.t_event_log( target_type,
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


ALTER FUNCTION mc.trigfn_t_param_value_after_delete() OWNER TO d3l243;

