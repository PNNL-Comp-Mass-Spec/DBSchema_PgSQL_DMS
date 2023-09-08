--
-- Name: request_folder_create_task(text, integer, text, text, text, boolean, integer); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.request_folder_create_task(IN _processorname text, INOUT _taskid integer DEFAULT 0, INOUT _parameters text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _taskcounttopreview integer DEFAULT 10)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns first available entry in sw.t_data_folder_create_queue
**
**  Example XML parameters returned in _parameters:
**      <root>
**        <package>4893</package>
**        <Path_Local_Root>E:\DataPkgs</Path_Local_Root>
**        <Path_Shared_Root>\\protoapps\DataPkgs\</Path_Shared_Root>
**        <Path_Folder>Public\2023\4893_51920_PhoHet_metabolites</Path_Folder>
**        <cmd>add</cmd>
**        <Source_DB>DMS_Data_Package</Source_DB>
**        <Source_Table>T_Data_Package</Source_Table>
**      </root>
**
**  Arguments:
**    _processorName        Name of the processor requesting a task
**    _taskID               TaskID assigned; 0 if no task available
**    _parameters           Task parameters (as XML)
**    _message              Status message
**    _returnCode           Return code
**    _infoOnly             When true, preview the task that would be returned
**    _taskCountToPreview   The number of tasks to preview when _infoOnly is true
**
**  Auth:   mem
**  Date:   03/17/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/09/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _taskAssigned boolean;
    _taskNotAvailableErrorCode text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _taskAssigned := false;

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs; clear the outputs
    ---------------------------------------------------

    _processorName      := Coalesce(_processorName, '');
    _taskID             := 0;
    _parameters         := '';
    _infoOnly           := Coalesce(_infoOnly, false);
    _taskCountToPreview := Coalesce(_taskCountToPreview, 10);

    ---------------------------------------------------
    -- The Package Folder Create Manager expects a non-zero
    -- return value if no tasks are available
    -- Code 'U53000' is used for this
    ---------------------------------------------------

    _taskNotAvailableErrorCode := 'U53000';

    BEGIN

        ---------------------------------------------------
        -- Get first available task from sw.t_data_folder_create_queue
        ---------------------------------------------------

        SELECT entry_id
        INTO _taskID
        FROM sw.t_data_folder_create_queue
        WHERE state = 1
        ORDER BY entry_id
        LIMIT 1;

        If FOUND Then
            _taskAssigned := true;
        End If;

        ---------------------------------------------------
        -- If a task step was found (_taskID <> 0) and if _infoOnly is false,
        -- update the step state to Running
        ---------------------------------------------------

        If _taskAssigned AND Not _infoOnly Then
            UPDATE sw.t_data_folder_create_queue
            SET state = 2,
                processor = _processorName,
                start = CURRENT_TIMESTAMP,
                finish = Null
            WHERE entry_id = _taskID;

        End If;

    END;

    COMMIT;

    If _taskAssigned Then

        ---------------------------------------------------
        -- Task was assigned; return parameters in XML format
        --
        -- Example XML:
        -- <root>
        --   <package>4893</package>
        --   <Path_Local_Root>E:\DataPkgs</Path_Local_Root>
        --   <Path_Shared_Root>\\protoapps\DataPkgs\</Path_Shared_Root>
        --   <Path_Folder>Public\2023\4893_51920_PhoHet_metabolites</Path_Folder>
        --   <cmd>add</cmd>
        --   <Source_DB>DMS_Data_Package</Source_DB>
        --   <Source_Table>T_Data_Package</Source_Table>
        -- </root>
        ---------------------------------------------------

        SELECT xml_item::text
        INTO _parameters
        FROM ( SELECT
                XMLELEMENT(name "root",
                   XMLELEMENT(name "package", source_id),
                   XMLELEMENT(name "Path_Local_Root", path_local_root),
                   XMLELEMENT(name "Path_Shared_Root", path_shared_root),
                   XMLELEMENT(name "Path_Folder", path_folder),
                   XMLELEMENT(name "cmd", command),
                   XMLELEMENT(name "Source_DB", source_db),
                   XMLELEMENT(name "Source_Table", source_table)
                        ) AS xml_item
               FROM sw.t_data_folder_create_queue
               WHERE entry_id = _taskID
            ) AS LookupQ;

        If _infoOnly And char_length(_message) = 0 Then
            _message := format('Task %s would be assigned to %s', _taskID, _processorName);
        End If;
    Else
        ---------------------------------------------------
        -- No task step found; update _returnCode and _message
        --
        -- _returnCode will be 'U53000'
        ---------------------------------------------------

        _returnCode := _taskNotAvailableErrorCode;
        _message := 'No available tasks';

    End If;

    ---------------------------------------------------
    -- Dump candidate list if in infoOnly mode
    ---------------------------------------------------

    If _infoOnly Then

        -- Preview the next _taskCountToPreview available tasks

        RAISE INFO '';

        _formatSpecifier := '%-16s %-14s %-9s %-9s %-15s %-50s %-130s %-7s';

        _infoHead := format(_formatSpecifier,
                            'Source_DB',
                            'Source_Table',
                            'Entry_ID',
                            'Source_ID',
                            'Path_Local_Root',
                            'Path_Shared_Root',
                            'Path_Folder',
                            'Command'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------------',
                                     '--------------',
                                     '---------',
                                     '---------',
                                     '---------------',
                                     '--------------------------------------------------',
                                     '----------------------------------------------------------------------------------------------------------------------------------',
                                     '-------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Source_DB,
                   Source_Table,
                   Entry_ID,
                   Source_ID,
                   Path_Local_Root,
                   Path_Shared_Root,
                   Path_Folder,
                   Command
            FROM sw.t_data_folder_create_queue
            WHERE state = 1
            ORDER BY entry_id
            LIMIT _taskCountToPreview
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Source_DB,
                                _previewData.Source_Table,
                                _previewData.Entry_ID,
                                _previewData.Source_ID,
                                _previewData.Path_Local_Root,
                                _previewData.Path_Shared_Root,
                                _previewData.Path_Folder,
                                _previewData.Command
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

END
$$;


ALTER PROCEDURE sw.request_folder_create_task(IN _processorname text, INOUT _taskid integer, INOUT _parameters text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _taskcounttopreview integer) OWNER TO d3l243;

--
-- Name: PROCEDURE request_folder_create_task(IN _processorname text, INOUT _taskid integer, INOUT _parameters text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _taskcounttopreview integer); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.request_folder_create_task(IN _processorname text, INOUT _taskid integer, INOUT _parameters text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _taskcounttopreview integer) IS 'RequestFolderCreateTask';

