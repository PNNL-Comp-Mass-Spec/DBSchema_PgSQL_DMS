--
CREATE OR REPLACE PROCEDURE sw.import_job_processors
(
    _bypassDMS boolean = false,
    INOUT _message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get list of jobs and associated processors
**      and count of associated groups that are enabled for general processing
**
**  Auth:   grk
**  Date:   05/26/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/17/2009 mem - Removed Insert operation for T_Local_Job_Processors, since SyncJobInfo now populates T_Local_Job_Processors (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          06/27/2009 mem - Now removing entries from T_Local_Job_Processors only if the job is complete or not present in T_Jobs; if a job is failed but still in T_Jobs, the entry is not removed from T_Local_Job_Processors
**          07/01/2010 mem - No longer logging message "Updated T_Local_Job_Processors; DeleteCount=" each time T_Local_Job_Processors is updated
**          06/01/2015 mem - No longer deleting rows in T_Local_Job_Processors since we have deprecated processor groups
**          02/15/2016 mem - Re-enabled support for processor groups, but altered logic to wait for 2 hours before deleting completed jobs
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';

    If _bypassDMS Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Remove job-processor associations
    -- from jobs that completed at least 2 hours ago
    ---------------------------------------------------

    DELETE FROM sw.t_local_job_processors
    WHERE job IN ( SELECT job
                   FROM sw.t_jobs
                   WHERE state = 4 AND
                         finish < CURRENT_TIMESTAMP - INTERVAL '2 hours';

END
$$;

COMMENT ON PROCEDURE sw.import_job_processors IS 'ImportJobProcessors';
