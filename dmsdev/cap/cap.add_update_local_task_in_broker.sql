--
-- Name: add_update_local_task_in_broker(integer, text, integer, text, text, text, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.add_update_local_task_in_broker(INOUT _job integer, IN _scriptname text, IN _priority integer, IN _jobparam text, IN _comment text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Edit or reset a capture task job directly in cap.t_tasks
**
**  Arguments:
**    _job              Capture task job
**    _scriptName       Script name (unused by this procedure)
**    _priority         Processing priority (defaults to 4)
**    _jobParam         XML parameters for the job; if an empty string, leave the existing parameters unchanged
**    _comment          Job comment
**    _mode             Mode: 'update' or 'reset' ('add' mode is not supported for capture task jobs)
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user (unused by this procedure)
**
**  Example usage:
**
**      CALL cap.add_update_local_task_in_broker(
**          _job        => 5280268,
**          _scriptname => 'DatasetArchive',
**          _priority   => 4,
**          _jobParam   => '',
**          _comment    => '',
**          _mode       => 'update');
**
**      CALL cap.add_update_local_task_in_broker(
**          _job         => 5280268,
**          _scriptname => 'DatasetArchive',
**          _priority   => 4,
**          _jobParam   => '<Param Section="DatasetQC" Name="ComputeOverallQualityScores" Value="True" /><Param Section="DatasetQC" Name="CreateDatasetInfoFile" Value="True" /><Param Section="DatasetQC" Name="SaveLCMS2DPlots" Value="True" /><Param Section="JobParameters" Name="Dataset" Value="QC_Mam_19_01-run04_19July22_Remus_WBEH-22-05-07" /><Param Section="JobParameters" Name="Dataset_ID" Value="1060934" />',
**          _comment    => '',
**          _mode       => 'update');
**
**  Auth:   grk
**  Date:   11/16/2010 grk - Initial release
**          03/15/2011 dac - Modified to allow updating in HOLD mode
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/08/2016 mem - Include capture task job number in errors raised by RAISERROR
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          08/28/2022 mem - When validating _mode = 'update', use state 3 for complete
**          08/28/2022 mem - Ported to PostgreSQL
**          08/31/2022 mem - Remove unused variables and fix call to local_error_handler
**          09/01/2022 mem - Change default value for _mode and send '<auto>' to get_current_function_info()
**          04/02/2023 mem - Rename procedure and functions
**          04/27/2023 mem - Use boolean for data type name
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          08/25/2023 mem - Use Trim() on procedure arguments
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/11/2023 mem - Customize the column names included in the status message
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

    _logErrors boolean := true;
    _state int;
    _reset boolean := false;
    _updatedColumns text;

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
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        -----------------------------------------------
        -- Validate the inputs
        -----------------------------------------------

        _job        := Coalesce(_job, 0);
        _scriptName := Trim(Coalesce(_scriptName, ''));
        _priority   := Coalesce(_priority, 4);
        _jobParam   := Trim(Coalesce(_jobParam, ''));
        _comment    := Trim(Coalesce(_comment, ''));

        _mode       := Trim(Lower(Coalesce(_mode, '')));

        If _mode = 'reset' Then
            _mode := 'update';
            _reset := true;
        End If;

        ---------------------------------------------------
        -- Does capture task job exist?
        ---------------------------------------------------

        SELECT State
        INTO _state
        FROM cap.t_tasks
        WHERE Job = _job;

        If _mode = 'update' And Not Found Then
            _logErrors := false;
            RAISE EXCEPTION 'Cannot update: capture task job % does not exist', _job;
        End If;

        If _mode = 'update' And Not _state In (1, 3, 5, 100) Then -- new, complete, failed, hold
            _logErrors := false;
            RAISE EXCEPTION 'Cannot update capture task job % in state %; must be 1, 3, 5, or 100', _job, _state;
        End If;

        ---------------------------------------------------
        -- Update mode
        --
        -- Restricted to certain capture task job states and limited to certain fields.
        -- Force reset of capture task?
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Update capture task job and params

            UPDATE cap.t_tasks
            SET priority = _priority ,
                comment = _comment ,
                state = CASE WHEN _reset THEN 20 ELSE state END -- 20=Resuming (update_task_state will handle final task state update)
            WHERE job = _job;

            -- Only update parameters if not an empty string
            If _jobParam = '' Then
                _updatedColumns := CASE WHEN _reset
                                        THEN 'priority, comment, and state'
                                        ELSE 'priority and comment'
                                   END;

                _message := format('Updated %s for capture task job %s; did not update parameters since _jobParam is empty', _updatedColumns, _job);
            Else
                UPDATE cap.t_task_parameters
                SET parameters = _jobParam::XML
                WHERE job = _job;

                _updatedColumns := CASE WHEN _reset
                                        THEN 'priority, comment, state, and parameters'
                                        ELSE 'priority, comment, and parameters'
                                   END;

                _message := format('Updated %s for capture task job %s', _updatedColumns, _job);
            End If;
        End If;

        ---------------------------------------------------
        -- add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            _logErrors := true;
            RAISE EXCEPTION 'Add mode is not supported by this procedure for capture task jobs';

            /*
            CALL cap.make_local_task_in_broker (
                    _scriptName,
                    _priority,
                    _jobParamXML,
                    _comment,
                    _debugMode,
                    _job OUTPUT,
                    _resultsFolderName OUTPUT,
                    _message OUTPUT);
            */
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;


        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE cap.add_update_local_task_in_broker(INOUT _job integer, IN _scriptname text, IN _priority integer, IN _jobparam text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_local_task_in_broker(INOUT _job integer, IN _scriptname text, IN _priority integer, IN _jobparam text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.add_update_local_task_in_broker(INOUT _job integer, IN _scriptname text, IN _priority integer, IN _jobparam text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateLocalTaskInBroker or AddUpdateLocalJobInBroker';

