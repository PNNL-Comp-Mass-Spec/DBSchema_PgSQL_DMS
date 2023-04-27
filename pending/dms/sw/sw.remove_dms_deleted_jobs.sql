--
CREATE OR REPLACE PROCEDURE sw.remove_dms_deleted_jobs
(
    _infoOnly boolean = false,
    INOUT _message text = '',
    _maxJobsToProcess int = 0
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete failed jobs that have been removed from the main tables in the public scchema
**
**  Arguments:
**    _infoOnly     When true, don't actually delete, just dump list of jobs that would have been
**
**  Auth:   grk
**  Date:   02/19/2009 grk - initial release (Ticket #723)
**          02/26/2009 mem - Updated to look for any job not present in DMS, but to exclude jobs with a currently running job step
**          06/01/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          04/13/2010 grk - don't delete jobs where dataset ID = 0
**          05/26/2017 mem - Treat state 9 (Running_Remote) as an active job
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN

    _message := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    ---------------------------------------------------
    -- Create table to track the list of affected jobs
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_SJL (
        Job int,
        State int
    );

    ---------------------------------------------------
    -- Find all jobs present in the Pipeline DB but not present in DMS
    -- V_DMS_PipelineExistingJob returns a list of all jobs in DMS (regardless of state)
    ---------------------------------------------------
    --
    INSERT INTO Tmp_SJL (job, state)
    SELECT job, state
    FROM t_jobs
    WHERE dataset_id <> 0 AND NOT job IN (SELECT job FROM V_DMS_PipelineExistingJobs);

    If Not FOUND Then
        DROP TABLE Tmp_SJL;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Remove any entries from Tmp_SJL that have a currently running job step
    -- However, ignore job steps that started over 48 hours ago
    ---------------------------------------------------
    --
    DELETE Tmp_SJL
    FROM sw.t_job_steps JS
    WHERE Tmp_SJL.job = JS.job AND
          JS.state IN (4,9) AND
          JS.start >= CURRENT_TIMESTAMP - INTERVAL '48 hours';

    If Not Exists (SELECT * FROM Tmp_SJL) Then
        DROP TABLE Tmp_SJL;
        RETURN;
    End If;

    If _maxJobsToProcess > 0 Then
        -- Limit the number of jobs to delete
        DELETE FROM Tmp_SJL
        WHERE NOT Job IN ( SELECT Job
                           FROM Tmp_SJL
                           ORDER BY Job
                           LIMIT _maxJobsToProcess)
    End If;

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    Call sw.remove_selected_jobs (
        _infoOnly,
        _message => _message,
        _logDeletions => true,
        _logToConsoleOnly => false);

    DROP TABLE Tmp_SJL;
END
$$;

COMMENT ON PROCEDURE sw.remove_dms_deleted_jobs IS 'RemoveDMSDeletedJobs';
