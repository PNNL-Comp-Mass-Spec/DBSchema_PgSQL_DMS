--
-- Name: set_ctm_step_task_complete(integer, integer, integer, text, integer, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.set_ctm_step_task_complete(IN _job integer, IN _step integer, IN _completioncode integer, IN _completionmessage text DEFAULT ''::text, IN _evaluationcode integer DEFAULT 0, IN _evaluationmessage text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update capture task job step in cap.t_task_steps
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/30/2009 grk - Made _message an output parameter
**          01/15/2010 grk - Set step state back to enable If retrying
**          05/05/2011 mem - Now leaving Next_Try unchanged If state = 5 (since _completionCode = 0)
**          02/08/2012 mem - Added support for _evaluationCode = 3 when _completionCode = 0
**          09/10/2013 mem - Added support for _evaluationCode being 4, 5, or 6
**          09/11/2013 mem - Now auto-adjusting the holdoff interval for ArchiveVerify capture task job steps
**          09/18/2013 mem - Added support for _evaluationCode = 7 (MyEMSL is already up to date)
**          09/19/2013 mem - Now skipping ArchiveStatusCheck when skipping ArchiveVerify
**          10/16/2013 mem - Now updating Evaluation_Message when skipping the ArchiveVerify step
**          09/24/2014 mem - No longer looking up machine
**          11/03/2013 mem - Added support for _evaluationCode = 8 (failed, do not retry)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/21/2017 mem - Added support for _evaluationCode = 9 (tool skipped)
**          12/04/2017 mem - Rename variables and add logic checks
**          06/14/2018 mem - Call public.post_email_alert if a reporter ion m/z validation error or warning is detected
**          07/30/2018 mem - Include dataset name when calling public.Post_Email_Alert
**          08/09/2018 mem - Expand _completionMessage to varchar(512)
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          08/21/2020 mem - Set _holdoffIntervalMinutes to 60 (or higher) if _retryCount is 0
**          06/11/2023 mem - Ported to PostgreSQL
**          06/14/2023 mem - Send true to post_email_alert instead of 1
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _stepInfo record;
    _newStepState int := 5;
    _myEMSLStateNew int := 0;

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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Get current state of this capture task job step
        ---------------------------------------------------

        SELECT TS.state AS InitialState,
               TS.Processor AS Processor,
               TS.Retry_Count AS RetryCount,
               TS.Holdoff_Interval_Minutes AS HoldoffIntervalMinutes,
               TS.Next_Try AS NextTry,
               TS.Tool AS StepTool,
               TS.Output_Folder_Name AS OutputFolderName,
               T.Dataset_ID AS DatasetID,
               T.Dataset AS DatasetName
        INTO _stepInfo
        FROM cap.t_task_steps TS
             INNER JOIN cap.t_local_processors LP
               ON LP.processor_name = TS.Processor
             INNER JOIN cap.t_tasks T
               ON TS.Job = T.Job
        WHERE TS.Job = _job AND
              TS.Step = _step;

        If Not FOUND Then
            _returnCode := 'U5201';
            _message := format('Empty query results for capture task job %s, step %s when obtaining the current state of the job step using cap.t_task_steps', _job, _step);
            RETURN;
        End If;

        If _stepInfo.InitialState <> 4 Then
            _returnCode := 'U5202';
            _message := format('Capture task job step is not in correct state to be completed; job: %s, step: %s, actual state: %s, expected state: 4',
                                _job, _step, _stepInfo.InitialState);
            RETURN;
        End If;

        ---------------------------------------------------
        -- Determine completion state
        -- Initially assume new state will be 5 (success)
        ---------------------------------------------------

        If _completionCode = 0 And _evaluationCode <> 9 Then
            -- Completed successfully
            _newStepState := 5;
        Else
            -- Either completion code is non-zero, or the step was skipped (eval-code 9)

            If _evaluationCode = 8 Then -- EVAL_CODE_FAILURE_DO_NOT_RETRY Then
                -- Failed
                _newStepState := 6;
                _stepInfo.RetryCount := 0;
            End If;

            If _evaluationCode = 9 Then -- EVAL_CODE_SKIPPED Then
                -- Skipped
                _newStepState := 3;
            End If;

            If Not _newStepState IN (3, 6) And (_stepInfo.RetryCount > 0 Or _evaluationCode = 3) Then
                If _stepInfo.InitialState = 4 Then
                    -- Retry the step
                    _newStepState := 2;
                End If;

                If _stepInfo.RetryCount > 0 Then
                    _stepInfo.RetryCount := _stepInfo.RetryCount - 1; -- decrement retry count
                End If;

                If _evaluationCode = 3 Then
                    -- The captureTaskManager returns 3 (EVAL_CODE_NETWORK_ERROR_RETRY_CAPTURE) when a network error occurs during capture
                    -- Auto-retry the capture again (even if _stepInfo.RetryCount is 0)
                    _stepInfo.NextTry := CURRENT_TIMESTAMP + INTERVAL '15 minutes';
                Else
                    If _stepInfo.StepTool = 'ArchiveVerify' AND _stepInfo.RetryCount > 0 Then
                        _stepInfo.HoldoffIntervalMinutes :=
                            CASE WHEN _stepInfo.HoldoffIntervalMinutes < 5 THEN 5
                                 WHEN _stepInfo.HoldoffIntervalMinutes < 10 THEN 10
                                 WHEN _stepInfo.HoldoffIntervalMinutes < 15 THEN 15
                                 WHEN _stepInfo.HoldoffIntervalMinutes < 30 THEN 30
                                 ELSE _stepInfo.HoldoffIntervalMinutes
                            END;
                    End If;

                    If _stepInfo.RetryCount = 0 AND _stepInfo.HoldoffIntervalMinutes < 60 Then
                        _stepInfo.HoldoffIntervalMinutes := 60;
                    End If;

                    If _newStepState <> 5 Then
                        _stepInfo.NextTry := CURRENT_TIMESTAMP + make_interval(mins => _stepInfo.HoldoffIntervalMinutes);
                    End If;
                End If;

            Else
                If Not _newStepState IN (3, 6) Then
                    -- Failed
                    _newStepState := 6;
                End If;
            End If;
        End If;

        BEGIN

            ---------------------------------------------------
            -- Update capture task job step
            ---------------------------------------------------
            --
            UPDATE cap.t_task_steps
            SET    State = _newStepState,
                   Finish = CURRENT_TIMESTAMP,
                   Completion_Code = _completionCode,
                   Completion_Message = _completionMessage,
                   Evaluation_Code = _evaluationCode,
                   Evaluation_Message = _evaluationMessage,
                   Retry_Count = _stepInfo.RetryCount,
                   Holdoff_Interval_Minutes = _stepInfo.HoldoffIntervalMinutes,
                   Next_Try = _stepInfo.NextTry
            WHERE Job = _job AND
                  Step = _step;

            If _stepInfo.StepTool In ('ArchiveUpdate', 'ArchiveUpdateTest', 'DatasetArchive') AND _evaluationCode IN (6, 7) Then
                -- If _evaluationCode = 6, we copied data to Aurora via FTP but did not upload to MyEMSL
                -- If _evaluationCode = 7, we uploaded data to MyEMSL, but there were no new files to upload, so there is nothing to verify
                -- In either case, skip the ArchiveVerify and ArchiveStatusCheck steps for this capture task job (if they exist)

                UPDATE cap.t_task_steps
                SET State = 3,
                    Completion_Code = 0,
                    Completion_Message = '',
                    Evaluation_Code = 0,
                    Evaluation_Message =
                      CASE
                          WHEN _evaluationCode = 6 THEN 'Skipped since MyEMSL upload was skipped'
                          WHEN _evaluationCode = 7 THEN 'Skipped since MyEMSL files were already up-to-date'
                          ELSE 'Skipped for unknown reason'
                      END
                WHERE Job = _job AND
                      Tool IN ('ArchiveVerify', 'ArchiveStatusCheck') AND
                      NOT State IN (4, 5, 7);

            End If;

        END;

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

    COMMIT;

    BEGIN
        ---------------------------------------------------
        -- Check for reporter ion m/z validation warnings or errors
        ---------------------------------------------------

        If _completionMessage ILike '%Over%of the % spectra have a minimum m/z value larger than the required minimum%' Then
            _message := format('Dataset %s (ID %s): %s',
                                _stepInfo.DatasetName, _stepInfo.DatasetID, _completionMessage);

            CALL public.post_email_alert ('Error', _message, 'Set_CTM_Step_Task_Complete', _recipients => 'admins', _postMessageToLogEntries => true);

        ElsIf _completionMessage ILike '%Some of the % spectra have a minimum m/z value larger than the required minimum%' Or
              _completionMessage ILike '%reporter ion peaks likely could not be detected%' Then

            _message := format('Dataset %s (ID %s): %s',
                                _stepInfo.DatasetName, _stepInfo.DatasetID, _completionMessage);

            CALL public.post_email_alert ('Warning', _message, 'Set_CTM_Step_Task_Complete', _recipients => 'admins', _postMessageToLogEntries => true);
        End If;

        ---------------------------------------------------
        -- Possibly update MyEMSL State values
        ---------------------------------------------------

        If _completionCode = 0 Then

            -- _evaluationCode = 4 means Submitted to MyEMSL
            -- _evaluationCode = 5 means Verified in MyEMSL

            If _stepInfo.StepTool Like '%Archive%' And _evaluationCode IN (4, 5) Then
                -- Update the MyEMSLState values

                If _evaluationCode = 4 Then
                    _myEMSLStateNew := 1;
                End If;

                If _evaluationCode = 5 Then
                    _myEMSLStateNew := 2;
                End If;

                CALL public.update_myemsl_state (_stepInfo.DatasetID, _stepInfo.OutputFolderName, _myEMSLStateNew);

            End If;
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


ALTER PROCEDURE cap.set_ctm_step_task_complete(IN _job integer, IN _step integer, IN _completioncode integer, IN _completionmessage text, IN _evaluationcode integer, IN _evaluationmessage text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_ctm_step_task_complete(IN _job integer, IN _step integer, IN _completioncode integer, IN _completionmessage text, IN _evaluationcode integer, IN _evaluationmessage text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.set_ctm_step_task_complete(IN _job integer, IN _step integer, IN _completioncode integer, IN _completionmessage text, IN _evaluationcode integer, IN _evaluationmessage text, INOUT _message text, INOUT _returncode text) IS 'SetCTMStepTaskComplete or SetStepTaskComplete';

