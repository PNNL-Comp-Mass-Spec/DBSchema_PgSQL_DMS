--
-- Name: make_new_archive_update_task(text, text, boolean, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.make_new_archive_update_task(IN _datasetname text, IN _resultsdirectoryname text DEFAULT ''::text, IN _allowblankresultsdirectory boolean DEFAULT false, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create a new archive update task for the specified dataset and results directory
**
**  Arguments:
**    _datasetName                  Dataset name
**    _resultsdirectoryname         Results directory name
**    _allowBlankResultsDirectory   Set to true if you need to update the dataset file; the downside is that the archive update will involve a byte-to-byte comparison of all data in both the dataset directory and all subdirectories
**    _infoOnly                     True to preview the capture task job that would be created
**    _message                      Status message
**    _returnCode                   Return code
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
**          06/20/2023 mem - Ported to PostgreSQL, removing parameters _pushDatasetToMyEMSL and _pushDatasetRecursive
**          09/07/2023 mem - Align assignment statements
**                         - Update warning messages
**          01/20/2024 mem - Ignore case when resolving dataset name to ID
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetID int;
    _jobID int;
    _script text;

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

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _datasetName                := Trim(Coalesce(_datasetName, ''));
        _resultsDirectoryName       := Trim(Coalesce(_resultsDirectoryName, ''));
        _allowBlankResultsDirectory := Coalesce(_allowBlankResultsDirectory, false);
        _infoOnly                   := Coalesce(_infoOnly, false);

        If _datasetName = '' Then
            _message := 'Dataset name not defined';
            _returnCode := 'U5201';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If _resultsDirectoryName = '' And Not _allowBlankResultsDirectory Then
            _message := 'Results directory name was not specified; to update the dataset file and all subdirectories, set _allowBlankResultsDirectory to true';
            _returnCode := 'U5202';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate this dataset and determine its Dataset_ID
        ---------------------------------------------------

        SELECT dataset_id
        INTO _datasetID
        FROM public.t_dataset
        WHERE dataset = _datasetName::citext;

        If Not FOUND Then
            _message := format('Dataset not found, unable to continue: %s', _datasetName);
            _returnCode := 'U5203';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure a pending archive update task doesn't already exist
        ---------------------------------------------------

        SELECT job
        INTO _jobID
        FROM cap.t_tasks
        WHERE Script = 'ArchiveUpdate' AND
              Dataset_ID = _datasetID AND
              Coalesce(results_folder_name, '') = _resultsDirectoryName AND
              State < 3;

        If FOUND Then
            If _resultsDirectoryName = '' Then
                _message := format('Existing pending ArchiveUpdate job already exists: job %s for %s and directory %s', _jobID, _datasetName, _resultsDirectoryName);
            Else
                _message := format('Existing pending ArchiveUpdate job already exists: job %s for %s', _jobID, _datasetName);
            End If;

            RAISE INFO '%', _message;
            RETURN;
        End If;

        _script := 'ArchiveUpdate';

        ---------------------------------------------------
        -- Create new Archive Update task for specified dataset
        ---------------------------------------------------

        If _infoOnly Then
            _message := format('Would create a new archive update task (%s) for dataset ID %s: %s', _script, _datasetID, _datasetName);

            If _resultsDirectoryName <> '' Then
                _message := format('%s, results folder %s', _message, _resultsDirectoryName);
            End If;

        Else

            INSERT INTO cap.t_tasks (
                script,
                dataset,
                dataset_id,
                results_folder_name,
                comment,
                priority
            )
            SELECT _script AS Script,
                   _datasetName AS Dataset,
                   _datasetID AS Dataset_ID,
                   _resultsDirectoryName AS Results_Folder_Name,
                   'Created manually using make_new_archive_update_task' AS comment,
                   CASE
                       WHEN _resultsDirectoryName = '' THEN 3
                       ELSE 4
                   END AS Priority
            RETURNING job
            INTO _jobID;

            _message := format('Created new archive update task %s for dataset %s', _jobID, _datasetName);

            If _resultsDirectoryName = '' Then
                _message := format('%s and all subdirectories', _message);
            Else
                _message := format('%s and results directory %s', _message, _resultsDirectoryName);
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


ALTER PROCEDURE cap.make_new_archive_update_task(IN _datasetname text, IN _resultsdirectoryname text, IN _allowblankresultsdirectory boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE make_new_archive_update_task(IN _datasetname text, IN _resultsdirectoryname text, IN _allowblankresultsdirectory boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.make_new_archive_update_task(IN _datasetname text, IN _resultsdirectoryname text, IN _allowblankresultsdirectory boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'MakeNewArchiveUpdateTask or MakeNewArchiveUpdateJob';

