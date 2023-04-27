--
CREATE OR REPLACE PROCEDURE sw.update_job_step_processing_stats
(
    _minimumTimeIntervalMinutes integer = 4,
    _minimumTimeIntervalMinutesForIdenticalStats integer = 60,
    INOUT _message text = '',
    _infoOnly boolean = false
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
    _myRowCount int := 0;
    _timeIntervalLastUpdateMinutes real;
    _timeIntervalIdenticalStatsMinutes real;
    _mostRecentPostingTime timestamp;
    _updateTable boolean := true;
BEGIN
    _timeIntervalLastUpdateMinutes := 0;
    _timeIntervalIdenticalStatsMinutes := 0;

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
    )

    -----------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------

    _message := '';
    _infoOnly := Coalesce(_infoOnly, false);

    _mostRecentPostingTime := Null;

    -----------------------------------------------------
    -- Lookup the most recent posting time
    -----------------------------------------------------
    --
    SELECT MAX(entered) INTO _mostRecentPostingTime
    FROM sw.t_job_step_processing_stats
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

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

    If _updateTable Or _infoOnly Then
        -----------------------------------------------------
        -- Cache the new stats
        -----------------------------------------------------
        --
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
        WHERE (State = 4)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _infoOnly Then
            SELECT *
            FROM Tmp_JobStepProcessingStats
            ORDER BY Job, Step
        Else
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
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _message := format('Appended %s rows to the Job Step Processing Stats table', _myRowCount);
        End If;

    Else
        _message := ('Update skipped since last update was %s minutes ago', round(_timeIntervalLastUpdateMinutes, 1));
    End If;

    DROP TABLE Tmp_JobStepProcessingStats;
END
$$;

COMMENT ON PROCEDURE sw.update_job_step_processing_stats IS 'UpdateJobStepProcessingStats';
