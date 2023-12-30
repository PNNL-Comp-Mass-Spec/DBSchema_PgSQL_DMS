--
-- Name: update_job_step_processing_stats(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_job_step_processing_stats(IN _minimumtimeintervalminutes integer DEFAULT 4, IN _minimumtimeintervalminutesforidenticalstats integer DEFAULT 60, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Append new entries to sw.T_Job_Step_Processing_Stats, showing details of running job steps
**
**  Arguments:
**    _minimumTimeIntervalMinutes                   Set this to 0 to force the addition of new data to sw.T_Job_Step_Processing_Stats
**    _minimumTimeIntervalMinutesForIdenticalStats  This controls how often identical stats will get added to the table
**    _infoOnly                                     When true, preview updates
**    _message                                      Status message
**    _returnCode                                   Return code
**
**  Auth:   mem
**  Date:   11/23/2015
**          08/14/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _insertCount int;
    _timeIntervalLastUpdateMinutes numeric;
    _timeIntervalIdenticalStatsMinutes numeric;
    _mostRecentPostingTime timestamp;
    _updateTable boolean := true;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _timeIntervalLastUpdateMinutes := 0;
    _timeIntervalIdenticalStatsMinutes := 0;

    -----------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------

    _minimumTimeIntervalMinutes                  := Coalesce(_minimumTimeIntervalMinutes, 0);
    _minimumTimeIntervalMinutesForIdenticalStats := Coalesce(_minimumTimeIntervalMinutesForIdenticalStats, 60);
    _infoOnly                                    := Coalesce(_infoOnly, false);

    _mostRecentPostingTime := Null;

    -----------------------------------------------------
    -- Lookup the most recent posting time
    -----------------------------------------------------

    SELECT MAX(entered)
    INTO _mostRecentPostingTime
    FROM sw.t_job_step_processing_stats;

    If Not FOUND Or _minimumTimeIntervalMinutes <= 0 Then
        _updateTable := true;
    Else
        _timeIntervalLastUpdateMinutes := extract(epoch FROM (CURRENT_TIMESTAMP - _mostRecentPostingTime)) / 60.0;

        If _timeIntervalLastUpdateMinutes >= _minimumTimeIntervalMinutes Then
            _updateTable := true;
        Else
            _updateTable := false;
        End If;
    End If;

    If Not _updateTable And Not _infoOnly Then
        _message := format('Update skipped since last update was %s minutes ago', round(_timeIntervalLastUpdateMinutes, 1));
        RETURN;
    End If;

    CREATE TEMP TABLE Tmp_JobStepProcessingStats (
        Job int NOT NULL,
        Step int NOT NULL,
        Processor text NULL,
        RunTime_Minutes numeric NULL,
        Job_Progress real NULL,
        RunTime_Predicted_Hours numeric NULL,
        Prog_Runner_Core_Usage real NULL,
        CPU_Load int NULL,
        Actual_CPU_Load int
    );

    -----------------------------------------------------
    -- Cache the new stats
    -----------------------------------------------------

    INSERT INTO Tmp_JobStepProcessingStats( Job,
                                            Step,
                                            Processor,
                                            RunTime_Minutes,
                                            Job_Progress,
                                            RunTime_Predicted_Hours,
                                            Prog_Runner_Core_Usage,
                                            CPU_Load,
                                            Actual_CPU_Load )
    SELECT Job,
           Step,
           Processor,
           RunTime_Minutes,
           Job_Progress,
           RunTime_Predicted_Hours,
           Prog_Runner_Core_Usage,
           CPU_Load,
           Actual_CPU_Load
    FROM sw.V_Job_Steps
    WHERE State = 4;

    If _infoOnly Then

        RAISE INFO '';

        If Not Exists (SELECT job FROM Tmp_JobStepProcessingStats) Then
            _message := 'No running job steps were found in sw.V_Job_Steps';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_JobStepProcessingStats;
            RETURN;
        End If;

        _formatSpecifier := '%-9s %-4s %-25s %-15s %-12s %-23s %-22s %-8s %-15s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Step',
                            'Processor',
                            'RunTime_Minutes',
                            'Job_Progress',
                            'RunTime_Predicted_Hours',
                            'Prog_Runner_Core_Usage',
                            'CPU_Load',
                            'Actual_CPU_Load'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '----',
                                     '-------------------------',
                                     '---------------',
                                     '------------',
                                     '-----------------------',
                                     '----------------------',
                                     '--------',
                                     '---------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job,
                   Step,
                   Processor,
                   RunTime_Minutes,
                   Job_Progress,
                   RunTime_Predicted_Hours,
                   Prog_Runner_Core_Usage,
                   CPU_Load,
                   Actual_CPU_Load
            FROM Tmp_JobStepProcessingStats
            ORDER BY Job, Step
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Step,
                                _previewData.Processor,
                                _previewData.RunTime_Minutes,
                                _previewData.Job_Progress,
                                _previewData.RunTime_Predicted_Hours,
                                _previewData.Prog_Runner_Core_Usage,
                                _previewData.CPU_Load,
                                _previewData.Actual_CPU_Load
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_JobStepProcessingStats;
        RETURN;
    End If;

    INSERT INTO sw.t_job_step_processing_stats( entered,
                                                job,
                                                step,
                                                processor,
                                                runtime_minutes,
                                                job_progress,
                                                runtime_predicted_hours,
                                                prog_runner_core_usage,
                                                cpu_load,
                                                actual_cpu_load )
    SELECT CURRENT_TIMESTAMP::timestamp Entered,
           job,
           step,
           processor,
           runtime_minutes,
           job_progress,
           runtime_predicted_hours,
           prog_runner_core_usage,
           cpu_load,
           actual_cpu_load
    FROM Tmp_JobStepProcessingStats;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    _message := format('Appended %s rows to the Job Step Processing Stats table', _insertCount);

    DROP TABLE Tmp_JobStepProcessingStats;
END
$$;


ALTER PROCEDURE sw.update_job_step_processing_stats(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_job_step_processing_stats(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_job_step_processing_stats(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateJobStepProcessingStats';

