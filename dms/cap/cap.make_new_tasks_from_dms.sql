--
-- Name: make_new_tasks_from_dms(text, text, boolean, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.make_new_tasks_from_dms(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _loggingenabled boolean DEFAULT false, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add dataset capture task jobs for datasets in state New in public.t_dataset
**
**  Arguments:
**    _message              Status message
**    _returnCode           Return code
**    _loggingEnabled       Set to true to enable progress logging
**    _infoOnly             True to preview changes that would be made
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          02/10/2010 dac - Removed comment stating that capture task jobs were created from test script
**          03/09/2011 grk - Added logic to choose different capture script based on instrument group
**          09/17/2015 mem - Added parameter _infoOnly
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/27/2019 mem - Use get_dataset_capture_priority to determine capture capture task jobs priority using dataset name and instrument group
**          06/20/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _statusMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

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

        _infoOnly       := Coalesce(_infoOnly, false);
        _loggingEnabled := Coalesce(_loggingEnabled, false);

        If _loggingEnabled Then
            _statusMessage := 'Entering make_new_tasks_from_dms';
            CALL public.post_log_entry ('Progress', _statusMessage, 'Make_New_Tasks_From_DMS', 'cap');
        End If;

        ---------------------------------------------------
        -- Add new capture task jobs
        ---------------------------------------------------

        If Not _infoOnly Then

            INSERT INTO cap.t_tasks (
                script,
                comment,
                dataset,
                dataset_id,
                priority
            )
            SELECT CASE
                       WHEN Src.Instrument_Group = 'IMS' THEN 'IMSDatasetCapture'
                       ELSE 'DatasetCapture'
                   END AS script,
                   '' AS comment,
                   Src.dataset,
                   Src.dataset_id,
                   cap.get_dataset_capture_priority(Src.Dataset, Src.Instrument_Group) AS priority
            FROM cap.V_DMS_Get_New_Datasets Src
                 LEFT OUTER JOIN cap.t_tasks Target
                   ON Src.dataset_id = Target.dataset_id
            WHERE Target.dataset_id IS NULL;

        Else
            RAISE INFO '';

            _formatSpecifier := '%-20s %-10s %-8s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Script',
                                'Dataset_ID',
                                'Priority',
                                'Dataset'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------',
                                         '----------',
                                         '--------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT CASE
                           WHEN Src.Instrument_Group = 'IMS' THEN 'IMSDatasetCapture'
                           ELSE 'DatasetCapture'
                       END AS Script,
                       Src.Dataset_ID,
                       cap.get_dataset_capture_priority(Src.Dataset, Src.Instrument_Group) AS Priority,
                       Src.Dataset
                FROM cap.V_DMS_Get_New_Datasets Src
                     LEFT OUTER JOIN cap.t_tasks Target
                       ON Src.Dataset_ID = Target.Dataset_ID
                WHERE Target.Dataset_ID IS NULL
                ORDER BY dataset_id
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Script,
                                    _previewData.Dataset_ID,
                                    _previewData.Priority,
                                    _previewData.Dataset
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        If _loggingEnabled Then
            _statusMessage := 'Exiting';
            CALL public.post_log_entry ('Progress', _statusMessage, 'Make_New_Tasks_From_DMS', 'cap');
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


ALTER PROCEDURE cap.make_new_tasks_from_dms(INOUT _message text, INOUT _returncode text, IN _loggingenabled boolean, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE make_new_tasks_from_dms(INOUT _message text, INOUT _returncode text, IN _loggingenabled boolean, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.make_new_tasks_from_dms(INOUT _message text, INOUT _returncode text, IN _loggingenabled boolean, IN _infoonly boolean) IS 'MakeNewTasksFromDMS or MakeNewJobsFromDMS';

