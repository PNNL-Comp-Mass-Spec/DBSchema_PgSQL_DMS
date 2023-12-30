--
-- Name: extend_multiple_jobs(text, text, text, text, boolean, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.extend_multiple_jobs(IN _joblist text, IN _extensionscriptname text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Apply an extension script to a series of jobs
**
**  Arguments:
**    _jobList                  Comma-separated list of jobs to extend
**    _extensionScriptName      Example: MSGFPlus_MzXml_Extend_IDPicker
**    _message                  Status message
**    _returnCode               Return code
**    _infoOnly                 When true, create and populate the temporary tables, but do not add new rows to t_jobs, t_job_steps, etc. When true, auto-sets _debugMode to true
**    _debugMode                When true, various debug messages will be shown, and the contents of the temporary tables are written to four database tables:
**                              - sw.T_Tmp_New_Jobs
**                              - sw.T_Tmp_New_Job_Steps
**                              - sw.T_Tmp_New_Job_Step_Dependencies
**                              - sw.T_Tmp_New_Job_Parameters
**
**  Auth:   mem
**  Date:   10/22/2010 mem - Initial version
**          08/01/2023 mem - Ported to PostgreSQL
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
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

    INSERT INTO Tmp_JobsToExtend (Job, Valid)
    SELECT Value, false
    FROM public.parse_delimited_integer_list(_jobList);

    ---------------------------------------------------
    -- Validate that the job numbers exist in sw.t_jobs or sw.t_jobs_history
    ---------------------------------------------------

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

    If Exists (SELECT Job FROM Tmp_JobsToExtend WHERE Not Valid) Then
        FOR _message IN
            SELECT format('Invalid job (either not in sw.t_jobs or in sw.t_jobs_history but does not have state=4): %s', job)
            FROM Tmp_JobsToExtend
            WHERE Not Valid
        LOOP
            RAISE WARNING '%', _message;
        END LOOP;
    End If;

    DELETE FROM Tmp_JobsToExtend
    WHERE Not Valid;

    If Not Exists (SELECT * FROM Tmp_JobsToExtend) Then
        _message := 'No valid jobs';
        _returnCode := 'U5201';

        DROP TABLE Tmp_JobsToExtend;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure all of the jobs used the same script
    ---------------------------------------------------

    SELECT MIN(Script),
           MAX(Script),
           MIN(Job)
    INTO _scriptFirst, _scriptLast, _Job
    FROM Tmp_JobsToExtend;

    If Coalesce(_scriptFirst, '') <> Coalesce(_scriptLast, '') Then
        _message := format('The jobs must all have the same script defined: %s <> %s', _scriptFirst, _scriptLast);
        _returnCode := 'U5202';

        DROP TABLE Tmp_JobsToExtend;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate that the extension script is appropriate for the existing job script
    ---------------------------------------------------

    CALL sw.validate_extension_script_for_job (
                _job,
                _extensionScriptName,
                _message    => _message,        -- Output
                _returnCode => _returnCode);    -- Output

    If _returnCode <> '' Then
        DROP TABLE Tmp_JobsToExtend;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Loop through the jobs and call create_job_steps() for each
    ---------------------------------------------------

    FOR _job IN
        SELECT Job
        FROM Tmp_JobsToExtend
        ORDER BY JOb
    LOOP

        CALL sw.create_job_steps (
                    _message             => _message,       -- Output
                    _returnCode          => _returnCode,    -- Output
                    _mode                => 'ExtendExistingJob',
                    _existingJob         => _job,
                    _extensionScriptName => _extensionScriptName,
                    _infoOnly            => _infoOnly,
                    _debugMode           => _debugMode);

    END LOOP;

    DROP TABLE Tmp_JobsToExtend;

END
$$;


ALTER PROCEDURE sw.extend_multiple_jobs(IN _joblist text, IN _extensionscriptname text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE extend_multiple_jobs(IN _joblist text, IN _extensionscriptname text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.extend_multiple_jobs(IN _joblist text, IN _extensionscriptname text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _debugmode boolean) IS 'ExtendMultipleJobs';

