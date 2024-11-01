--
-- Name: update_pending_jobs(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_pending_jobs(IN _requestid integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update job states for pending jobs associated with analysis job requests that have a non-zero value for max_active_jobs
**
**      If the number of active jobs is less than max_active_jobs, change job state from 20 to 1 for the required number of jobs
**
**  Arguments:
**    _requestID        Analysis job request id; when zero, process all job requests with new, active, or pending jobs
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   10/31/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _requestInfo record;
    _jobCountToEnable int;
    _action text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _requestID := Coalesce(_requestID, 0);
    _infoOnly  := Coalesce(_infoOnly, false);

    RAISE INFO '';

    ------------------------------------------------
    -- Find job requests with active, failed, or pending jobs
    ------------------------------------------------

    CREATE TEMP TABLE T_Tmp_JobRequestsToProcess (
        Request_ID int NOT NULL,
        Max_Active_Jobs int NOT NULL,
        Active_Jobs int NOT NULL,
        Pending_Jobs int NOT NULL
    );

    INSERT INTO T_Tmp_JobRequestsToProcess (Request_ID, Max_Active_Jobs, Active_Jobs, Pending_Jobs)
    SELECT AJR.request_id,
           AJR.max_active_jobs,
           SUM(CASE WHEN J.job_state_id IN (1,2,5)  THEN 1 ELSE 0 END) AS Active_Jobs,
           SUM(CASE WHEN J.job_state_id = 20 THEN 1 ELSE 0 END) AS Pending_Jobs
    FROM t_analysis_job_request AJR
         INNER JOIN t_analysis_job J
         ON AJR.request_id = J.request_id
    WHERE AJR.max_active_jobs > 0 AND J.job_state_id IN (1,2,5,20)  -- 1=New, 2=In Progress, 5=Failed, 20=Pending
    GROUP BY AJR.request_id, AJR.max_active_jobs
    HAVING COUNT(*) > 0;

    If Not FOUND Then
        _message := 'Did not find any analysis job requests with active or pending jobs and a non-zero value for max_active_jobs';
        RAISE INFO '%', _message;

        DROP TABLE T_Tmp_JobRequestsToProcess;
        RETURN;
    End If;

    FOR _requestInfo IN
        SELECT Request_ID, Max_Active_Jobs, Active_Jobs, Pending_Jobs
        FROM T_Tmp_JobRequestsToProcess
        ORDER BY Request_ID
    LOOP
        If _requestInfo.Active_Jobs >= _requestInfo.Max_Active_Jobs Then
            If _infoOnly Then
                If _requestInfo.Active_Jobs > _requestInfo.Max_Active_Jobs Then
                    RAISE INFO 'Job request % has % active %, which is larger than the max active job count (%)',
                               _requestInfo.Request_ID,
                               _requestInfo.Active_Jobs,
                               public.check_plural(_requestInfo.Active_Jobs, 'job', 'jobs'),
                               _requestInfo.Max_Active_Jobs;
                Else
                    RAISE INFO 'Job request % has % active %, which is equal to the max active job count',
                               _requestInfo.Request_ID,
                               _requestInfo.Active_Jobs,
                               public.check_plural(_requestInfo.Active_Jobs, 'job', 'jobs');
                End If;
            End If;

            CONTINUE;
        End If;

        If _requestInfo.Pending_Jobs = 0 Then
            RAISE INFO 'Job request % has % active % and no pending jobs (max active job count is %)',
                       _requestInfo.Request_ID,
                       _requestInfo.Active_Jobs,
                       public.check_plural(_requestInfo.Active_Jobs, 'job', 'jobs'),
                       _requestInfo.Max_Active_Jobs;

            CONTINUE;
        End If;

        _jobCountToEnable := _requestInfo.Max_Active_Jobs - _requestInfo.Active_Jobs;

        _message := format('Job request %s has %s active %s and %s pending %s (max active job count is %s); ACTION_PLACEHOLDER %s %s to have state 1=New',
                           _requestInfo.Request_ID,
                           _requestInfo.Active_Jobs,
                           public.check_plural(_requestInfo.Active_Jobs, 'job', 'jobs'),
                           _requestInfo.Pending_Jobs,
                           public.check_plural(_requestInfo.Pending_Jobs, 'job', 'jobs'),
                           _requestInfo.Max_Active_Jobs,
                           _jobCountToEnable,
                           public.check_plural(_jobCountToEnable, 'job', 'jobs'));

        _action := CASE WHEN _infoOnly THEN 'would update' ELSE 'updating' END;

        RAISE INFO '%', Replace(_message, 'ACTION_PLACEHOLDER', _action);

        If _infoOnly Then
            _message := Replace(_message, 'ACTION_PLACEHOLDER', _action);
            CONTINUE;
        End If;

        UPDATE t_analysis_job
        SET job_state_id = 1
        WHERE job IN (SELECT job
                      FROM t_analysis_job
                      WHERE request_id = _requestInfo.Request_ID AND
                            job_state_id = 20
                      ORDER BY job
                      LIMIT _jobCountToEnable
                     );

        _message := Replace(_message, 'ACTION_PLACEHOLDER', 'updated');

        CALL post_log_entry ('Normal', _message, 'Update_Pending_Jobs');
    END LOOP;

    DROP TABLE T_Tmp_JobRequestsToProcess;
END
$$;


ALTER PROCEDURE public.update_pending_jobs(IN _requestid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_pending_jobs(IN _requestid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_pending_jobs(IN _requestid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdatePendingJobs';

