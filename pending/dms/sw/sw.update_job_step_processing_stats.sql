--
CREATE OR REPLACE PROCEDURE sw.update_job_step_processing_stats
(
    _minimumTimeIntervalMinutes integer = 4,
    _minimumTimeIntervalMinutesForIdenticalStats integer = 60,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Appends new entries to T_Job_Step_Processing_Stats,
**      showing details of running job steps
**
**  Arguments:
**    _minimumTimeIntervalMinutes                    Set this to 0 to force the addition of new data to T_Job_Step_Processing_Stats
**    _minimumTimeIntervalMinutesForIdenticalStats   This controls how often identical stats will get added to T_Job_Step_Processing_Stats
**
**  Auth:   mem
**  Date:   11/23/2015
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _insertCount int;
    _timeIntervalLastUpdateMinutes real;
    _timeIntervalIdenticalStatsMinutes real;
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

    _message := '';
    _returnCode := '';
    _infoOnly := Coalesce(_infoOnly, false);

    _mostRecentPostingTime := Null;

    -----------------------------------------------------
    -- Lookup the most recent posting time
    -----------------------------------------------------

    SELECT MAX(entered)
    INTO _mostRecentPostingTime
    FROM sw.t_job_step_processing_stats;

    If Coalesce(_minimumTimeIntervalMinutes, 0) = 0 Or _mostRecentPostingTime Is Null Then
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
        RunTime_Minutes numeric(9,1) NULL,
        Job_Progress real NULL,
        RunTime_Predicted_Hours numeric(9,2) NULL,
        ProgRunner_CoreUsage real NULL,
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
                                            ProgRunner_CoreUsage,
                                            CPU_Load,
                                            Actual_CPU_Load )
    SELECT Job,
           Step,
           Processor,
           RunTime_Minutes,
           Job_Progress,
           RunTime_Predicted_Hours,
           ProgRunner_CoreUsage,
           CPU_Load,
           Actual_CPU_Load
    FROM V_Job_Steps
    WHERE State = 4;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-9s %-4s %-25s %-15s %-12s %-23s %-20s %-8s %-15s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Step',
                            'Processor',
                            'RunTime_Minutes',
                            'Job_Progress',
                            'RunTime_Predicted_Hours',
                            'ProgRunner_CoreUsage',
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
                                     '--------------------',
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
                   ProgRunner_CoreUsage,
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
                                _previewData.ProgRunner_CoreUsage,
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
    FROM Tmp_JobStepProcessingStats
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    _message := format('Appended %s rows to the Job Step Processing Stats table', _insertCount);

    DROP TABLE Tmp_JobStepProcessingStats;
    RETURN;

END
$$;

COMMENT ON PROCEDURE sw.update_job_step_processing_stats IS 'UpdateJobStepProcessingStats';
