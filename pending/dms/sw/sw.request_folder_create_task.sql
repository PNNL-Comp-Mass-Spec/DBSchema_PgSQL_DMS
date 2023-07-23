--
CREATE OR REPLACE PROCEDURE sw.request_folder_create_task
(
    _processorName text,
    INOUT _taskID int = 0,
    INOUT _parameters text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _taskCountToPreview int = 10
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns first available entry in T_Data_Folder_Create_Queue
**
**  Example XML parameters returned in _parameters:
**      <root>
**      <package>264</package>
**      <Path_Local_Root>F:\DataPkgs</Path_Local_Root>
**      <Path_Shared_Root>\\protoapps\DataPkgs\</Path_Shared_Root>
**      <Path_Folder>2011\Public\264_PNWRCE_Dengue_iTRAQ</Path_Folder>
**      <cmd>add</cmd>
**      <Source_DB>DMS_Data_Package</Source_DB>
**      <Source_Table>T_Data_Package</Source_Table>
**      </root>
**
**  Arguments:
**    _processorName        Name of the processor requesting a task
**    _taskID               TaskID assigned; 0 if no task available
**    _parameters           Task parameters (in XML)
**    _message              Output message
**    _returnCode           Return code
**    _infoOnly             Set to true to preview the task that would be returned
**    _taskCountToPreview   The number of tasks to preview when _infoOnly is true
**
**  Auth:   mem
**  Date:   03/17/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _taskAssigned boolean
    _taskNotAvailableErrorCode int;

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

    _processorName := Coalesce(_processorName, '');
    _taskID := 0;
    _parameters := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _taskCountToPreview := Coalesce(_taskCountToPreview, 10);

    ---------------------------------------------------
    -- The analysis manager expects a non-zero
    -- return value if no tasks are available
    -- Code 'U53000' is used for this
    ---------------------------------------------------

    _taskNotAvailableErrorCode := 53000;

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
        -- <Param package="4898" path_local_root="E:\DataPkgs" path_shared_root="\\protoapps\DataPkgs\" path_folder="Public\2023\4898_Agilent_tune_files_acquired_on_20May2021" cmd="add" source_db="DMS_Data_Package" source_table="T_Data_Package"/>
        ---------------------------------------------------

        SELECT xml_item
        INTO _xmlParameters
        FROM ( SELECT
                 XMLAGG(XMLELEMENT(
                        NAME "Param",
                        XMLATTRIBUTES(
                            source_id As "package",
                            path_local_root As "path_local_root",
                            path_shared_root As "path_shared_root",
                            path_folder As "path_folder",
                            command As "cmd",
                            source_db As "source_db",
                            source_table As "source_table"))
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

        _returnCode := format('U%s', _taskNotAvailableErrorCode);
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
                   Source_Table
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

COMMENT ON PROCEDURE sw.request_folder_create_task IS 'RequestFolderCreateTask';
