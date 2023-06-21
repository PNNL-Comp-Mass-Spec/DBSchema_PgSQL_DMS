--
CREATE OR REPLACE PROCEDURE cap.remove_selected_tasks
(
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _logDeletions boolean
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete capture task jobs given in temp table Tmp_Selected_Jobs
**      (populated by the caller)
**
**  Arguments:
**    _infoOnly       When true, don't actually delete, just dump list of capture task jobs that would be deleted
**    _logDeletions   When true, logs each deleted job number in cap.t_log_entries
**
**  Auth:   grk
**  Date:   09/12/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _numJobs int;
    _formatSpecifier text := '%-10s %-10s';
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;

    _job int;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _logDeletions := Coalesce(_logDeletions, false);

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _numJobs
    FROM Tmp_Selected_Jobs
    --
    If _numJobs = 0 Then
       RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

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
            ORDER BY Job;
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
    WHERE (Job IN (SELECT Job FROM Tmp_Selected_Jobs))

    ---------------------------------------------------
    -- Delete capture task job parameters
    ---------------------------------------------------

    DELETE FROM cap.t_task_parameters
    WHERE Job IN (SELECT Job FROM Tmp_Selected_Jobs)

    ---------------------------------------------------
    -- Delete job steps
    ---------------------------------------------------

    DELETE FROM cap.t_task_steps
    WHERE Job IN (SELECT Job FROM Tmp_Selected_Jobs)

    ---------------------------------------------------
    -- Delete entries in t_tasks
    ---------------------------------------------------

    If _logDeletions Then

        ---------------------------------------------------
        -- Delete capture task jobs one at a time, posting a log entry for each deleted job
        ---------------------------------------------------

        FOR _job IN
            SELECT Job
            FROM Tmp_Selected_Jobs
            ORDER BY Job
        LOOP

            DELETE FROM cap.t_tasks
            WHERE Job = _job;

            _message := format('Deleted job %s from t_tasks', _job);
            CALL public.post_log_entry ('Normal', _message, 'Remove_Selected_Tasks', 'cap');

        END LOOP; -- </c>

    Else

        ---------------------------------------------------
        -- Delete in bulk
        ---------------------------------------------------

        DELETE FROM cap.t_tasks
        WHERE Job IN (SELECT Job FROM Tmp_Selected_Jobs);

    End If;

END
$$;

COMMENT ON PROCEDURE cap.remove_selected_tasks IS 'RemoveSelectedTasks or RemoveSelectedJobs';
