--
-- Name: update_analysis_job_state_name_cached(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_analysis_job_state_name_cached(IN _jobstart integer DEFAULT 0, IN _jobfinish integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update column state_name_cached in t_analysis_job for one or more jobs
**
**  Arguments:
**    _jobStart     First job number
**    _jobFinish    Last job number; if 0 or a negative number, will use 2147483647
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   12/12/2007 mem - Initial version (Ticket #585)
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          04/03/2014 mem - Now showing _message when _infoOnly is true
**          05/27/2014 mem - Now using a temporary table to track the jobs that need to be updated (due to deadlock issues)
**          02/26/2024 mem - Ported to PostgreSQL
**          09/05/2024 mem - Refactor code into procedure update_analysis_job_state_name_cached_work()
**
*****************************************************/
DECLARE
    _jobCountUpdated int := 0;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _jobStart  := Coalesce(_jobStart, 0);
    _jobFinish := Coalesce(_jobFinish, 0);
    _infoOnly  := Coalesce(_infoOnly, false);

    If _jobFinish <= 0 Then
        _jobFinish := 2147483647;
    End If;

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int NOT NULL
    );

    ---------------------------------------------------
    -- Find jobs that need to be updated
    ---------------------------------------------------

    INSERT INTO Tmp_JobsToUpdate (job)
    SELECT AJ.job
    FROM t_analysis_job AJ
         INNER JOIN V_Analysis_Job_and_Dataset_Archive_State AJDAS
           ON AJ.job = AJDAS.job
    WHERE AJ.job >= _jobStart AND
          AJ.job <= _jobFinish AND
          AJ.state_name_cached IS DISTINCT FROM AJDAS.Job_State;

    ---------------------------------------------------
    -- Update cached state names
    ---------------------------------------------------

    CALL update_analysis_job_state_name_cached_work (
            _infoonly        => _infoonly,
            _jobCountUpdated => _jobCountUpdated,   -- Output
            _message         => _message,           -- Output
            _returncode      => _returncode);       -- Output

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _jobCountUpdated, public.check_plural(_jobCountUpdated, 'job', 'jobs'));

    If Not _infoOnly Then
        CALL post_usage_log_entry ('update_analysis_job_state_name_cached', _usageMessage);
    End If;

    DROP TABLE Tmp_JobsToUpdate;
END
$$;


ALTER PROCEDURE public.update_analysis_job_state_name_cached(IN _jobstart integer, IN _jobfinish integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_analysis_job_state_name_cached(IN _jobstart integer, IN _jobfinish integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_analysis_job_state_name_cached(IN _jobstart integer, IN _jobfinish integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateAnalysisJobStateNameCached';

