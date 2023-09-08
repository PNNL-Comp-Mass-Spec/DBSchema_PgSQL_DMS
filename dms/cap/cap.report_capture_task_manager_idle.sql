--
-- Name: report_capture_task_manager_idle(text, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.report_capture_task_manager_idle(IN _managername text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Assure that no running capture task job steps are associated with the given manager
**
**      Used by the Capture Task Manager if a database error occurs while requesting a new capture task job step
**      For example, a deadlock error, which can leave a capture task job step in state 4 and
**      associated with a manager, even though the manager isn't actually running the job step
**
**  Auth:   mem
**  Date:   08/01/2017 mem - Initial release
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          06/22/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _job text;
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
        -- Validate the inputs
        ---------------------------------------------------

        _managerName := Trim(Coalesce(_managerName, ''));
        _infoOnly    := Coalesce(_infoOnly, false);

        If _managerName = '' Then
            _message := 'Manager name cannot be empty';
            _returnCode := 'U5201';
            RETURN;
        End If;

        If Not Exists (SELECT * FROM cap.t_local_processors WHERE processor_name = _managerName::citext) Then
            _message := format('Manager not found in cap.t_local_processors: %s', _managerName);
            _returnCode := 'U5202';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Look for running step tasks associated with this manager
        ---------------------------------------------------

        -- There should, under normal circumstances, only be one active capture task job step (if any) for this manager

        -- If there are multiple job steps, _job will only track one of the capture task jobs,
        -- but the update query below will reset all of the associated steps

        SELECT Job
        INTO _job
        FROM cap.t_task_steps
        WHERE Processor = _managerName::citext AND State = 4
        LIMIT 1;

        If Not FOUND Then
            _message := format('No active capture task job steps are associated with manager %s', _managerName);

            If _infoOnly Then
                RAISE INFO '';
                RAISE INFO '%', _message;
            End If;

            RETURN;
        End If;

        If _infoOnly Then
            -- Preview the running tasks

            RAISE INFO '';

            _formatSpecifier := '%-10s %-10s %-5s %-20s %-20s %-10s %-15s %-20s %-15s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Dataset_ID',
                                'Step',
                                'Script',
                                'Tool',
                                'State',
                                'Processor',
                                'Start',
                                'Runtime_minutes',
                                'Dataset'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '----------',
                                         '-----',
                                         '--------------------',
                                         '--------------------',
                                         '----------',
                                         '---------------',
                                         '--------------------',
                                         '---------------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT job, dataset_id, step, script, tool, state_name,
                       processor, timestamp_text(start) As start, runtime_minutes, dataset
                FROM cap.V_task_Steps
                WHERE Processor = _managerName::citext AND State = 4
                ORDER BY Job, Step
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.job,
                                    _previewData.dataset_id,
                                    _previewData.step,
                                    _previewData.script,
                                    _previewData.tool,
                                    _previewData.state_name,
                                    _previewData.processor,
                                    _previewData.start,
                                    _previewData.runtime_minutes,
                                    _previewData.dataset
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        Else
            -- Change task state back to 2=Enabled

            UPDATE cap.t_task_steps
            SET State = 2
            WHERE Processor = _managerName::citext AND State = 4;

            _message := format('Reset capture task job step state back to 2 for job %s', _job);
            CALL public.post_log_entry ('Warning', _message, 'Report_Capture_Task_Manager_Idle', 'cap');
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


ALTER PROCEDURE cap.report_capture_task_manager_idle(IN _managername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE report_capture_task_manager_idle(IN _managername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.report_capture_task_manager_idle(IN _managername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'ReportCaptureTaskManagerIdle or ReportManagerIdle';

