--
CREATE OR REPLACE PROCEDURE cap.make_new_archive_update_task
(
    _datasetName text,
    _resultsDirectoryName text = '',
    _allowBlankResultsDirectory int = 0,
    _pushDatasetToMyEMSL int = 0,
    _pushDatasetRecursive int = 0,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates a new archive update task for the specified dataset and results directory
**
**  Arguments:
**    _allowBlankResultsDirectory   Set to 1 if you need to update the dataset file; the downside is that the archive update will involve a byte-to-byte comparison of all data in both the dataset directory and all subdirectories
**    _pushDatasetToMyEMSL          Set to 1 to push the dataset to MyEMSL instead of updating the data at \\aurora.emsl.pnl.gov\archive\dmsarch
**    _pushDatasetRecursive         Set to 1 to recursively push a directory and all subdirectories into MyEMSL
**    _infoOnly                     True to preview the capture task job that would be created
**
**  Auth:   mem
**  Date:   05/07/2010 mem - Initial version
**          09/08/2010 mem - Added parameter _allowBlankResultsDirectory
**          05/31/2013 mem - Added parameter _pushDatasetToMyEMSL
**          07/11/2013 mem - Added parameter _pushDatasetRecursive
**          10/24/2014 mem - Changed priority to 2 when _resultsDirectoryName = ''
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/28/2017 mem - Update status messages
**          03/06/2018 mem - Also look for ArchiveUpdate tasks on hold when checking for an existing archive update task
**          05/17/2019 mem - Switch from folder to directory
**          06/27/2019 mem - Default capture task job priority is now 4; higher priority is now 3
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _resultsDirectoryName := Coalesce(_resultsDirectoryName, '');
        _allowBlankResultsDirectory := Coalesce(_allowBlankResultsDirectory, 0);
        _pushDatasetToMyEMSL := Coalesce(_pushDatasetToMyEMSL, 0);
        _pushDatasetRecursive := Coalesce(_pushDatasetRecursive, 0);
        _infoOnly := Coalesce(_infoOnly, false);
        _message := '';

        If _datasetName Is Null Then
            _message := 'Dataset name not defined';
            _returnCode := 'U5201';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If _resultsDirectoryName = '' And _allowBlankResultsDirectory = 0 Then
            _message := 'Results directory name is blank; to update the Dataset file and all subdirectories, set _allowBlankResultsDirectory to 1';
            _returnCode := 'U5202';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate this dataset and determine its Dataset_ID
        ---------------------------------------------------

        SELECT Dataset_ID
        INTO _datasetID
        FROM public.t_dataset
        WHERE dataset = _datasetName;

        If Not FOUND Then
            _message := 'Dataset not found: ' || _datasetName || '; unable to continue';
            _returnCode := 'U5203';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure a pending archive update task doesn't already exist
        ---------------------------------------------------
        --
        _jobID := 0;

        SELECT Job
        INTO _jobID
        FROM cap.t_tasks
        WHERE Script = 'ArchiveUpdate' AND
              Dataset_ID = _datasetID AND
              Coalesce(Results_Folder_Name, '') = _resultsDirectoryName AND
              State In (1,2,4,7);

        If _jobID > 0 Then
            If _resultsDirectoryName = '' Then
                _message := 'Existing pending capture task job already exists for ' || _datasetName || ' and subdirectory ' || _resultsDirectoryName || '; task ' || _jobID::text;
            Else
                _message := 'Existing pending capture task job already exists for ' || _datasetName || '; task ' || _jobID::text;
            End If;

            RAISE INFO '%', _message;
            RETURN;
        End If;

        If _pushDatasetToMyEMSL <> 0 Then
            If _pushDatasetRecursive <> 0 Then
                _script := 'MyEMSLDatasetPushRecursive';
            Else
                _script := 'MyEMSLDatasetPush';
            End If;
        Else
            _script := 'ArchiveUpdate';
        End If;

        ---------------------------------------------------
        -- Create new Archive Update task for specified dataset
        ---------------------------------------------------
        --
        If _infoOnly Then
            _message := format('Would create a new archive update task (%s) for dataset ID %s: %s', _script, _datasetID, _datasetName);

            If _resultsDirectoryName <> '' Then
                _message := format('%s, results folder %s', _message, _resultsDirectoryName);
            End If;

        Else

            INSERT INTO cap.t_tasks( Script,
                                     Dataset,
                                     Dataset_ID,
                                     Results_Folder_Name,
                                     comment,
                                     Priority )
            SELECT _script AS Script,
                   _datasetName AS Dataset,
                   _datasetID AS Dataset_ID,
                   _resultsDirectoryName AS Results_Folder_Name,
                   'Created manually using MakeNewArchiveUpdateJob' AS comment,
                   CASE
                       WHEN _resultsDirectoryName = '' THEN 3
                       ELSE 4
                   END AS Priority
            RETURNING job
            INTO _jobID;

            _message := 'Created capture task job ' || _jobID::text || ' for dataset ' || _datasetName;

            If _resultsDirectoryName = '' Then
                _message := _message || ' and all subdirectories';
            Else
                _message := _message || ' and results directory ' || _resultsDirectoryName;
            End If;

        End If;

        If _message <> '' Then
            RAISE INFO '%', _message;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;
END
$$;

COMMENT ON PROCEDURE cap.make_new_archive_update_task IS 'MakeNewArchiveUpdateJob';
