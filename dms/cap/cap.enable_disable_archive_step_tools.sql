--
-- Name: enable_disable_archive_step_tools(boolean, text, boolean); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.enable_disable_archive_step_tools(_enable boolean DEFAULT false, _disablecomment text DEFAULT ''::text, _infoonly boolean DEFAULT false) RETURNS TABLE(task text, processor_name public.citext, tool_name public.citext, priority smallint, enabled smallint, comment public.citext, last_affected timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Enables or disables archive and archive update step tools
**
**  Arguments:
**    _enable           True to enable the step tools, false to disable
**    _disableComment   Optional text to add/remove from the Comment field (added if _enable is false, removed if _enable is true)
**    _infoOnly         View step tools that would be updated
**
**  Auth:   mem
**  Date:   05/06/2011 mem - Initial version
**          05/12/2011 mem - Added comment parameter
**          12/16/2013 mem - Added step tools 'ArchiveVerify' and 'ArchiveStatusCheck'
**          12/11/2015 mem - Clearing comments that start with 'Disabled' when _enable = 1
**          12/18/2017 mem - Avoid adding _disableComment to the comment field multiple times
**          10/11/2022 mem - Ported to PostgreSQL
**          05/12/2023 mem - Rename variables
**          05/29/2023 mem - Use format() for string concatenation
**          09/01/2023 mem - Remove unnecessary cast to citext for string constants
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _newState int;
    _oldState int;
    _task text;
    _updateCount int;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------

    _enable         := Coalesce(_enable, false);
    _disableComment := Coalesce(_disableComment, '');
    _infoOnly       := Coalesce(_infoOnly, false);

    If _enable Then
        _newState := 1;
        _oldState := -1;
        _task := 'Enable';
    Else
        _newState := -1;
        _oldState := 1;
        _task := 'Disable';
    End If;

    -----------------------------------------------
    -- Create a temp table to track the tools to update
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_ToolsToUpdate (
        Tool_Name text
    );

    INSERT INTO Tmp_ToolsToUpdate (Tool_Name)
    VALUES ('DatasetArchive'), ('ArchiveUpdate'), ('ArchiveVerify'), ('ArchiveStatusCheck');

    -----------------------------------------------
    -- Preview changes, or perform the work
    -----------------------------------------------

    If _infoOnly Then
        RETURN QUERY
        SELECT _task AS Task,
               ProcTool.processor_name,
               ProcTool.tool_name,
               ProcTool.priority,
               ProcTool.enabled,
               ProcTool.comment,
               ProcTool.last_affected
        FROM cap.t_processor_tool ProcTool
             INNER JOIN Tmp_ToolsToUpdate FilterQ
               ON ProcTool.tool_name = FilterQ.tool_name
        WHERE ProcTool.enabled = _oldState
        ORDER BY ProcTool.processor_name;

        DROP TABLE Tmp_ToolsToUpdate;
        RETURN;
    End If;

    -- Update the Enabled column
    --
    UPDATE cap.t_processor_tool ProcTool
    SET enabled = _newState
    FROM Tmp_ToolsToUpdate FilterQ
    WHERE ProcTool.Tool_Name = FilterQ.Tool_Name AND
          ProcTool.Enabled = _oldState;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount = 0 Then
        RAISE INFO '%', format('Did not find any rows in cap.t_processor_tool with Enabled = %s and Tool_Name = %s',
                                _oldState, 'DatasetArchive, ArchiveUpdate, ArchiveVerify, or ArchiveStatusCheck');
    Else
        RAISE INFO '%', format('Changed Enabled from %s to %s for %s %s in cap.t_processor_tool',
                                _oldState, _newState, _updateCount, public.check_plural(_updateCount, 'row', 'rows'));
    End If;

    If _disableComment <> '' Then
        -- Add or remove _disableComment from the Comment column
        --
        If Not _enable Then
            UPDATE cap.t_processor_tool Proctool
            SET comment = CASE
                              WHEN comment = '' THEN _disableComment
                              ELSE format('%s; %s', comment, _disableComment)
                          END
            FROM Tmp_ToolsToUpdate FilterQ
            WHERE ProcTool.Tool_Name = FilterQ.Tool_Name AND
                  ProcTool.enabled = _newState AND
                  NOT ProcTool.comment LIKE '%' || _disableComment || '%';

        Else

            UPDATE cap.t_processor_tool Proctool
            SET comment = CASE
                              WHEN comment = _disableComment THEN ''
                              ELSE Replace(comment, format('; %s', _disableComment), '')
                          END
            FROM Tmp_ToolsToUpdate FilterQ
            WHERE ProcTool.Tool_Name = FilterQ.Tool_Name AND
                  ProcTool.enabled = _newState;
        End If;
    End If;

    If _disableComment = '' And _enable Then

        UPDATE cap.t_processor_tool ProcTool
        SET comment = ''
        FROM Tmp_ToolsToUpdate FilterQ
        WHERE ProcTool.Tool_Name = FilterQ.Tool_Name AND
              ProcTool.enabled = _newState AND
              ProcTool.comment ILIKE 'Disabled%';

    End If;

    RETURN QUERY
    SELECT _task || 'd' AS Task,
           ProcTool.processor_name,
           ProcTool.tool_name,
           ProcTool.priority,
           ProcTool.enabled,
           ProcTool.comment,
           ProcTool.last_affected
    FROM cap.t_processor_tool ProcTool
         INNER JOIN Tmp_ToolsToUpdate FilterQ
           ON ProcTool.tool_name = FilterQ.tool_name
    WHERE ProcTool.enabled = _newState
    ORDER BY ProcTool.processor_name;

    DROP TABLE Tmp_ToolsToUpdate;

END
$$;


ALTER FUNCTION cap.enable_disable_archive_step_tools(_enable boolean, _disablecomment text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION enable_disable_archive_step_tools(_enable boolean, _disablecomment text, _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.enable_disable_archive_step_tools(_enable boolean, _disablecomment text, _infoonly boolean) IS 'EnableDisableArchiveStepTools';

