--
-- Name: trigfn_t_processor_tool_after_update(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_processor_tool_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column Last_Affected
**
**  Auth:   mem
**  Date:   03/24/2012 mem - Initial version
**          07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If NEW.enabled = OLD.enabled AND NEW.priority = OLD.priority THEN
        RETURN null;
    End If;

    UPDATE cap.T_Processor_Tool
    SET Last_Affected = CURRENT_TIMESTAMP
    FROM NEW
    WHERE cap.T_Processor_Tool.Processor_Name = NEW.Processor_Name AND
          cap.T_Processor_Tool.Tool_Name = NEW.Tool_Name;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_processor_tool_after_update() OWNER TO d3l243;

