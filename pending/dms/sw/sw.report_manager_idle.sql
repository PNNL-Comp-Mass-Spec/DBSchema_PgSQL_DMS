--
CREATE OR REPLACE PROCEDURE sw.report_manager_idle
(
    _managerName text = '',
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Assure that no running job steps are associated with the given manager
**
**      Used by the analysis manager if a database error occurs while requesting a new job task
**      For example, a deadlock error, which can leave a job step in state 4 and
**      associated with a manager, even though the manager isn't actually running the job step
**
**  Auth:   mem
**  Date:   08/01/2017 mem - Initial release
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _job int := 0;
    _remoteInfoId int := 0;
    _newJobState int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

    _managerName := Coalesce(_managerName, '');
    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode := '';

    If _managerName = '' Then
        _message := 'Manager name cannot be empty';
        RAISE EXCEPTION '%', _message;
    End If;

    If Not Exists (SELECT * FROM sw.t_local_processors WHERE processor_name = _managerName) Then
        _message := format('Manager not found in sw.t_local_processors: %s', _managerName);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Look for running step tasks associated with this manager
    ---------------------------------------------------

    -- There should, under normal circumstances, only be one active job step (if any) for this manager
    -- If there are multiple job steps, _job will only track one of the jobs
    --
    SELECT job,
           Coalesce(remote_info_id, 0)
    INTO _job, _remoteInfoId
    FROM sw.t_job_steps
    WHERE processor = _managerName AND state = 4
    LIMIT 1;

    If Not FOUND Then
        _message := format('No active job steps are associated with manager %s', _managerName);
        RETURN;
    End If;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        -- Preview the running tasks
        --
        SELECT *
        FROM V_Job_Steps
        WHERE Processor = _managerName AND State = 4
        ORDER BY Job, Step
    Else
        -- Change task state back to 2 or 9
        --
        If _remoteInfoId > 1 Then
            _newJobState := 9  ; -- RunningRemote
        Else
            _newJobState := 2   ; -- Enabled;
        End If;

        UPDATE sw.t_job_steps
        SET state = _newJobState
        WHERE processor = _managerName AND state = 4;

        _message := format('Reset step task state back to %s for job %s', _newJobState, _job);

        CALL public.post_log_entry ('Warning', _message, 'Report_Manager_Idle', 'sw');
    End If;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE sw.report_manager_idle IS 'ReportManagerIdle';
