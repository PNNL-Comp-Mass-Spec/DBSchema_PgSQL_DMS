--
-- Name: report_manager_idle(text, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.report_manager_idle(IN _managername text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Assure that no running job steps are associated with the given manager.
**      Used by the analysis manager if a database error occurs while requesting a new step task.
**
**      For example, a deadlock error can leave a job step in state 4 and associated with a manager,
**      even though the manager isn't actually running the job step
**
**  Arguments:
**    _managerName      Manager name
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   08/01/2017 mem - Initial release
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          08/08/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _job int := 0;
    _remoteInfoId int := 0;
    _newJobState int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _managerName := Trim(Coalesce(_managerName, ''));
    _infoOnly    := Coalesce(_infoOnly, false);

    If _managerName = '' Then
        _message := 'Manager name cannot be empty';
        RAISE EXCEPTION '%', _message;
    End If;

    If Not Exists (SELECT processor_id FROM sw.t_local_processors WHERE processor_name = _managerName::text) Then
        _message := format('Manager not found in sw.t_local_processors: %s', _managerName);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Look for running step tasks associated with this manager
    ---------------------------------------------------

    -- There should, under normal circumstances, only be one active job step (if any) for this manager
    -- If there are multiple job steps, _job will only track one of the jobs (but the state of both running job steps will be changed to 2)

    SELECT job,
           Coalesce(remote_info_id, 0)
    INTO _job, _remoteInfoId
    FROM sw.t_job_steps
    WHERE processor = _managerName::citext AND state = 4
    LIMIT 1;

    If Not FOUND Then
        _message := format('No active job steps are associated with manager %s', _managerName);
        RETURN;
    End If;

    -- Change step state back to 2 or 9

    If _remoteInfoId > 1 Then
        _newJobState := 9; -- RunningRemote
    Else
        _newJobState := 2; -- Enabled;
    End If;

    If _infoOnly Then
        -- Preview the running job steps

        RAISE INFO '';

        _formatSpecifier := '%-9s %-4s %-25s %-20s %-10s %-5s %-9s %-20s %-20s %-20s %-80s %-11s %-15s %-30s %-15s %-30s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Step',
                            'Script',
                            'Tool',
                            'State_name',
                            'State',
                            'State_New',
                            'Start',
                            'Finish',
                            'Processor',
                            'Dataset',
                            'Data_Pkg_ID',
                            'Completion_Code',
                            'Completion_Message',
                            'Evaluation_Code',
                            'Evaluation_Message'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '----',
                                     '-------------------------',
                                     '--------------------',
                                     '----------',
                                     '-----',
                                     '---------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------------------------------------------------------------------',
                                     '-----------',
                                     '---------------',
                                     '------------------------------',
                                     '---------------',
                                     '------------------------------'
                                    );
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT JS.Job,
                   JS.Step,
                   JS.Script,
                   JS.Tool,
                   JS.State_name,
                   JS.State,
                   _newJobState AS State_New,
                   public.timestamp_text(JS.Start) AS Start,
                   public.timestamp_text(JS.Finish) AS Finish,
                   JS.Processor,
                   JS.Dataset,
                   JS.Data_Pkg_ID,
                   JS.Completion_Code,
                   JS.Completion_Message,
                   JS.Evaluation_Code,
                   JS.Evaluation_Message
            FROM V_Job_Steps JS
            WHERE Processor = _managerName::citext AND State = 4
            ORDER BY JS.Job, JS.Step
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Step,
                                _previewData.Script,
                                _previewData.Tool,
                                _previewData.State_name,
                                _previewData.State,
                                _previewData.State_New,
                                _previewData.Start,
                                _previewData.Finish,
                                _previewData.Processor,
                                _previewData.Dataset,
                                _previewData.Data_Pkg_ID,
                                _previewData.Completion_Code,
                                _previewData.Completion_Message,
                                _previewData.Evaluation_Code,
                                _previewData.Evaluation_Message
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    UPDATE sw.t_job_steps
    SET state = _newJobState
    WHERE processor = _managerName::citext AND state = 4;

    _message := format('Reset step state back to %s for job %s', _newJobState, _job);

    CALL public.post_log_entry ('Warning', _message, 'Report_Manager_Idle', 'sw');

    RAISE INFO '';
    RAISE INFO '%', _message;
END
$$;


ALTER PROCEDURE sw.report_manager_idle(IN _managername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE report_manager_idle(IN _managername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.report_manager_idle(IN _managername text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'ReportManagerIdle';

