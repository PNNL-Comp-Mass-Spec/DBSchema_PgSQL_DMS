--
CREATE OR REPLACE PROCEDURE sw.synchronize_job_stats_with_dms
(
    _jobListToProcess text = '',
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Makes sure the job start/end times defined in T_Jobs match those in DMS
**      Only processes jobs with a state of 4 or 5 in T_Jobs
**
**  Arguments:
**    _jobListToProcess   Jobs to process; if blank, will process all jobs in T_Jobs
**
**  Auth:   mem
**  Date:   02/27/2010 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _insertCount int;
    _updateCount int;
    _defaultDate datetime;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    _jobListToProcess := Coalesce(_jobListToProcess, '');
    _infoOnly := Coalesce(_infoOnly, false);

    _defaultDate := make_date(2000, 1, 1);

    ---------------------------------------------------
    -- Table to hold jobs to process
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsToProcess (
        Job int
    )

    CREATE INDEX IX_Tmp_JobsToProcess_Job ON Tmp_JobsToProcess (Job);

    ---------------------------------------------------
    -- Populate Tmp_JobsToProcess
    ---------------------------------------------------

    If _jobListToProcess = '' Then
        INSERT INTO Tmp_JobsToProcess (Job)
        SELECT sw.t_jobs.job
        FROM sw.t_jobs
        WHERE sw.t_jobs.state IN (4,5);
    Else
        INSERT INTO Tmp_JobsToProcess (job)
        SELECT sw.t_jobs.job
        FROM sw.t_jobs
            INNER JOIN ( SELECT Value AS Job
                        FROM public.parse_delimited_integer_list ( _jobListToProcess, ',' )
                        ) ValueQ
            ON sw.t_jobs.job = ValueQ.job
        WHERE sw.t_jobs.state IN (4,5);
    End If;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    _message := format('Validating start/finish times for %s %s', _insertCount, public.check_plural(_insertCount, 'job', 'jobs'));

    ---------------------------------------------------
    -- Update jobs where the start or finish time differ
    ---------------------------------------------------

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        SELECT sw.t_jobs.job,
               Target.start AS Start,
               sw.t_jobs.start AS StartNew,
               Target.finish AS Finish,
               sw.t_jobs.finish AS FinishNew,
               Target.processing_time_minutes AS ProcTimeMinutes,
               JobProcTime.ProcessingTimeMinutes AS ProcTimeMinutesNew,
               Abs( extract(epoch FROM (sw.t_jobs.start - target.start)) ) AS StartDiffSeconds,
               Abs( extract(epoch FROM (sw.t_jobs.finish - target.Finish)) ) AS FinishDiffSeconds,
               Round(Abs(Coalesce(Target.processing_time_minutes, 0) - JobProcTime.ProcessingTimeMinutes), 2) AS ProcTimeDiffMinutes
        FROM sw.t_jobs
             INNER JOIN public.t_analysis_job Target
               ON sw.t_jobs.job = Target.job
             INNER JOIN Tmp_JobsToProcess JTP
               ON sw.t_jobs.job = JTP.job
             INNER JOIN V_Job_Processing_Time JobProcTime
               ON sw.t_jobs.job = JobProcTime.job
        WHERE Abs( extract(epoch FROM (sw.t_jobs.start - Coalesce(Target.start, _defaultDate))) )   > 1 OR
              Abs( extract(epoch FROM (sw.t_jobs.finish - Coalesce(Target.finish, _defaultDate))) ) > 1
              Abs(Coalesce(Target.processing_time_minutes, 0) - JobProcTime.ProcessingTimeMinutes)  > 0.1
        ORDER BY sw.t_jobs.job

    Else

        UPDATE public.t_analysis_job
        SET target.start = sw.t_jobs.start,
            target.Finish = sw.t_jobs.finish,
            processing_time_minutes = JobProcTime.ProcessingTimeMinutes
        FROM sw.t_jobs
             INNER JOIN public.t_analysis_job Target
               ON sw.t_jobs.job = Target.job
             INNER JOIN Tmp_JobsToProcess JTP
               ON sw.t_jobs.job = JTP.job
             INNER JOIN sw.V_Job_Processing_Time JobProcTime
               ON sw.t_jobs.job = JobProcTime.job
        WHERE Abs( extract(epoch FROM (sw.t_jobs.start - Coalesce(Target.start, _defaultDate))) )   > 1 OR
              Abs( extract(epoch FROM (sw.t_jobs.finish - Coalesce(Target.finish, _defaultDate))) ) > 1
              Abs(Coalesce(Target.processing_time_minutes, 0) - JobProcTime.ProcessingTimeMinutes)  > 0.1
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('%s; Updated %s %s', _message, _updateCount, public.check_plural(_updateCount, 'job', 'jobs'));
    End If;

    RAISE INFO '%', _message;

    DROP TABLE Tmp_JobsToProcess;

END
$$;

COMMENT ON PROCEDURE sw.synchronize_job_stats_with_dms IS 'SynchronizeJobStatsWithDMS';
