--
-- Name: import_job_processors(boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.import_job_processors(IN _bypassdms boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add/remote processors from sw.t_local_job_processors
**
**      This procedure was deprecated in May 2015 since we no longer use sw.t_local_job_processors
**
**  Arguments:
**    _bypassDMS    When true, the logic in this procedure is completely bypassed (and thus t_local_job_processors is not updated)
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   05/26/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/17/2009 mem - Removed Insert operation for T_Local_Job_Processors, since Sync_Job_Info now populates T_Local_Job_Processors (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          06/27/2009 mem - Now removing entries from T_Local_Job_Processors only if the job is complete or not present in T_Jobs; if a job is failed but still in T_Jobs, the entry is not removed from T_Local_Job_Processors
**          07/01/2010 mem - No longer logging message "Updated T_Local_Job_Processors; DeleteCount=" each time T_Local_Job_Processors is updated
**          06/01/2015 mem - No longer deleting rows in T_Local_Job_Processors since we have deprecated processor groups
**          02/15/2016 mem - Re-enabled support for processor groups, but altered logic to wait for 2 hours before deleting completed jobs
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          07/29/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    _bypassDMS := Coalesce(_bypassDMS, false);

    If _bypassDMS Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Remove job-processor associations
    -- from jobs that completed at least 2 hours ago
    ---------------------------------------------------

    DELETE FROM sw.t_local_job_processors
    WHERE job IN (SELECT job
                  FROM sw.t_jobs
                  WHERE state = 4 AND
                        finish < CURRENT_TIMESTAMP - INTERVAL '2 hours'
                 );

END
$$;


ALTER PROCEDURE sw.import_job_processors(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE import_job_processors(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.import_job_processors(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text) IS 'ImportJobProcessors';

