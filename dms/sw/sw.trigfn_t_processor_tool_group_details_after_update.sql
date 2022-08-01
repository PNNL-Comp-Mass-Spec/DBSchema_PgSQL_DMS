--
-- Name: trigfn_t_processor_tool_group_details_after_update(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_t_processor_tool_group_details_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column last_affected in t_processor_tool_group_details when enabled or priority changes
**
**  Auth:   mem
**  Date:   07/26/2011 mem - Initial version
**          07/31/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If NEW.enabled = OLD.enabled AND NEW.priority = OLD.priority THEN
        RETURN null;
    End If;

    UPDATE sw.t_processor_tool_group_details
    SET Last_Affected = CURRENT_TIMESTAMP
    FROM NEW N
    WHERE sw.t_processor_tool_group_details.group_id = N.group_id AND
          sw.t_processor_tool_group_details.mgr_id = N.mgr_id AND
          sw.t_processor_tool_group_details.tool_name = N.tool_name;

    RETURN null;
END
$$;


ALTER FUNCTION sw.trigfn_t_processor_tool_group_details_after_update() OWNER TO d3l243;

