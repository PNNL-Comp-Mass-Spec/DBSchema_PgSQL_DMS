--
-- Name: remove_job_from_main_tables(integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.remove_job_from_main_tables(IN _job integer, IN _infoonly boolean DEFAULT false, IN _validatejobstepsuccess boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete specified job from sw.t_jobs, sw.t_job_steps, etc.
**
**  Arguments:
**    _job                      Job to remove
**    _infoOnly                 When true, don't actually delete, just dump list of jobs that would have been
**    _validateJobStepSuccess   When true, remove any jobs that have failed, in progress, or holding job steps
**
**  Auth:   mem
**  Date:   11/19/2010 mem - Initial version
**          08/08/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _deleteCount int;
    _saveTime timestamp;
BEGIN
    _message := '';
    _returnCode := '';

    _saveTime := CURRENT_TIMESTAMP;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _job Is Null Then
        _message := 'Job not defined; nothing to do';
        RETURN;
    End If;

    _infoOnly               := Coalesce(_infoOnly, false);
    _validateJobStepSuccess := Coalesce(_validateJobStepSuccess, false);

    ---------------------------------------------------
    -- Create table to track the list of affected jobs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Selected_Jobs (
        Job int,
        State int
    );

    ---------------------------------------------------
    -- Insert specified job to Tmp_Selected_Jobs
    ---------------------------------------------------

    INSERT INTO Tmp_Selected_Jobs
    SELECT job, state
    FROM sw.t_jobs
    WHERE job = _job;

    If Not FOUND Then
        _message := format('Warning: Job %s not found in sw.t_jobs', _job);

        RAISE INFO '';
        RAISE WARNING '%', _message;
        DROP TABLE Tmp_Selected_Jobs;
        RETURN;
    End If;

    If _validateJobStepSuccess Then
        -- Remove any jobs that have failed, in progress, or holding job steps
        DELETE FROM Tmp_Selected_Jobs
        WHERE EXISTS ( SELECT 1
                       FROM sw.t_job_steps JS
                       WHERE Tmp_Selected_Jobs.job = JS.job AND
                             NOT JS.state IN (3, 5)
                     );
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        RAISE INFO '';

        If _deleteCount > 0 Then
            _message := format('Warning: Not deleting job %s since it has 1 or more steps that are not skipped or complete and _validateJobStepSuccess is true', _job);

            RAISE WARNING '%', _message;
            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        Else
            RAISE INFO 'All of the job''s steps are successful or skipped; deleting job %s', _job;
        End If;
    End If;

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    CALL sw.remove_selected_jobs (
                _infoOnly,
                _message      => _message,      -- Output
                _returncode   => _returncode,   -- Output
                _logDeletions => false);

    DROP TABLE Tmp_Selected_Jobs;
END
$$;


ALTER PROCEDURE sw.remove_job_from_main_tables(IN _job integer, IN _infoonly boolean, IN _validatejobstepsuccess boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE remove_job_from_main_tables(IN _job integer, IN _infoonly boolean, IN _validatejobstepsuccess boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.remove_job_from_main_tables(IN _job integer, IN _infoonly boolean, IN _validatejobstepsuccess boolean, INOUT _message text, INOUT _returncode text) IS 'RemoveJobFromMainTables';

