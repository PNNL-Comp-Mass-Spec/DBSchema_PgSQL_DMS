--
-- Name: synchronize_task_stats_with_task_steps(boolean, boolean, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.synchronize_task_stats_with_task_steps(IN _infoonly boolean DEFAULT true, IN _completedjobsonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Makes sure the capture task job stats (start and finish)
**          agree with the capture task job steps for each capture task job
**
**  Auth:   mem
**  Date:   01/22/2010 mem - Initial version
**          03/10/2014 mem - Fixed logic related to _completedJobsOnly
**          09/30/2022 mem - Fixed bug that used the wrong state_id for completed tasks
**                         - Ported to PostgreSQL
**          02/02/2023 mem - Update table aliases
**          05/12/2023 mem - Rename variables
**          05/29/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _insertCount int;
    _updateCount int;
    _formatSpecifier text := '%-10s %-10s %-20s %-20s %-20s %-20s';
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Validate the inputs; clear the outputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int,
        StartNew timestamp Null,
        FinishNew timestamp Null
    );

    CREATE UNIQUE INDEX IX_Tmp_JobsToUpdate ON Tmp_JobsToUpdate (Job);

    ---------------------------------------------------
    -- Find capture task jobs that need to be updated
    -- When _completedJobsOnly is true, filter on task state 3=complete
    ---------------------------------------------------

    INSERT INTO Tmp_JobsToUpdate ( Job )
    SELECT T.job
    FROM cap.t_tasks T
         INNER JOIN cap.t_task_steps TS
           ON T.Job = TS.Job
    WHERE (T.State = 3 And _completedJobsOnly OR Not _completedJobsOnly) AND
          T.Finish < TS.Finish
    GROUP BY T.job
    UNION
    SELECT T.Job
    FROM cap.t_tasks T
         INNER JOIN cap.t_task_steps TS
           ON T.Job = TS.Job
    WHERE (T.State = 3 And _completedJobsOnly OR Not _completedJobsOnly) AND
          T.Start > TS.Start
    GROUP BY T.Job;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    If _insertCount = 0 Then
        If _completedJobsOnly Then
            _message := 'All completed';
        Else
            _message := 'All';
        End If;

        _message := format('%s capture task jobs have up-to-date Start and Finish times; nothing to do', _message);

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        DROP TABLE Tmp_JobsToUpdate;
        RETURN;
    Else
        _message := format('%s %s Start and/or Finish times times updated in cap.t_tasks',
                           _insertCount,
                           public.check_plural(_insertCount, 'capture task job needs to have its', 'capture task jobs need to have their'));
    End If;

    UPDATE Tmp_JobsToUpdate
    SET StartNew = SourceQ.Step_Start,
        FinishNew = SourceQ.Step_Finish
    FROM ( SELECT T.Job,
                  MIN(TS.Start) AS Step_Start,
                  MAX(TS.Finish) AS Step_Finish
           FROM cap.t_tasks T
                INNER JOIN cap.t_task_steps TS
                  ON T.Job = TS.Job
           WHERE T.Job IN (SELECT Job FROM Tmp_JobsToUpdate)
           GROUP BY T.Job
         ) SourceQ
    WHERE Tmp_JobsToUpdate.Job = SourceQ.Job;

    If _infoOnly Then

        RAISE INFO ' ';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'State',
                            'Start',
                            'Finish',
                            'Start_New',
                            'Finish_New'
                        );

        _infoHeadSeparator := format(_formatSpecifier,
                            '----------',
                            '----------',
                            '--------------------',
                            '--------------------',
                            '--------------------',
                            '--------------------'
                        );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT T.Job,
                   T.State,
                   T.Start,
                   T.Finish,
                   JTU.StartNew,
                   JTU.FinishNew
            FROM cap.t_tasks T
                 INNER JOIN Tmp_JobsToUpdate JTU
                   ON T.Job = JTU.Job
        LOOP
            _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.State,
                                    timestamp_text(_previewData.Start),
                                    timestamp_text(_previewData.Finish),
                                    timestamp_text(_previewData.StartNew),
                                    timestamp_text(_previewData.FinishNew)
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

    Else

        ---------------------------------------------------
        -- Update the Start/Finish times
        ---------------------------------------------------

        UPDATE cap.t_tasks Target
        SET Start = JTU.StartNew,
            Finish = JTU.FinishNew
        FROM Tmp_JobsToUpdate JTU
        WHERE Target.Job = JTU.Job;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Updated Start and/or Finish times in cap.t_tasks for %s capture task %s',
                           _updateCount,
                           public.check_plural(_updateCount, 'job', 'jobs'));
    End If;

    DROP TABLE Tmp_JobsToUpdate;
END
$$;


ALTER PROCEDURE cap.synchronize_task_stats_with_task_steps(IN _infoonly boolean, IN _completedjobsonly boolean, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE synchronize_task_stats_with_task_steps(IN _infoonly boolean, IN _completedjobsonly boolean, INOUT _message text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.synchronize_task_stats_with_task_steps(IN _infoonly boolean, IN _completedjobsonly boolean, INOUT _message text) IS 'SynchronizeTaskStatsWithTaskSteps or SynchronizeJobStatsWithJobSteps';

