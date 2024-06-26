--
-- Name: update_actual_cpu_loading(boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_actual_cpu_loading(IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update actual_cpu_load based on t_processor_status
**      (using Prog_Runner_Core_Usage values pushed by the Analysis Manager)
**
**  Arguments:
**    _infoOnly     When true, preview the results; when false, update sw.t_job_steps
**
**  Auth:   mem
**  Date:   11/20/2015 mem - Initial release
**          01/05/2016 mem - Check for load values over 255
**          05/26/2017 mem - Ignore jobs running remotely
**          08/02/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    ---------------------------------------------------
    -- Look for actively running Progrunner tasks in sw.t_processor_status
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_PendingUpdates (
        Processor_Name text NOT NULL,
        Job int NOT NULL,
        Step int NOT NULL,
        New_CPU_Load int NOT NULL
    );

    ---------------------------------------------------
    -- Find managers with an active job step and valid values for Prog_Runner_Process_ID and Prog_Runner_Core_Usage
    ---------------------------------------------------

    INSERT INTO Tmp_PendingUpdates (
        Processor_Name,
        Job,
        Step,
        New_CPU_Load
    )
    SELECT PS.processor_name,
           JS.job,
           JS.step,
           Round(PS.prog_runner_core_usage::numeric, 0) AS New_CPU_Load
    FROM sw.t_processor_status PS
         INNER JOIN sw.t_job_steps JS
           ON PS.job = JS.job AND
              PS.job_step = JS.step AND
              PS.processor_name = JS.processor
    WHERE JS.state = 4 AND
          Coalesce(JS.remote_info_id, 0) <= 1 AND
          Coalesce(PS.prog_runner_process_id, 0) > 0 AND
          NOT (PS.prog_runner_core_usage IS NULL);

    -- Make sure New_CPU_Load is <= 32767

    UPDATE Tmp_PendingUpdates
    SET New_CPU_Load = 32767
    WHERE New_CPU_Load > 32767;

    If Not Exists (SELECT * FROM Tmp_PendingUpdates) Then
        DROP TABLE Tmp_PendingUpdates;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Preview the results or update sw.t_job_steps
    ---------------------------------------------------

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-9s %-4s %-25s %-15s %-12s %-20s %-8s %-15s %-12s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Step',
                            'Tool',
                            'RunTime_Minutes',
                            'Job_Progress',
                            'Processor',
                            'CPU_Load',
                            'Actual_CPU_Load',
                            'New_CPU_Load',
                            'Dataset'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '----',
                                     '-------------------------',
                                     '---------------',
                                     '------------',
                                     '--------------------',
                                     '--------',
                                     '---------------',
                                     '------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT JS.Job,
                   JS.Step,
                   JS.Tool,
                   JS.RunTime_Minutes,
                   JS.Job_Progress,
                   JS.Processor,
                   JS.CPU_Load,
                   JS.Actual_CPU_Load,
                   U.New_CPU_Load,
                   JS.Dataset
            FROM Tmp_PendingUpdates U
                 INNER JOIN V_Job_Steps JS
                   ON U.Job = JS.Job AND
                      U.Step = JS.Step AND
                      U.Processor_Name = JS.Processor
            ORDER BY JS.Tool, JS.Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Step,
                                _previewData.Tool,
                                _previewData.RunTime_Minutes,
                                _previewData.Job_Progress,
                                _previewData.Processor,
                                _previewData.CPU_Load,
                                _previewData.Actual_CPU_Load,
                                _previewData.New_CPU_Load,
                                _previewData.Dataset
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        UPDATE sw.t_job_steps JS
        SET actual_cpu_load = U.New_CPU_Load
        FROM Tmp_PendingUpdates U
        WHERE U.job = JS.job AND
              U.step = JS.step AND
              U.Processor_Name = JS.processor AND
              JS.actual_cpu_load <> U.New_CPU_Load OR
              JS.actual_cpu_load IS NULL;
    End If;

    DROP TABLE Tmp_PendingUpdates;
END
$$;


ALTER PROCEDURE sw.update_actual_cpu_loading(IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_actual_cpu_loading(IN _infoonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_actual_cpu_loading(IN _infoonly boolean) IS 'UpdateActualCPULoading';

