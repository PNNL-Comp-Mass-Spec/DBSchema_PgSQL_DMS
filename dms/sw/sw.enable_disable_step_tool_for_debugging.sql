--
-- Name: enable_disable_step_tool_for_debugging(text, boolean, text, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.enable_disable_step_tool_for_debugging(_tool text DEFAULT ''::text, _debugmode boolean DEFAULT false, _groupname text DEFAULT 'Monroe Development Box'::text, _infoonly boolean DEFAULT false) RETURNS TABLE(action text, group_id integer, mgr_id integer, tool_name public.citext, priority smallint, enabled smallint, comment public.citext, max_step_cost smallint, max_job_priority smallint, last_affected timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Bulk enables or disables a step tool to allow for debugging
**
**  Arguments:
**    _tool             Step tool name
**    _debugMode        True to disable managers (and thus allow for debugging); false to re-enable the managers
**    _infoOnly         View step tools that would be updated
**
**  Example usage:
**    SELECT * FROM sw.enable_disable_step_tool_for_debugging('MSGFPlus', _debugMode => true, _infoOnly => true);
**    SELECT * FROM sw.enable_disable_step_tool_for_debugging('MSGFPlus', _debugMode => true, _infoOnly => false);
**    SELECT * FROM sw.enable_disable_step_tool_for_debugging('MSGFPlus', _debugMode => false, _infoOnly => true);
**    SELECT * FROM sw.enable_disable_step_tool_for_debugging('MSGFPlus', _debugMode => false, _infoOnly => false);
**
**  Auth:   mem
**  Date:   10/22/2013 mem - Initial version
**          11/11/2013 mem - Added parameter _groupName
**          11/22/2013 mem - Now validating _tool
**          09/01/2017 mem - Implement functionality of _infoOnly
**          08/26/2021 mem - Auto-change _groupName to the default value if an empty string
**          06/09/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          12/08/2023 mem - Select a single column when using If Not Exists()
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          08/04/2024 mem - Ignore case when filtering on tool name
**
*****************************************************/
DECLARE
    _message text := '';
    _updateCount int;
    _updatedRows int := 0;
    _groupID int;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _tool      := Trim(Coalesce(_tool, ''));
    _groupName := Trim(Coalesce(_groupName, ''));
    _debugMode := Coalesce(_debugMode, false);
    _infoOnly  := Coalesce(_infoOnly, false);

    If _groupName = '' Then
        _groupName := 'Monroe Development Box';
    End If;

    SELECT PTG.group_id
    INTO _groupID
    FROM sw.t_processor_tool_groups PTG
    WHERE PTG.group_name = _groupName::citext;

    If Not FOUND Then
        _message := format('Error, group not found: %s', _groupName);
    ElsIf Not Exists (SELECT PTGD.tool_name FROM sw.t_processor_tool_group_details PTGD WHERE PTGD.tool_name = _tool::citext) Then
        _message := format('Error, tool not found: %s', _tool);
    End If;

    ---------------------------------------------------
    -- Assure that tool name is properly capitalized
    ---------------------------------------------------

    SELECT PTGD.tool_name
    INTO _tool
    FROM sw.t_processor_tool_group_details PTGD
    WHERE PTGD.tool_name = _tool::citext;

    If _message <> '' Then
        RETURN QUERY
        SELECT _message      AS message,
               _groupID      AS group_id,
               0             AS mgr_id,
               _tool::citext AS tool_name,
               0::int2       AS priority,
               null::int2    AS enabled,
               ''::citext    AS comment,
               0::int2       AS max_step_cost,
               0::int2       AS max_job_priority,
               current_timestamp::timestamp without time zone;

        RETURN;
    End If;

    If Not _debugMode Then

        -- Disable debugging

        If Not _infoOnly Then
            UPDATE sw.t_processor_tool_group_details Target
            SET enabled = 1
            WHERE Target.tool_name = _tool::citext AND Target.enabled < 0 AND Target.group_id <> _groupID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            UPDATE sw.t_processor_tool_group_details Target
            SET enabled = 0
            WHERE Target.tool_name = _tool::citext AND Target.enabled <> 0 AND Target.group_id = _groupID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            If _updatedRows = 0 Then
                _message := format('Debug mode is already disabled for %s, group %s', _tool, _groupName);
            Else
                _message := format('Debug mode disabled for %s; updated %s %s',
                                    _tool, _updatedRows, public.check_plural(_updatedRows, 'row', 'rows'));
            End If;
        Else
            RETURN QUERY
            SELECT 'Set enabled to 1' AS Action,
                   PTGD.group_id,
                   PTGD.mgr_id,
                   PTGD.tool_name,
                   PTGD.priority,
                   PTGD.enabled,
                   PTGD.comment,
                   PTGD.max_step_cost,
                   PTGD.max_job_priority,
                   PTGD.last_affected
            FROM sw.t_processor_tool_group_details PTGD
            WHERE PTGD.tool_name = _tool::citext AND PTGD.enabled < 0 AND PTGD.group_id <> _groupID
            UNION
            SELECT 'Set enabled to 0' AS Action,
                   PTGD.group_id,
                   PTGD.mgr_id,
                   PTGD.tool_name,
                   PTGD.priority,
                   PTGD.enabled,
                   PTGD.comment,
                   PTGD.max_step_cost,
                   PTGD.max_job_priority,
                   PTGD.last_affected
            FROM sw.t_processor_tool_group_details PTGD
            WHERE PTGD.tool_name = _tool::citext AND PTGD.enabled <> 0 AND PTGD.group_id = _groupID;

            If Not FOUND Then
                RETURN QUERY
                SELECT format('Debug mode is already disabled for group %s', _groupName) AS Comment,
                       PTGD.group_id,
                       PTGD.mgr_id,
                       PTGD.tool_name,
                       PTGD.priority,
                       PTGD.enabled,
                       PTGD.comment,
                       PTGD.max_step_cost,
                       PTGD.max_job_priority,
                       PTGD.last_affected
                FROM sw.t_processor_tool_group_details PTGD
                WHERE PTGD.tool_name = _tool::citext AND PTGD.enabled > 0;
            End If;
        End If;

    Else
        -- Enable debugging

        If Not _infoOnly Then
            UPDATE sw.t_processor_tool_group_details Target
            SET enabled = -1
            WHERE Target.tool_name = _tool::citext AND Target.enabled > 0 AND Target.group_id <> _groupID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            UPDATE sw.t_processor_tool_group_details Target
            SET enabled = 1
            WHERE Target.tool_name = _tool::citext AND Target.enabled <> 1 AND Target.group_id = _groupID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            If _updatedRows = 0 Then
                _message := format('Debug mode is already enabled for %s, group %s', _tool, _groupName);
            Else
                _message := format('Debug mode enabled for %s; updated %s %s',
                                    _tool, _updatedRows, public.check_plural(_updatedRows, 'row', 'rows'));
            End If;
        Else
            RETURN QUERY
            SELECT 'Set enabled to -1' AS Action,
                   PTGD.group_id,
                   PTGD.mgr_id,
                   PTGD.tool_name,
                   PTGD.priority,
                   PTGD.enabled,
                   PTGD.comment,
                   PTGD.max_step_cost,
                   PTGD.max_job_priority,
                   PTGD.last_affected
            FROM sw.t_processor_tool_group_details PTGD
            WHERE PTGD.tool_name = _tool::citext AND PTGD.enabled > 0 AND PTGD.group_id <> _groupID
            UNION
            SELECT 'Set enabled to 1' AS Action,
                   PTGD.group_id,
                   PTGD.mgr_id,
                   PTGD.tool_name,
                   PTGD.priority,
                   PTGD.enabled,
                   PTGD.comment,
                   PTGD.max_step_cost,
                   PTGD.max_job_priority,
                   PTGD.last_affected
            FROM sw.t_processor_tool_group_details PTGD
            WHERE PTGD.tool_name = _tool::citext AND PTGD.enabled <> 1 AND PTGD.group_id = _groupID;

            If Not FOUND Then
                RETURN QUERY
                SELECT format('Debug mode is already enabled for group %s', _groupName) AS Comment,
                       PTGD.group_id,
                       PTGD.mgr_id,
                       PTGD.tool_name,
                       PTGD.priority,
                       PTGD.enabled,
                       PTGD.comment,
                       PTGD.max_step_cost,
                       PTGD.max_job_priority,
                       PTGD.last_affected
                FROM sw.t_processor_tool_group_details PTGD
                WHERE PTGD.tool_name = _tool::citext AND PTGD.enabled > 0;
            End If;
        End If;

    End If;

    If _message = '' Then
        RETURN;
    End If;

    RETURN QUERY
    SELECT _message,
           _groupID      AS group_id,
           0             AS mgr_id,
           _tool::citext AS tool_name,
           0::int2       AS priority,
           null::int2    AS enabled,
           ''::citext    AS comment,
           0::int2       AS max_step_cost,
           0::int2       AS max_job_priority,
           current_timestamp::timestamp without time zone;

END
$$;


ALTER FUNCTION sw.enable_disable_step_tool_for_debugging(_tool text, _debugmode boolean, _groupname text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION enable_disable_step_tool_for_debugging(_tool text, _debugmode boolean, _groupname text, _infoonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.enable_disable_step_tool_for_debugging(_tool text, _debugmode boolean, _groupname text, _infoonly boolean) IS 'EnableDisableStepToolForDebugging';

