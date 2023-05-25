--
CREATE OR REPLACE PROCEDURE sw.enable_disable_step_tool_for_debugging
(
    _tool text = '',
    _debugMode boolean = false,
    _groupName text = 'Monroe Development Box',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Bulk enables or disables a step tool to allow for debugging
**
**  Arguments:
**    _debugMode   True to disable on pubs to allow for debugging; false to enable on pubs
**
**  Auth:   mem
**  Date:   10/22/2013 mem - Initial version
**          11/11/2013 mem - Added parameter _groupName
**          11/22/2013 mem - Now validating _tool
**          09/01/2017 mem - Implement functionality of _infoOnly
**          08/26/2021 mem - Auto-change _groupName to the default value if an empty string
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _updatedRows int := 0;
    _matchCount int;
    _groupID int;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _tool := Coalesce(_tool, '');
    _debugMode := Coalesce(_debugMode, false);
    _groupName := Coalesce(_groupName, '');
    _infoOnly := Coalesce(_infoOnly, false);

    If _groupName = '' Then
        _groupName := 'Monroe Development Box';
    End If;

    SELECT group_id
    INTO _groupID
    FROM sw.t_processor_tool_groups
    WHERE group_name = _groupName;

    If Not FOUND Then
        RAISE INFO 'Group not found: "%"; cannot continue', _groupName;
        RETURN;
    End If;

    If Not Exists (SELECT * FROM sw.t_processor_tool_group_details WHERE tool_name = _tool) Then
        RAISE INFO 'Tool not found: "%"; cannot continue', _tool;
        RETURN;
    End If;

    If Not _debugMode Then

        -- Disable debugging

        If Not _infoOnly Then
            UPDATE sw.t_processor_tool_group_details
            SET enabled = 1
            WHERE tool_name = _tool AND enabled < 0 AND group_id <> _groupID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            UPDATE sw.t_processor_tool_group_details
            SET enabled = 0
            WHERE tool_name = _tool AND enabled <> 0 AND group_id = _groupID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            If _updatedRows = 0 Then
                RAISE INFO 'Debug mode is already disabled for %', _tool;
            Else
                RAISE INFO 'Debug mode disabled for %; updated % rows', _tool, _updatedRows;
            End If;
        Else
            -- ToDo: Convert this to use RAISE INFO

            _matchCount := 0;

            SELECT 'Set enabled to 1' as Action, *
            FROM sw.t_processor_tool_group_details
            WHERE tool_name = _tool AND enabled < 0 AND group_id <> _groupID
            UNION
            SELECT 'Set enabled to 0' as Action, *
            FROM sw.t_processor_tool_group_details
            WHERE tool_name = _tool AND enabled <> 0 AND group_id = _groupID;

            If _matchCount = 0 Then
                SELECT 'Debug mode is already disabled' AS Comment, *
                FROM sw.t_processor_tool_group_details
                WHERE tool_name = _tool AND enabled > 0;
            End If;
        End If;

    Else

        -- Enable debugging

        If Not _infoOnly Then
            UPDATE sw.t_processor_tool_group_details
            SET enabled = -1
            WHERE tool_name = _tool AND enabled > 0 AND group_id <> _groupID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            UPDATE sw.t_processor_tool_group_details
            SET enabled = 1
            WHERE tool_name = _tool AND enabled <> 1 AND group_id = _groupID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _updatedRows := _updatedRows + _updateCount;

            If _updatedRows = 0 Then
                RAISE INFO 'Debug mode is already enabled for %', _tool;
            Else
                RAISE INFO 'Debug mode enabled for %; updated % rows', _tool, _updatedRows;
            End If;
        Else
            -- Convert this to use RAISE INFO

            SELECT 'Set enabled to -1' as Action, *
            FROM sw.t_processor_tool_group_details
            WHERE tool_name = _tool AND enabled > 0 AND group_id <> _groupID
            UNION
            SELECT 'Set enabled to 1' as Action, *
            FROM sw.t_processor_tool_group_details
            WHERE tool_name = _tool AND enabled <> 1 AND group_id = _groupID;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _matchCount = 0 Then
                SELECT 'Debug mode is already enabled' AS Comment, *
                FROM sw.t_processor_tool_group_details
                WHERE tool_name = _tool AND enabled > 0;
            End If;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.enable_disable_step_tool_for_debugging IS 'EnableDisableStepToolForDebugging';
