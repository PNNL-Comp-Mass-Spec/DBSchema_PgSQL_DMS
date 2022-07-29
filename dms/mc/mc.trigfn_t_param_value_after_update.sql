--
-- Name: trigfn_t_param_value_after_update(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.trigfn_t_param_value_after_update() RETURNS trigger
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
**          03/14/2022 mem - Only append to t_event_log if the value changes
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
          NEW.type_id = 17 AND
          NEW.value <> OLD.value;

    RETURN null;
END
$$;


ALTER FUNCTION mc.trigfn_t_param_value_after_update() OWNER TO d3l243;

