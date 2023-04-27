--
CREATE OR REPLACE PROCEDURE sw.extend_multiple_jobs
(
    _jobList text,
    _extensionScriptName text,
    INOUT _message text = '',
    INOUT _returnCode text = '',
    _infoOnly boolean = false,
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Applies an extension script to a series of jobs
**
**  Arguments:
**    _jobList               Comma separated list of jobs to extend
**    _extensionScriptName   Example: Sequest_Extend_MSGF
**
**  Auth:   mem
**  Date:   10/22/2010 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _scriptFirst text;
    _scriptLast text;
    _job int;
BEGIN
    _message := '';
    _returnCode := '';

    CREATE TEMP TABLE Tmp_JobsToExtend (
        Job int NOT NULL,
        Valid boolean NOT NULL,
        Script text NULL
    );

    ---------------------------------------------------
    -- Populate a temporary table with the list of jobs
    ---------------------------------------------------
    --

    INSERT INTO Tmp_JobsToExtend (Job, Valid)
    SELECT Value, false
    FROM public.parse_delimited_integer_list(_jobList, ',');

    ---------------------------------------------------
    -- Validate that the job numbers exist in sw.t_jobs or sw.t_jobs_history
    ---------------------------------------------------
    --
    UPDATE Tmp_JobsToExtend
    SET Valid = true, script = sw.t_jobs.script
    FROM sw.t_jobs
    WHERE Tmp_JobsToExtend.job = sw.t_jobs.job;

    UPDATE Tmp_JobsToExtend
    SET Valid = true, script = sw.t_jobs_history.script
    FROM sw.t_jobs_history
    WHERE Tmp_JobsToExtend.job = sw.t_jobs_history.job AND
          sw.t_jobs_history.state = 4;

    ---------------------------------------------------
    -- Warn the user if any invalid jobs are present
    ---------------------------------------------------
    --
    If Exists (SELECT * FROM Tmp_JobsToExtend WHERE Valid = 0) Then
        FOR _message IN
            SELECT format('Invalid job (either not in sw.t_jobs or in sw.t_jobs_history but does not have state=4): %s', job)
            FROM Tmp_JobsToExtend
            WHERE Not Valid;
        LOOP
            RAISE WARNING '%', _message;
        END LOOP;
    End If;

    DELETE FROM Tmp_JobsToExtend
    WHERE Not Valid;

    If NOT EXISTS (SELECT * FROM Tmp_JobsToExtend) Then
        _message := 'No valid jobs';
        _returnCode := 'U5201';

        DROP TABLE Tmp_JobsToExtend;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure all of the jobs used the same script
    ---------------------------------------------------
    --
    SELECT MIN(Script),
           MAX(Script),
           MIN(Job)
    INTO _scriptFirst, _scriptLast, _Job
    FROM Tmp_JobsToExtend

    If Coalesce(_scriptFirst, '') <> Coalesce(_scriptLast, '') Then
        _message := format('The jobs must all have the same script defined: %s <> %s', _scriptFirst, _scriptLast);
        _returnCode := 'U5202';

        DROP TABLE Tmp_JobsToExtend;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate that the extension script is appropriate for the existing job script
    ---------------------------------------------------
    --
    Call sw.validate_extension_script_for_job (
            _job,
            _extensionScriptName,
            _message => _message,           -- Output
            _returnCode => _returnCode);    -- Output

    If _returnCode <> '' Then
        DROP TABLE Tmp_JobsToExtend;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Loop through the jobs and call create_job_steps for each
    ---------------------------------------------------
    --

    FOR _job IN
        SELECT Job
        FROM Tmp_JobsToExtend
        ORDER BY JOb
    LOOP

        Call sw.create_job_steps (
            _message => _message,
            _returnCode => _returnCode,
            _mode => 'ExtendExistingJob',
            _extensionScriptName => _extensionScriptName,
            _existingJob => _job,
            _infoOnly => _infoOnly,
            _debugMode => _debugMode);

    END LOOP;

    DROP TABLE Tmp_JobsToExtend;

END
$$;

COMMENT ON PROCEDURE sw.extend_multiple_jobs IS 'ExtendMultipleJobs';
