--
CREATE OR REPLACE PROCEDURE sw.remove_job_from_main_tables
(
    _job int,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _validateJobStepSuccess boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete specified job from the main tables in the public schema
**
**  Arguments:
**    _job                      Job to remove
**    _infoOnly                 When true, don't actually delete, just dump list of jobs that would have been
**    _validateJobStepSuccess   When true, remove any jobs that have failed, in progress, or holding job steps
**
**  Auth:   mem
**  Date:   11/19/2010 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _deleteCount int;
    _saveTime timestamp;
BEGIN
    _message := '';
    _returnCode:= '';

    _saveTime := CURRENT_TIMESTAMP;

    ---------------------------------------------------
    -- Create table to track the list of affected jobs
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_SJL (
        Job int,
        State int
    );

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _job Is Null Then
        _message := 'Job not defined; nothing to do';
        RETURN;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);
    _validateJobStepSuccess := Coalesce(_validateJobStepSuccess, false);

    ---------------------------------------------------
    -- Insert specified job to Tmp_SJL
    ---------------------------------------------------
    --

    INSERT INTO Tmp_SJL
    SELECT job, state
    FROM sw.t_jobs
    WHERE job = _job;

    If _validateJobStepSuccess Then
        -- Remove any jobs that have failed, in progress, or holding job steps
        DELETE Tmp_SJL
        FROM sw.t_job_steps JS
        WHERE Tmp_SJL.job = JS.job AND
              NOT (JS.state IN (3, 5));
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        If _deleteCount > 0 Then
            _message := format('Warning: Removed %s %s with one or more steps that was not skipped or complete',
                                _deleteCount, public.check_plural(_deleteCount, 'job', 'jobs'));
            RAISE WARNING '%', _message;
        Else
            RAISE INFO 'Successful jobs have been confirmed to all have successful (or skipped) steps';
        End If;
    End If;

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    CALL sw.remove_selected_jobs (
            _infoOnly,
            _message => _message,
            _logDeletions => false);

    DROP TABLE Tmp_SJL;
END
$$;

COMMENT ON PROCEDURE sw.remove_job_from_main_tables IS 'RemoveJobFromMainTables';
