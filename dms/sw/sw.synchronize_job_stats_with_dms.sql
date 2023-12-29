--
-- Name: synchronize_job_stats_with_dms(text, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.synchronize_job_stats_with_dms(IN _joblisttoprocess text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make sure the job start/end times defined in sw.t_jobs match those in public.t_analysis_job
**      Only processes jobs with a state of 4 or 5 in sw.t_jobs
**
**  Arguments:
**    _jobListToProcess     Jobs to process; if blank, will process all jobs in sw.t_jobs
**    _infoOnly             When true, preview updates
**
**  Auth:   mem
**  Date:   02/27/2010 mem - Initial version
**          08/12/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
    _insertCount int;
    _updateCount int;
    _defaultDate timestamp;
    _msg text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _jobListToProcess := Trim(Coalesce(_jobListToProcess, ''));
    _infoOnly         := Coalesce(_infoOnly, false);

    _defaultDate := make_date(2000, 1, 1);

    ---------------------------------------------------
    -- Table to hold jobs to process
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsToProcess (
        Job int
    );

    CREATE INDEX IX_Tmp_JobsToProcess_Job ON Tmp_JobsToProcess (Job);

    RAISE INFO '';

    ---------------------------------------------------
    -- Populate Tmp_JobsToProcess
    ---------------------------------------------------

    If _jobListToProcess = '' Then
        INSERT INTO Tmp_JobsToProcess (Job)
        SELECT sw.t_jobs.job
        FROM sw.t_jobs
        WHERE sw.t_jobs.state IN (4, 5);

        If Not FOUND Then
            _message := 'No jobs in sw.t_jobs are in state 4 or 5';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_JobsToProcess;
            RETURN;
        End If;
    Else
        INSERT INTO Tmp_JobsToProcess (job)
        SELECT sw.t_jobs.job
        FROM sw.t_jobs
             INNER JOIN ( SELECT Value AS Job
                          FROM public.parse_delimited_integer_list(_jobListToProcess)
                        ) ValueQ
            ON sw.t_jobs.job = ValueQ.job
        WHERE sw.t_jobs.state IN (4, 5);

        If Not FOUND Then
            _message := 'None of the specified jobs are in state 4 or 5 in sw.t_jobs';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_JobsToProcess;
            RETURN;
        End If;
    End If;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    _message := format('Validating start/finish times for %s %s', _insertCount, public.check_plural(_insertCount, 'job', 'jobs'));
    RAISE INFO '%', _message;

    ---------------------------------------------------
    -- Update jobs where the start or finish time differ
    ---------------------------------------------------

    If _infoOnly Then

        RAISE INFO '';

        If Not Exists ( SELECT sw.t_jobs.Job
                        FROM sw.t_jobs
                             INNER JOIN public.t_analysis_job Target
                               ON sw.t_jobs.job = Target.job
                             INNER JOIN Tmp_JobsToProcess JTP
                               ON sw.t_jobs.job = JTP.job
                             INNER JOIN sw.V_Job_Processing_Time JobProcTime
                               ON sw.t_jobs.job = JobProcTime.job
                        WHERE Abs(extract(epoch FROM (sw.t_jobs.start  - Coalesce(Target.start,  _defaultDate))) ) > 1 OR   -- Start or Finish times differ by more than 1 second
                              Abs(extract(epoch FROM (sw.t_jobs.finish - Coalesce(Target.finish, _defaultDate))) ) > 1 OR
                              Abs(Coalesce(Target.processing_time_minutes, 0) - JobProcTime.Processing_Time_Minutes) > 0.1  -- Processing time differs by more than 6 seconds
                      )
        Then
            _message := 'No jobs in sw.t_jobs with state 4 or 5 have start/finish times or processing times that disagree with public.t_analysis_job';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_JobsToProcess;
            RETURN;
        End If;

        _formatSpecifier := '%-9s %-20s %-20s %-20s %-20s %-17s %-21s %-18s %-19s %-22s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Start',
                            'Start_New',
                            'Finish',
                            'Finish_New',
                            'Proc_Time_Minutes',
                            'Proc_Time_Minutes_New',
                            'Start_Diff_Seconds',
                            'Finish_Diff_Seconds',
                            'Proc_Time_Diff_Minutes'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------',
                                     '-----------------',
                                     '---------------------',
                                     '------------------',
                                     '-------------------',
                                     '----------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT sw.t_jobs.Job,
                   public.timestamp_text(Target.start) AS Start,
                   public.timestamp_text(sw.t_jobs.start) AS Start_New,
                   public.timestamp_text(Target.finish) AS Finish,
                   public.timestamp_text(sw.t_jobs.finish) AS Finish_New,
                   Round(Target.processing_time_minutes::numeric, 2) AS Proc_Time_Minutes,
                   Round(JobProcTime.Processing_Time_Minutes::numeric, 2) AS Proc_Time_Minutes_New,
                   Round(Abs(extract(epoch FROM (sw.t_jobs.start  - target.start))  ), 1) AS Start_Diff_Seconds,
                   Round(Abs(extract(epoch FROM (sw.t_jobs.finish - target.Finish)) ), 1) AS Finish_Diff_Seconds,
                   Round(Abs(Coalesce(Target.processing_time_minutes, 0) - JobProcTime.Processing_Time_Minutes)::numeric, 2) AS Proc_Time_Diff_Minutes
            FROM sw.t_jobs
                 INNER JOIN public.t_analysis_job Target
                   ON sw.t_jobs.job = Target.job
                 INNER JOIN Tmp_JobsToProcess JTP
                   ON sw.t_jobs.job = JTP.job
                 INNER JOIN sw.V_Job_Processing_Time JobProcTime
                   ON sw.t_jobs.job = JobProcTime.job
            WHERE Abs(extract(epoch FROM (sw.t_jobs.start  - Coalesce(Target.start,  _defaultDate))) ) > 1 OR   -- Start or Finish times differ by more than 1 second
                  Abs(extract(epoch FROM (sw.t_jobs.finish - Coalesce(Target.finish, _defaultDate))) ) > 1 OR
                  Abs(Coalesce(Target.processing_time_minutes, 0) - JobProcTime.Processing_Time_Minutes) > 0.1    -- Processing time differs by more than 6 seconds
            ORDER BY sw.t_jobs.job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Start,
                                _previewData.Start_New,
                                _previewData.Finish,
                                _previewData.Finish_New,
                                _previewData.Proc_Time_Minutes,
                                _previewData.Proc_Time_Minutes_New,
                                _previewData.Start_Diff_Seconds,
                                _previewData.Finish_Diff_Seconds,
                                _previewData.Proc_Time_Diff_Minutes
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_JobsToProcess;
        RETURN;
    End If;

    UPDATE public.t_analysis_job Target
    SET start = J.start,
        Finish = J.finish,
        processing_time_minutes = JobProcTime.Processing_Time_Minutes
    FROM sw.t_jobs J
         INNER JOIN Tmp_JobsToProcess JTP
           ON J.job = JTP.job
         INNER JOIN sw.V_Job_Processing_Time JobProcTime
           ON J.job = JobProcTime.job
    WHERE J.job = Target.job AND
          (Abs(extract(epoch FROM (J.start  - Coalesce(Target.start,  _defaultDate))) ) > 1 OR   -- Start or Finish times differ by more than 1 second
           Abs(extract(epoch FROM (J.finish - Coalesce(Target.finish, _defaultDate))) ) > 1 OR
           Abs(Coalesce(Target.processing_time_minutes, 0) - JobProcTime.Processing_Time_Minutes) > 0.1 -- Processing time differs by more than 6 seconds
          );
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    _msg := format('Updated %s %s', _updateCount, public.check_plural(_updateCount, 'job', 'jobs'));
    RAISE INFO '%', _msg;

    _message := format('%s; %s', _message, Lower(_msg));

    DROP TABLE Tmp_JobsToProcess;

END
$$;


ALTER PROCEDURE sw.synchronize_job_stats_with_dms(IN _joblisttoprocess text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE synchronize_job_stats_with_dms(IN _joblisttoprocess text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.synchronize_job_stats_with_dms(IN _joblisttoprocess text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SynchronizeJobStatsWithDMS';

