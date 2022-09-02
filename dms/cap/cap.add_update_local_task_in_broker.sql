--
-- Name: add_update_local_task_in_broker(integer, text, integer, text, text, text, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.add_update_local_task_in_broker(INOUT _job integer, IN _scriptname text, IN _priority integer, IN _jobparam text, IN _comment text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Edit or reset a capture task job directly in broker database
**
**  Arguments:
**    _mode     'update' or 'reset' ('add' mode is not supported for capture task jobs)
**
**  Example usage:
**
**      Call cap.add_update_local_task_in_broker(
**          5280268, 'DatasetArchive', 4,
**          _jobParam => '',
**          _comment => '',
**          _mode => 'update');
**
**      Call cap.add_update_local_task_in_broker(
**          5280268, 'DatasetArchive', 4,
**          '<Param Section="DatasetQC" Name="ComputeOverallQualityScores" Value="True" /><Param Section="DatasetQC" Name="CreateDatasetInfoFile" Value="True" /><Param Section="DatasetQC" Name="SaveLCMS2DPlots" Value="True" /><Param Section="JobParameters" Name="Dataset" Value="QC_Mam_19_01-run04_19July22_Remus_WBEH-22-05-07" /><Param Section="JobParameters" Name="Dataset_ID" Value="1060934" />',
**          _comment => '',
**          _mode => 'update');
**
**  Auth:   grk
**  Date:   11/16/2010 grk - Initial release
**          03/15/2011 dac - Modified to allow updating in HOLD mode
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/08/2016 mem - Include capture task job number in errors raised by RAISERROR
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          08/28/2022 mem - Ported to PostgreSQL
**          08/31/2022 mem - Remove unused variables and fix call to local_error_handler
**          09/01/2022 mem - Change default value for _mode and send '<auto>' to get_current_function_info()
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized bool;
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;

    _logErrors bool := true;
    _state int;
    _reset bool := false;
BEGIN

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
        -----------------------------------------------
        -- Validate the inputs
        -----------------------------------------------

        _job := Coalesce(_job, 0);
        _scriptName := Coalesce(_scriptName, '');
        _priority := Coalesce(_priority, 4);
        _jobParam := Coalesce(_jobParam, '');
        _comment := Coalesce(_comment, '');

        _mode := Lower(Coalesce(_mode, ''));

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

        If _mode = 'update' AND Not Found Then
            _logErrors := false;
            RAISE EXCEPTION 'Cannot update nonexistent capture task job: %', _job;
        End If;

        If _mode = 'update' AND NOT _state IN (1, 3, 5, 100) Then -- new, complete, failed, hold
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
            --
            UPDATE  cap.t_tasks
            SET     priority = _priority ,
                    comment = _comment ,
                    state = CASE WHEN _reset THEN 20 ELSE state END -- 20=resuming (update_job_state will handle final task state update)
            WHERE   job = _job;

            -- Only update parameters if not an empty string
            If char_length(_jobParam) = 0 Then
                _message := format('Updated priority, comment, and state for capture task job %s; did not update parameters since _jobParam is empty', _job);
            Else
                UPDATE  cap.t_task_parameters
                SET     parameters = _jobParam::XML
                WHERE   job = _job;

                _message := format('Updated priority, comment, state, and parameters for capture task job %s', _job);
            End If;
        End If;

        ---------------------------------------------------
        -- add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            _logErrors := true;
            RAISE EXCEPTION 'Add mode is not implemented in this procedure for capture task jobs';

            /*
            Call cap.make_local_task_in_broker (
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

COMMENT ON PROCEDURE cap.add_update_local_task_in_broker(INOUT _job integer, IN _scriptname text, IN _priority integer, IN _jobparam text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateLocalJobInBroker';

