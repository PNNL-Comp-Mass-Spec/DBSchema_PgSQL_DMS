--
-- Name: add_update_analysis_job_processors(integer, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_analysis_job_processors(INOUT _id integer, IN _state text, IN _processorname text, IN _machine text, IN _notes text, IN _analysistoolslist text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing analysis job processor
**
**  Arguments:
**    _id                   Processor ID in t_analysis_job_processors
**    _state                State
**    _processorName        Processor name
**    _machine              Machine
**    _notes                Notes
**    _analysisToolsList    Comma-separated list of analysis tools
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Auth:   grk
**  Date:   02/15/2007 (ticket 389)
**          02/23/2007 grk - Added _analysisToolsList stuff
**          03/15/2007 mem - Tweaked invalid tool name error message
**          02/13/2008 mem - Now assuring that _analysisToolsList results in a non-redundant list of analysis tool names (Ticket #643)
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will populate field Entered_By with this name
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/18/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning message
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _state             := Trim(Upper(Coalesce(_state, '')));
    _processorName     := Trim(Coalesce(_processorName, ''));
    _machine           := Trim(Coalesce(_machine, ''));
    _notes             := Trim(Coalesce(_notes, ''));
    _analysisToolsList := Trim(Coalesce(_analysisToolsList, ''));
    _mode              := Trim(Lower(Coalesce(_mode, '')));

    If Not _state IN ('D', 'E') Then
        _message := 'State must be "D" or "E" (for disabled or enabled)';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _processorName = '' Then
        _message := 'Processor name cannot be an empty string';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If _machine = '' Then
        _message := 'Machine cannot be an empty string';
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If Not _mode IN ('add', 'update') Then
        _message := format('Invalid mode "%s"; the only supported modes are add or update', _mode);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create temporary table to hold list of analysis tools
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_AnalysisTools (
        ToolName citext,
        ToolID int NULL
    );

    ---------------------------------------------------
    -- Populate table from tool list
    ---------------------------------------------------

    INSERT INTO Tmp_AnalysisTools (ToolName)
    SELECT DISTINCT Value
    FROM public.parse_delimited_list(_analysisToolsList);

    ---------------------------------------------------
    -- Get tool ID for each tool in temp table
    ---------------------------------------------------

    UPDATE Tmp_AnalysisTools Target
    SET ToolID = analysis_tool_id
    FROM t_analysis_tool AnTool
    WHERE Target.ToolName = AnTool.analysis_tool;

    ---------------------------------------------------
    -- Any invalid tool names?
    ---------------------------------------------------

    If Exists (SELECT ToolName FROM Tmp_AnalysisTools WHERE ToolID IS NULL) Then
        SELECT string_agg(ToolName, ', ' ORDER BY ToolName)
        INTO _message
        FROM Tmp_AnalysisTools
        WHERE ToolID IS NULL;

        _message := format('Invalid tool %s: %s',
                                CASE WHEN Position(',' In _message) > 0
                                     THEN 'names'
                                     ELSE 'name'
                                END,
                                Coalesce(_message, '??'));
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    If _mode = 'add' And Exists (SELECT processor_id FROM t_analysis_job_processors WHERE processor_name = _processorName::citext) Then
        _message := format('Cannot add processor %s since it already exists', _processorName);
         RAISE WARNING '%', _message;

        _returnCode := 'U5206';

        DROP TABLE Tmp_AnalysisTools;
        RETURN;
    End If;

    If _mode = 'update' And Not Exists (SELECT processor_id FROM t_analysis_job_processors WHERE processor_id = _id) Then
        _message := format('Cannot update processor ID %s since it does not exist', _id);
         RAISE WARNING '%', _message;

        _returnCode := 'U5207';

        DROP TABLE Tmp_AnalysisTools;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO t_analysis_job_processors (
            state,
            processor_name,
            machine,
            notes
        ) VALUES (
            _state,
            _processorName,
            _machine,
            _notes
        )
        RETURNING processor_id
        INTO _id;

        -- If _callingUser is defined, update entered_by in t_analysis_job_processors
        If Trim(Coalesce(_callingUser)) <> '' Then
            CALL public.alter_entered_by_user ('public', 't_analysis_job_processors', 'processor_id', _id, _callingUser, _entryDateColumnName => 'last_affected', _message => _alterEnteredByMessage);
        End If;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_analysis_job_processors
        SET state          = _state,
            processor_name = _processorName,
            machine        = _machine,
            notes          = _notes
        WHERE processor_id = _id;

        -- If _callingUser is defined, update entered_by in t_analysis_job_processors
        If Trim(Coalesce(_callingUser)) <> '' Then
            CALL public.alter_entered_by_user ('public', 't_analysis_job_processors', 'processor_id', _id, _callingUser, _entryDateColumnName => 'last_affected', _message => _alterEnteredByMessage);
        End If;

    End If;

    ---------------------------------------------------
    -- Action for both modes
    ---------------------------------------------------

    If _mode = 'add' or _mode = 'update' Then

        ---------------------------------------------------
        -- Remove any references to tools that are not in the list
        ---------------------------------------------------

        DELETE FROM t_analysis_job_processor_tools
        WHERE processor_id = _id AND NOT tool_id IN (SELECT ToolID FROM Tmp_AnalysisTools);

        ---------------------------------------------------
        -- Add references to tools that are in the list, but not in the table
        ---------------------------------------------------

        INSERT INTO t_analysis_job_processor_tools (tool_id, processor_id)
        SELECT ToolID, _id
        FROM Tmp_AnalysisTools
        WHERE NOT ToolID IN
            (
                SELECT tool_id
                FROM t_analysis_job_processor_tools
                WHERE processor_id = _id
            );

        -- If _callingUser is defined, update entered_by in t_analysis_job_processor_tools
        If Trim(Coalesce(_callingUser)) <> '' Then
            CALL public.alter_entered_by_user ('public', 't_analysis_job_processor_tools', 'processor_id', _id, _callingUser, _message => _alterEnteredByMessage);
        End If;

    End If;

    DROP TABLE Tmp_AnalysisTools;
END
$$;


ALTER PROCEDURE public.add_update_analysis_job_processors(INOUT _id integer, IN _state text, IN _processorname text, IN _machine text, IN _notes text, IN _analysistoolslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_analysis_job_processors(INOUT _id integer, IN _state text, IN _processorname text, IN _machine text, IN _notes text, IN _analysistoolslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_analysis_job_processors(INOUT _id integer, IN _state text, IN _processorname text, IN _machine text, IN _notes text, IN _analysistoolslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateAnalysisJobProcessors';

