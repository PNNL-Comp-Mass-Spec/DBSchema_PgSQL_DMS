--
-- Name: trigfn_t_process_step_control_after_update(); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.trigfn_t_process_step_control_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the last_affected and entered_by fields
**      if the value for enabled changes
**
**  Auth:   mem
**  Date:   08/30/2006
**          07/31/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    UPDATE pc.t_process_step_control
    SET last_affected = CURRENT_TIMESTAMP,
        entered_by = SESSION_USER
    WHERE pc.t_process_step_control.processing_step_name = NEW.processing_step_name;

    RETURN null;
END
$$;


ALTER FUNCTION pc.trigfn_t_process_step_control_after_update() OWNER TO d3l243;

