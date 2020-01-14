--
-- Name: trigfn_u_t_param_value(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE FUNCTION mc.trigfn_u_t_param_value() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates last_affected and entered_by if the parameter value changes
**      Adds an entry to t_event_log if type_id 17 (mgractive) is updated
**
**  Auth:   mem
**  Date:   01/14/2020 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, %', TG_TABLE_NAME, TG_WHEN, TG_LEVEL, TG_OP;

    -- Update the last_affected and entered_by columns in t_param_value
    UPDATE mc.t_param_value
    SET last_affected = CURRENT_TIMESTAMP,
        entered_by = SESSION_USER
    WHERE mc.t_param_value.entry_id = NEW.entry_id;

    -- Add a new row to t_event_log
    INSERT INTO mc.t_event_log( target_type,
                                target_id,
                                target_state,
                                prev_target_state )
    SELECT 1 AS target_type,
           NEW.mgr_id,
           CASE NEW.value
               WHEN 'True' THEN 1
               ELSE 0
           END AS target_state,
           CASE OLD.value
               WHEN 'True' THEN 1
               ELSE 0
            END AS prev_target_state
    WHERE OLD.mgr_id = NEW.mgr_id AND
          OLD.type_id = NEW.type_id AND
          OLD.type_id = 17;

    RETURN null;
END
$$;


ALTER FUNCTION mc.trigfn_u_t_param_value() OWNER TO d3l243;
