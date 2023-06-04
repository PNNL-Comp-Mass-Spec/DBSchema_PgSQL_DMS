--
CREATE OR REPLACE PROCEDURE public.update_analysis_job_state_name_cached
(
    _jobStart int = 0,
    _jobFinish int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates column state_name_cached in T_Analysis_Job for 1 or more jobs
**
**  Auth:   mem
**  Date:   12/12/2007 mem - Initial version (Ticket #585)
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          04/03/2014 mem - Now showing _message when _infoOnly is true
**          05/27/2014 mem - Now using a temporary table to track the jobs that need to be updated (due to deadlock issues)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobCount int := 0;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    _jobStart := Coalesce(_jobStart, 0);
    _jobFinish := Coalesce(_jobFinish, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    If _jobFinish = 0 Then
        _jobFinish := 2147483647;
    End If;

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job Int Not Null
    )

    ---------------------------------------------------
    -- Find jobs that need to be updated
    ---------------------------------------------------
    --
    INSERT INTO Tmp_JobsToUpdate (job)
    SELECT AJ.job
    FROM t_analysis_job AJ
         INNER JOIN V_Analysis_Job_and_Dataset_Archive_State AJDAS
           ON AJ.job = AJDAS.job
    WHERE AJ.job >= _jobStart AND
          AJ.job <= _jobFinish AND
          AJ.state_name_cached Is Distinct From AJDAS.Job_State;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        ---------------------------------------------------
        -- Preview the jobs
        ---------------------------------------------------
        --
        SELECT AJ.job AS Job,
               AJ.state_name_cached AS State_Name_Cached,
               AJDAS.Job_State AS New_State_Name_Cached
        FROM t_analysis_job AJ INNER JOIN
             V_Analysis_Job_and_Dataset_Archive_State AJDAS ON AJ.job = AJDAS.job
        WHERE AJ.job IN (Select job From Tmp_JobsToUpdate);
        --
        GET DIAGNOSTICS _jobCount = ROW_COUNT;

        If _jobCount = 0 Then
            _message := 'All jobs have up-to-date cached job state names';
        Else
            _message := format('Found %s %s to update',
                                _jobCount, public.check_plural(_jobCount, 'job', 'jobs');
        End If;

        RAISE INFO '%', _message;
    Else

        If Exists (Select * From Tmp_JobsToUpdate) Then
            ---------------------------------------------------
            -- Update the jobs
            ---------------------------------------------------
            --
            UPDATE t_analysis_job AJ
            SET state_name_cached = Coalesce(AJDAS.Job_State, '')
            FROM V_Analysis_Job_and_Dataset_Archive_State AJDAS
            WHERE AJ.job = AJDAS.Job AND AJ.job IN (Select Job From Tmp_JobsToUpdate)
            --
            GET DIAGNOSTICS _jobCount = ROW_COUNT;

            If _jobCount = 0 Then
                _message := '';
            Else
                _message := format('Updated the cached job state name for %s %s',
                                    _jobCount, public.check_plural(_jobCount, 'job', 'jobs');
            End If;
        End If;

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _jobCount, public.check_plural(_jobCount, 'job', 'jobs'));

    If Not _infoOnly Then
        CALL post_usage_log_entry ('Update_Analysis_Job_State_Name_Cached', _usageMessage;);
    End If;

    DROP TABLE Tmp_JobsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.update_analysis_job_state_name_cached IS 'UpdateAnalysisJobStateNameCached';
