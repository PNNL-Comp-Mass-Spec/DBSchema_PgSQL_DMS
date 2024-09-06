--
-- Name: update_cached_analysis_job_state_name_recent_and_active(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_analysis_job_state_name_recent_and_active(IN _mostrecentdays integer DEFAULT 7, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update column state_name_cached in t_analysis_job for recent jobs and active jobs
**
**  Arguments:
**    _mostRecentDays   Update jobs created or started within the given number of days; if 0, only update active jobs
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   09/05/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _dateThreshold timestamp;
    _jobCountUpdated int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mostRecentDays := Coalesce(_mostRecentDays, 7);
    _infoOnly       := Coalesce(_infoOnly, false);

    If _mostRecentDays <= 0 Then
        _mostRecentDays := 0;
        _dateThreshold := CURRENT_DATE + make_interval(years => 10);
    Else
        _dateThreshold := CURRENT_DATE - make_interval(days => _mostRecentDays);
    End If;

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int NOT NULL
    );

    ---------------------------------------------------
    -- Find jobs that need to be updated
    ---------------------------------------------------

    INSERT INTO Tmp_JobsToUpdate (job)
    SELECT job
    FROM t_analysis_job
    WHERE _mostRecentDays > 0 AND (created >= _dateThreshold OR start >= _dateThreshold) OR
          job_state_id IN (1, 2, 19);   -- New, Job In Progress, or Special Proc. Waiting

    ---------------------------------------------------
    -- Update cached state names
    ---------------------------------------------------

    CALL update_analysis_job_state_name_cached_work (
            _infoonly        => _infoonly,
            _jobCountUpdated => _jobCountUpdated,   -- Output
            _message         => _message,           -- Output
            _returncode      => _returncode);       -- Output

    If _jobCountUpdated > 0 And Not _infoonly Then
        RAISE INFO 'Updated cached job state name for % %', _jobCountUpdated, public.check_plural(_jobCountUpdated, 'job', 'jobs');
    End If;

    DROP TABLE Tmp_JobsToUpdate;
END
$$;


ALTER PROCEDURE public.update_cached_analysis_job_state_name_recent_and_active(IN _mostrecentdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

