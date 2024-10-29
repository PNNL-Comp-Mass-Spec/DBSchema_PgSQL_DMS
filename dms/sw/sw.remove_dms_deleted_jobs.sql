--
-- Name: remove_dms_deleted_jobs(boolean, text, text, integer); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.remove_dms_deleted_jobs(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _maxjobstoprocess integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete failed jobs that have been removed from the main tables in the public scchema
**
**  Arguments:
**    _infoOnly             When true, don't actually delete, just dump list of jobs that would have been
**    _message              Status message
**    _returnCode           Return code
**    _maxJobsToProcess     Maximum number of jobs to process
**
**  Auth:   grk
**  Date:   02/19/2009 grk - Initial release (Ticket #723)
**          02/26/2009 mem - Updated to look for any job not present in DMS, but to exclude jobs with a currently running job step
**          06/01/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          04/13/2010 grk - Don't delete jobs where dataset ID = 0
**          05/26/2017 mem - Treat state 9 (Running_Remote) as an active job
**          07/29/2023 mem - Ported to PostgreSQL
**          10/28/2024 mem - Use a Left Outer Join when looking for jobs in sw.t_jobs that are not in v_dms_pipeline_existing_jobs
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    ---------------------------------------------------
    -- Create table to track the list of affected jobs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Selected_Jobs (
        Job int,
        State int
    );

    ---------------------------------------------------
    -- Find all jobs present in sw.t_jobs but not present in public.t_analysis_job
    -- View sw.v_dms_pipeline_existing_jobs returns a list of all jobs in public.t_analysis_job (regardless of state)
    ---------------------------------------------------

    INSERT INTO Tmp_Selected_Jobs (job, state)
    SELECT J.job, J.state
    FROM sw.t_jobs J
         LEFT OUTER JOIN sw.v_dms_pipeline_existing_jobs AllJobs
           ON J.job = AllJobs.job
    WHERE J.dataset_id <> 0 AND AllJobs.job Is Null;

    If Not FOUND Then
        DROP TABLE Tmp_Selected_Jobs;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Remove any entries from Tmp_Selected_Jobs that have a currently running job step
    -- However, ignore job steps that started over 48 hours ago
    ---------------------------------------------------

    DELETE FROM Tmp_Selected_Jobs
    WHERE EXISTS
        (SELECT 1
         FROM Tmp_Selected_Jobs INNER JOIN
              sw.t_job_steps JS
                ON Tmp_Selected_Jobs.job = JS.job
         WHERE JS.state IN (4, 9) AND
               JS.start >= CURRENT_TIMESTAMP - INTERVAL '48 hours'
        );

    If Not Exists (SELECT job FROM Tmp_Selected_Jobs) Then
        DROP TABLE Tmp_Selected_Jobs;
        RETURN;
    End If;

    If _maxJobsToProcess > 0 Then
        -- Limit the number of jobs to delete
        DELETE FROM Tmp_Selected_Jobs
        WHERE NOT Job IN (SELECT Job
                          FROM Tmp_Selected_Jobs
                          ORDER BY Job
                          LIMIT _maxJobsToProcess);
    End If;

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    CALL sw.remove_selected_jobs (
                _infoOnly,
                _message          => _message,      -- Output
                _returnCode       => _returnCode,   -- Output
                _logDeletions     => true,
                _logToConsoleOnly => false);

    DROP TABLE Tmp_Selected_Jobs;
END
$$;


ALTER PROCEDURE sw.remove_dms_deleted_jobs(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer) OWNER TO d3l243;

--
-- Name: PROCEDURE remove_dms_deleted_jobs(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.remove_dms_deleted_jobs(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer) IS 'RemoveDMSDeletedJobs';

