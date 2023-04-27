--
CREATE OR REPLACE PROCEDURE public.add_update_analysis_job_processors
(
    INOUT _id int,
    _state text,
    _processorName text,
    _machine text,
    _notes text,
    _analysisToolsList text,
    _mode text = 'add',
    INOUT _message text = '',
    INOUT _returnCode text = '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing T_Analysis_Job_Processors
**
**  Arguments:
**    _mode   'add' or 'update'
**
**  Auth:   grk
**  Date:   02/15/2007 (ticket 389)
**          02/23/2007 grk - added _analysisToolsList stuff
**          03/15/2007 mem - Tweaked invalid tool name error message
**          02/13/2008 mem - Now assuring that _analysisToolsList results in a non-redundant list of analysis tool names (Ticket #643)
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will populate field Entered_By with this name
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _tmp int;
    _transName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Create temporary table to hold list of analysis tools
    ---------------------------------------------------

    CREATE TEMP TABLE TD (
        ToolName text,
        ToolID int null
    );

    ---------------------------------------------------
    -- Populate table from dataset list
    ---------------------------------------------------
    --
    INSERT INTO Tmp_DatasetInfo (ToolName)
    SELECT DISTINCT Item
    FROM public.parse_delimited_list(_analysisToolsList);

    ---------------------------------------------------
    -- Get tool ID for each tool in temp table
    ---------------------------------------------------
    --
    UPDATE T
    SET T.ToolID = analysis_tool_id
    FROM Tmp_DatasetInfo T INNER JOIN
         t_analysis_tool ON T.ToolName = analysis_tool;

    ---------------------------------------------------
    -- Any invalid tool names?
    ---------------------------------------------------

    If Exists (SELECT COUNT(*) FROM Tmp_DatasetInfo WHERE ToolID Is Null) Then
        SELECT ToolName
        INTO _message
        FROM Tmp_DatasetInfo
        WHERE ToolID is null
        LIMIT 1;

        _message := 'Invalid tool name: ' || Coalesce(_message, '??');
        RAISE WARNING '%', _message;

        _returnCode := 'U5208';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Cannot update a non-existent entry
        --
        SELECT processor_id
        INTO _tmp
        FROM  t_analysis_job_processors
        WHERE processor_id = _id;

        If Not FOUND Then
            _message := 'Cannot update processor ID ' || _id::text || '; existing entry not found in the database';
             RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Set up transaction name
    ---------------------------------------------------
    _transName := 'AddUpdateAnalysisJobProcessors';

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    If _mode = 'add' Then
        ---------------------------------------------------
        -- Start transaction
        --
        begin transaction _transName

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
        If char_length(_callingUser) > 0 Then
            Call alter_entered_by_user ('t_analysis_job_processors', 'processor_id', _id, _callingUser, _entryDateColumnName => 'last_affected');
        End If;

    End If; -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If _mode = 'update' Then

        ---------------------------------------------------
        -- Start transaction
        --
        begin transaction _transName

        UPDATE t_analysis_job_processors
        SET
            state = _state,
            processor_name = _processorName,
            machine = _machine,
            notes = _notes
        WHERE (processor_id = _id)

        -- If _callingUser is defined, update entered_by in t_analysis_job_processors
        If char_length(_callingUser) > 0 Then
            Call alter_entered_by_user ('t_analysis_job_processors', 'processor_id', _id, _callingUser, _entryDateColumnName => 'last_affected');
        End If;

    End If; -- update mode

    ---------------------------------------------------
    -- Action for both modes
    ---------------------------------------------------

    If _mode = 'add' or _mode = 'update' Then
        ---------------------------------------------------
        -- Remove any references to tools that are not in the list
        --
        DELETE FROM t_analysis_job_processor_tools
        WHERE processor_id = _id AND NOT tool_id IN (SELECT ToolID FROM Tmp_DatasetInfo);

        ---------------------------------------------------
        -- Add references to tools that are in the list, but not in the table
        --
        INSERT INTO t_analysis_job_processor_tools (tool_id, processor_id)
        SELECT ToolID, _id
        FROM Tmp_DatasetInfo
        WHERE NOT ToolID IN
            (
                SELECT tool_id
                FROM t_analysis_job_processor_tools
                WHERE (processor_id = _id)
            )

        -- If _callingUser is defined, update entered_by in t_analysis_job_processor_tools
        If char_length(_callingUser) > 0 Then
            Call alter_entered_by_user ('t_analysis_job_processor_tools', 'processor_id', _id, _callingUser);
        End If;

    End If; -- add or update mode

    DROP TABLE TD;
END
$$;

COMMENT ON PROCEDURE public.add_update_analysis_job_processors IS 'AddUpdateAnalysisJobProcessors';
