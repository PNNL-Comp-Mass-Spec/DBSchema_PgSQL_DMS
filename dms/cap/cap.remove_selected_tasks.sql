--
-- Name: remove_selected_tasks(boolean, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.remove_selected_tasks(IN _infoonly boolean DEFAULT false, IN _logdeletions boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete capture task jobs in temp table Tmp_Selected_Jobs (populated by the caller)
**
**          CREATE TEMP TABLE Tmp_Selected_Jobs (
**              Job int not null,
**              State int
**          );
**
**  Arguments:
**    _infoOnly       When true, don't actually delete, just display the list of capture task jobs that would be deleted
**    _logDeletions   When true, logs each deleted job number to cap.t_log_entries
**
**  Auth:   grk
**  Date:   09/12/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          06/22/2023 mem - Ported to PostgreSQL
**          06/29/2023 mem - Disable trigger trig_t_tasks_after_delete on cap.t_tasks when deleting in bulk
**                         - Update comments and messages
**
*****************************************************/
DECLARE
    _job int;
    _jobCount int;
    _deleteCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _logDeletions := Coalesce(_logDeletions, false);

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _jobCount
    FROM Tmp_Selected_Jobs;

    If _jobCount = 0 Then
        RETURN;
    End If;

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview the capture task jobs to be deleted
        ---------------------------------------------------

        RAISE INFO '';
        RAISE INFO 'Previewing the % capture task % that would be deleted', _jobCount, public.check_plural(_jobCount, 'job', 'jobs');
        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'State'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job, State
            FROM Tmp_Selected_Jobs
            ORDER BY Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.State
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete capture task job dependencies
    ---------------------------------------------------

    DELETE FROM cap.t_task_step_dependencies
    WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);

    ---------------------------------------------------
    -- Delete capture task job parameters
    ---------------------------------------------------

    DELETE FROM cap.t_task_parameters
    WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);

    ---------------------------------------------------
    -- Delete job steps
    ---------------------------------------------------

    DELETE FROM cap.t_task_steps
    WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);

    ---------------------------------------------------
    -- Delete entries in cap.t_tasks
    ---------------------------------------------------

    If _logDeletions Then

        ---------------------------------------------------
        -- Delete capture task jobs one at a time, posting a log entry for each deleted job
        ---------------------------------------------------

        _deleteCount := 0;

        FOR _job IN
            SELECT Job
            FROM Tmp_Selected_Jobs
            ORDER BY Job
        LOOP

            DELETE FROM cap.t_tasks
            WHERE job = _job;

            _message := format('Deleted job %s from cap.t_tasks', _job);
            CALL public.post_log_entry ('Normal', _message, 'Remove_Selected_Tasks', 'cap');

            _deleteCount := _deleteCount + 1;
        END LOOP;

    Else

        ---------------------------------------------------
        -- Delete in bulk
        ---------------------------------------------------

        ALTER TABLE cap.t_tasks DISABLE TRIGGER trig_t_tasks_after_delete;

        DELETE FROM cap.t_tasks
        WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        ALTER TABLE cap.t_tasks ENABLE TRIGGER trig_t_tasks_after_delete;

    End If;

    RAISE INFO '';
    RAISE INFO 'Deleted % capture task %', _deleteCount, public.check_plural(_deleteCount, 'job', 'jobs');
END
$$;


ALTER PROCEDURE cap.remove_selected_tasks(IN _infoonly boolean, IN _logdeletions boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE remove_selected_tasks(IN _infoonly boolean, IN _logdeletions boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.remove_selected_tasks(IN _infoonly boolean, IN _logdeletions boolean, INOUT _message text, INOUT _returncode text) IS 'RemoveSelectedTasks or RemoveSelectedJobs';

