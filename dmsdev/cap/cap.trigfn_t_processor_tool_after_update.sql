--
-- Name: trigfn_t_processor_tool_after_update(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_processor_tool_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column last_affected in t_processor_tool when enabled or priority changes
**
**  Auth:   mem
**  Date:   03/24/2012 mem - Initial version
**          07/31/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    UPDATE cap.t_processor_tool
    SET last_affected = CURRENT_TIMESTAMP
    WHERE cap.t_processor_tool.processor_name = NEW.processor_name AND
          cap.t_processor_tool.tool_name = NEW.tool_name;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_processor_tool_after_update() OWNER TO d3l243;

