--
-- Name: trigfn_t_process_step_control_after_update(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_process_step_control_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the Last_Affected and Entered_By fields
**
**  Auth:   mem
**  Date:   08/30/2006
**          07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If NEW.enabled = OLD.enabled Then
        RETURN null;
    End If;

    UPDATE cap.T_Process_Step_Control
    SET Last_Affected = CURRENT_TIMESTAMP,
        Entered_By = SYSTEM_USER
    FROM NEW
    WHERE cap.T_Process_Step_Control.Processing_Step_Name = N.Processing_Step_Name;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_process_step_control_after_update() OWNER TO d3l243;

