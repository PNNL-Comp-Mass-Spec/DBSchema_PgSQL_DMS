--
-- Name: enable_disable_ctm_step_tool_for_debugging(text, boolean, boolean); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.enable_disable_ctm_step_tool_for_debugging(_tool text DEFAULT ''::text, _debugmode boolean DEFAULT false, _infoonly boolean DEFAULT false) RETURNS TABLE(task text, processor_name public.citext, tool_name public.citext, priority smallint, enabled smallint, comment public.citext, last_affected timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**   Bulk enables or disables a step tool to allow for debugging
**
**  Arguments:
**    _tool             Step tool name
**    _debugMode        True to disable managers (and thus allow for debugging); false to re-enable the managers
**    _infoOnly         View step tools that would be updated
**
**  Auth:   mem
**  Date:   10/29/2013 mem - Initial version
**          04/30/2014 mem - Now validating _tool
**          09/01/2017 mem - Implement functionality of _infoOnly
**          10/11/2022 mem - Ported to PostgreSQL
**          04/02/2023 mem - Rename procedure and functions
**          05/12/2023 mem - Rename variables
**          05/22/2023 mem - Use format() for string concatenation
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/08/2023 mem - Select a single column when using If Not Exists()
**
*****************************************************/
DECLARE
    _updateCount int;
    _updatedRows int := 0;
    _message text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _tool      := Trim(Coalesce(_tool, ''));
    _debugMode := Coalesce(_debugMode, false);
    _infoOnly  := Coalesce(_infoOnly, false);

    If Not Exists (SELECT T.tool_name FROM cap.t_processor_tool T WHERE T.tool_name = _tool) Then
        RAISE INFO 'Tool not found: "%"; cannot continue', _tool;
        RETURN;
    End If;

    If Not _debugMode Then
        -- Disable debugging

        If Not _infoOnly Then
            UPDATE cap.t_processor_tool T
            SET enabled = 1
            WHERE T.tool_name = _tool AND T.enabled < 0 AND T.processor_name <> 'Monroe_CTM';
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            UPDATE cap.t_processor_tool T
            SET enabled = 0
            WHERE T.tool_name = _tool AND T.enabled <> 0 AND T.processor_name = 'Monroe_CTM';
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            If _updatedRows = 0 Then
                _message := format('Debug mode is already disabled for %s', _tool);
            Else
                _message := format('Debug mode disabled for %s; updated %s %s', _tool, _updatedRows, public.check_plural(_updatedRows, 'row', 'rows'));
            End If;

            RETURN QUERY
            SELECT _message AS task,
                   ''::citext AS processor_name,
                   ''::citext AS tool_name,
                   1::smallint AS priority,
                   0::smallint AS enabled,
                   ''::citext AS "comment",
                   CURRENT_TIMESTAMP::timestamp AS last_affected;

        Else
            RETURN QUERY
            SELECT 'Set enabled to 1' AS task, T.processor_name, T.tool_name, T.priority, T.enabled, T.comment, T.last_affected
            FROM cap.t_processor_tool T
            WHERE T.tool_name = _tool AND T.enabled < 0 AND T.processor_name <> 'Monroe_CTM'
            UNION
            SELECT 'Set enabled to 0' AS task, T.processor_name, T.tool_name, T.priority, T.enabled, T.comment, T.last_affected
            FROM cap.t_processor_tool T
            WHERE T.tool_name = _tool AND T.enabled <> 0 AND T.processor_name = 'Monroe_CTM';

            If Not FOUND Then
                RETURN QUERY
                SELECT 'Debug mode is already disabled' AS task, T.processor_name, T.tool_name, T.priority, T.enabled, T.comment, T.last_affected
                FROM cap.t_processor_tool T
                WHERE T.tool_name = _tool and T.enabled > 0;
            End If;
        End If;

    Else
        -- Enable debugging

        If Not _infoOnly Then
            UPDATE cap.t_processor_tool T
            SET enabled = -1
            WHERE T.tool_name = _tool AND T.enabled > 0 AND T.processor_name <> 'Monroe_CTM';
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            UPDATE cap.t_processor_tool t
            SET enabled = 1
            WHERE T.tool_name = _tool AND T.enabled <> 1 AND T.processor_name = 'Monroe_CTM';
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            If _updatedRows = 0 Then
                _message := format('Debug mode is already enabled for %s', _tool);
            Else
                _message := format('Debug mode enabled for %s; updated %s %s', _tool, _updatedRows, public.check_plural(_updatedRows, 'row', 'rows'));
            End If;

            RETURN QUERY
            SELECT _message AS task,
                   ''::citext AS processor_name,
                   ''::citext AS tool_name,
                   1::smallint AS priority,
                   1::smallint AS enabled,
                   ''::citext AS "comment",
                   CURRENT_TIMESTAMP::timestamp AS last_affected;

        Else
            RETURN QUERY
            SELECT 'Set enabled to -1' AS task, T.processor_name, T.tool_name, T.priority, T.enabled, T.comment, T.last_affected
            FROM cap.t_processor_tool T
            WHERE T.tool_name = _tool AND T.enabled > 0 AND T.processor_name <> 'Monroe_CTM'
            UNION
            SELECT 'Set enabled to 1' AS task, T.processor_name, T.tool_name, T.priority, T.enabled, T.comment, T.last_affected
            FROM cap.t_processor_tool T
            WHERE T.tool_name = _tool AND T.enabled <> 1 AND T.processor_name = 'Monroe_CTM';

            If Not FOUND Then
                RETURN QUERY
                SELECT 'Debug mode is already enabled' AS task, T.processor_name, T.tool_name, T.priority, T.enabled, T.comment, T.last_affected
                FROM cap.t_processor_tool T
                WHERE T.tool_name = _tool AND T.enabled > 0;
            End If;
        End If;
    End If;

END
$$;


ALTER FUNCTION cap.enable_disable_ctm_step_tool_for_debugging(_tool text, _debugmode boolean, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION enable_disable_ctm_step_tool_for_debugging(_tool text, _debugmode boolean, _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.enable_disable_ctm_step_tool_for_debugging(_tool text, _debugmode boolean, _infoonly boolean) IS 'EnableDisableStepToolForDebugging';

